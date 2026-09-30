# LSN — Korean Lesson — FE 세션 로그 (`lesson-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: (없음) Step 1.5 [FE] 완료 — LSN-1.5.3(카드 네비 통합), LSN-1.5.2(TtsHelper, PM 위임). 그 전 LSN [FE]·PM-1.P [FE] 전부 완료
- 다음 할 일: PM 지시 대기. TtsHelper 후속(다른 세션/PM): lab 의 자체 FlutterTts → `TtsHelper.speak(text)` 한 줄 교체. /api/tts 는 API_CONTRACT 에 BE 기록 필요
- 막힌 것: 없음
- 실행 중인 것: `flutter run` 백그라운드 on iPhone 17 Pro (3ABA3DBC…), API_PORT=8081, DEV_JWT(scratchpad/token, 19:40 재발급). hot reload = `echo r > scratchpad/flutter_in`. 시뮬레이터가 꺼져 있으면 `xcrun simctl boot 3ABA3DBC-D969-440C-A263-37FF2FAB32A5`. ⚠️ 시뮬레이터 도구는 항상 device UDID 명시
  (scratchpad = /private/tmp/claude-501/-Users-hadohadopapi-Desktop-Maru-wt-lesson/24896aea-182f-4ce6-8c7b-f31a4642466e/scratchpad)
- TTS 확인 팁: 시뮬레이터 소리는 못 들으니 `tts_cache` 테이블(maru_lesson) 새 행 / flutter.log 의 "server audio unavailable"(폴백) 로 판단
- 마지막 커밋: `75009e9` [LSN-1.5.2]. 커밋은 `git commit -- <경로>`
- 짝 세션에게: FE 는 /api/tts 를 GET ?text= + Bearer, 응답 바이트를 audio/mpeg 로 재생. 200자 초과는 요청 안 하고 기기 음성.

## 기록 (시간순 추가만, 수정 금지)

### 2026-09-30 16:30~17:00 · LSN-1.1.2 화면 점검 [x]
- 환경: flutter pub get, :8081(lesson-be) 사용, dev_tester 토큰, iPhone 17 Pro 에서 flutter run.
- **확인 방법**: API 응답(`/api/units/{0..3}/lessons`) JSON 전체 덤프 + 시뮬레이터 조작. u1-l1 은 9단계 **완주**(의도적 오답 포함), lesson2 는 JSON 으로만 확인(**화면 미확인**), Unit 0 은 u0_l5 소개 단계 화면 + 12개 레슨 JSON 확인(퀴즈 화면 **미확인**, 코드로 확인).
- 실사 재확인(그대로 재현됨): 완료 화면 "Basic Vowels Mastered!"(1.2.1), 단계 title/instruction 미표시(1.2.2), 자음 레슨에도 "basic vowels"/"Open your mouth wide"(1.2.3), 조립 스낵바가 Check 가림(1.2.5), 빈 입력으로 Finish 가능(1.2.7), Unit 2 "No lessons found."(1.2.8), 선택지 테두리 Colors.blue(1.2.9), 탭 분석 "Sarah → word"·"이예요"·"." 블록·"Sarah입니다고" 오답(BE 1.3.x).
- DB 확인: u1-l1 완료 후 `user_progress` = score 100 / stars 3 / current_step 999 (오답을 냈는데도 100) → 1.2.6.
- 데이터 사실: 단계 JSON 은 두 형식 혼재(`content`+`step_type` vs `contentObj`+`stepType`). API 는 둘 다 내려주고 없는 쪽은 null → 현 StepModel 의 `contentObj ?? content` 로 정상 동작. 모든 단계에 top-level `title`/`instruction` 있음(단, u1-l1 조립 2단계는 null). Unit 0 items 는 `jamo`/`romanization` 만 있음 → 카드 설명은 step `instruction` 을 쓰는 게 현실적.
- 새로 발견(PLAN 추가): 1.2.15[BE] 진행 조회 API 없음, 1.2.16 목록 완료 표시, 1.2.17 탭 분석 동일 어절 동시 하이라이트·패널 위치, 1.2.18 조립 UX(드래그만, 거북이 슬롯 어절 구분 없음·한 줄 Row 라 긴 어절이면 가로 넘침, 정답 피드백 없음), 1.2.19 한글 카드 Next 비활성·설명 잘림, 1.3.7[BE] 콘텐츠.
- 거북이 단계: 슬롯 5개가 화면 좌우 끝까지 참(17 Pro 기준) → 작은 화면에선 넘칠 것. 선택지 10개+슬롯 6개면 화면이 꽉 차고 스크롤 없음 → 1.2.5 에서 같이 처리.

### 2026-09-30 17:10 · LSN-1.2.1 완료 화면 데이터 사용 [x] `90b1900`
- `completion_step_widget.dart`: 고정 "Basic Vowels Mastered!"/"1 × Basic Vowels Completed" 제거 → 제목 = step `title`(없으면 "Lesson Complete!"), 부제 = `instruction`, 본문 박스 = content `text`, "What you learned" 칩 = `highlights`. 스크롤 가능, 색은 colorScheme. `step_renderer.dart` 에서 title/instruction 전달.
- 검증: analyze 새 경고 없음(기존 12개 그대로). 시뮬레이터에서 임시로 마지막 단계부터 시작하게 바꿔(커밋 안 함, 되돌림) u1-l1 → "Lesson 1 Mastered!"+text+칩 [은/는][입니다], lesson2 → "Great Job!"+"You have completed Lesson 2." 만 표시 확인.
- 참고: colorScheme.primary(시드 생성색)가 AppBar 의 하드코딩 0xFF6B4EFF 보다 톤이 어두움 → 1.2.9 에서 레슨 화면 전체를 theme 로 맞추면 통일됨.

### 2026-09-30 17:20 · LSN-1.2.2 단계 title/instruction 표시 [x] `9a2af53`
- `lesson_screen.dart`: 진행바 아래 `_StepHeader`(step `title` 굵게 + `instruction` 회색, 4줄 제한). completion 단계는 자체 표시라 제외, 둘 다 null(u1-l1 조립 단계)이면 생략. AnimatedSwitcher 가 짧은 콘텐츠를 세로 가운데로 띄우던 것 → 위 정렬.
- `introduction_step_widget.dart`: 한글 카드 단계의 고정 제목 "Let's learn the basic vowels one by one"/"Tap each vowel…" 삭제 (헤더가 실제 데이터로 대체).
- 검증: analyze 새 경고 없음. 시뮬레이터 lesson2 1단계("Today's Goal"+설명, 본문 위 정렬), u0_l5 1단계("Consonant + Vowel = Sound"+instruction) 확인. 조립 단계 헤더(lesson2 "Sentence Building #1")는 1.2.5 에서 같이 확인 예정(미확인).

### 2026-09-30 17:35 · LSN-1.2.3 한글 카드 고정 설명 제거 [x] `ca37591`
- 데이터에 설명 필드가 없어서(BE 요청 대신) **글자 자체에서 계산한 사실만** 표시: 유형 칩(Vowel/Consonant/Syllable block/Word), "Sounds like: [romanization]", 모음 합성(ㅘ = ㅗ + ㅏ)·혼자 쓸 때 ㅇ(와), 자음 + ㅏ(ㄱ + ㅏ = 가)·쌍자음, 음절 분해(닭 = ㄷ + ㅏ + ㄺ, 받침 표시), 단어는 음절별 분해. item 에 `description`/`tip` 이 생기면 그걸 우선 표시 → **BE 1.2.12 의 "한글 카드 설명 필드" 요청은 불필요**.
- 새 파일 `lesson/utils/hangul.dart` (유니코드 조합 계산) + 테스트 `test/features/lesson/hangul_test.dart` (3개 통과).
- 글자 카드 높이 220→170 (설명 카드가 잘리던 것).
- 검증: analyze 새 경고 없음, flutter test 통과. 시뮬레이터 u0_l5 ㄱ("Consonant / [g] / ㄱ + ㅏ = 가"), u0_l4 ㅘ("Vowel / [wa] / ㅗ + ㅏ / 와") 확인. 음절·단어 카드는 테스트로만 확인(화면 미확인).

### 2026-09-30 17:50 · LSN-1.2.4 듣기 퀴즈 [x] `264fe61`
- `practice_step_widget.dart` listen_match: initState 에서 items 를 한 번 섞어 **문제 수 = 항목 수, 중복 없음**(기존: 항상 5문제, 매번 무작위라 중복). "Question i/N", "Score: 맞힌수/N" 실제 계산(기존 "Score: 0/6" 고정). "find the correct vowel" 고정 카드 삭제 → 헤더(1.2.2)가 step instruction 표시 + "Tap Listen, then choose what you hear." Check 후 "Correct! That was X." / "Not quite — you heard X." 표시. 선택지 2열 그리드(8개까지 스크롤 없이). 마지막 버튼 "Finish Quiz (x/N)". 색은 colorScheme.
- 검증: analyze 새 경고 없음. 시뮬레이터 u0_l4 퀴즈: Question 1/6·Score 0/6 → 오답 시 빨강+정답 안내, 임시 debugPrint 로 정답 확인 후 정답 선택 → Score 1/6·초록 확인 (임시 코드 제거 후 커밋).
- 남은 것: 점수를 레슨 점수로 넘기는 건 1.2.6.

### 2026-09-30 18:00 · LSN-1.2.5 조립 문제 스낵바·오버플로 [x] `3e9cae0`
- `agglutinative_step_widget.dart`: 토끼→거북이 성공 / 오답 스낵바 삭제 → Check 버튼 바로 위 인라인 배너(성공 초록 "Great! Now split each block into its smallest parts.", 오답 errorContainer "Not quite. Tap a placed block…"). 블록을 놓거나 빼면 오답 배너 사라짐. 보드+선택지 트레이를 SingleChildScrollView 로, Check 버튼은 하단 고정. 거북이 슬롯 Row→Wrap(어절이 길어도 가로로 안 넘침). 문장 카드 좌우 여백. 색 colorScheme, withOpacity 3개 → withValues.
- 검증: analyze 새 경고 없음(lesson 전체 12→9, 이 파일 withOpacity 제거분). 시뮬레이터 u1-l1 7단계(임시 점프, 되돌림): 오답(저고+Sarah입니다.) → 인라인 오답 배너+Check 보임, 블록 제거 시 배너 사라짐, 정답 → 거북이 단계 + 성공 배너, "Check & Finish" 가려지지 않음, 슬롯이 어절별로 줄바꿈.
- 미확인: 작은 화면(SE) 실기 확인 안 함(스크롤 구조라 넘치지 않을 것으로 봄). 헤더(1.2.2) — u1-l1 조립 단계는 title null 이라 헤더 없음 확인.

### 2026-09-30 18:15 · LSN-1.2.6 실제 점수 전송 [x] `40fe8b5`
- 채점 단계가 첫 시도 결과 (맞힌수, 전체)를 `onScore` 로 보고: 듣기 퀴즈 = 문제별, fill_blank·listening·multiple_choice = 문항별(첫 Check 기준, Try Again 후 정답은 불인정), 조립 = 🐰·🐢 단계당 1점(총 2). user_input·listen_repeat·카드 단계는 채점 안 함.
- `lesson_screen.dart`: 단계별 결과를 모아 `round(100×맞힌수/전체)` 전송 (채점 문항이 하나도 없으면 100 — 읽기만 있는 레슨). completion 단계에 "Score: x%" 표시.
- 검증: analyze 새 경고 없음. 시뮬레이터 u0_l4 퀴즈(임시 점프+정답 debugPrint, 되돌림) 4/6 정답 → DB `user_progress` u0_l4 score **67**, stars **2** (BE 1.2.11 규칙), time 76초. 이전엔 항상 100/3.
- 미확인: 조립 단계 점수·completion 의 "Score: x%" 화면은 코드로만 확인(u1-l1 전체 완주 안 함).

### 2026-09-30 18:30 · LSN-1.2.7 user_input 검사 [x] `95a878b` (+ 1.2.2 보정 `52e24c0`)
- `practice_step_widget.dart`: 입력 전부터 템플릿 "저는 ____입니다." 표시, 입력하면 실시간 반영. Check 버튼은 **빈 입력·20자 초과·템플릿 고정부(저는/입니다) 재입력 시 비활성** + 영어 안내("Type only the missing part — '저는' is already in the sentence." 등). Check 후 완성 문장 + 🔊 + 데이터 `feedback.correct` 표시 → Next. 정답이 없는 문항(자기 이름)이라 채점(점수)엔 넣지 않음.
- 같은 파일: 연습 본문을 스크롤 + 하단 버튼 고정 구조로(키보드 올라와도 안 넘침), 버튼 색 colorScheme(`_primaryButton`).
- 1.2.2 보정: 헤더가 짧으면 가운데 정렬되던 것 → 왼쪽 정렬(`52e24c0`).
- 검증: analyze 새 경고 없음. 시뮬레이터 u1-l1 6단계(임시 점프, 되돌림): 빈 입력 Check 비활성 / 24자 입력 → 빨간 안내+비활성 / "Tom" → "저는 Tom입니다." + "Great job!…" + Finish Practice. (시뮬레이터 도구로 한글 입력이 안 돼서 '저는' 재입력 검사는 **화면 미확인**, 코드로만 확인)

### 2026-09-30 18:45 · LSN-1.2.8 Unit 2·3 Coming soon [x] `fa89b4e`
- `unit_selection_screen.dart`: 유닛 0~3 각각 `unitLessonsProvider` 로 조회 → 제목 = 첫 레슨의 `unitTitle`(DB, BE lsn_002 로 Unit 1 = "Introduce Yourself" 통일), 부제 = 실제 레슨 수("12 lessons"/"3 lessons"). 레슨 0개 유닛은 자물쇠 + "Coming soon / New lessons are being prepared." + 탭 불가 (가짜 주제명 안 씀). 로딩 "Loading…", 오류 "Couldn't load lessons. Tap to retry."(탭 시 재조회). 색 colorScheme.
- `lesson_provider.dart`: `unitLessonsProvider` 를 autoDispose 로 → 유닛 화면에 다시 들어오면 새로 받음 (BE 가 u1-l3 추가했는데 "2 lessons" 로 캐시돼 있던 것 확인 후 수정).
- 검증: analyze 새 경고 없음. 시뮬레이터: Unit 0 "Basics of Hangeul · 12 lessons", Unit 1 "Introduce Yourself · 3 lessons", Unit 2·3 잠금 카드, 탭해도 이동 없음. 오류 상태는 서버를 끄지 않아서 **화면 미확인**.

### 2026-09-30 17:05 · LSN-1.3.6 조립 위젯 새 데이터 대응 [x] `d1af914`
- ⚠️ 정정: 이 LOG 의 앞선 1.2.1~1.2.8 기록 시각(17:10~18:45)은 추정으로 잘못 적었음. 실제로는 16:30~17:00 사이 작업. 이후는 `date` 기준.
- (1.2.9 보다 먼저 진행: BE lsn_003 으로 새 조립 데이터가 이미 DB 에 들어가 있어 데모 핵심 화면 우선)
- `agglutinative_step_widget.dart`: 선택지 배치는 `id` 기준(같은 텍스트 2개도 각각 배치 가능), 채점은 텍스트 비교(동일 형태소는 서로 바꿔도 정답). 🐢 단계에서 **분해하지 않는 어절**(correct_turtle 1개 = correct_rabbit, 예: lesson2·u1-l3 의 '저는')은 회색 고정 블록으로 미리 놓고 트레이에서도 뺌 → 레슨 목표 형태소만 빈칸. 안내 "Now split the part this lesson teaches — grey blocks stay whole." 단계 칩 Row→Wrap(352px 폭에서 overflow — 테스트가 잡음).
- `morphological_text_chunk.dart`: `tokens: []` 청크는 탭 불가·밑줄 없음 (BE 요청). withOpacity 3개 정리.
- 테스트 `test/features/lesson/agglutinative_step_widget_test.dart` 2개: (a) '는' 두 번 필요한 문장 — 두 '는' 모두 배치·onScore (2,2), (b) '저는' 통째 유지 문장 — 빈칸 2개만, 트레이에 '저는' 없음. `flutter test test/features/lesson` 5개 통과.
- 시뮬레이터: lesson2 조립 #1(저는 회색 고정 + 학생/이에요) → #2(저는 + 의사/예요) → 완료 화면 "Great Job! / Score: 100% / text / 칩[이에요][예요]" 확인. (임시 점프, 되돌림)
- 미확인: u1-l1·u1-l3 조립은 이 태스크에서 화면 확인 안 함 → 1.4.2 에서 u1-l3 완주 예정.

### 2026-09-30 17:05 · LSN-1.2.9 영어 오류문구·테마 색 [x] `a28910c`
- `lesson_list_screen.dart`: "레슨 데이터를 불러오지 못했습니다." → "Couldn't load the lessons / Please check your connection and try again." + **Retry** 버튼(provider invalidate). 빈 유닛 "No lessons found." → "Coming soon". 당겨서 새로고침. 미사용 `_buildMockLessonCard` 삭제.
- 레슨 화면 전체(lesson_screen, intro, practice, agglutinative, morph chunk): 0xFF6B4EFF·0xFF8B5CF6·Colors.blue·Colors.purple → `colorScheme.primary`, redAccent → `colorScheme.error`, Scaffold 흰 배경 강제 제거. withOpacity 전부 withValues.
- 검증: `flutter analyze lib/features/lesson` → **No issues found** (시작 시 12개). flutter test 5개 통과. 시뮬레이터 Unit 1 목록·u1-l1 1단계·탭 분석 패널 색 통일 확인 (새 청크 데이터 "Sarah (name)", "예요 → am/is/are (polite)" 도 확인). 오류+Retry 화면은 서버를 끌 수 없어 **미확인**(짝 BE 서버 공유).
- PM 참고: `colorScheme.primary`(시드 0xFF6B4EFF 로 만든 M3 톤)는 브랜드색보다 탁한 보라로 보임. 브랜드색 그대로 원하면 main.dart 의 ColorScheme 에서 primary 를 고정해야 함(PM 소관).

### 2026-09-30 17:06 · LSN-1.2.16 목록 완료 표시 [x] `dca1a65`
- progress: `UserProgressRepository.getUnitProgress(unitId)` (GET /api/progress/lessons?unitId=), `unitProgressProvider` (autoDispose family, lessonId→기록 Map).
- `lesson_list_screen.dart`: 카드 오른쪽에 완료 = ✓ + 별 3칸(starsEarned 만큼 채움), in_progress = "In progress", 기록 없음 = 화살표. 진행 기록 조회 실패해도 목록은 정상 표시(보조 정보). 당겨서 새로고침 시 같이 갱신.
- `lesson_screen.dart`: 레슨 제출 후 `unitProgressProvider(unitId)` invalidate → 목록 복귀 시 바로 반영.
- 검증: analyze No issues. 시뮬레이터 Unit 0 목록에서 u0_l4 "Combined Vowels" ✓ ★★☆ (DB score 67 / stars 2 와 일치). 제출 직후 목록 갱신은 1.4.2 에서 확인 예정(**아직 미확인**).

### 2026-09-30 17:08 · LSN-1.2.17 탭 분석 하이라이트·패널 위치 [x] `4f85c0a`
- `morphological_text_chunk.dart`: 선택 기준 display 텍스트 → **청크 인덱스**(`selectedIndex`), 콜백 `onChunkTap(index, chunk)`.
- `introduction_step_widget.dart`: (문장 인덱스, 청크 인덱스)로 선택 저장, Grammar Analysis 패널을 **탭한 문장 카드 바로 아래**에 표시(기존: 모든 문장 아래). 같은 청크 다시 탭/X 로 닫기. 영어 뜻 색 colorScheme.
- 검증: analyze No issues. 시뮬레이터 u1-l1 Conversation #1: 2번째 문장의 '저는' 탭 → 그 칩만 하이라이트(3번째 문장 '저는'은 그대로), 패널이 2번째 문장 바로 아래 "저 → I (polite)…".

### 2026-09-30 17:14 · LSN-1.2.18 조립 UX [x] `f50e4ef`
- `agglutinative_step_widget.dart`: 블록 **탭 → 첫 빈칸에 배치**(드래그도 유지), 🐢 슬롯 위에 어절 라벨(예: '커피를' 아래 [커피][를]), 정답 시 "Correct! <문장>" 1.2초 표시 후 다음 단계(그동안 Check 비활성), 🐢 오답 시 데이터 `turtle_explanation` 을 "Hint: …" 로 덧붙임. 옵션 글자색 onPrimary.
- 테스트 추가(탭 배치 + 힌트), 기존 테스트는 지연 진행에 맞게 수정 → `flutter test test/features/lesson` 6개 통과. analyze No issues.
- 시뮬레이터: u1-l3 조립 3문제를 **탭만으로** 완주. #1 🐢 에서 일부러 [를][커피] → "Hint: '를' marks the object. After a vowel use 를, after a consonant use 을." 확인, 정답 시 "Correct! 저는 커피를 좋아해요." 확인. '저는·좋아해요·민수는·마셔요'는 회색 고정, 목표 조사 어절만 분해.

### 2026-09-30 17:14 · LSN-1.4.2 u1-l3 완주 확인 [x] (코드 변경 없음, 검증 커밋 `f50e4ef` 기준)
- 시뮬레이터에서 u1-l3 "What do you like?" 9단계 **처음부터 끝까지 완주** (임시 점프 없이).
  - 1~3 intro: 탭 분석 정상, 문법 단계의 "=", "coffee", "(object)" 청크는 탭 불가(밑줄 없음).
  - 4 Pattern Practice: 4문항(를/을/을/를), Q1 일부러 오답 → Try Again → 정답.
  - 5 Vocabulary, 6~8 조립 3문제: 🐢 에서 '저는/민수는'·동사 어절은 통째(회색), '커피를/빵을/물을' 만 분해 — 발표 주장 "레슨 목표 조사만 분해"가 화면으로 확인됨. '민수는' 에 는(JX)가 있어도 이 레슨에선 분해 안 함.
  - 9 완료: "Lesson 3 Mastered!" + "Score: 80%" (첫 시도: 연습 3/4 + 조립 5/6 = 8/10) + text.
- DB: `user_progress` u1-l3 completed / score **80** / stars **3** / 259초. 목록 복귀 시 u1-l3 에 ✓ ★★★ **바로 반영**(1.2.16 제출 후 갱신 확인 완료).
- 작은 문제: 완료 화면에서 "What you learned" 칩이 Continue 버튼 위에서 잘려 보임(스크롤하면 보임) → 발견만, P2.

### 2026-09-30 17:16 · LSN-1.2.19 한글 카드 Next 버튼 [x] `d9e0ae4`
- `introduction_step_widget.dart`: 하단 "Next" 가 마지막 카드 전까지 비활성이던 것 → Next = 다음 카드, 마지막 카드에서 "Continue" = 다음 단계. "Previous" 는 첫 카드에서 비활성(기존: 눌러도 반응 없음). 설명 잘림은 1.2.3 에서 카드 높이 조정으로 이미 해결.
- `completion_step_widget.dart`: 체크 아이콘 112→80, 여백 축소 → "What you learned" 칩이 스크롤 없이 보임(1.4.2 에서 발견한 잘림).
- 검증: analyze No issues. 시뮬레이터 u0_l1: Next 4번 → 5/5 에서 Continue 로 바뀜, 1/5 에서 Previous 비활성. u0_l1 완료 단계(BE lsn_002 로 추가된 것, 임시 점프 후 되돌림) "Basic Vowels Complete! / You practiced: ㅏ ㅓ ㅗ ㅜ ㅣ / 칩 5개" 한 화면에 표시.

### 2026-09-30 17:20 · LSN-1.2.13 레슨 이어하기 [x] `2c3c255`
- 저장 시점: 레슨 도중 **나갈 때 1번**(PopScope, 뒤로 버튼·스와이프 모두) `in_progress` + `currentStep`(0-based 단계 인덱스) + 경과 초. 단계마다 저장하지 않은 이유: BE 가 호출마다 attempts+1, 시간 누적이라 부풀려짐. 저장 후 목록 provider 갱신 → "In progress".
- 목록에서 in_progress 레슨(currentStep 1 이상) 탭 → "Continue where you left off? / You stopped at step n of N." [Start over][Continue]. completed 레슨은 항상 처음부터.
- 완료 시 currentStep 999 → 실제 단계 수. 제출 실패 시 SnackBar "Couldn't save your progress. Please check your connection."(기존: 조용히 무시).
- **정직성 수정**: 이어하기로 채점 단계를 건너뛰고 이번 세션에 채점 결과가 없으면 score 를 보내지 않음(기존 로직이면 100 전송 = 가짜 만점). 서버는 누락을 0점·별 1개로 저장하고 최고 기록은 유지.
- progress 모델: 요청 score nullable(누락 시 JSON 에서 제외). `saveInProgress()` 추가.
- 검증: analyze No issues, flutter test 6개 통과. 시뮬레이터: u0_l1 도중 나가기 → DB in_progress/current_step 3, 목록 "In progress" → 재진입 다이얼로그 → Continue → Step 4/4 → 완료 → completed/current_step 4. u0_l2 로 퀴즈 건너뛴 이어하기 완료 → **score 0 / ★1** (수정 전이었다면 100/★3).
- 참고: 수정 전 테스트로 로컬 DB 의 dev_tester u0_l1 이 100/★3 로 남아 있음(테스트 데이터, Railway 무관).

### 2026-09-30 18:17 · [PM 위임] PM-1.P.11 프로필 게이트 서버 실패 [x] `97ce570`
- (PM 위임 D-08 — 🔒 main.dart, features/profile 수정)
- `main.dart`: `ProviderScope(retry: (_, __) => null)` → **앱 전체 provider 자동 재시도 끔**(Riverpod 3 기본은 실패 시 ~10회/40초 재시도하며 loading 유지 → 무한 스피너처럼 보임). ⚠️ 다른 기능 FE 도 영향: 오류가 즉시 error 상태로 나옴(각 화면 오류 UI 필요).
- `profile_gate.dart`: 연결 실패 → "Can't reach Maru right now / Please check your internet connection…" + **Retry** + **Log out**. 404(계정 없음) → "Account not found" + Log out (기존: 막다른 화면).
- 검증: analyze No issues. 시뮬레이터에서 API_PORT=8099(닫힌 포트)로 실행 → 앱 시작 약 2초 내 오류 화면, Retry → 다시 오류 화면(스피너 고착 없음), Log out → 로그인 화면. 404 화면은 **미확인**.
- 주의(세션 기록): 스크린샷 도구가 기본 장치로 iPhone Air(mission)를 한 번 캡처함 — 조작은 없었음. 이후 모든 조작에 device UDID 명시.

### 2026-09-30 18:23 · [PM 위임] PM-1.P.1f 로그인 실패 무한 로딩 [x] `589ccb7`
- (PM 위임 D-08 — 🔒 core/**, screens/auth 수정)
- `auth_repository.dart`: `verifyIdToken` → 실패 시 영어 메시지 반환(성공 null), **절대 throw 안 함**. data 가 비어있지 않은 String 인지 검사(기존 `as String` 이 200+data:null 에 TypeError → 잡히지 않아 loading 고착). 401/403/400 = "We couldn't verify your account…", 연결 실패 = "Can't reach Maru right now…".
- `auth_provider.dart`: loginWithBackend try/catch, `errorMessage` 보관. `login_screen.dart`: 오류 문구 표시, Google/Apple 예외를 로그만 찍던 것 → 화면 표시, Apple 취소는 무시.
- `dio_client.dart`: `/api/auth/*` 의 401/403 은 세션 만료로 처리하지 않음(BE 1.P.1 이 401 을 돌려주면 인터셉터가 즉시 logout → 오류 문구가 사라지던 문제 예방). 세션 만료 스낵바 한국어 → "Your session has expired. Please log in again."
- **새로 발견 → 같이 수정: iOS 에서 "Sign in with Google" 누르면 앱이 즉시 종료(크래시)**. Info.plist 에 GIDClientID 가 없어 네이티브 SDK 가 abort(실사 §2-C 는 "조용히 무반응" 추정이었으나 실제는 크래시). → iOS 에서 `GoogleSignIn(clientId: <Info.plist REVERSED_CLIENT_ID 에서 유도한 iOS 클라이언트 ID>)` 전달(공개 식별자). 이제 iOS 로그인 동의창("maru이(가) google.com을 사용하여 로그인…")이 뜸. 취소 시 조용히 로그인 화면.
- ⚠️ PM 확인 필요: BE 는 id token 의 audience 를 `GOOGLE_CLIENT_ID`(.env) 로 검사. iOS 토큰 aud 가 다르면 서버가 401 → 앱은 "We couldn't verify your account" 표시(무한 로딩 아님). 실제 iOS 구글 로그인 성공까지는 `--dart-define=GOOGLE_SERVER_CLIENT_ID=<서버 GOOGLE_CLIENT_ID>` 로 serverClientId 지정이 필요할 수 있음 — **실계정 로그인은 미확인**(계정 필요).
- 검증: analyze No issues. `test/core/auth_repository_test.dart` 4개 통과(JWT 성공·200+data:null·401·연결 실패). curl: 가짜 토큰 → HTTP 401 `{"status":401,"message":"Google sign-in failed…","data":null}`. 시뮬레이터: Google 버튼 → 크래시 없이 동의창 → 취소 → 로그인 화면.

### 2026-09-30 18:26 · [PM 위임] PM-1.P.2 홈 프로필 아이콘 로그아웃 확인 [x] `803fcba`
- (PM 위임 D-08 — 🔒 screens/home 수정)
- `home_screen.dart`: 사람 아이콘 = 즉시 logout → "Log out? / You're signed in as <닉네임>." [Cancel][Log out] 다이얼로그(닉네임은 profileProvider). tooltip "Account".
- 검증: analyze 새 경고 없음(기존 withOpacity 1개는 1.P.4 에서 정리). 시뮬레이터: 아이콘 → 다이얼로그 "You're signed in as Tester." → Cancel → 홈 유지. Log out 버튼 동작은 1.P.11 에서 같은 logout() 경로로 확인.

### 2026-09-30 18:27 · [PM 위임] PM-1.P.4 홈 통계·복습 배너 상태 [x] `786be53`
- (PM 위임 D-08 — 🔒 screens/home 수정, R-003 (1))
- `home_screen.dart`: 통계 카드 loading → 카드 안 작은 스피너, error → "Couldn't load your progress." + Retry(invalidate). 복습 배너 loading → 얇은 진행바, error → "Couldn't check today's word reviews." + Retry, 0개 → 배너 없음(정상). "1 words" → `count == 1 ? 'word' : 'words'`. withOpacity 정리 → `flutter analyze lib/screens` No issues.
- 검증: 시뮬레이터 정상 상태(🔥1 ★9) 확인. 임시 override(통계 error, 복습 수 1; 커밋 전 원복)로 오류 행+Retry, "1 word ready to review" 화면 확인. 실제 서버 오류·로딩 스피너는 **미확인**(너무 빨라 캡처 불가).

### 2026-09-30 18:29 · [PM 위임] PM-1.P.3 Stats/Settings 탭 [x] `0a4e90b` (18:27 시작, 약 10분 — 탭 숨김 대체 불필요)
- (PM 위임 D-08 — 🔒 screens/home/main_screen, features/stats·profile 수정. 새 파일 `features/stats/screens/stats_screen.dart`, `features/profile/screens/settings_screen.dart`)
- **Stats** ("My Progress"): `/api/me/stats` 의 현재 스트릭·별·완료 레슨·학습 시간(분→"1 h 5 min") 타일 + 최장 스트릭·마지막 학습일(Today/Yesterday/날짜). 단/복수 처리. 로딩 스피너, 오류 "Couldn't load your progress" + Retry, 당겨서 새로고침. 하단에 학습 시간·스트릭 산정 기준 한 줄(정직 표기).
- **Settings**: 닉네임(탭 → 수정 다이얼로그, PUT /api/me/profile), 이메일(있을 때만), Log out(확인 다이얼로그), App version 1.0.0(pubspec 과 수동 동기화 — package_info 패키지 없음, 추가 금지).
- `main_screen.dart`: 두 탭 연결, 선택 색 colorScheme.primary.
- 검증: analyze No issues. 시뮬레이터 Stats = API 값과 일치(🔥1, ★9, 레슨 4, 7 min, 최장 1 day, Today). Settings 닉네임 Tester→Tester2 저장("Nickname updated.", DB 확인) 후 API 로 Tester 복원. Stats 오류 화면은 **미확인**.

### 2026-09-30 18:30 · [PM 위임] PM-1.P.6 로그인 부제·Android 라벨 [x] `4250665`
- (PM 위임 D-08 — 🔒 screens/auth, android/ 수정)
- 로그인 부제 "Korean Grammar Lab" → **"Learn Korean, one piece at a time."** (형태소 조립 컨셉에 맞춘 슬로건. deliverables/CLAIMS.md 가 아직 없어 임시 선택 — PM 이 문구 바꾸려면 `login_screen.dart` 한 줄). 제목 "Maru" 색 blueAccent → colorScheme.primary.
- `AndroidManifest.xml` android:label "maru" → "Maru". iOS CFBundleDisplayName 은 이미 "Maru".
- 검증: analyze No issues. 시뮬레이터 Settings → Log out(확인 다이얼로그) → 로그인 화면에 새 부제 확인. Android 라벨은 에뮬레이터 **미확인**(파일 변경만).
- 참고: Settings 닉네임 표시는 서버 값 복원(API) 후에도 앱 캐시로 "Tester2" 가 남아 있었음 — 테스트 부산물, 다음 앱 시작 시 "Tester".

### 2026-09-30 18:31 · [PM 위임] PM-1.P.9 테마 primary = 0xFF6B4EFF [x] `0f8c579`
- (PM 위임 D-08 — 🔒 main.dart 수정)
- `ColorScheme.fromSeed(seedColor: brand).copyWith(primary: 0xFF6B4EFF, onPrimary: white)` — fromSeed 가 만든 탁한 보라(1.2.9 때 보고한 문제) → 정확한 브랜드색. 나머지 톤(container 등)은 seed 기반 유지.
- 검증: 시뮬레이터 로그인 "Maru" 제목, 레슨 AppBar·Continue·진행바가 선명한 브랜드 보라로 표시. 흰 글씨 대비 OK(육안).
- **Step 1.P [FE] 마무리 점검**: `flutter analyze lib/main.dart lib/core lib/screens lib/features/{profile,stats,lesson,progress}` → No issues. `flutter test test/core test/features/lesson` → 전부 통과(10개).

### 2026-09-30 19:43 · LSN-1.5.3 한글 카드 네비 중복 통합 [x] `604e722` (피드백 R2 #2)
- worktree 가 main 과 동기화된 상태에서 시작(PM). flutter pub get 완료. 시뮬레이터가 Shutdown 상태라 `simctl boot` 후 실행.
- `introduction_step_widget.dart`: 카드 아래 `< 1/5 >` 화살표 줄 삭제 → 점 인디케이터 옆에 "1 / 5" (표시 전용). 조작은 하단 Previous / Next(마지막 카드에서 Continue) 하나로, 스와이프 유지.
- 검증: analyze No issues. 시뮬레이터 u0_l1: 1/5 에서 Previous 비활성·Next 활성, 스와이프 → 2/5 로 점·숫자 동기화.

### 2026-09-30 19:47 · [PM 위임] LSN-1.5.2 공통 TtsHelper [x] `75009e9`
- (PM 위임 — 🔒 core/utils/tts_helper.dart, pubspec.yaml/lock, ios/Podfile.lock 수정. 패키지 **just_audio ^0.10.6** 1개 추가 → audio_session 이 전이 의존성으로 따라옴)
- **공개 API**: `TtsHelper.speak(String text)` (기존 시그니처 그대로 → vocab 의 기존 호출도 자동으로 서버 음성 사용) + `TtsHelper.stop()`(화면 나갈 때용).
- 동작: `GET /api/tts?text=` (lesson-be 1.5.1, OpenAI TTS·서버 DB 캐시) mp3 바이트 → just_audio 재생. 앱 메모리 캐시 60개(재생 반복 시 서버 미호출). base URL 은 dio_client 와 같은 규칙(API_BASE_URL/API_PORT), JWT 는 SecureStorage. 타임아웃 8초, 200자 초과는 바로 폴백. 새 speak/stop 이 오면 다운로드 중인 이전 요청은 재생 안 함.
- **폴백**: 어떤 실패든 flutter_tts(ko-KR, 속도 0.45, 기기에 설치된 premium/enhanced 한국어 음성 우선).
- 호출부 교체: lesson `introduction_step_widget`, `practice_step_widget` 만(FlutterTts 인스턴스 제거, dispose 에서 TtsHelper.stop()). vocab·lab 파일은 수정 안 함(lab 은 아직 자체 FlutterTts — PM 이 나중에 한 줄 교체).
- 검증: `flutter analyze lib/core lib/features/lesson` No issues, `flutter analyze lib` error 0. 시뮬레이터(소리는 들을 수 없어 로그·DB 로 확인): u0_l1 스피커 탭 → 임시 debugPrint 로 **서버 음성 33024 bytes, just_audio 가 2.06초 길이로 디코드** 확인(DB tts_cache 의 'ㅏ' 크기와 일치). 임시로 포트 8099 → "server audio unavailable, using device voice" 후 flutter_tts 로 'ㅓ' 재생 경로 확인. 원복 후 'ㅓ' 가 서버 호출돼 tts_cache 에 새 행(19:47:15) 생성. 임시 코드 제거 후 커밋.
- 실수 기록: 임시 줄 삭제(sed /TEMP-VERIFY/d) 때 같은 줄의 실제 `return` 까지 지워졌다가 analyze 에서 잡고 복구 → 커밋본은 정상.
- 참고: macos/GeneratedPluginRegistrant.swift 는 빌드 부산물이라 되돌림(커밋 제외). API_CONTRACT 에 /api/tts 는 아직 BE 기록 전(응답: 200 audio/mpeg 확인).
