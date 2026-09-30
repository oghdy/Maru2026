# VOC — Vocabulary — FE 세션 로그 (`vocab-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음 — R2 의 VOC-1.5.1(리디자인), VOC-1.5.2(Match 애니메이션) 완료
- 다음 할 일: **VOC-1.5.3(TTS 교체)은 PM 이 main 동기화 알려줄 때까지 대기** (지시). 그 뒤 발음 버튼 2곳(카드 앞면 `vocabulary_card_item.dart` `TtsHelper.speak`)을 새 API 로.
- 미확인: Daily Review 완료 화면(SessionSummaryView 공용, due 단어 생기면 확인), release/실기기 60fps.
- 실행 중인 것: 서버 :8082 (vocab-be). 앱 flutter run on iPhone 17(191ABCE7…) API_PORT=8082, stdin fifo scratchpad/flutter_in, 로그 scratchpad/flutter.log. 스크린샷 도구 scratchpad/shot.sh <이름> → docs/features/vocab/screenshots/r2/
- 마지막 커밋: 3fe6d12 (1.5.2), a163aa8 (1.5.1). push 안 함.
- 짝 세션에게: API 변경 요청 없음(덱 진행률은 레슨 API 합산). 공용 index → `git commit -- <경로>`.

## 기록 (시간순 추가만, 수정 금지)

### 09-30 17:40 · VOC-1.1.2 현황 점검 (코드 변경 없음)
iPhone 17 시뮬레이터 + :8082 + dev_tester 로 직접 점검. 확인한 것:
- 덱 목록: 14덱 정상 표시(영어 제목 변환 OK). 레슨 목록(쇼핑/경제 46단어 → L1 30, L2 16) 정상. 완료 표시 없음(API 키 `completed` vs FE `isCompleted` + BE false 고정 → 1.2.3/1.2.4).
- Match(L2, 16단어): 헤더 "Round 1/6" 고정 확인(실제 4라운드). 닫기 시 `vocabulary_game_screen.dart:36` 에서 `_debugLifecycleState == created` assertion 로그 확인(1.2.1).
  같은 라운드에 "brand"/"trademark, brand"(브랜드/상표) 처럼 뜻이 겹치는 쌍이 나옴 → 콘텐츠 문제, FE 로는 처리 안 함(참고).
- 레슨 시트 문구 "Test your knowledge with 4x4 game" 사실과 다름 → 1.2.10 추가.
- Word Study: 검은 배경(1.2.7), 진행 표시 없음. Good/Again 제출 → `POST /review` 200, DB fsrs_progress 에 Good=+4d, Again=+5m 저장 확인.
  코드상: LESSON 모드에서 이미 학습한 카드는 평가 버튼 대신 "Swipe up" 배지만 → 마지막 카드가 학습한 단어면 완료 화면 도달 불가 → 1.2.9 추가(시뮬레이터 미재현, 코드 근거).
- 게임 provider 가 autoDispose 아님 → 1.2.11 추가(1.2.2 와 함께).
- 오늘의 복습: 현재 due 0개라 홈 배너 미표시 → 화면 진입은 미확인(Again 단어가 17:38 이후 due 되면 확인 예정).

### 09-30 17:45 · VOC-1.2.1 짝맞추기 dispose 버그 — 5d35904
- `vocabulary_game_screen.dart:36` `super.initState()` → `super.dispose()`.
- 확인: hot reload 후 L2 Match 진입→X 로 닫기, flutter 로그에 assertion(수정 전 `_debugLifecycleState == created` 발생) 없음. `flutter analyze lib/features/vocabulary` 13건 = 기존(withOpacity 12 + `_triggerShake` 미사용 1), 새 경고 없음.

### 09-30 17:50 · VOC-1.2.2 + VOC-1.2.11 짝맞추기 실제 개수 / autoDispose — 736f7da
- provider: `totalPairs`(서버가 준 타일의 pairId 수), `totalRounds = ceil(totalPairs/5)`, `isGameOver = totalPairs>0 && matches>=totalPairs` (30 고정 제거). 빈 레슨이면 로딩 무한 대신 "There are no words in this lesson yet." 표시.
  `startGame` 은 새 상태로 시작(copyWith 로 errorMessage 를 못 지우던 문제 → Retry 대비). await 뒤 `ref.mounted` 체크. provider → `NotifierProvider.autoDispose.family`.
- screen: "Round n/{totalRounds}"(게임 끝나면 숨김), 진행바 `/totalPairs`, 완료 문구 "You matched all N words in Lesson L"("mastered" → "matched": 게임 1회로 암기했다고 주장하지 않음). 색상 colorScheme.primary, 이 파일 withOpacity → withValues, 미사용 `_shakeController/_triggerShake` 제거.
- 확인(시뮬레이터): 동물/식물 L2(4단어) → "Round 1/1", 1쌍 후 진행바 25%, 4쌍 후 "You matched all 4 words in Lesson 2". Finish → 재진입 시 새로 섞인 게임(Round 1/1)으로 시작, `/game/40` 재요청 확인. 로그 예외 0건. 여러 라운드(쇼핑 L2 16단어 → 4라운드)는 계산식으로만 확인(미확인).
- analyze: vocabulary 폴더 6건 = 다른 파일의 기존 withOpacity. 새 경고 없음.

### 09-30 17:58 · VOC-1.2.4 레슨 목록 완료/진행 표시 — c4f70e4
- `WordLesson`: `studiedWords` 추가, 완료 = `isCompleted ?? completed`(BE 1.2.3 키 + 하위 호환). `vocabularyLessonsProvider`(FutureProvider.autoDispose.family) 신설 → 목록 화면이 FutureBuilder(빌드마다 재요청) 대신 사용.
- 카드: 미시작 "N words" + ›, 진행중 "k of N words studied" + 진행바 + "k/N", 완료 "All N words studied" + ✓ + 초록 테두리. Word Study/Match 에서 돌아오면 invalidate → 자동 갱신. 당겨서 새로고침. 오류 시 영어 안내 + Retry(예외 원문 제거). 빈 덱 안내문. 시트에 SafeArea. 이 파일 색상 colorScheme, withOpacity 정리.
- 확인(시뮬레이터, 쇼핑/경제): L2 "2 of 16" 진행 표시 → Word Study 다녀온 뒤 3/16 으로 자동 갱신 → 나머지 13단어 API 로 평가 후 당겨서 새로고침 → "All 16 words studied" ✓. 오류 화면은 서버를 내릴 수 없어 **미확인**(코드만).
- **새 P0 발견 → VOC-1.2.12**: Word Study 에서 스와이프로 넘긴 뒤 평가하면 provider 의 currentIndex 단어로 제출됨. 3번째 카드 상표(2697)에 Good → 요청 `wordId:1229`(단추). 로그로 확인. (검증용으로 상표·L2 나머지는 dev_tester 로 curl 평가함)
- analyze: 새 경고 없음(남은 4건 = 다른 파일 기존 withOpacity).

### 09-30 18:05 · VOC-1.2.12 (P0) + VOC-1.2.9 평가 오제출 / Word Study 진행·완료 — d428a1f
- 원인: `submitRating` 이 provider `currentIndex` 의 단어로 제출하는데, 스와이프는 PageView 만 넘기고 index 는 그대로 → 다른 단어로 평가 저장. 완료 판정도 같은 index 기준이라 어긋남.
- 수정: `widgets/vocabulary_session_pager.dart` 신설(Word Study·Daily Review 공용). 평가는 **그 카드의 WordCard** 로 제출(`submitRating(word, rating)` → 성공 여부 반환, 실패 시 SnackBar "Couldn't save your rating…"), `onPageChanged` → `setCurrentIndex`, 마지막 카드에서 평가/Finish → `completeSession()`. 앱바에 "n / N". 이미 학습한 카드(LESSON 모드)는 "Swipe up" 배지 대신 "Already learned. It will come back in Daily Review." + **Next word / Finish** 버튼. load 시 새 상태로 시작(이전 errorMessage 가 남던 문제 수정).
- 확인(시뮬레이터): 쇼핑/경제 L1 에서 두 번 스와이프(3 / 30) 후 바지 Good → 요청 `wordId: 2070`(= 바지, DB 확인), 4 / 30 으로 이동. L2(전부 학습함) 1/16 → Next word 15회 → 16/16 에서 버튼이 Finish → "Lesson Completed!" 도달. 목록 복귀 시 L1 "1 of 30" 갱신.
- Daily Review 화면은 같은 pager 를 쓰지만 이 태스크에서 시뮬레이터로는 **미확인**(1.2.7 에서 확인 예정).
- git 사고: 첫 커밋(e09460f)에 vocab-be 가 stage 해 둔 `WordGameDto.java` 삭제가 섞여 들어감 → 즉시 `reset --soft` 후 `git commit -- <내 경로>` 로 재커밋(d428a1f). vocab-be 의 삭제는 **stage 상태 그대로 복원**됨. 이후 모든 커밋은 `git commit -- <paths>` 로.

### 09-30 18:15 · VOC-1.2.7 + VOC-1.2.6 테마 / 예외 원문 제거 — 2fbe367, 후속 5d2a3ee
- 1.2.7: Word Study·Daily Review 검은 배경 제거 → `colorScheme.surfaceContainerLow` 배경, 앞면 카드 surfaceContainerLowest+그림자, 뒷면 primaryContainer+primary 테두리, TTS·뜻 primary. 카드는 남은 공간을 채우고 평가 바는 아래(Column, 이전 Positioned bottom:60 은 작은 화면에서 겹칠 수 있었음). 뒷면 내용 스크롤 가능. AppBar 는 배경과 같은 단색(투명이면 상태바 아이콘이 흰색으로 떠서 안 보였음).
  완료 화면: Word Study "Lesson Completed! You went through all N words…" + "Back to Lessons"(이전 "Return to Deck List" 는 실제로 레슨 목록으로 가서 틀린 문구, 버튼 글자 대비도 낮았음). Daily Review: 복습할 게 없었으면 "Nothing to review right now", 했으면 "You reviewed N due word(s)."(이전: 0개여도 "finished all your reviews").
- 1.2.6: repository 가 `Exception('Failed…: $e')` 로 감싸던 것 제거 → `repository/vocabulary_errors.dart` `friendlyVocabularyError()` 가 DioException 종류별 영어 문구(연결 실패 / 404 "There are no words here yet." / 기타). `widgets/vocabulary_error_view.dart`(안내 + Retry) 를 덱·레슨·Word Study·Daily Review·Match 모두 사용. 세션 notifier 에 `retry()`(마지막 로드 반복). 평가 저장 실패 시 SnackBar.
  후속(5d2a3ee): Riverpod 3 기본 자동 재시도(최대 10회, 약 40초 동안 스피너만) → 내 FutureProvider 3개(`vocabularyCategoriesProvider`, `vocabularyLessonsProvider`, `dailyReviewCountProvider`)에 `retry: null` 정책 → 오류가 ~1초 안에 뜨고 Retry 로 제어.
- 확인(시뮬레이터): 테마 — L1 앞/뒷면, 상태바 색, Daily Review(브랜드 1개 due → "1 / 1" → Good → `wordId:2475, DAILY_REVIEW`, DB state 2/reps 2/+2일 → "You reviewed 1 due word."). 오류 — 앱을 API_PORT=8099 로 띄우고 8099→8082 TCP 프록시(scratchpad/proxy.py)를 켰다 끄는 방식으로 서버 다운 재현(짝 BE 서버는 안 건드림): 덱 목록 오류 화면(재시도 끄기 전 ~40초 후 표시 확인) → 끈 뒤 레슨 목록 ~2초 내 "Couldn't reach the server…" → 프록시 켜고 Retry → 목록 복구. Word Study 오류 → Retry → 1/30 로드. 오프라인 평가 → SnackBar 확인. Match 오류 화면은 같은 위젯이지만 **미확인**.
- analyze: vocabulary 폴더 **No issues found**(기존 withOpacity 경고까지 모두 정리됨).

### 09-30 18:16 · VOC-1.2.10 Match 진입 문구 — 22fdf6d
- "Test your knowledge with 4x4 game" → "Match English and Korean, 5 pairs per round"(실제 동작). 시뮬레이터 시트에서 확인. ※ 커밋 메시지 태그 오타 `[VOC-1.210]` (= VOC-1.2.10), rebase 금지라 그대로 둠.

### 참고 (PM 영역, REQUESTS R-00x 로 전달)
- 홈 배너 "1 words ready to review" 단수 처리(`home_screen.dart`).
- 서버에 못 붙으면 시작 화면(프로필 게이트)이 스피너만 계속 돎 — /api/me 실패 시 오류+재시도 필요(실사 §2-C 와 같은 계열).

### 09-30 18:00 · VOC-1.3.4 평가 버튼 다음 간격 표시 — fa7eeeb
- `WordCard` 에 `nextIntervals`(BE 1.3.3) 파싱. 버튼 2줄: "Again / 5m", "Hard / 1d", "Good / 4d", "Easy / 14d".
- **동작 수정 포함**: BE 1.3.2 로 가드가 "이미 학습 + 복습일 전"으로 바뀜(기한 지난 단어는 Word Study 에서도 반영). FE 의 "Already learned" 바를 `state != new` 대신 서버 신호 `nextIntervals == null` 기준으로 변경(`ratingAppliesInLesson`; 필드가 아예 없는 구버전 서버면 새 단어만 반영으로 간주).
- 확인(시뮬레이터): 쇼핑/경제 L1 돈(새 단어) 버튼에 5m/1d/4d/14d 표시. 돈 Again → 요청 `wordId:1427, rating:1`. 바지(학습함·기한 전) → "Already learned" + Next word. 기한 지난 학습 단어가 버튼으로 나오는지는 아래 18:0x 기록.
- analyze: No issues.

### 09-30 18:00 · VOC-1.4.1 덱 이름 번역 정리 — c477e51
- 60줄 switch → const Map. DB 14개 덱 전부 포함 확인(curl `/decks`), DB 에 없는 8개 항목(식생활·주생활 등) 제거, 없는 이름은 원문 표시. `koreanTitle` 추가.
- 덱 목록 부제 "Beginner • 46 words" → "쇼핑/경제 · 46 words". **Beginner 표시 제거 이유**: 서버 level 이 14개 덱 모두 'Beginner' 고정인데 B·C 등급 4,676개가 섞여 있음(실사 §4-C) → 사실과 다른 표시. (서버 필드는 그대로 읽음)
- 확인: 시뮬레이터 덱 목록 스크린샷(영어 제목 + 한국어 부제). analyze No issues.

### 09-30 18:05 · VOC-1.3.4 추가 확인 (기한 지난 학습 단어)
- 돈(1427) Again 후 기한(18:02) 지난 뒤 Word Study L1 재진입 → "Already learned" 대신 평가 버튼 표시, 간격도 재학습용으로 바뀜(Again 5m / Hard 1d / Good 2d / Easy 3d). Good → 응답 `applied:true, nextReviewDate 10-02 18:02` = 표시한 "2d" 와 일치. DB state 2.
- 최종: `flutter analyze lib/features/vocabulary` No issues. PLAN 의 [FE] 태스크 전부 [x].

### 09-30 19:55 · VOC-1.5.1 단어장 비주얼 리디자인 (R2 피드백 #5 "너무 단순, 안 예쁨") — a163aa8
- 준비: main 동기화 후 pub get, 앱 재실행(시뮬레이터가 꺼져 있어 iPhone 17 부팅 후 실행). 브랜드 primary 0xFF6B4EFF 반영 확인.
- 공용 `widgets/vocab_style.dart`: `DeckVisual`(14덱 아이콘 + 강조색 — primary 의 hue 를 14등분 회전, 노랑~연두는 명도 낮춤. 하드코딩 팔레트 없음), `gameAccent`(primary hue+120° 코랄, Match 전용), `FadeSlideIn`(순차 등장), `PressableScale`(누름 축소). 새 패키지 없음.
- 덱 목록: 그라디언트 헤더("14 topic decks · 5,561 words") + 2열 그리드 카드(아이콘, 영어/한국어 이름, 진행바 "k / N studied", 다 끝나면 ✓). 진행률은 레슨 목록과 같은 `vocabularyLessonsProvider` 합산(API 변경 없음, 덱 14개 × 가벼운 요청).
- 레슨 목록: 덱 헤더(진행 링 + "k of N words studied / m of L lessons complete"), 레슨 행에 진행 링·완료 ✓, 이어 할 레슨에 "Continue/Up next" 배지+테두리. 모드 시트: 큰 옵션 카드 2개(Word Study=primary, Match=gameAccent), 드래그 핸들.
- 단어 카드: 앞면 상단 브랜드 띠, 품사 칩, 큰 한국어(FittedBox), 원형 TTS 버튼, "Tap to see the meaning". 뒷면: 한국어 → 뜻(primary) → 품사 칩 → 예문 박스. 플립은 easeInOutCubic + 뒤집는 중 6% 축소(깊이감). 평가 버튼은 연한 톤 카드(색 테두리 + 간격). 상단에 진행바(애니메이션).
- 완료 화면(`widgets/session_summary_view.dart`, Word Study·Daily Review 공용): 탄성 배지 + 페이드업, 이번 세션 평가 요약(Again/Hard/Good/Easy 개수 — provider 에 `ratingCounts` 추가).
- 스크린샷 (`screenshots/r2/`, iPhone 17):
  - 전: before_1_decks · before_2_lessons · before_3_mode_sheet · before_4_card_front · before_5_card_back · before_6_match
  - 후: after_1_decks · after_1b_decks_scrolled · after_2_lessons · after_3_mode_sheet · after_4_card_front(학습함) · after_4b_card_new_front · after_4c_card_rating · after_5_card_back · after_6_study_complete
- 확인: 동물/식물 L2 4단어 Good/Easy/Again/Good → 요청 wordId 3408/3436/3873/4653 순서대로, 완료 화면 요약 1/0/2/1 일치. analyze No issues. Daily Review 완료 화면은 같은 위젯이지만 이 태스크에선 **미확인**.

### 09-30 20:02 · VOC-1.5.2 Match Madness 부드럽게 (R2 "매치가 부드럽지 않다") — 3fe6d12
- 원인(이전): 정답이면 0.3초·오답이면 0.5초 동안 보드 전체 잠금 + 라운드 전환 0.6초 대기 후 타일이 한 번에 바뀜, 흔들림은 선형 사인, 타일은 Expanded 로 화면 높이를 꽉 채워 쌍이 적으면 비정상적으로 큼.
- provider: 정답은 **즉시 matched**(보드 잠금 없음, 타일이 스스로 애니메이션), 마지막 짝/라운드 끝은 pop-out(0.45초) 후 진행. 오답 잠금 0.45초. `mistakes`, `startedAt`/`finishedAt` 추가 → 완료 화면 실제 통계(시간·실수·정확도 = 맞힌 짝/(맞힌 짝+실수)).
- 타일(`_MatchTile`, 컨트롤러 3개): 라운드마다 40ms 간격 순차 pop-in(easeOutBack), 선택 시 AnimatedScale 1.05 + 색/그림자 전환(180ms), 정답 초록 → 1.12 pop → 0.6 로 줄며 fade(420ms), 오답 errorContainer 색 + 감쇠 사인 shake(420ms) + 햅틱. 고정 높이 68, 가운데 정렬.
- 헤더: 진행바 애니메이션 + "k/N", 라운드 칩은 바뀔 때 scale 전환. 보드↔완료는 AnimatedSwitcher.
- 완료: CustomPainter 컨페티(60조각, 중력 가속, 2.6초, IgnorePointer+RepaintBoundary) + 탄성 트로피 + 통계 3칸, 실수 0이면 "Perfect Match!". Play Again 은 gameAccent.
- 스크린샷(`screenshots/r2/`): after_7_match(보드) · after_7b_match_selected · after_7c_match_wrong(흔들림 중) · after_7d_match_correct(사라지는 중) · after_7e_round2_enter(순차 등장 중) · after_8_match_complete(컨페티). 전: before_6_match.
- 확인: 쇼핑/경제 L2(15쌍 = 3라운드) 끝까지 플레이. 일부러 1회 오답 → 완료 화면 "1 mistakes / 94%(15/16)" 일치. Play Again → 새로 섞인 Round 1/3, 예외 0.
- **60fps 측정**: 임시 `SchedulerBinding.addTimingsCallback` 로거로 전 과정 483프레임 기록(커밋 전 제거). **debug 빌드** 기준 build 중앙값 1.2ms / p95 6.4ms, raster 중앙값 1.2ms / p95 4.0ms, 16.7ms 초과 14프레임(2.9%, 최대 raster 74.8ms — 완료 화면 전환·첫 컨페티 등 1회성 스파이크로 추정). iOS 시뮬레이터는 profile/release 모드를 지원하지 않아 **release 60fps 는 미확인**(실기기 profile 모드에서 확인 필요). debug 가 release 보다 느리므로 체감상 끊김 없음.
- analyze No issues.
