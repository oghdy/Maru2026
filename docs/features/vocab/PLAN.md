# VOC — Vocabulary PLAN

- 세션: `vocab-be`, `vocab-fe` · worktree `/Users/hadohadopapi/Desktop/Maru-wt/vocab` · 브랜치 `feat/vocab`
- 서버 :8082 · DB `maru_vocab` · 시뮬레이터 iPhone 17
- 범위: 덱/레슨 목록 · Word Study(카드+4단계 평가) · Match 게임 · 오늘의 복습 · FSRS 스케줄러 · vocab-pipeline
- 발표 주장(맞춰야 할 것): "FSRS 알고리즘 기반 복습 추천", "망각곡선·stability/difficulty 연산", "5,965 → 5,561 단어 14개 덱 / 30단어 레슨"
- 참고: 홈의 "오늘의 복습" 배너는 PM 소유(`home_screen.dart`). 배너 조건·동작 변경은 REQUESTS 로.
- 동결: 10/1 15:00 · 우선순위 P0 > P1 > P2

## Phase 1 — 기능 수정

### Step 1.1 현황 점검
- [x] VOC-1.1.1 [BE] P0 서버 기동, `/api/v1/vocabulary/*` 전 엔드포인트 응답 확인 → `API_CONTRACT.md` 에 현재 요청/응답 기록. `FsrsAlgorithmTest`·`VocabularyServiceTest`·`VocabularyIntegrationTest` 실행 결과 기록 — (문서만, 커밋 없음)
- [x] VOC-1.1.3 [BE] P0 **가장 먼저**: `VocabularyServiceTest.java` 컴파일 오류(10건) 수정 → 모든 세션의 `./gradlew test` 차단 해소 (R-001). 현재 서비스 시그니처에 맞추되 서비스 코드는 이 태스크에서 바꾸지 말 것 — 8a78d48
- [x] VOC-1.1.2 [FE] P0 덱 → 레슨 → Word Study / Match / 오늘의 복습 완주하며 점검, 새 문제는 태스크 추가 (코드 변경 없음, 결과 LOG_fe 09-30 17:40 → 1.2.9~1.2.11 추가)

### Step 1.2 P0 버그·하드코딩
- [x] VOC-1.2.1 [FE] P0 짝맞추기 `dispose()` 에서 `super.initState()` 호출 버그 (실사 §2-C, `vocabulary_game_screen.dart:34-37`) — 5d35904
- [x] VOC-1.2.2 [FE] P0 "Round n/6", 진행바 `/30`, "You mastered all 30 words" 고정 → 실제 단어 수·라운드 수 (실사 §8-P1#18, `vocabulary_game_screen.dart:80,105,259`) — 736f7da
- [x] VOC-1.2.3 [BE] P0 레슨 완료 여부 `isCompleted(false)` 고정 TODO → 사용자 학습 기록으로 계산 (실사 §2-A, `VocabularyService.java:211`) — 787e014
- [x] VOC-1.2.4 [FE] P0 레슨 목록에 완료/진행 표시 반영 — c4f70e4
- [x] VOC-1.2.5 [BE] P1 게임 API: 묶음 단어가 5개 미만/30개 미만일 때 안전 처리, 라운드 계산에 필요한 총 개수 제공(필드 추가) — fba1f23
- [x] VOC-1.2.6 [FE] P1 예외 원문 노출 제거 → 영어 안내 + Retry (`vocabulary_game_screen.dart:91`, `daily_review_screen.dart:63`) — 2fbe367, 5d2a3ee
- [x] VOC-1.2.7 [FE] P1 단어 카드 검은 배경 → 앱 톤(theme) (실사 §8-P1#19, `vocabulary_learning_screen.dart:35`, `daily_review_screen.dart:38`) — 2fbe367
- [x] VOC-1.2.8 [BE] P1 `POST /review` 입력 검증: rating 1~4 밖 → 400(현재 조용히 GOOD), 없는/누락 wordId → 400/404(현재 500) (1.1.1 에서 발견) — c6ab127
- [x] VOC-1.2.9 [FE] P1 Word Study: 진행 표시(n / N) 없음 + LESSON 모드에서 마지막 카드(또는 전부)가 이미 학습한 단어면 평가 버튼이 없어 완료 화면에 도달 불가 → 'Next'/'Finish' 버튼 제공 (`vocabulary_card_item.dart:92-94`) — d428a1f
- [x] VOC-1.2.10 [FE] P1 Match 진입 문구 "Test your knowledge with 4x4 game" 사실과 다름(실제: 라운드당 5쌍, 2열) (`vocabulary_lesson_list_screen.dart:138`) — 22fdf6d
- [x] VOC-1.2.11 [FE] P1 게임 provider 가 autoDispose 아님 → 같은 레슨 재진입 시 이전 게임 상태(완료 화면 등) 잔존 가능. 1.2.2 와 함께 처리 — 736f7da
- [x] VOC-1.2.12 [FE] **P0** Word Study/Daily Review: 스와이프로 넘긴 뒤 평가하면 **다른 단어(provider currentIndex 의 단어)로 제출**됨 → FSRS 데이터 오염. 예: 3번째 카드 상표(2697)에 Good → 요청은 wordId 1229(단추). PageView 인덱스와 provider 인덱스 동기화 + 평가 시 해당 카드의 word 로 제출. 완료 판정도 같은 원인으로 어긋남 (`vocabulary_provider.dart:106-125`, `vocabulary_card_item.dart:228`). 1.2.9 와 함께 — d428a1f

### Step 1.3 FSRS 사실화 (발표 "FSRS 기반" 주장 뒷받침)
- [x] VOC-1.3.1 [BE] P1 `FsrsAlgorithm` 을 공개된 **FSRS 표준 공식 + 기본 파라미터 `w[]`** 로 교체: 초기 S/D, retrievability R(t,S), 경과일 반영, 목표 기억률 0.9 → 다음 간격. `FsrsAlgorithmTest` 갱신 (실사 §6-(3), `FsrsAlgorithm.java:15-18`). 스키마 변경 필요 시 추가만 — 4a9e650
- [x] VOC-1.3.2 [BE] P1 Word Study 모드에서 이미 학습한 단어 평가가 무시되는 동작(`submitReview` 63-68) 정리 — 발표의 "Spacing Integrity Guard" 의도 유지하되 문서화 — 45f987b
- [x] VOC-1.3.3 [BE] P2 평가 버튼별 다음 복습 간격 미리보기(예: Good → 3d) 필드 제공 — 262ce98 (`nextIntervals`)
- [x] VOC-1.3.4 [FE] P2 평가 버튼에 다음 간격 표시 ("Again · 1m / Good · 3d") — fa7eeeb

### Step 1.4 정리 (P2)
- [x] VOC-1.4.1 [FE] P2 덱 이름 영어 번역 switch(`word_category.dart:17-78`) 정리 또는 누락 보완 — c477e51
- [x] VOC-1.4.2 [BE] P2 미사용 코드 정리 판단(`getRandomWordsForGame`, `findRandomWordsByCategory` 등) — 삭제는 테스트 영향 확인 후 — 288c58d (삭제)

### Step 1.5 사용자 피드백 R2 (09-30 19:30, 하도윤 직접 사용 후) — 원문: `/Users/hadohadopapi/Downloads/9_30_디테일하게_고쳐야할_부분들.pdf`
> 목표: "UI/UX 에서 사용자 경험 극대화". 스크린샷 기준 iPhone 16 Pro Max.
- [ ] VOC-1.5.1 [FE] P0 **단어장 전체 비주얼 리디자인** (피드백 #5 "너무 단순, 안 예쁨"): 덱 목록(카테고리별 아이콘/색 카드, 진행률), 레슨 목록, 단어 카드(여백·타이포·앞뒤 플립 애니메이션), 완료 화면. 브랜드 `colorScheme` 기반, 새 패키지 없이 Flutter 기본 애니메이션으로
- [ ] VOC-1.5.2 [FE] P0 **Match Madness 부드럽게**: 타일 등장 stagger, 선택 시 scale/색 전환, 정답 짝 pop+fade, 오답 shake(부드럽게), 라운드 전환 트랜지션, 완료 축하 연출. 60fps 확인
- [ ] VOC-1.5.3 [FE] P1 발음 버튼을 새 `TtsHelper.speak()` 로 교체 — **PM 이 main 동기화 알린 뒤에** (LSN-1.5.2 선행)
