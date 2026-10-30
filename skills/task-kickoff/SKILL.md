---
name: task-kickoff
description: "Start one plan item (for example T-3). Collect its acceptance criteria and related decisions and answers, add a verifiable checklist under the item in wiki/PLAN.md, and open an empty draft decision section. Use when the user says 'T-3 시작' or begins implementing an item. If the user also asked to implement, continue straight into implementation after the checklist. Never pushes. 작업 항목 착수 준비."
license: MIT
---

# 작업 착수 (task-kickoff)

항목 하나를 시작할 때 체크리스트와 빈 결정 기록 자리를 깔아 준다. **추측으로 채우지 않는다 — 빈칸은 빈 채로.**

## 0. 입력
- 항목 ID(T-n). 없으면 묻는다.
- wiki/PLAN.md 에 없는 작업이면 먼저 $plan-backlog 로 항목을 만들거나, 사용자가 말한 범위·수용 기준을 그대로 받아 적는다.

## 1. 맥락 수집 (읽기만)
- wiki/PLAN.md 의 T-n: 범위·근거·수용 기준.
- 관련 결정·답변: `rg -n "<키워드>|T-n" wiki/decisions.md wiki/collab-log.md wiki/conflicts` (rg 가 없으면 `grep -rn`).
  이전 결정과 어긋나지 않도록 관련 내용을 3줄 이내로 요약해 보여준다.
- 코드에서 건드릴 파일·모듈 후보를 찾는다(목록만).

## 2. 체크리스트 (PLAN.md 의 T-n 아래)

```
- [ ] <검증 가능한 작은 단계 1>
- [ ] <단계 2>
- [ ] 수용 기준 검증 명령 실행 → wiki/verification.md 기록
```

- 수용 기준 1개를 확인 가능한 단계 몇 개로 나눈다. 너무 잘게도, 너무 뭉뚱그리지도 않는다.

## 3. 결정 기록 자리 (wiki/decisions.md)

```
## T-n <제목> — status: draft
| 날짜 | 결정 | 이유·근거 | 대안 | 검증 |
|---|---|---|---|---|
```

- 헤더만 만든다. 구현하며 결정이 생길 때마다 1행씩 추가한다(날짜는 `TZ=KST-9 date '+%F %H:%M'`, 근거는 `README.md:줄` 또는 Q-ID).
- 구현 중 요구 자체를 바꿔야 하면(README와 다른 동작이 필요 등) 코드로 밀어붙이지 말고 멈춘 뒤 판정 질문($requirements-audit)이나 $change-proposal 로 넘긴다.

## 4. 마무리
- PLAN.md 의 T-n 상태를 '진행', 시작 시각을 기록한다.
- 체크리스트를 3줄 이내로 보여준다. 사용자가 구현까지 요청했으면 멈추지 말고 이어서 구현한다(아니면 여기서 멈춘다).
- 커밋은 $task-complete 에서 로컬로만 한다. push 는 하지 않는다.
