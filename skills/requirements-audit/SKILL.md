---
name: requirements-audit
description: "Find contradictions and under-specified points across the task README, provided files and the business owner's answers, and turn each into one judgement question for the human to relay. Also records pasted answers in wiki/collab-log.md and updates the question status. Detect and surface only, never resolve. Use at the start, when an answer arrives, and before submission. Not for code review. 요구사항 모순·미구체화 탐지 → wiki/conflicts/Q-NNN.md + 업무 담당자에게 보낼 판정 질문 목록."
license: MIT
---

# 요구사항 점검 (requirements-audit)

탐지는 AI, **판정은 사람**(사용자가 업무 담당자에게 확인). 모순을 찾아 드러낼 뿐 고르거나 고치지 않는다.

## 절대 규칙
- 어느 쪽이 맞는지 고르지 않는다("최신 문서가 맞을 것" 같은 추정 금지). 양쪽 원문을 나란히 둔다. 제출물·형식·필수조건이 걸리면 임시안만 README 쪽으로 둔다(AGENTS.md).
- 실제로 적힌 내용만 보고한다. 없는 모순을 만들지 않는다. 애매하면 보고하되, 한 번에 Q 파일은 영향 높음·중간 최대 7개, 낮음은 화면 목록에 한 줄씩만.
- 과제 README·제공 파일은 고치지 않는다. 쓰는 곳은 wiki/conflicts/ 와 화면 출력뿐이다.

## 범위
- 대상: 과제 README와 제공 파일(읽기 전용), wiki/raw/, wiki/collab-log.md(업무 담당자 답변), wiki/decisions.md, wiki/PLAN.md.
- 사용자가 주제·파일을 지정하면 그 범위만 본다. 새 답변이 들어온 직후에는 그 답과 관련된 범위를 먼저 본다.
- 중복 금지: wiki/conflicts/Q-*.md 에 같은 주제·같은 양측이 이미 있으면 새 파일 대신 기존 파일에 근거 행만 추가한다.
- wiki/conflicts/KNOWN.md 에 적힌 보류·알려진 갭은 보고하지 않는다(이 목록은 사람이 관리한다).

## 유형 (7종)
1 직접 모순 · 2 수치·스펙 불일치 · 3 시점·순서 충돌 · 4 정의·용어 드리프트 · 5 결정 번복 · 6 고아 참조(없는 파일·항목·화면을 가리킴) · 7 미구체화(결정처럼 쓰였지만 구현에 필요한 값이 없음. 예: "로그인 지원" → 어떤 방식? "알림" → 어떤 채널·빈도?)

완화(보고하지 않음):
- 구현 세부(라이브러리, 내부 구조, 필드 이름 등)가 비어 있는 것은 정상이다. 다른 요구가 그 값에 기대거나 두 출처가 같은 값을 다르게 말할 때만 7로 본다.
- 명시적 보류("추후 결정", "범위 밖", "선택 사항")는 모순이 아니다. 한 문장이 "X를 한다 + 세부는 추후"라고 하면 하나의 일관된 진술이다.

## 출력 1 — wiki/conflicts/Q-NNN.md (1건 1파일, 번호 = 기존 최대 + 1)

```
# Q-NNN · <주제 한 줄>

**유형** <1~7> · **영향** 높음|중간|낮음 · **상태** open · **관련** <T-n 또는 ->

> **판정 질문** — <업무 담당자가 한 줄로 답할 수 있게. 가능하면 A/B 선택지. 답은 쓰지 않는다>

| 입장 | 원문 인용 | 출처 |
|:--:|---|---|
| A | "<원문 그대로>" | `README.md:12` |
| B | "<원문 그대로>" | `wiki/collab-log.md:30` |

**답이 없을 때 임시안** — <되돌리기 쉬운 기본값 1개와 이유. 결정은 사람이 한다>
```

- 한 행 = 인용 1개 + 출처 1개(`파일:줄`). 같은 입장의 근거가 여럿이면 A, A 로 행을 나눈다. 인용 안의 `|` 는 `\|`. 요약·해설 금지.

## 출력 2 — 전달용 목록 (화면)
- open 항목을 영향 높은 순으로, 메신저에 바로 옮길 수 있게 출력한다(한 번에 5~7개). 각 줄은 Q-ID로 시작하고(영향 표시는 화면용), 끝에 "Q-ID별로 답해 주세요" 한 줄.
  예: `Q-003 쿠폰과 할인을 함께 적용하나요? A) 함께 B) 하나만`
- 사용자가 보냈다고 하면 보낸 목록을 wiki/collab-log.md 에 '보냄'(KST 시각·Q-ID 순서)으로 기록한다.
- 답 없이도 진행 가능한 항목은 "임시안으로 진행 예정"으로 따로 묶는다.
- 사용자가 받은 답을 붙여 주면: wiki/collab-log.md 에 원문 그대로(시각·Q-ID) 기록 → 번호만 있는 답은 직전 '보냄' 기록의 순서로 Q-ID에 대응시키고 대응표를 보여 준다 → 해당 Q 파일 **상태** answered 와 `> **판정** — <시각> 업무 담당자: <요지> (wiki/collab-log.md:줄)` 추가 → 이미 정한 계획·결정·수용 기준이 바뀌면 $change-proposal.
- 시간 안에 답이 없으면: 임시안을 wiki/decisions.md 에 '가정'으로 기록하고 진행한다. 답이 오면 다시 본다.

## 전체 점검
- "전체 점검"을 요청받으면 references/full-audit.md 절차로 모든 문서를 한 번 감사한다.

## 하지 않는 것
- 메신저나 외부로 직접 보내기, git push. 출력은 파일과 화면뿐이고 커밋은 로컬에서만 한다.
