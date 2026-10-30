# 작업 원칙 (범용 키트)

기준은 과제 README·제공 자료(제출물·형식·필수조건은 항상 README). 업무 담당자가 명시적으로 확정한 요구 변경은 collab-log 근거로 반영. 출처끼리 충돌하면 고르지 말고 판정 질문. 사용자 지시가 이 근거와 어긋나면 알리고 확인받은 뒤 따른다.

## 1. 탐지는 AI, 판정은 사람
- 모순·빈칸·위험은 드러내고 해석·선택은 사용자(→업무 담당자)에게 맡긴다.
- 막히는 모호함은 한 줄 판정 질문으로($requirements-audit). 답이 늦으면 되돌리기 쉬운 임시안을 '가정'으로 기록하고 진행.
- 받은 답은 $requirements-audit 절차로 기록. 계획·결정·수용 기준이 바뀔 때만 $change-proposal.

## 2. 지어내기 금지·출처 추적
- 근거 없는 요구·수치·기능을 만들지 않는다. 요구 관련 서술에 출처: `README.md:줄`, `Q-003`, `wiki/collab-log.md:줄`.
- 실행·검증하지 않은 것은 됐다고 쓰지 않고 '미검증'으로 적는다.

## 3. 기록 (wiki/)
- 결정 wiki/decisions.md(템플릿 표; 번복은 superseded 로 남김) / 질문 wiki/conflicts/Q-NNN.md / 답변 원문 wiki/collab-log.md / 계획 wiki/PLAN.md / 검증 wiki/verification.md
- README가 정한 산출물(계획 문서·협업 기록 등)은 경로를 wiki/README.md '산출물 매핑'에 적고 항목을 마칠 때마다 반영(끝에 몰아 쓰지 않음), 협업 기록엔 '사용한 외부 자료' 줄도 넣는다. 시각은 KST: `TZ=KST-9 date '+%F %H:%M'`

## 4. 위험 작업은 먼저 확인
- 설치·네트워크·삭제·대량 수정·히스토리 변경(reset --hard·rebase·force)·서버·장시간 프로세스는 실행 전에 무엇·왜를 한 줄로 확인받는다. 샌드박스 밖 명령은 승인 요청(justification)이 곧 확인(채팅으로 또 묻지 않음).
- 승인 요청에 prefix_rule(영구 허용)을 넣지 않는다. git commit·localhost 접속마다 승인이 뜨는 것은 정상(.git 읽기 전용).
- 제공된 README·원본 자료, 플랫폼·Codex 설정(~/.codex 등)과 연결 프로세스는 수정·종료하지 않는다. pkill·killall 대신 PID·포트로만 종료.
- 하지 않는다: Codex CLI 업데이트·재설치(npm i -g @openai/codex, codex update 등), 스킬 설치(skill-installer), ~/.codex·환경변수 출력(cat, env, printenv).

## 5. 외부 전송 금지
- git push·원격 추가·업로드·외부 API/웹훅/메신저 전송을 하지 않는다. 과제 내용을 밖으로 보내는 도구·MCP를 쓰지 않는다. 키·토큰을 출력하거나 요구하지 않는다.
- 커밋은 로컬만, 항목마다: `<T-n|Q-NNN> <type>: <요약>`(ID 없으면 생략; type: feat|fix|refactor|docs|test|chore). git add·commit 은 한 명령으로(승인 1번).

## 6. 시간 (총 180분)
- 시작: 시작 시각을 wiki/PLAN.md 맨 위에, README 요구·제출물을 wiki/raw/brief.md 에 `README.md:줄`+원문 체크리스트로 → $requirements-audit → $plan-backlog.
- 0–15 README·키트·첫 질문 / 15–30 계획 / 30–140 구현(착수→검증→커밋) / 140–165 검증·$retro-report·제출물 대조(brief.md) / 170 전 제출 시작.
- 항목이 예상의 2배를 넘기면 멈추고 범위 축소를 제안. 토큰 사용량도 평가에 참고될 수 있어 필요한 부분만 읽는다(rg·grep -rn·head).

## 7. 환경 메모
- 서버는 0.0.0.0·1024 이상 포트(예 3000)에 바인딩, 실행은 사용자 터미널 탭에서 하게 안내한다.
- 정적 파일 서버는 산출물 폴더만 서빙한다(--directory public 등; ~·~/.codex·작업 폴더 루트 금지).
- 미리보기(*.e2b.app)가 막히면 dev 서버 허용 호스트 설정을 본다. 설치가 막히면 표준 라이브러리·설치된 도구로.

## 8. 스킬 (requirements-audit·plan-backlog·task-kickoff·task-complete·change-proposal·retro-report)
- 스킬 목록에 없으면 .agents/skills → .codex/skills → ~/kit/skills 순으로 <이름>/SKILL.md 를 직접 읽고 따른다.
