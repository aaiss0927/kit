---
name: retro-report
description: "Near the end (about 30 minutes left), draft wiki/RETRO.md from recorded data only: plan vs actual, estimated vs actual time from git timestamps, reversed decisions, open questions, verification results and remaining limitations, plus a 10-line recap of key decisions. No evaluation and no invented data. 마무리 회고: 검증 결과·남은 한계·핵심 결정 요약."
license: MIT
---

# 마무리 회고 (retro-report)

기록을 모아 정리할 뿐, 평가·질책·결론 강요는 하지 않는다.

## 소스
- `TZ=KST-9 git log --date=format-local:'%F %H:%M' --stat` (커밋 시각, KST) · 실제 소요는 PLAN.md 의 시작·완료 시각 우선
- wiki/PLAN.md (예상 시간·버킷·상태), wiki/decisions.md (번복·superseded), wiki/conflicts/ (open·answered·resolved),
  wiki/verification.md (통과·실패·미검증), wiki/collab-log.md

## wiki/RETRO.md 구성
1. 계획 대비 실제 — 완료·미완·보류 항목 수와 목록.
2. 예상 vs 실제 시간 — 항목별로 나란히. 데이터가 없으면 '데이터 없음'.
3. 잘된 점 / 막힌 점 — 근거(커밋, 검증 결과, 답변 대기)가 있는 것만.
4. 결정 회고 — 번복된 결정과 이유(출처 포함).
5. 남은 한계·미검증·open 질문 — 있는 그대로.
6. 핵심 결정 10줄 — "무엇을, 왜 정했고, 무엇으로 검증했나". 사람이 자기 말로 설명할 수 있게 짧게.

## 규칙
- 기록에 없는 사건·수치는 만들지 않는다. 없으면 '데이터 없음'.
- 마지막에 6번 '핵심 결정 10줄'을 화면에 그대로 출력한다(사람이 제출 전에 읽고 후속 서술형에 대비).
- 평가 대신 사실: "느렸다" ✕ → "T-4 예상 20분 / 실제 45분, Q-003 답 대기" ○.
- 과제 README가 정한 산출물(계획 문서·협업 기록 등)이 있으면 그 파일에 들어갈 '검증 결과·남은 한계' 문단 초안도 함께 보여주고, 반영은 사람이 확인한 뒤 한다.
