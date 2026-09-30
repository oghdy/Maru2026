# MARU 작업 문서 지도

> 목적: 세션 컨텍스트가 커지거나 요약돼도 방향을 잃지 않기 + 사람이 한눈에 진행상황 파악.
> 모든 세션은 이 폴더를 **main 체크아웃 절대경로**(`/Users/hadohadopapi/Desktop/Maru-main/docs`)로 읽고 쓴다.

## 먼저 볼 것
| 누가 | 파일 |
|---|---|
| 사람(하도윤) | [00_pm/STATUS.md](00_pm/STATUS.md) → 세션별 현재 상태 한눈에 |
| 모든 세션 | 루트 [CLAUDE.md](../CLAUDE.md) → 규칙·소유권·포트 |
| 기능 세션 | `features/<기능>/LOG_<be·fe>.md` 의 ▶ HANDOFF → `PLAN.md` → `API_CONTRACT.md` |

## 구조
```
docs/
├── README.md                 ← 지금 이 파일
├── 00_pm/
│   ├── MASTER_PLAN.md        전체 Phase>Step>Task, 일정 (PM 관리)
│   ├── STATUS.md             9개 세션 상태판 (각 세션이 자기 줄 갱신)
│   ├── REQUESTS.md           세션 → PM 요청함 (잠금 파일 수정, 막힘, 교차 영향)
│   ├── DECISIONS.md          결정 기록 (무엇을·왜)
│   └── INTEGRATION_LOG.md    머지·배포·Railway 반영 기록
├── reference/
│   └── MARU_실사보고서.md      2026-09-15 코드 실사. 버그 원본 목록(파일:라인)
├── features/<lesson|vocab|mission|lab>/
│   ├── PLAN.md               기능별 Phase>Step>Task ([BE]/[FE] 담당 태그)
│   ├── API_CONTRACT.md       BE↔FE 약속 (엔드포인트·JSON·스키마 변경)
│   ├── LOG_be.md             BE 세션 로그 (HANDOFF + 시간순 기록)
│   └── LOG_fe.md             FE 세션 로그
└── deliverables/             Phase 4 제출 서류 7종 작업물
```

## ID·표기 규칙
- 계층: **Phase > Step > Task**. ID = `<기능코드>-<P>.<S>.<T>` (예: `LSN-1.2.3` = Lesson, Phase 1, Step 2, Task 3)
- 기능코드: `PM` `LSN`(lesson) `VOC`(vocab) `MSN`(mission) `LAB`(lab)
- 체크박스: `[ ]` 대기 · `[~]` 진행 중 · `[x]` 완료 · `[!]` 막힘 · `[-]` 취소(사유 기재)
- 완료 표기: `- [x] LSN-1.2.3 [FE] 설명 — ✅ a1b2c3d`
- 우선순위 태그: `P0`(시연에 그대로 보임, 반드시) · `P1`(보이면 어색) · `P2`(여유 있으면)
- 실사보고서 참조: `(실사 §8-P0#1)` 처럼 절·번호 표기

## 공통 Phase
| Phase | 이름 | 담당 | 목표 시각 |
|---|---|---|---|
| P0 | 준비 | PM | 9/30 밤 |
| P1 | 기능 수정 | 8개 기능 세션 | **10/1 15:00 동결** |
| P2 | 통합·QA | PM (+ 수정 요청받은 세션) | 10/1 18:00 |
| P3 | 배포 | PM | 10/1 20:00 |
| P4 | 제출물 7종 | PM | 10/2 |

## LOG 기록 템플릿
```markdown
### 2026-09-30 22:10 · LSN-1.1.2 · 완료
- 변경: `features/lesson/widgets/completion_step_widget.dart`
- 커밋: a1b2c3d
- 확인: iPhone 17 Pro 시뮬레이터에서 u1-l1 완료 화면 문구가 레슨 데이터로 표시됨 (스크린샷 확인)
- 메모/영향: 없음
```
