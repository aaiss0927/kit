---
name: retro-report
description: "Near the end (about 30 minutes left), draft wiki/RETRO.md from recorded data only: plan vs actual, estimated vs actual time from git timestamps, reversed decisions, open questions, verification results and remaining limitations, plus a 10-line recap of key decisions. Also writes wiki/ARCHITECTURE.md: one Mermaid flowchart of the finished system (components, data flow, external dependencies) with a 2-line note and file:line evidence per component. No evaluation and no invented data. 마무리 회고: 검증 결과·남은 한계·핵심 결정 요약·완성본 구조도."
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

## wiki/ARCHITECTURE.md — 완성본 구조도
- 먼저 실제 구조를 확인한다: `git ls-files`, 진입점(실행 명령·서버 시작 코드), 의존성 파일(package.json·requirements.txt 등), 외부 연결(HTTP·DB·파일·포트)을 rg 로 찾는다.
- Mermaid `flowchart LR` 하나로 그린다: 구성요소(실행 단위·모듈·데이터 저장소), 화살표 라벨에 오가는 데이터, 외부 의존(라이브러리·외부 API·포트)은 `subgraph` 로 묶는다.
- 문법: 노드 ID 는 영문(api, db), 라벨은 큰따옴표(`api["API 서버 (src/server.js)"]`, `api -->|"주문 JSON"| db`). 한글·괄호·슬래시가 문법을 깨지 않게 한다.
- 다이어그램 아래 구성요소마다 2줄: 하는 일 / 근거 `파일:줄`. 이어서 요청이 들어와 결과가 나가기까지의 데이터 흐름을 3–5줄로.
- 코드에 실제로 있는 것만 그린다. 확인하지 못한 연결은 그리지 않고 '미확인'으로 적는다.

## 규칙
- 기록에 없는 사건·수치는 만들지 않는다. 없으면 '데이터 없음'.
- 마지막에 6번 '핵심 결정 10줄'을 화면에 그대로 출력하고 ARCHITECTURE.md 경로를 알린다(사람이 제출 전에 읽고 후속 서술형에 대비).
- 평가 대신 사실: "느렸다" ✕ → "T-4 예상 20분 / 실제 45분, Q-003 답 대기" ○.
- 과제 README가 정한 산출물(계획 문서·협업 기록 등)이 있으면 그 파일에 들어갈 '검증 결과·남은 한계' 문단 초안도 함께 보여주고(구조도를 넣을지도 묻는다), 반영은 사람이 확인한 뒤 한다.
