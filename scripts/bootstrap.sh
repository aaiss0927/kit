#!/usr/bin/env bash
# bootstrap.sh - install this kit into a task workspace (offline, idempotent, no sudo)
#
# Usage: bash ~/kit/scripts/bootstrap.sh [options]
#   --target DIR          workspace to install into (default: $HOME/workspace; must already exist)
#   --skills MODE         agents | codex | both | none   (default: DEFAULT_SKILLS below)
#                           agents -> DIR/.agents/skills   (current Codex repo-scope location)
#                           codex  -> DIR/.codex/skills    (legacy location; Codex 0.163 reads both)
#                           both   -> both (Codex 0.163 then lists every skill twice)
#                           none   -> no copy; Codex reads ~/kit/skills/<name>/SKILL.md on request
#   --agents-md MODE      new-only | skip (default new-only). An existing AGENTS.md is NEVER edited:
#                           the kit rules then go to DIR/AGENTS.kit.md and a one-line prompt is printed.
#   --wiki MODE           init | skip (default init): fresh task wiki in DIR/wiki (missing files only)
#   --commit              then make ONE local commit of exactly the installed kit paths; the message records
#                           kit URL @ commit (tag). Never pushes, never runs git init or git config.
#   --dry-run             print what would happen, write nothing
#   -h, --help            show this help
# Guarantees: no network, no sudo, no installs, never overwrites or edits an existing file, never writes
# through a symlink, never writes to ~/.codex or ~/.agents, commits only with --commit.
# Exit status: 0 done, 1 a copy or the commit failed, 2 bad option or precondition.

# DEFAULT_SKILLS (사전체험 /skills 결과로 확정, 소문자 agents|codex|both|none):
#   agents = 작업 폴더 .agents/skills (기본) · none = 복사하지 않음(AGENTS.md §8 대로 SKILL.md 를 직접 읽기)
#   codex = .codex/skills (Codex 0.163 은 .agents/skills 와 똑같이 읽으므로 보통 필요 없음)
DEFAULT_SKILLS="agents"

TARGET="$HOME/workspace"; SKILLS="$DEFAULT_SKILLS"; AGENTS_MODE="new-only"; WIKI="init"; DRY=0; COMMIT=0
export GIT_OPTIONAL_LOCKS=0   # read-only git queries must not refresh any index

die() { printf 'bootstrap: %s\n' "$*" >&2; exit 2; }
usage() { awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0" 2>/dev/null; }

while [ $# -gt 0 ]; do
  case "$1" in
    --target) shift; TARGET="${1:-}" ;;
    --target=*) TARGET="${1#--target=}" ;;
    --skills) shift; SKILLS="${1:-}" ;;
    --skills=*) SKILLS="${1#--skills=}" ;;
    --agents-md) shift; AGENTS_MODE="${1:-}" ;;
    --agents-md=*) AGENTS_MODE="${1#--agents-md=}" ;;
    --wiki) shift; WIKI="${1:-}" ;;
    --wiki=*) WIKI="${1#--wiki=}" ;;
    --commit) COMMIT=1 ;;
    --dry-run|-n) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (see --help)" ;;
  esac
  [ $# -gt 0 ] && shift
done
case "$SKILLS" in agents|codex|both|none) ;; *) die "--skills must be agents|codex|both|none" ;; esac
case "$AGENTS_MODE" in new-only|skip) ;; *) die "--agents-md must be new-only|skip" ;; esac
case "$WIKI" in init|skip) ;; *) die "--wiki must be init|skip" ;; esac

KIT_DIR="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -P)"
[ -n "$KIT_DIR" ] && [ -f "$KIT_DIR/AGENTS.md" ] && [ -d "$KIT_DIR/skills" ] || die "kit files not found next to this script"
[ -n "$TARGET" ] || die "--target is empty"
case "$TARGET" in "~") TARGET="$HOME" ;; "~/"*) TARGET="$HOME/${TARGET#\~/}" ;; esac
[ -d "$TARGET" ] || die "target directory does not exist: $TARGET (작업 폴더를 --target 으로 지정)"
TGT="$(cd "$TARGET" && pwd -P)"
case "$TGT/" in "$KIT_DIR/"*) die "target is inside the kit itself ($TGT) - use your workspace" ;; esac
case "$KIT_DIR/" in "$TGT/"*) die "the kit is inside the target ($KIT_DIR) - 작업 폴더 밖으로 옮긴 뒤 다시 실행: mv \"$KIT_DIR\" ~/kit && bash ~/kit/scripts/bootstrap.sh --commit" ;; esac
[ "$DRY" = 1 ] || [ -w "$TGT" ] || die "target is not writable: $TGT"

# ---- provenance (no network: reads the local clone only) ---------------------------------------------
KIT_COMMIT="unknown"; KIT_SHORT="unknown"; KIT_TAG=""; KIT_DIRTY=""; KURL="${KIT_URL:-}"
if command -v git >/dev/null 2>&1 && [ "$(git -C "$KIT_DIR" rev-parse --show-toplevel 2>/dev/null)" = "$KIT_DIR" ]; then
  KIT_COMMIT="$(git -C "$KIT_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
  KIT_SHORT="$(git -C "$KIT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  KIT_TAG="$(git -C "$KIT_DIR" describe --tags --exact-match HEAD 2>/dev/null)"
  KIT_DIRTY="$(git -C "$KIT_DIR" status --porcelain 2>/dev/null | head -n 1)"
  [ -n "$KURL" ] || KURL="$(git -C "$KIT_DIR" config --get remote.origin.url 2>/dev/null)"
fi
KURL="${KURL:-unknown}"
case "$KURL" in *://*@*) KURL="${KURL%%://*}://${KURL##*@}" ;; esac   # drop any userinfo, even one containing '/' or '@'
NOW="$(TZ=KST-9 date '+%Y-%m-%d %H:%M' 2>/dev/null) KST"

NC=0; NS=0; NW=0; NF=0; CREATED=""
say() { printf '%s\n' "$*"; }
created() { NC=$((NC+1)); say "  + $1"; }
same() { NS=$((NS+1)); say "  = $1 (already identical)"; }
warn() { NW=$((NW+1)); say "  ! $1"; }
addpath() { case " $CREATED " in *" $1 "*) ;; *) CREATED="$CREATED $1" ;; esac; }

linked() { # linked DEST : true if DEST or any parent below $TGT is a symlink
  _q="$1"; _root="$TGT"; case "$_q" in "$TGT"/*) ;; *) _root="$HOME" ;; esac
  while [ "$_q" != "$_root" ] && [ "$_q" != "/" ] && [ "$_q" != "." ]; do
    [ -L "$_q" ] && return 0
    _q="$(dirname "$_q")"
  done
  return 1
}
# copy helpers return 0 when DEST now holds the kit's content (created or identical), 1 otherwise
copy_new() { # copy_new SRC DEST LABEL : one file, only if DEST is missing
  if linked "$2"; then warn "$3: symlink in path - skipped (never writes through links)"; return 1; fi
  if [ -e "$2" ]; then
    if cmp -s "$1" "$2" 2>/dev/null; then same "$3"; return 0; fi
    warn "$3 exists and differs - left untouched"; return 1
  fi
  if [ "$DRY" = 1 ]; then NC=$((NC+1)); say "  + $3 (dry-run)"; return 0; fi
  if mkdir -p "$(dirname "$2")" && cp "$1" "$2"; then created "$3"; return 0; fi
  NF=$((NF+1)); warn "$3: copy failed"; return 1
}
copy_dir_new() { # copy_dir_new SRCDIR DESTDIR LABEL : whole directory, only if DESTDIR is missing
  if linked "$2"; then warn "$3: symlink in path - skipped (never writes through links)"; return 1; fi
  if [ -e "$2" ]; then
    if diff -rq "$1" "$2" >/dev/null 2>&1; then same "$3"; return 0; fi
    warn "$3 exists and differs - left untouched"; return 1
  fi
  if [ "$DRY" = 1 ]; then NC=$((NC+1)); say "  + $3/ (dry-run)"; return 0; fi
  if mkdir -p "$(dirname "$2")" && cp -R "$1" "$2"; then created "$3/"; return 0; fi
  NF=$((NF+1)); warn "$3: copy failed"; return 1
}
count_entries() { if [ -d "$1" ]; then ls -A "$1" 2>/dev/null | wc -l | tr -d ' '; else echo 0; fi; }
install_skills() { # install_skills DEST_ROOT LABEL_ROOT [REL_ROOT] : REL_ROOT given -> record paths for the commit
  if linked "$1"; then warn "$2: symlink in path - skipped (never writes through links)"; return 1; fi
  _all=1; _ok=""; _n=0
  for _d in "$KIT_DIR"/skills/*/; do
    _d="${_d%/}"
    [ -f "$_d/SKILL.md" ] || continue
    _b="$(basename "$_d")"; _n=$((_n+1))
    if copy_dir_new "$_d" "$1/$_b" "$2/$_b"; then _ok="$_ok $_b"; else _all=0; fi
  done
  [ -n "${3:-}" ] || return 0
  if [ "$DRY" = 1 ] || { [ "$_all" = 1 ] && [ "$(count_entries "$1")" = "$_n" ]; }; then addpath "$3"
  else for _b in $_ok; do addpath "$3/$_b"; done; fi
}
sed_esc() { printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'; }

say "kit:    $KURL @ $KIT_SHORT${KIT_TAG:+ ($KIT_TAG)}${KIT_DIRTY:+ [local changes]}"
say "target: $TGT   skills=$SKILLS agents-md=$AGENTS_MODE wiki=$WIKI$([ "$COMMIT" = 1 ] && echo ' commit')$([ "$DRY" = 1 ] && echo ' DRY-RUN')"

# ---- AGENTS.md -----------------------------------------------------------------------------------------
KIT_PROMPT=""
if [ "$AGENTS_MODE" = "new-only" ]; then
  say "[AGENTS.md]"
  if [ -e "$TGT/AGENTS.override.md" ] || [ -L "$TGT/AGENTS.override.md" ]; then
    warn "AGENTS.override.md exists - Codex reads it instead of AGENTS.md here (not touched)"
    if copy_new "$KIT_DIR/AGENTS.md" "$TGT/AGENTS.kit.md" "AGENTS.kit.md"; then addpath AGENTS.kit.md; KIT_PROMPT="AGENTS.kit.md"; fi
  elif [ ! -e "$TGT/AGENTS.md" ] && [ ! -L "$TGT/AGENTS.md" ]; then
    copy_new "$KIT_DIR/AGENTS.md" "$TGT/AGENTS.md" "AGENTS.md" && addpath AGENTS.md
  elif [ ! -L "$TGT/AGENTS.md" ] && cmp -s "$KIT_DIR/AGENTS.md" "$TGT/AGENTS.md"; then
    same "AGENTS.md"; addpath AGENTS.md
  else
    warn "AGENTS.md already exists (platform/task file or link?) - not edited"
    if copy_new "$KIT_DIR/AGENTS.md" "$TGT/AGENTS.kit.md" "AGENTS.kit.md"; then addpath AGENTS.kit.md; KIT_PROMPT="AGENTS.kit.md"; fi
  fi
  CHOME="${CODEX_HOME:-$HOME/.codex}"
  for _f in AGENTS.override.md AGENTS.md; do
    [ -f "$CHOME/$_f" ] && say "  i global $CHOME/$_f exists (platform instructions; read only, never edited)"
  done
else
  say "[AGENTS.md] skipped (--agents-md skip)"
fi

# ---- skills --------------------------------------------------------------------------------------------
case "$SKILLS" in agents|both) say "[skills] -> .agents/skills"; install_skills "$TGT/.agents/skills" ".agents/skills" ".agents/skills" ;; esac
case "$SKILLS" in codex|both) say "[skills] -> .codex/skills (legacy location)"; install_skills "$TGT/.codex/skills" ".codex/skills" ".codex/skills" ;; esac
[ "$SKILLS" = none ] && say "[skills] not copied (--skills none): Codex reads $KIT_DIR/skills/<name>/SKILL.md on request"

# ---- wiki ----------------------------------------------------------------------------------------------
if [ "$WIKI" = "init" ]; then
  say "[wiki] -> wiki/"
  W="$TGT/wiki"; TPL="$KIT_DIR/templates/wiki"
  if [ ! -d "$TPL" ]; then
    warn "templates/wiki missing in the kit - skipped"
  elif linked "$W"; then
    warn "wiki: symlink in path - skipped (never writes through links)"
  elif [ -e "$W" ] && [ ! -d "$W" ]; then
    warn "wiki exists and is not a directory - skipped"
  elif [ -d "$W" ] && [ -n "$(ls -A "$W" 2>/dev/null)" ] && ! grep -q 'kit-wiki' "$W/README.md" 2>/dev/null; then
    warn "wiki/ already exists and is not a kit wiki - skipped (rename it, or use --wiki skip)"
  else
    _all=1; _ok=""; _n=0
    set -f; _oifs="$IFS"; IFS='
'
    for _rel in $(cd "$TPL" && find . -type f | LC_ALL=C sort); do
      _rel="${_rel#./}"; _n=$((_n+1))
      if [ "$_rel" != "README.md" ]; then
        if copy_new "$TPL/$_rel" "$W/$_rel" "wiki/$_rel"; then _ok="$_ok wiki/$_rel"; else _all=0; fi
        continue
      fi
      if linked "$W/README.md"; then
        warn "wiki/README.md: symlink in path - skipped"; _all=0
      elif [ -e "$W/README.md" ]; then
        if grep -q 'kit-wiki' "$W/README.md" 2>/dev/null; then same "wiki/README.md"; _ok="$_ok wiki/README.md"
        else warn "wiki/README.md exists - left untouched"; _all=0; fi
      elif [ "$DRY" = 1 ]; then
        NC=$((NC+1)); say "  + wiki/README.md (dry-run; provenance $KURL @ $KIT_SHORT)"
      elif mkdir -p "$W" && sed -e "s|{{KIT_URL}}|$(sed_esc "$KURL")|g" \
          -e "s|{{KIT_COMMIT}}|$(sed_esc "$KIT_COMMIT${KIT_TAG:+ ($KIT_TAG)}")|g" \
          -e "s|{{IMPORTED_AT}}|$(sed_esc "$NOW")|g" "$TPL/README.md" >"$W/README.md"; then
        created "wiki/README.md (provenance recorded)"; _ok="$_ok wiki/README.md"
      else
        NF=$((NF+1)); warn "wiki/README.md: write failed"; _all=0
      fi
    done
    IFS="$_oifs"; set +f
    if [ "$DRY" = 1 ] || { [ "$_all" = 1 ] && [ "$(cd "$W" 2>/dev/null && find . -type f | wc -l | tr -d ' ')" = "$_n" ]; }; then addpath wiki
    else for _p in $_ok; do addpath "$_p"; done; fi
  fi
else
  say "[wiki] skipped (--wiki skip)"
fi

# ---- result, provenance commit, next steps ---------------------------------------------------------------
IS_REPO=0; GTOP=""
if command -v git >/dev/null 2>&1 && git -C "$TGT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  IS_REPO=1; GTOP="$(cd "$(git -C "$TGT" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null && pwd -P)"
fi
if [ "$IS_REPO" = 1 ] && [ "$DRY" != 1 ] && [ -n "$CREATED" ]; then
  _keep=""
  for _p in $CREATED; do   # drop paths git would refuse (e.g. ignored by .gitignore) so `git add` cannot half-fail
    if git -C "$TGT" add -n -- "$_p" >/dev/null 2>&1; then _keep="$_keep $_p"
    else warn "$_p: git add 가 거부함(.gitignore 등) - 커밋 목록에서 제외. 넣을지는 직접 판단(git add -f)"; fi
  done
  CREATED="$_keep"
fi
MSG="chore: import kit $KURL @ $KIT_SHORT${KIT_TAG:+ ($KIT_TAG)}:$CREATED"
RERUN="bash \"$KIT_DIR/scripts/bootstrap.sh\""
[ "$TGT" = "$(cd "$HOME/workspace" 2>/dev/null && pwd -P)" ] || RERUN="$RERUN --target \"$TGT\""
[ "$SKILLS" = "$DEFAULT_SKILLS" ] || RERUN="$RERUN --skills $SKILLS"
[ "$AGENTS_MODE" = new-only ] || RERUN="$RERUN --agents-md $AGENTS_MODE"
[ "$WIKI" = init ] || RERUN="$RERUN --wiki $WIKI"
RERUN="$RERUN --commit"

say ""
if [ -z "$CREATED" ]; then
  say "git: 커밋할 키트 경로 없음"
elif [ "$IS_REPO" != 1 ]; then
  say "git: 작업 폴더가 git 저장소가 아님 - 커밋하지 않음. README·Cofa Helper 확인 후 필요하면:"
  say "  git -C \"$TGT\" init -q && $RERUN"
elif [ "$GTOP" != "$TGT" ]; then
  warn "git 저장소 최상위가 $GTOP (작업 폴더와 다름) - 자동 커밋하지 않음. 직접 판단:"
  say "  cd \"$TGT\" && git add --$CREATED; git commit -m \"$MSG\" --$CREATED; git log --oneline -1"
else
  IDOK=1
  { [ -n "$(git -C "$TGT" config user.name 2>/dev/null)" ] && [ -n "$(git -C "$TGT" config user.email 2>/dev/null)" ]; } || IDOK=0
  if [ "$COMMIT" = 1 ] && [ "$DRY" = 1 ]; then
    say "git (dry-run): 커밋할 경로:$CREATED"
  elif [ "$COMMIT" = 1 ] && [ "$IDOK" = 0 ]; then
    NF=$((NF+1))
    say "git: 사용자 정보(user.name/email)가 없어 커밋하지 않음. 이 저장소에만 설정한 뒤 같은 명령을 다시 실행:"
    say "  git -C \"$TGT\" config user.name <이름>; git -C \"$TGT\" config user.email <메일>"
    say "  $RERUN"
  elif [ "$COMMIT" = 1 ]; then
    # shellcheck disable=SC2086
    if ! git -C "$TGT" add -- $CREATED; then
      NF=$((NF+1)); warn "git add failed (위 오류 확인)"
    elif git -C "$TGT" diff --cached --quiet -- $CREATED; then
      say "git: 이미 커밋돼 있음(새 변경 없음): $(git -C "$TGT" log --oneline -1 2>/dev/null)"
    elif git -C "$TGT" commit -q -m "$MSG" -- $CREATED; then
      say "git: committed $(git -C "$TGT" log --oneline -1 2>/dev/null)"
    else
      NF=$((NF+1)); warn "git commit failed (위 오류 확인)"
    fi
  else
    say "git 기록(출처 남기기): 아래 둘 중 하나"
    say "  $RERUN"
    [ "$IDOK" = 0 ] && say "  (git 사용자 정보 없음 → 먼저: git -C \"$TGT\" config user.name <이름>; git -C \"$TGT\" config user.email <메일>)"
    say "  cd \"$TGT\" && git add --$CREATED; git commit -m \"$MSG\" --$CREATED; git log --oneline -1"
  fi
fi
say "== created $NC, identical $NS, warnings $NW, failed $NF$([ "$DRY" = 1 ] && echo ' (dry-run: nothing written)')"
[ "$NW" -eq 0 ] || say "   ! 위 '!' 줄을 먼저 확인(설치·커밋되지 않은 항목이 있을 수 있음)"
case "$SKILLS" in agents|both) SKREL=".agents/skills" ;; codex) SKREL=".codex/skills" ;; *) SKREL="" ;; esac
say "next:"
say "  cd \"$TGT\" && codex      # 업데이트 팝업만 Esc(=Skip; Enter=업데이트). 신뢰 화면은 Enter(그 화면의 Esc=종료). 이미 실행 중이면 /quit 후 다시"
if [ "$SKILLS" = none ]; then
  say "  /status → Agents.md 줄 확인 · /model → 권장 모델 선택 (--skills none: 키트 스킬은 목록에 없음)"
else
  say "  /status → Agents.md 줄 확인 · /skills → List skills(또는 \$) → 키트 스킬 6개(+기본 스킬) 확인 · /model → 권장 모델"
fi
[ -n "$KIT_PROMPT" ] && say "  첫 요청에 붙이기: \"작업 전에 $KIT_PROMPT 를 읽고 따르세요(과제 README·기존 AGENTS.md 가 우선).\""
say "  스킬이 목록에 없으면: \"<스킬이름> 스킬: ${SKREL:-$KIT_DIR/skills}/<스킬이름>/SKILL.md 를 읽고 그대로 수행해줘\"${SKREL:+ (없으면 $KIT_DIR/skills/...)}"
[ "$NF" -eq 0 ] || exit 1
exit 0
