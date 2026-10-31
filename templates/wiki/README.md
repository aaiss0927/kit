# 작업 위키

<!-- kit-wiki: created by bootstrap.sh from {{KIT_URL}} @ {{KIT_COMMIT}} at {{IMPORTED_AT}} -->

과제를 하면서 근거·질문·결정·검증을 남기는 작업 노트다. 과제 README가 정한 산출물 파일이 있으면
그 파일이 우선이고, 이 폴더는 그 산출물의 근거가 된다.

| 경로 | 내용 | 주로 쓰는 스킬 |
|---|---|---|
| raw/ | 원문 보관(만든 뒤 고치지 않음): brief.md(과제 README 요구·제출물 체크리스트, `README.md:줄`+원문), 업무 담당자가 준 긴 자료 사본 | Codex(시작 시), 사람 |
| conflicts/Q-NNN.md | 모순·미구체화 1건 = 1파일 + 판정 질문 | requirements-audit |
| conflicts/KNOWN.md | 알려진 보류·갭(보고 제외 목록, 사람이 관리) | 사람 |
| collab-log.md | 업무 담당자와 주고받은 질문·답 원문 | requirements-audit, change-proposal |
| PLAN.md | 작업 항목 T-n, 수용 기준, 타임박스, 체크리스트 | plan-backlog, task-kickoff |
| decisions.md | 결정 로그(항목별 섹션, draft → stable) | task-kickoff, task-complete, change-proposal |
| verification.md | 검증 명령·결과·남은 한계 | task-complete |
| proposals/ | 요구 변경 제안(diff) | change-proposal |
| concepts/ · index.md | (선택) 개념 1개 = 1페이지(frontmatter `sources:` 에 `파일:줄`) | 사람 |
| RETRO.md · ARCHITECTURE.md | 마무리 회고 · 완성본 구조도(Mermaid) | retro-report |

## 근거의 무게
- 기준은 과제 README·제공 자료다(제출물·형식·필수조건은 항상 README).
- 업무 담당자가 명시적으로 확정한 요구 변경은 collab-log 근거로 반영한다($change-proposal).
- 우리 가정(임시안)은 가장 약한 근거다. 출처끼리 충돌하면 고르지 말고 판정 질문으로 돌린다.

## 산출물 매핑 (착수 때 채운다)
- 계획 문서 → (README 지정 경로)
- 협업 기록 → (README 지정 경로)
- 기타 제출물 → (README 지정 경로)

## 사용한 외부 자료
- 작업 키트: {{KIT_URL}} @ {{KIT_COMMIT}} (가져온 시각 {{IMPORTED_AT}}) — AGENTS.md, 스킬 6개, 이 위키 템플릿을 scripts/bootstrap.sh 로 설치. 과제 코드 없음. 출처는 키트 README 참고.
