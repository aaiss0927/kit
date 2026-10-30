---
name: task-complete
description: "Close one plan item (for example T-3) before committing. Check the changes against the README, the business owner's answers and earlier decisions, ask the human about every contradiction, run the acceptance checks, record results in wiki/verification.md, mark the item's decisions stable and make one local commit 'T-n type: summary'. Never pushes. 항목 마무리: 일관성 점검 → 검증 → 로컬 커밋."
license: MIT
---

# 작업 마무리 (task-complete)

탐지는 AI, **판정은 사람.** 미해결 모순이나 실패한 검증을 안은 채 커밋하지 않는다.

## 0. 입력
- 항목 ID(T-n). 없으면 묻는다.

## 1. 변경 파악
- `git status --short`, `git diff --stat` 로 이번 항목의 변경을 확인한다. git 저장소가 아니면 바뀐 파일 목록을 사용자에게 확인한다.

## 2. 일관성 점검
- 기준: README·제공 파일, wiki/collab-log.md 의 답변, wiki/decisions.md 의 stable·가정 결정, wiki/conflicts/ 의 answered·resolved 항목.
- 이번 변경(코드·문서·이 항목의 결정)이 기준과 어긋나는지 본다: 직접 모순 · 수치·스펙 불일치 · 결정 번복 · 함께 동작할 수 없는 방식(통합 충돌) · 용어 드리프트.
- 완화: 구현 세부가 코드에서 정해지는 것, 명시적 보류, 아직 draft 인 것은 충돌이 아니다.
- 모순마다 양쪽 원문 인용과 `파일:줄`을 보여주고 어떻게 할지 묻는다. **답을 받을 때까지 멈춘다.** 네가 고르지 않는다. 다 풀릴 때까지 반복한다.

## 3. 검증
- PLAN.md 의 수용 기준마다 확인 명령(테스트 우선; 서버는 사용자가 띄운 상태에서 `curl -s 127.0.0.1:<포트>`)을 실행하고 wiki/verification.md 에 추가한다:

```
### T-n <KST 시각>
- 기준: <수용 기준> → 명령: `<명령>` → 결과: 통과|실패|미검증 (핵심 출력 1~3줄)
- 남은 한계: <알려진 제약·미구현·가정>
```

- 실패하면 커밋하지 않고 원인과 다음 조치를 보고한다.
- 확인하지 못한 기준은 '미검증'과 이유를 그대로 적는다. 통과로 꾸미지 않는다.

## 4. stable 전환 → 로컬 커밋
- 점검과 검증을 통과하면 decisions.md 의 `## T-n … — status: draft` 를 `stable` 로, PLAN.md 의 T-n 상태를 '완료'와 완료 시각으로 바꾼다.
- README 산출물(wiki/README.md '산출물 매핑')이 있으면 이 항목의 결정·검증·남은 한계를 그 파일에도 반영한다.
- 이 항목의 변경만 한 명령으로 커밋한다(.git 읽기 전용 → 승인 1번): `git add -- <파일들> && git commit -m "<T-n> <type>: <한 줄 요약>"` (type: feat|fix|refactor|docs|test|chore).
- push·원격 추가는 하지 않는다. 저장소가 아니면 커밋 대신 사용자에게 알린다.

## 규칙
- 판정은 사람. stable 전환은 이 스킬 안에서, 점검·검증을 통과한 뒤에만 한다.
