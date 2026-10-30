#!/usr/bin/env bash
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"
# probe.sh - read-only environment probe for the exam sandbox (Debian/Ubuntu; degrades elsewhere)
#
# Usage: bash probe.sh [options]
#   --no-net       skip ALL network checks (DNS, HTTPS, npm view, git)
#   --repo URL     also time `git ls-remote` and a shallow clone of URL (https://github.com/... only)
#   --keep-clone   keep the clone made by --repo (default: deleted)
#   -h, --help     show this help
#
# Reports: OS, CPU/memory/disk, timezone, runtimes and tools, Codex version, entry NAMES in ~/.codex,
# a whitelist summary of ~/.codex/config.toml, workspace git state, whether port 3000 is free and,
# unless --no-net, HTTPS reachability of github.com, pypi.org, files.pythonhosted.org, registry.npmjs.org.
# Safety: no `set -e`; every external command is guarded and time-limited; runtime < 60 s, also with --repo.
# Never prints secrets: no env listing, never opens ~/.codex/auth.json, config.toml only through the
# whitelist summary, never runs `codex login status`.
# Writes only under /tmp (or $PROBE_TMP); `codex --version` itself may create ~/.codex/tmp, as any codex
# start does. No installs, no pip download, no git push. Always exits 0.

NET=1; REPO_URL=""; KEEP_CLONE=0
BUDGET=55
PT="${PROBE_TMP:-/tmp}"

usage() { awk 'NR <= 2 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0" 2>/dev/null; }

while [ $# -gt 0 ]; do
  case "$1" in
    --no-net) NET=0 ;;
    --repo) shift; REPO_URL="${1:-}" ;;
    --repo=*) REPO_URL="${1#--repo=}" ;;
    --keep-clone) KEEP_CLONE=1 ;;
    -h|--help) usage; exit 0 ;;
    http://*|https://*|git@*|ssh://*) REPO_URL="$1" ;;
    *) printf 'probe: unknown option %s (try --help)\n' "$1" ;;
  esac
  [ $# -gt 0 ] && shift
done

FALSE_BIN="$(command -v false 2>/dev/null)"; [ -n "$FALSE_BIN" ] || FALSE_BIN="/usr/bin/false"
export PYTHONDONTWRITEBYTECODE=1 GIT_TERMINAL_PROMPT=0 GIT_OPTIONAL_LOCKS=0 GIT_ASKPASS="$FALSE_BIN" SSH_ASKPASS="$FALSE_BIN"
export NPM_CONFIG_UPDATE_NOTIFIER=false NPM_CONFIG_FUND=false NPM_CONFIG_AUDIT=false
export COREPACK_ENABLE_NETWORK=0 COREPACK_ENABLE_DOWNLOAD_PROMPT=0

TS="$(date +%Y%m%d-%H%M%S 2>/dev/null || echo now)"
LOG="$PT/probe-$TS.log"
TMPD="$(mktemp -d "$PT/probe-tmp.XXXXXX" 2>/dev/null)"
if [ -z "$TMPD" ] || [ ! -d "$TMPD" ]; then TMPD="$PT/probe-tmp.$$"; mkdir -p "$TMPD" 2>/dev/null; fi
( umask 077; : >"$LOG" ) 2>/dev/null || LOG="/dev/null"

has() { command -v "$1" >/dev/null 2>&1; }
TILDE="~"

# ---- time limits --------------------------------------------------------------------------------------
TO_BIN=""; TO_K=""
if has timeout; then TO_BIN="timeout"; elif has gtimeout; then TO_BIN="gtimeout"; fi
if [ -n "$TO_BIN" ] && "$TO_BIN" -k 1 3 true >/dev/null 2>&1; then TO_K="-k 1"; fi
to() { # to SECONDS cmd args...   (stdin is always /dev/null)
  _ts="$1"; shift
  if [ -n "$TO_BIN" ]; then
    # shellcheck disable=SC2086
    "$TO_BIN" $TO_K "$_ts" "$@" </dev/null
  elif has perl; then
    perl -e 'alarm shift @ARGV; exec { $ARGV[0] } @ARGV or exit 127' "$_ts" "$@" </dev/null
  else
    "$@" </dev/null
  fi
}
left() { echo $(( BUDGET - SECONDS )); }

# ---- redaction (applied to EVERYTHING printed or logged) ---------------------------------------------
redact() {
  LC_ALL=C sed -E \
    -e 's#([A-Za-z][A-Za-z0-9+.-]*://)[^[:space:]]*@#\1***@#g' \
    -e 's#(^|[^A-Za-z0-9_])(sk-|sk_live_|sk_test_|ghp_|gho_|ghu_|ghs_|ghr_|github_pat_|glpat-|xox[abposr]-|xapp-|AKIA|ASIA|AIza|ATATT|eyJ)[A-Za-z0-9_.=+/-]{6,}#\1\2***REDACTED***#g' \
    -e 's#([Bb]earer|BEARER|[Bb]asic|BASIC)[[:space:]]+[A-Za-z0-9_.=+/-]{6,}#\1 ***REDACTED***#g'
}
log() { printf '%s\n' "$*" | redact >>"$LOG" 2>/dev/null; }
logblock() { { printf '## %s\n' "$1"; cat; printf '\n'; } | redact >>"$LOG" 2>/dev/null; }
sum() { # sum MARK KEY TEXT...   MARK: OK | NG | ??
  _m="$1"; _k="$2"; shift 2
  _line="$(printf '%-3s %-9s %s' "$_m" "$_k" "$*" | LC_ALL=C tr '\n' ' ' | redact)"
  [ -n "$HOME" ] && [ "$HOME" != "/" ] && _line="${_line//"$HOME"/$TILDE}"
  [ "${#_line}" -gt 200 ] && _line="${_line:0:197}..."
  printf '%s\n' "$_line"
  printf 'SUMMARY %s\n' "$_line" >>"$LOG" 2>/dev/null
}
first() { head -n 1 | LC_ALL=C tr -d '\r'; }
vnum() { LC_ALL=C sed -E 's/^[^0-9]*([0-9][0-9A-Za-z.+-]*).*/\1/'; }
tool_ver() { # tool_ver tool [args] -> version number, '-' if missing, '?' if it failed
  _t="$1"; shift
  if ! has "$_t"; then echo "-"; return 0; fi
  _o="$(to 4 "$_t" "$@" 2>"$TMPD/ver.err")"; _rc=$?
  [ -n "$_o" ] || _o="$(cat "$TMPD/ver.err" 2>/dev/null)"
  _l="$(printf '%s\n' "$_o" | LC_ALL=C grep -m 1 '[0-9]' | LC_ALL=C tr -d '\r')"
  log "ver: $_t $* -> rc=$_rc: $_l"
  if [ "$_rc" -ne 0 ] || [ -z "$_l" ]; then echo "?"; return 0; fi
  printf '%s\n' "$_l" | vnum
}
names_in() { # names_in DIR -> space separated entry names (no content), 'none' if missing
  if [ ! -d "$1" ]; then echo "none"; return 0; fi
  _n="$(ls -A1 "$1" 2>/dev/null | head -n 30 | LC_ALL=C tr '\n' ' ')"
  echo "${_n:-empty}"
}

printf '== kit probe | %s KST | net=%s | log=%s\n' "$(TZ=KST-9 date '+%F %H:%M' 2>/dev/null)" "$([ "$NET" = 1 ] && echo on || echo off)" "$LOG"
log "probe start $(date 2>/dev/null) timeout=${TO_BIN:-perl/none}"

# ---- OS / user ----------------------------------------------------------------------------------------
if [ -r /etc/os-release ]; then
  OSN="$(sed -n 's/^PRETTY_NAME=//p' /etc/os-release 2>/dev/null | first | LC_ALL=C tr -d '"')"
elif has sw_vers; then OSN="macOS $(sw_vers -productVersion 2>/dev/null)"
else OSN="$(uname -s 2>/dev/null)"; fi
sum OK os "${OSN:-?} | $(uname -m 2>/dev/null) | kernel $(uname -r 2>/dev/null)"

UIDN="$(id -u 2>/dev/null)"
sum OK user "$(id -un 2>/dev/null) uid=$UIDN HOME=$HOME pwd=$(pwd)"

if has apt-get; then sum OK apt "apt-get $(tool_ver apt-get --version) present (update/install 은 실행하지 않음)"
elif has apk; then sum "??" apt "no apt-get (apk present)"
else sum "??" apt "no apt-get"; fi

# ---- CPU / memory / disk / timezone ------------------------------------------------------------------
NCPU="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo '?')"
if [ -r /proc/meminfo ]; then
  MEM="$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%.1fG total, %.1fG avail", t/1048576, a/1048576}' /proc/meminfo 2>/dev/null)"
elif has sysctl; then
  MEM="$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.1fG total", $1/1073741824}')"
fi
CG=""
if [ -r /sys/fs/cgroup/memory.max ]; then CG="$(cat /sys/fs/cgroup/memory.max 2>/dev/null)"
elif [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then CG="$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)"; fi
case "$CG" in
  ''|max) CGS="" ;;
  *[!0-9]*) CGS=" | cgroup $CG" ;;
  *) CGS=" | cgroup $(awk -v b="$CG" 'BEGIN{ if (b > 1e15) print "unlimited"; else printf "%.1fG", b/1073741824 }')" ;;
esac
sum OK cpu/mem "$NCPU cpu | ${MEM:-?}$CGS"
DISK="$(df -Pk "$HOME" "$PT" 2>/dev/null | awk 'NR>1 && !seen[$6]++ {printf "%s%s %.1fG free", (n++ ? "; " : ""), $6, $4/1048576}')"
sum OK disk "${DISK:-?}"

TZA="$(TZ=Asia/Seoul date +%z 2>/dev/null)"; TZB="$(TZ=KST-9 date +%z 2>/dev/null)"
if [ "$TZA" = "+0900" ]; then sum OK tz "Asia/Seoul OK (tzdata) | 지금 $(TZ=KST-9 date '+%F %H:%M') KST"
elif [ "$TZB" = "+0900" ]; then sum "??" tz "no tzdata -> TZ=KST-9 사용 (키트 스킬은 이미 TZ=KST-9)"
else sum NG tz "TZ odd: Asia/Seoul=$TZA KST-9=$TZB"; fi

# ---- runtimes -----------------------------------------------------------------------------------------
V_GIT="$(tool_ver git --version)"; V_PY="$(tool_ver python3 --version)"
if has pip3; then V_PIP="$(tool_ver pip3 --version)"
elif has pip; then V_PIP="$(tool_ver pip --version)"
elif has python3 && to 6 python3 -m pip --version >"$TMPD/pip" 2>&1; then V_PIP="$(first <"$TMPD/pip" | vnum) (python3 -m pip)"
else V_PIP="-"; fi
PYMODS="-"
if has python3; then
  PYMODS="$(to 6 python3 -c 'import importlib.util as u
m=["venv","ensurepip","numpy","pandas","requests","pytest","yaml","flask","fastapi"]
print(" ".join("%s:%s" % (x, "Y" if u.find_spec(x) else "N") for x in m))' 2>/dev/null)"
  [ -n "$PYMODS" ] || PYMODS="?"
fi
case "$PYMODS" in *"ensurepip:Y"*) VENV="venv OK" ;; *"venv:Y"*) VENV="venv w/o ensurepip (-m venv 실패 가능)" ;; *) VENV="venv ?" ;; esac
if [ "$V_GIT" = "-" ]; then MK=NG; elif [ "$V_PY" = "-" ]; then MK="??"; else MK=OK; fi
sum "$MK" core "git $V_GIT | python3 $V_PY | pip $V_PIP | $VENV"
MK=OK; has node || MK="??"
sum "$MK" node "node $(tool_ver node --version) | npm $(NPM_CONFIG_CACHE="$TMPD/npmc" tool_ver npm --version) | npx $(NPM_CONFIG_CACHE="$TMPD/npmc" tool_ver npx --version) | pnpm $(tool_ver pnpm --version) | bun $(tool_ver bun --version)"
PX_UV="$(tool_ver uv --version)"; PX_UVX="$(tool_ver uvx --version)"
PX_PIPX="$(PIPX_HOME="$TMPD/pipx" PIPX_BIN_DIR="$TMPD/pipx/bin" tool_ver pipx --version)"
MK=OK; [ "$PX_UV$PX_UVX$PX_PIPX" = "---" ] && MK="??"
sum "$MK" pytools "uv $PX_UV | uvx $PX_UVX | pipx $PX_PIPX"
sum OK tools "jq $(tool_ver jq --version) | rg $(tool_ver rg --version) | make $(tool_ver make --version) | gcc $(tool_ver gcc --version) | sqlite3 $(tool_ver sqlite3 --version) | curl $(tool_ver curl --version) | wget $(tool_ver wget --version)"
sum OK pymods "$PYMODS"

log "safe values: HOME=$HOME SHELL=${SHELL-} LANG=${LANG-} LC_ALL=${LC_ALL-} TZ=${TZ-} TERM=${TERM-} CODEX_HOME=${CODEX_HOME-}"
log "PATH=$PATH"

# ---- Codex ---------------------------------------------------------------------------------------------
CH="${CODEX_HOME:-$HOME/.codex}"
if has codex; then
  CBIN="$(command -v codex)"
  CREAL="$( (readlink -f "$CBIN" || readlink "$CBIN") 2>/dev/null)"
  case "$CBIN $CREAL" in
    *node_modules*|*/npm/*|*/.npm*) HOW="npm" ;;
    *Cellar*|*homebrew*|*linuxbrew*) HOW="brew" ;;
    *) HOW="other" ;;
  esac
  log "codex bin: $CBIN -> ${CREAL:-?}"
  CVER="$(tool_ver codex --version)"
  sum OK codex "$CBIN | codex-cli $CVER | install=$HOW (업데이트 팝업: Esc=Skip, Enter 금지)"
else
  sum NG codex "codex not on PATH"
fi
if [ -d "$CH" ]; then
  GAG=""
  for f in AGENTS.override.md AGENTS.md; do
    [ -f "$CH/$f" ] && GAG="$GAG $f($(wc -l <"$CH/$f" 2>/dev/null | tr -d ' ')L)"
  done
  sum OK codexhome "${CODEX_HOME:+CODEX_HOME set; }$CH: $(names_in "$CH")"
  MK=OK; [ -n "$GAG" ] && MK="??"
  sum "$MK" codexmd "global AGENTS:${GAG:- none}"
else
  sum "??" codexhome "$CH missing"
fi

toml_summary() { # whitelist-only summary of config.toml; sensitive keys masked, section values only if bool/number
  awk '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function sens(k) { k = tolower(k); return (k ~ /key|token|secret|passw|bearer|auth|credential|cookie|env|header/) }
    BEGIN { sec = ""; nmcp = 0; nproj = 0; mcp = "" }
    /^[ \t]*#/ { next }
    /^[ \t]*[[]/ {
      h = $0; sub(/^[ \t]*[[]+[ \t]*/, "", h); sub(/[ \t]*[]]+.*$/, "", h); sec = h
      if (sec ~ /^mcp_servers\./) {
        n = substr(sec, 13)
        if (substr(n, 1, 1) == "\"") { r = substr(n, 2); m = index(r, "\""); name = (m ? substr(r, 1, m - 1) : r) }
        else { m = index(n, "."); name = (m ? substr(n, 1, m - 1) : n) }
        if (!(name in seen)) { seen[name] = 1; mcp = mcp (nmcp ? ", " : "") name; nmcp++ }
      } else if (sec ~ /^projects\./) { nproj++ }
      next
    }
    /=/ {
      i = index($0, "="); k = trim(substr($0, 1, i - 1)); v = trim(substr($0, i + 1))
      show = 0
      if (sec == "" && k ~ /^(model|model_provider|model_reasoning_effort|model_verbosity|approval_policy|sandbox_mode|profile|default_permissions|project_doc_max_bytes|project_doc_fallback_filenames|project_root_markers|check_for_update_on_startup|web_search)$/) show = 1
      if (sec == "features" || sec == "sandbox_workspace_write" || sec == "skills" || sec ~ /^skills[.]/ || sec == "tools") show = 1
      if (k == "network_access" && (sec == "" || sec == "sandbox_workspace_write")) show = 1
      if (!show) next
      if (sens(k)) v = "***"
      else if (sec != "" && v !~ /^(true|false|-?[0-9][0-9.]*)$/) v = "(set)"
      if (length(v) > 90) v = substr(v, 1, 90) "..."
      print (sec == "" ? "" : sec ".") k " = " v
    }
    END { print "mcp_servers(" nmcp "): " (nmcp ? mcp : "-"); print "projects entries: " nproj }
  ' "$1" 2>/dev/null | redact
}
CF="$CH/config.toml"
if [ ! -f "$CF" ]; then sum "??" config "no $CF"
elif [ ! -r "$CF" ]; then sum "??" config "$CF not readable"
else
  S="$(toml_summary "$CF")"
  printf '%s\n' "$S" | logblock "config summary (redacted): $CF"
  MAIN="$(printf '%s\n' "$S" | grep -E '^(model|approval_policy|sandbox_mode|network_access|sandbox_workspace_write\.network_access|profile|project_doc)' | LC_ALL=C tr '\n' ';')"
  sum OK config "${MAIN:-no model/approval/sandbox keys}"
  MCPL="$(printf '%s\n' "$S" | grep '^mcp_servers(')"; FEAT="$(printf '%s\n' "$S" | grep -E '^(features|skills)\.' | sed 's/^features\.//' | LC_ALL=C tr '\n' ';')"
  sum OK mcp "$MCPL | ${FEAT:-no [features]/[skills] keys}"
fi
sum OK skills "~/.agents/skills: $(names_in "$HOME/.agents/skills") | $CH/skills: $(names_in "$CH/skills")"

# ---- workspace -----------------------------------------------------------------------------------------
WS="$HOME/workspace"
if [ -d "$WS" ]; then
  if has git && git -C "$WS" rev-parse --is-inside-work-tree >/dev/null 2>"$TMPD/ws.err"; then
    TOP="$(git -C "$WS" rev-parse --show-toplevel 2>/dev/null)"
    BR="$(git -C "$WS" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    NCM="$(git -C "$WS" rev-list --count HEAD 2>/dev/null || echo 0)"
    DTY="$(git -C "$WS" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    RMS="$(git -C "$WS" remote 2>/dev/null | LC_ALL=C tr '\n' ' ')"
    UNM="unset"; git -C "$WS" config user.name >/dev/null 2>&1 && UNM="set"
    { git -C "$WS" log --oneline -5 2>&1; git -C "$WS" remote -v 2>&1; git -C "$WS" status -sb 2>&1 | head -n 20; } | logblock "workspace git"
    WSG="git repo top=$TOP branch=${BR:-?} commits=$NCM dirty=$DTY remotes=${RMS:-none} user.name=$UNM"
  else
    WSG="not a git repo ($(head -c 80 "$TMPD/ws.err" 2>/dev/null | LC_ALL=C tr '\n' ' '))"
  fi
  HID="$(ls -A1 "$WS" 2>/dev/null | grep '^\.' | LC_ALL=C tr '\n' ' ')"
  WAG=""
  for f in AGENTS.override.md AGENTS.md AGENTS.kit.md; do
    [ -f "$WS/$f" ] && WAG="$WAG $f($(wc -l <"$WS/$f" 2>/dev/null | tr -d ' ')L)"
  done
  PCFG=""; [ -f "$WS/.codex/config.toml" ] && PCFG=" | .codex/config.toml present(project config)"
  WR="no"; [ -w "$WS" ] && WR="yes"
  sum OK ws "$WS | $WSG"
  sum OK ws-files "AGENTS:${WAG:- none} | hidden: ${HID:-none} | .agents/skills: $(names_in "$WS/.agents/skills") | writable=$WR$PCFG"
  ls -A1 "$WS" 2>/dev/null | head -n 50 | logblock "workspace entries"
else
  sum "??" ws "$WS missing (pwd=$(pwd))"
fi

# ---- port 3000 only (the preview default); other listening ports are not listed --------------------------
if has ss; then L3="$(to 3 ss -ltn 2>/dev/null)"
elif has netstat; then L3="$(to 3 netstat -an 2>/dev/null | grep -i listen)"
elif [ -r /proc/net/tcp ]; then   # Linux without ss/netstat: LISTEN(0A) entries on port 3000(0BB8)
  L3="$(awk 'FNR > 1 && $4 == "0A" { n = split($2, a, ":"); if (a[n] == "0BB8") print "proc:3000 " }' /proc/net/tcp /proc/net/tcp6 2>/dev/null)"
else L3="__no_tool__"; fi
if [ "$L3" = "__no_tool__" ]; then sum "??" port3000 "unknown (ss/netstat 없음) - 서버는 0.0.0.0:3000 이상"
elif printf '%s\n' "$L3" | grep -qE '[:.]3000[[:space:]]'; then sum "??" port3000 "in use -> 다른 포트(예 3001) 사용"
else sum OK port3000 "free (서버는 0.0.0.0 에 바인딩)"; fi

# ---- network (skipped entirely with --no-net) ----------------------------------------------------------
dns_ok() {
  if has getent; then to 4 getent hosts "$1" >/dev/null 2>&1; return $?; fi
  if has python3; then to 4 python3 -c 'import socket,sys; socket.getaddrinfo(sys.argv[1], 443)' "$1" >/dev/null 2>&1; return $?; fi
  if has host; then to 4 host "$1" >/dev/null 2>&1; return $?; fi
  return 2
}
if [ "$NET" != 1 ]; then
  sum "??" net "skipped (--no-net)${REPO_URL:+ - repo test not run}"
else
  DNSR=""
  for h in github.com pypi.org registry.npmjs.org; do
    if dns_ok "$h"; then DNSR="$DNSR $h:ok"; else DNSR="$DNSR $h:FAIL"; fi
  done
  case "$DNSR" in *FAIL*) sum "??" dns "$DNSR" ;; *) sum OK dns "$DNSR" ;; esac

  if has curl; then
    for pair in "github=https://github.com/robots.txt" "pypi=https://pypi.org/simple/six/" \
                "files=https://files.pythonhosted.org/" "npm=https://registry.npmjs.org/-/ping"; do
      _n="${pair%%=*}"; _u="${pair#*=}"
      ( curl -sS -o /dev/null -w '%{http_code} %{time_total}' --max-time 5 "$_u" >"$TMPD/h.$_n" 2>"$TMPD/h.$_n.err" ) &
    done
    wait
    HTR=""; NFAIL=0; NBLK=0; GHOK=0
    for _n in github pypi files npm; do
      _r="$(cat "$TMPD/h.$_n" 2>/dev/null)"; _c="${_r%% *}"; _t="${_r#* }"
      [ -n "$_c" ] || _c="000"
      _t="$(LC_NUMERIC=C printf '%.1f' "$_t" 2>/dev/null || echo '?')"
      case "$_c" in
        000) NFAIL=$((NFAIL+1)); _s="$_n:FAIL" ;;
        401|403|407|451) NBLK=$((NBLK+1)); _s="$_n:$_c!" ;;
        *) _s="$_n:$_c"; [ "$_n" = github ] && GHOK=1 ;;
      esac
      HTR="$HTR $_s(${_t}s)"
      [ -s "$TMPD/h.$_n.err" ] && log "curl $_n: $(head -c 200 "$TMPD/h.$_n.err")"
    done
    if [ $((NFAIL + NBLK)) -ge 4 ]; then MK=NG; elif [ "$NFAIL" -gt 0 ] || [ "$NBLK" -gt 0 ] || [ "$GHOK" = 0 ]; then MK="??"; else MK=OK; fi
    sum "$MK" https "$HTR (000/FAIL=연결 안 됨, !=HTTP 4xx 응답)"
  else
    sum NG https "curl missing"
  fi

  if has npm && [ "$(left)" -gt 12 ]; then
    NV="$(to 12 env NPM_CONFIG_CACHE="$TMPD/npm-cache" npm view is-number version 2>"$TMPD/npm.err" | tail -n 1 | tr -d '\r')"
    if [ -n "$NV" ]; then sum OK npm-view "is-number@$NV (registry metadata OK; 캐시는 /tmp)"
    else _e="$(head -c 120 "$TMPD/npm.err" 2>/dev/null | LC_ALL=C tr '\n' ' ')"; sum "??" npm-view "failed: ${_e:-출력 없음(12초 제한 초과 가능)}"; fi
  elif has npm; then sum "??" npm-view "skipped (time budget)"; fi

  if [ -n "$REPO_URL" ]; then
    case "$REPO_URL" in
      https://github.com/*)
        if ! has git; then sum NG git "git missing"
        elif [ "$(left)" -le 12 ]; then sum "??" git "skipped (time budget)"
        else
          _t0=$SECONDS
          to 10 git -c credential.helper= ls-remote "$REPO_URL" HEAD >"$TMPD/lsr" 2>"$TMPD/lsr.err"; _rc=$?
          _t1=$((SECONDS - _t0))
          if [ "$_rc" -eq 0 ] && [ -s "$TMPD/lsr" ]; then
            _h="$(cut -c1-7 "$TMPD/lsr" | first)"
            _ct=$(( $(left) - 3 )); [ "$_ct" -gt 25 ] && _ct=25
            if [ "$_ct" -ge 5 ]; then
              DEST="$PT/probe-clone-$TS"; _t0=$SECONDS
              to "$_ct" env GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=10 \
                git -c credential.helper= clone -q --depth 1 "$REPO_URL" "$DEST" >"$TMPD/clone.out" 2>&1; _rc2=$?
              _t2=$((SECONDS - _t0))
              if [ "$_rc2" -eq 0 ]; then
                sum OK git "ls-remote ${_t1}s HEAD=$_h | clone --depth 1 ${_t2}s $(du -sk "$DEST" 2>/dev/null | cut -f1)KB"
              else
                sum NG git "ls-remote OK (${_t1}s) but clone failed/timed out (${_ct}s limit) rc=$_rc2: $(head -c 80 "$TMPD/clone.out" | LC_ALL=C tr '\n' ' ')"
              fi
              if [ "$KEEP_CLONE" = 1 ]; then log "clone kept at $DEST"; else rm -rf "$DEST"; fi
            else
              sum OK git "ls-remote ${_t1}s HEAD=$_h (clone skipped: time budget)"
            fi
          else
            _hint=""
            grep -q -i -E 'could not read Username|Authentication failed|not found|Repository not found' "$TMPD/lsr.err" 2>/dev/null \
              && _hint=" -> 비공개·없음·주소 오타 (익명 접근 불가)"
            case "$_rc" in 124|137|142) _hint=" -> 시간 초과(10초 제한, 응답 없음)" ;; esac
            sum NG git "ls-remote failed rc=$_rc${_hint}: $(head -c 100 "$TMPD/lsr.err" 2>/dev/null | LC_ALL=C tr '\n' ' ')"
          fi
        fi ;;
      *) sum "??" git "only https://github.com/... URLs are tested (SSH/other hosts skipped)" ;;
    esac
  fi
fi

# ---- done ----------------------------------------------------------------------------------------------
printf -- '-- %ss | 상세 로그: %s (비밀값 미포함·외부 공유 금지) | next: bootstrap.sh --commit → cd ~/workspace && codex → /status → /skills(List skills) → /model\n' "$SECONDS" "$LOG"
case "$TMPD" in "$PT"/probe-tmp.*) rm -rf "$TMPD" ;; esac
exit 0
