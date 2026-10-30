---
name: change-proposal
description: "When a business-owner answer or instruction changes something already in the plan, decisions or acceptance criteria, list what it affects with rg evidence, write a short reviewable proposal to wiki/proposals/, and apply it only after an explicit '적용' or 'apply'. Plain answers to open questions are recorded by requirements-audit instead. Never edits the provided README or provided materials, never pushes. 요구 변경 → 영향 목록 → diff 제안 → 명시 승인 후 적용."
license: MIT
---

# 변경 제안 (change-proposal)

사람은 판단(말)만 하고, AI는 일관된 수정안을 만든다. **적용은 명시 승인 후에만.**

## 1. 판단 수집
- 업무 담당자 답변·지시가 wiki/collab-log.md 에 아직 없으면 원문 그대로(KST 시각, 관련 Q-ID) 기록한다(이미 있으면 다시 쓰지 않는다).
- 번호만 붙인 답(1. … 2. …)은 직전 '보냄' 기록의 질문 순서로 Q-ID에 대응시키고, 대응표를 보여 확인받는다. 같은 답이 반복되면 한 번만 반영한다.
- 답이 애매하거나 사용자가 무엇을 정해야 하는지 헷갈려 하면, 결정 포인트와 선택지를 쉬운 말로 설명하고 기본안을 제안하되 승인 없이 바꾸지 않는다.
- 정정이 오면 의미 차이를 그대로 반영해 다시 제안한다(비슷한 선택지를 뭉뚱그리지 않는다).

## 2. 영향 목록 (바꾸기 전)
- 바뀌는 용어·값과 동의어로 `rg -n` (없으면 `grep -rn`): wiki/, 코드, 테스트, 설정.
- 결과는 `파일:줄` + 영향 이유 한 줄. '영향 후보'로 제시하고 확실하지 않으면 그렇게 표시한다. 근거 없이 영향을 단정하지 않는다.

## 3. 제안 파일 wiki/proposals/PROPOSAL-<YYYYMMDD-HHMM>.md (KST)
- 구성: ① 판단 요약(원문 인용 + collab-log 위치) ② 영향 목록 ③ `## 변경안` ④ 적용 후 할 일(테스트 수정, $requirements-audit 재실행).
- 변경안은 `파일:줄` → 바꿀 내용 한 줄씩. 5줄 넘게 바뀌는 파일만 diff 코드블록(`--- a/<경로>`, `+++ b/<경로>`, `@@ <위치> @@`, `-`/`+`).
- 기준 문서는 wiki 쪽(PLAN.md, decisions.md, conflicts/, concepts/)이다. 제공된 README·원본 자료는 고치지 않는다.
- 같은 내용이 여러 곳에 중복돼 있을 수 있으니 옛 값·동의어를 전부 찾아 함께 바꾼다.
- 화면에는 경로와 3줄 요약만 출력하고 "적용할까요?"에서 멈춘다.

## 4. 적용 (사용자가 '적용'이라고 답한 범위만)
- diff 문자열을 그대로 붙이는 대신 파일을 정확히 편집하고, `git diff --check` 와 옛 값 재검색으로 확인한다.
- 결정 이력은 지우지 않는다: 이전 행의 결정 칸 앞에 `[superseded <KST 날짜> PROPOSAL-…]` 를 붙이고 새 결정은 새 행으로 쓴다.
- 관련 Q 파일 **상태** resolved(open → answered → resolved), PROPOSAL 에 '적용됨'을 표시한다.
- 코드·테스트 정렬이 필요하면 해당 항목의 $task-kickoff 또는 새 계획 항목으로 넘긴다.
- 커밋은 로컬만(`<T-n 또는 Q-NNN> docs: <요약>`). push 는 하지 않는다.
