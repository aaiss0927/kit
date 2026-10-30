---
name: plan-backlog
description: "Turn the task README and confirmed answers into a prioritized, time-boxed plan in wiki/PLAN.md. Every item has evidence and acceptance criteria an outsider can verify. Use after the first requirements-audit and whenever scope changes. Proposes only, the human picks. 근거·수용 기준·타임박스가 있는 작업 계획 제안(must/should/stretch/hold)."
license: MIT
---

# 작업 계획 제안 (plan-backlog)

제안은 AI, **선택·확정은 사람**. 근거 없는 기능은 만들지 않는다.

## 0. 근거 정리
- wiki/raw/brief.md 가 없으면 README의 요구 문장을 원문 그대로 줄번호와 함께 뽑아 만든다(요약 금지).
  제출물 목록과 제약(언어·실행 방법·포트·금지 사항)은 따로 적고, 제출물 경로는 wiki/README.md '산출물 매핑'에도 적는다.
- 정책·값은 기억이 아니라 매번 문서에서 읽는다: README, wiki/collab-log.md, wiki/decisions.md, wiki/conflicts/.

## 1. 규칙
- 항목마다 근거(`README.md:줄`, Q-ID 답변)가 있어야 한다. 근거 없는 항목·추측한 범위는 제안하지 않고 판정 질문으로 돌린다($requirements-audit).
- 이미 계획에 있는 범위는 새 항목 대신 기존 항목의 범위 수정으로 제안한다.
- 성격이 다른 일(예: 화면 vs 데이터 처리 vs 운영 기능)을 한 항목에 섞지 않는다.
- 큰 묶음을 먼저 보이고 그 아래 실행 항목을 둔다. 평면 목록만 던지지 않는다.
- 내부 설계는 구현하며 정하도록 여지를 남긴다. 사용자가 원하지 않으면 세부 설계를 고정하지 않는다.

## 2. 항목 형식 (wiki/PLAN.md)

```
### T-<n> <결과가 드러나는 제목> — must|should|stretch|hold · 예상 <분>분 (신뢰 상|중|하)
- 범위: <무엇을, 1~2줄>
- 근거: `README.md:<줄>` · Q-<번호>
- 수용 기준(외부 검증 가능): <관찰 가능한 동작·수치·명령 결과. 예: "`pytest -q` 통과", "빈 입력이면 400과 오류 메시지">
- 상태: 제안
```

- 수용 기준이 그대로 검증 항목이 된다. 기준을 만들 수 없을 만큼 막연하면 제안하지 말고 질문으로 돌린다.

## 3. 시간 배분 (전체 180분, 남은 시간 = 180 − (지금 − PLAN.md 맨 위 시작 시각))
- must 합계는 남은 시간의 60% 이하로 잡고, 검증·문서·제출에 최소 30분을 남긴다.
- 예상 시간은 '초기 추정'이라고 밝히고 근거(불확실성)를 한 줄 단다.
- open 판정 질문에 걸린 항목은 hold 또는 신뢰 '하'로 두고, 답 없이 진행할 임시안이 있으면 적는다.

## 4. 진행
1. PLAN.md 초안을 쓰고, 화면에는 번호 요약(ID·제목·버킷·분)만 출력한다.
2. "어느 항목부터 확정할까요?"라고 묻고 사람이 고른 것만 상태를 '확정'으로 바꾼다. 순차 진행을 원하면 1개씩 제안한다.
3. 거절·보류된 항목은 같은 형태로 다시 제안하지 않는다. 범위가 섞였다는 이유면 더 작게 나눈다.
4. 첫 확정 항목은 $task-kickoff 로 시작한다.
