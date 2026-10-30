# kit — Codex 작업 키트 / generic Codex working kit

시험 전에 준비한 범용 작업 하네스입니다. 과제별 내용·정답 코드·비밀값이 없고, 실행해도 외부로 데이터를 보내지 않습니다.
A generic harness prepared before the exam: no task content, no answer code, no secrets, no network side effects.

## 구성 / Contents
- `AGENTS.md` — Codex 작업 원칙: 탐지는 AI·판정은 사람, 출처 추적, 결정 기록, 위험 작업 전 확인, 외부 전송 금지, 시간 배분 / Codex working agreement
- `skills/` — agentskills.io 형식 스킬 6개 / six skills in agentskills.io format
  `requirements-audit` · `plan-backlog` · `task-kickoff` · `task-complete` · `change-proposal` · `retro-report`
- `templates/wiki/` — 빈 작업 위키(raw · conflicts · decisions · collab-log · PLAN · verification) / empty task-wiki template
- `scripts/probe.sh` — 환경 점검, 읽기 전용(공개 호스트 4곳에 읽기 요청만, `--no-net` 가능) / read-only environment probe
- `scripts/bootstrap.sh` — 작업 폴더에 설치(오프라인, sudo 없음, 기존 파일·링크를 덮어쓰지 않음, `--commit` 일 때만 로컬 커밋 1개) / offline, idempotent installer

## 사용 / Usage
```
git clone -b exam-2026-10-31 https://github.com/aaiss0927/kit ~/kit   # 동결 태그 / frozen tag
bash ~/kit/scripts/bootstrap.sh --commit   # ~/workspace 에 AGENTS.md(없을 때만)·.agents/skills·wiki/ 설치 + 출처 로컬 커밋
bash ~/kit/scripts/bootstrap.sh --dry-run  # 미리보기 / preview only
bash ~/kit/scripts/probe.sh --no-net       # 환경 점검 / environment probe
```
그다음 `cd ~/workspace && codex` → `/status`, `/skills`(List skills) 로 확인합니다. 스킬이 목록에 없으면 `.agents/skills/<이름>/SKILL.md` 를 읽고 따르라고 요청합니다.
Then start `codex` in the workspace and check `/status` and `/skills` (List skills); if a skill is not listed, ask Codex to read its SKILL.md.

## 원칙 / Principles
- 스크립트는 사용자가 터미널에서 직접 실행합니다. 홈 설정(`~/.codex`, `~/.agents`)에는 쓰지 않고, probe.sh 는 거기서 항목 이름·줄 수와 허용 목록 요약만 출력합니다.
  Scripts never write to home-level config (~/.codex, ~/.agents) and never write through symlinks; probe.sh prints only entry names, line counts and a whitelisted config summary from it.
- `git push`·업로드·외부 API 호출이 없습니다. 커밋은 작업 폴더의 로컬 커밋뿐입니다. / No pushes, uploads or external API calls.
- 이 저장소는 시험 시작 전에 동결(태그 `exam-2026-10-31`, archive)하고 결과 발표까지 수정하지 않습니다. / Frozen before the exam; unchanged until results.
- 출처: 작성자가 시험 전에 자신의 기존 프로젝트 관리 도구의 절차와 일부 지침 문구를 일반화해 다시 작성했습니다. 초안 작성과 검토에 AI 코딩 도구(Claude Code)를 사용했고, 시험 중 AI 사용은 제공된 Codex 로만 합니다. 원본 저장소의 파일·이력·프로젝트 데이터는 포함하지 않습니다.
  Provenance: written before the exam by generalizing the procedures and some instruction wording of the author's own project-management tool; an AI coding tool (Claude Code) was used for drafting and review; during the exam only the provided Codex is used. No files, history or project data from the original are included.

License: MIT
