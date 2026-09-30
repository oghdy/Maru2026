# VOC — Vocabulary PLAN

- 세션: `vocab-be`, `vocab-fe` · worktree `/Users/hadohadopapi/Desktop/Maru-wt/vocab` · 브랜치 `feat/vocab`
- 서버 :8082 · DB `maru_vocab` · 시뮬레이터 iPhone 17
- 범위: 덱/레슨 목록 · Word Study(카드+4단계 평가) · Match 게임 · 오늘의 복습 · FSRS 스케줄러 · vocab-pipeline
- 발표 주장(맞춰야 할 것): "FSRS 알고리즘 기반 복습 추천", "망각곡선·stability/difficulty 연산", "5,965 → 5,561 단어 14개 덱 / 30단어 레슨"
- 참고: 홈의 "오늘의 복습" 배너는 PM 소유(`home_screen.dart`). 배너 조건·동작 변경은 REQUESTS 로.
- 동결: 10/1 15:00 · 우선순위 P0 > P1 > P2

## Phase 1 — 기능 수정

### Step 1.1 현황 점검
- [ ] VOC-1.1.1 [BE] P0 서버 기동, `/api/v1/vocabulary/*` 전 엔드포인트 응답 확인 → `API_CONTRACT.md` 에 현재 요청/응답 기록. `FsrsAlgorithmTest`·`VocabularyServiceTest`·`VocabularyIntegrationTest` 실행 결과 기록
- [ ] VOC-1.1.2 [FE] P0 덱 → 레슨 → Word Study / Match / 오늘의 복습 완주하며 점검, 새 문제는 태스크 추가

### Step 1.2 P0 버그·하드코딩
- [ ] VOC-1.2.1 [FE] P0 짝맞추기 `dispose()` 에서 `super.initState()` 호출 버그 (실사 §2-C, `vocabulary_game_screen.dart:34-37`)
- [ ] VOC-1.2.2 [FE] P0 "Round n/6", 진행바 `/30`, "You mastered all 30 words" 고정 → 실제 단어 수·라운드 수 (실사 §8-P1#18, `vocabulary_game_screen.dart:80,105,259`)
- [ ] VOC-1.2.3 [BE] P0 레슨 완료 여부 `isCompleted(false)` 고정 TODO → 사용자 학습 기록으로 계산 (실사 §2-A, `VocabularyService.java:211`)
- [ ] VOC-1.2.4 [FE] P0 레슨 목록에 완료/진행 표시 반영
- [ ] VOC-1.2.5 [BE] P1 게임 API: 묶음 단어가 5개 미만/30개 미만일 때 안전 처리, 라운드 계산에 필요한 총 개수 제공(필드 추가)
- [ ] VOC-1.2.6 [FE] P1 예외 원문 노출 제거 → 영어 안내 + Retry (`vocabulary_game_screen.dart:91`, `daily_review_screen.dart:63`)
- [ ] VOC-1.2.7 [FE] P1 단어 카드 검은 배경 → 앱 톤(theme) (실사 §8-P1#19, `vocabulary_learning_screen.dart:35`, `daily_review_screen.dart:38`)

### Step 1.3 FSRS 사실화 (발표 "FSRS 기반" 주장 뒷받침)
- [ ] VOC-1.3.1 [BE] P1 `FsrsAlgorithm` 을 공개된 **FSRS 표준 공식 + 기본 파라미터 `w[]`** 로 교체: 초기 S/D, retrievability R(t,S), 경과일 반영, 목표 기억률 0.9 → 다음 간격. `FsrsAlgorithmTest` 갱신 (실사 §6-(3), `FsrsAlgorithm.java:15-18`). 스키마 변경 필요 시 추가만
- [ ] VOC-1.3.2 [BE] P1 Word Study 모드에서 이미 학습한 단어 평가가 무시되는 동작(`submitReview` 63-68) 정리 — 발표의 "Spacing Integrity Guard" 의도 유지하되 문서화
- [ ] VOC-1.3.3 [BE] P2 평가 버튼별 다음 복습 간격 미리보기(예: Good → 3d) 필드 제공
- [ ] VOC-1.3.4 [FE] P2 평가 버튼에 다음 간격 표시 ("Again · 1m / Good · 3d")

### Step 1.4 정리 (P2)
- [ ] VOC-1.4.1 [FE] P2 덱 이름 영어 번역 switch(`word_category.dart:17-78`) 정리 또는 누락 보완
- [ ] VOC-1.4.2 [BE] P2 미사용 코드 정리 판단(`getRandomWordsForGame`, `findRandomWordsByCategory` 등) — 삭제는 테스트 영향 확인 후
