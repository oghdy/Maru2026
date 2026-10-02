# LAB — Language Lab — FE 세션 로그 (`lab-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음. Step 1.9 전부 완료 (1.9.1 89a66e2 · 1.9.2 4fb6b24+fe59a69 · 1.9.3 81970fe)
- 다음 할 일: PM 지시 대기
- 막힌 것 / 기다리는 것: REQUESTS R-005(홈 카드 부제, PM) · R-006(turtle_lab_sad·talking 에셋, char-lead) — 에셋만 추가되면 코드 수정 없이 자동 반영
- 실행 중인 것: 없음 (서버 :8084·flutter run·iPhone 16 Pro 시뮬레이터 종료)
- 마지막 커밋: 81970fe
- 짝 세션에게: API 변화 없음
- 주의: 새 캐릭터 에셋은 hot reload 로 안 잡힘 → flutter run 재시작. 시뮬레이터 도구는 device 꼭 지정, 연속 탭 1초 이상. 시뮬레이터 입력은 한국어 키보드라 영어 `text` 가 자모로 바뀜(오류 테스트는 숫자 "12345" 로)

## 기록 (시간순 추가만, 수정 금지)

### 09-30 · LAB-1.1.2 [FE] 현황 점검 (코드 변경 없음)
- 실행: iPhone 16 Pro `63ED4387…` + `API_PORT=8084` + DEV_JWT(maru_lab). 서버는 lab-be 가 띄운 :8084.
- Hangeul Lab: ㄱ+ㅏ → Combine → `가` 표시 + TTS 호출 확인(소리는 미확인). 동작은 정상.
  - 레이아웃: 상단(제목·슬롯·Combine)·결과 카드가 고정이고 자판만 Expanded 스크롤 → 결과가 뜨면 16 Pro 에서도 자판이 1줄 미만만 보임. 작은 화면은 더 나쁨 → 1.3.3
  - 받침 자판의 빈 항목(`SizedBox.shrink`)이 Wrap 안에서 간격을 먹어 첫 줄이 밀림, 로마자(`yae`,`yeo`)가 자모와 겹침, 다시 듣기·초기화 버튼 없음 → 1.3.3
  - 색: AppBar 제목·자판·슬롯 모두 `blueAccent`/`Colors.blue` → 1.3.2
- AI Grammar Lab: `저는 밥을 먹어요`/Tense → 캐시 HIT 즉시 3개 카드 정상. Emotion 칩은 가로 스크롤 밖이라 처음엔 안 보임.
  - 오류: repository 가 `Exception('Error exploring AI Lab: $e')` 로 감싸고 화면이 `e.toString()` 을 빨간 글씨로 표시(`lab_screen.dart:416`) — 재시도 없음 → 1.2.4
  - 로딩: 스피너 + "Gemini is thinking..." 뿐. 로딩 중에도 칩/Combine 이 눌려 요청이 겹치고 늦게 온 응답이 이김 → 1.2.5
  - 입력: 시뮬레이터 도구로 한국어 타이핑 불가(붙여넣기로 우회) — 실제 학습자도 한국어 키보드가 없을 수 있음 → 예문 칩 1.3.5 추가
  - 하드코딩 색(deepPurple/blue/red) → 1.3.6 추가. 입력 영역 스크롤 불가·칩 가로스크롤 → 1.3.7 추가
- 서버 쪽 참고(BE 담당, API_CONTRACT §1-4 와 동일): 빈 문장에 200 + "Error: ..." 결과. FE 는 빈 입력을 막고 있음.
- ⚠ 실수 기록: 첫 탭 2회가 device 미지정으로 mission 시뮬레이터(iPhone Air)에 들어감 → Mission Chat Setup 화면이 열려 있을 수 있음. 이후 모든 시뮬레이터 호출에 UDID 명시.

### 09-30 · LAB-1.2.4 [FE] 오류 원문 노출 → 영어 안내 + Retry (be85157)
- `ai_lab_repository.dart`: 모든 실패를 `AiLabFailure(message)` 로 변환. 연결 실패/타임아웃은 FE 문구, 400/502/503/504 는 서버 `message` 사용(API_CONTRACT §1-5, 영어 사용자용), 그 외(500·404 등)는 "Something went wrong. Please try again." 응답 모양이 틀리면(배열 아님·빈 배열) badResponse.
- `lab_screen.dart`: 오류 화면 = 아이콘 + 문구 + Retry(마지막 요청 재실행: 해당 카테고리 또는 Combine). 색은 `colorScheme.error`.
- 확인: `flutter analyze lib/features/lab` No issues. 시뮬레이터(16 Pro)에서 explore 경로를 임시로 존재하지 않는 경로로 바꿔 hot reload → 404 → 안내문+Retry 표시 확인 → 원복 후 Retry → Politeness 결과 3개 정상. 서버 400/502/504 실제 문구 표시는 BE 1.2.1·1.2.3 머지 후 확인 예정(미확인).

### 09-30 · LAB-1.2.5 [FE] 첫 요청 로딩 UX + 중복 요청 방지 (b6bf419)
- `lab_screen.dart`: 요청 중엔 칩·Combine 비활성 + 핸들러 첫 줄 `if (_isLoading) return`. 요청 시작 시 키보드 닫음.
- 로딩 화면: "Exploring <category> variations..." / "Combining N modifiers..." + 경과 시간에 따라 문구 변경(0–2s "Asking the AI...", 3–11s "This sentence is new, so the AI is writing fresh examples.", 12s~ "Almost there. New sentences can take up to 30 seconds.") + 3s 부터 경과 초 표시. Timer 는 종료·dispose 시 cancel.
- 확인: analyze No issues. 시뮬레이터에서 새 문장(`우리 동생이 학교에 가요`/negation) — 실제 요청이 ~35s 걸려 서버 504 → 로딩 중 22s·34s 시점 문구·초 표시, 버튼 비활성 확인, 그 사이 Retry 영역 재탭은 무시(flutter 로그상 요청 1건) → 504 서버 문구 "The AI took too long to respond. Please try again." + Retry 표시. 그 전 요청은 503 서버 문구 표시 확인.
- Combine 경로는 같은 로딩/오류 코드 사용 — 시뮬레이터 확인은 서버 Gemini 가 503/504 중이라 미확인.
- 짝 세션(lab-be)에게: 18:24~18:26 :8084 explore MISS 가 503(빠르게) 한 번, 504(~35s) 한 번 났음. 작업 중인 Gemini 변경(1.2.1/1.2.2) 영향일 수 있음.

### 09-30 · LAB-1.3.1 [FE] 칩 라벨 규칙 (8b5fb0e)
- 규칙: 문법 용어는 **영어 라벨 + 옆에 작은 회색 한국어 용어** (`_bilingualLabel`). Explore 칩: Tense 시제 / Politeness 존댓말 / Negation 부정문 / Emotion 감정. Combine 드롭다운 제목: Tense 시제 / Politeness 높임 / Sentence Type 문장 유형 / Negation 부정.
- 서버로 보내는 category 는 라벨 파싱(`split(' ')[0]`) 대신 명시 key(`tense|politeness|negation|emotion`) — 값은 기존과 동일(API 변화 없음).
- 칩을 가로 스크롤 ListView → Wrap (Emotion 이 화면 밖에 숨던 문제, 1.3.7 일부). 칩 색은 `colorScheme.primaryContainer`.
- 확인: analyze No issues. 시뮬레이터: 칩 4개 2줄 표시, Politeness 탭 → 요청 `category: politeness` 200 결과 표시, Combine 펼침 라벨 확인.

### 09-30 · LAB-1.3.7 [FE] Grammar Lab 작은 화면 레이아웃 (8a887d0)
- 화면 전체를 하나의 `SingleChildScrollView`(드래그 시 키보드 닫힘)로. 결과 영역은 Expanded/ListView → Column. Combine 헤더 Row 에 Flexible+ellipsis, 드롭다운 `isExpanded` + 항목 ellipsis. (`dart format -l 120` 적용해 diff 가 큼 — 동작 변화는 위가 전부)
- 테스트 추가: `test/features/lab/lab_screen_layout_test.dart` — 320×568 + 키보드 260 에서 Combine 펼쳐도 overflow 없음. **옛 코드(8b5fb0e)로 돌리면 실패**(bottom 232px, right 133px overflow) / 새 코드 통과 확인.
- 확인: analyze(lib/features/lab, test/features/lab) No issues, 테스트 1/1 통과, 16 Pro 에서 Combine 펼친 채 스크롤로 결과 3개 끝까지 보임. 1.3.1 이전 레이아웃에서 났던 RenderFlex overflow(127px) 이후 재발 없음.

### 09-30 · LAB-1.3.5 [FE] 예문 칩 (349cd87)
- 입력창 아래 "Try:" + 예문 칩 3개(`저는 밥을 먹어요`, `강아지가 뛰어요`, `매일 아침 커피를 마셔요`) — 탭하면 입력창 채움. 모두 `maru_lab` ai_cache 에 여러 카테고리가 이미 있는 문장(발표 데모 시 즉시 HIT).
- 요청 시작 시 결과 영역을 `Scrollable.ensureVisible` 로 화면에 가져옴(Combine 펼친 상태에서 결과가 화면 밖에 뜨던 문제).
- 확인: analyze No issues, 레이아웃 테스트 통과. 16 Pro: 강아지가 뛰어요 → Negation 즉시 결과, 매일 아침… → Tense 결과가 자동 스크롤로 보임.
- lab-be 참고: 내가 09-30 18:2x 에 curl 로 보낸 `category:"bogus"` 결과가 `maru_lab` ai_cache 에 `explore:bogus`(저는 밥을 먹어요) 로 1건 캐시됨 — 테스트 찌꺼기. 1.2.3 에서 모르는 category 를 거절하면 추가로는 안 생김. 지울지는 lab-be 판단(패치 규칙 §4).

### 09-30 · LAB-1.3.6 [FE] Grammar Lab 색 → theme (444f6ff)
- `lab_screen.dart` 의 `Colors.*` 전부 제거 → `colorScheme` (primary/onPrimary/primaryContainer/onPrimaryContainer/surface/surfaceContainerLow/outlineVariant/onSurfaceVariant/shadow). AppBar 제목 "Grammar Lab 🧪" → 메뉴 카드와 같은 "AI Grammar Lab".
- 확인: analyze No issues, 레이아웃 테스트 통과. 16 Pro 에서 Combine: `매일 아침 커피를 마셔요` + Past + Negative → 캐시 HIT "매일 아침 커피를 안 마셨어요 / I didn't drink coffee every morning." 표시(Combine 경로 첫 시뮬레이터 확인 — 1.2.5 의 미확인 해소, 로딩→결과 정상).
- 참고: 현재 theme primary 가 브랜드 시드(0xFF6B4EFF)보다 탁한 보라로 보임 — main.dart 시드는 PM 소유라 그대로 따름.

### 09-30 · LAB-1.3.2 + LAB-1.3.3 [FE] Hangeul Lab 색·레이아웃·TTS (70c3d19)
- 1.3.2 색: `hangeul_lab_screen`·`hangeul_slot`·`hangeul_keyboard` 의 `Colors.*`(blueAccent/blue/grey/white/black) 전부 → `colorScheme`. AppBar 제목 파란색 제거.
- 1.3.3 레이아웃: 화면 전체 SingleChildScrollView. 큰 제목 "Feel free to experiment" → 한 줄 설명(받침 optional 명시). 결과 카드를 가로형으로 줄임(글자 64 + `[gan]` 로마자 + 🔊 다시 듣기) → 16 Pro 에서 결과가 떠도 받침 자판 3.5줄 보임(전엔 1줄 미만), 초기 상태는 자음 19개 전부 한 화면.
  - 슬롯 3개를 Expanded 로(320pt 폭에서 17px overflow 났음), 슬롯 내용 FittedBox.
  - 자판: 빈 받침 항목을 목록에서 걸러 Wrap 간격 밀림 제거, 로마자를 글자 아래로(`yae`·`yeo` 겹침 해결), ㅇ 초성은 "–". InkWell 탭 피드백.
  - AppBar "Reset"(선택 있을 때만), 결과 🔊 `replay()`, 칸 채우면 "Tap a filled box to change it." 안내. Combine 버튼의 의미 없는 "4" 배지 제거.
  - 받침 없음: ㄱ+ㅏ → 가 [ga], 받침 있음: +ㄴ → 간 [gan] 시뮬레이터 확인. Reset → 초기화 확인. 다시 듣기 버튼 탭 시 오류 없음(소리 자체는 시뮬레이터에서 미확인).
- 테스트 추가: `test/features/lab/hangeul_lab_screen_test.dart` — 320×568 에서 ㅎ+ㅏ+ㄴ → 한 [han], overflow 없음, Reset. (flutter_tts 채널은 목으로 응답)
- analyze(lib/features/lab, test/features/lab) No issues, `flutter test test/features/lab/` 2/2 통과.

### 09-30 · LAB-1.3.8 [FE] 입력 200자 제한 + 400 표시 (418e951)
- BE 권장(API_CONTRACT §3 18:31)에 따라 입력창 `maxLength: 200` (카운터 표시).
- `AiLabFailure.retryable`: 400(입력 문제)은 false → 오류 화면에 Retry 없이 편집 아이콘 + 서버 문구. 나머지(502/503/504/네트워크)는 기존대로 Retry.
- 확인: 최종 BE(:8084, 18:31 재시작)에 `hello world` → 400 "Please enter a sentence in Korean." 표시·Retry 없음 확인(= BE 1.2.3 실제 문구 확인, 1.2.4 미확인 항목 해소). analyze No issues, test/features/lab 2/2 통과.

### 09-30 · LAB-1.4.1 [FE] 결과 문장 듣기/복사 (06c96b5)
- Explore 카드·Combine 결과의 한국어 문장 옆에 🔊(flutter_tts, ko-KR, 0.45 배속) + 복사(Clipboard + "Copied" 스낵바). 새 패키지 없음(flutter_tts 기존 의존성).
- 확인: 16 Pro 에서 복사 → `simctl pbpaste` = "저는 밥을 먹었어요", 스낵바 확인. 듣기 탭 시 예외 없음(소리는 미확인). analyze No issues, test/features/lab 2/2.

### 09-30 · LAB-1.5.1 [FE] Hangeul Lab 주 버튼 "Try another" (피드백 R2 #3) (85623a5)
- 결과가 있으면 큰 주 버튼이 "Combine!" → "🔄 Try another"(전체 초기화)로 바뀜(AnimatedSwitcher). 칸을 바꾸면 결과가 지워져 다시 "Combine!". 우상단 작은 Reset 제거.
- 확인: 16 Pro 에서 ㄱ+ㅏ Combine → Try another / 받침 ㄴ 선택 → Combine! 복귀 / Combine(간) → Try another → 초기 상태. 위젯 테스트도 Try another 흐름으로 갱신, analyze·test 통과.
- 참고: 빌드 중 저장한 파일이 hot reload 에 안 잡혀(Reloaded 0) 한 번 `touch` 후 reload 해야 했음.

### 09-30 · LAB-1.5.2 [FE] Grammar Lab 결과 한 화면 (피드백 R2 #4) (1e3c7f3)
- 화면을 입력 모드 / 결과 모드로 분리(AnimatedSwitcher). 요청 시작(로딩)·결과·오류 = 결과 모드: 입력 폼 숨김 → 상단 요약 바 "Original + 원문 + ✏️ Edit" + (Explore) 규칙 ChoiceChip 4개 한 줄 — 그 자리에서 다른 규칙으로 바꿔 보기 / (Combine) 적용한 수식어 칩(Past · Negative) → 아래 결과 카드가 나머지 화면 전체. 로딩·오류도 같은 자리.
- Edit 또는 뒤로가기(PopScope) → 입력 모드로, 입력 문장·드롭다운 선택 유지. 400(입력 문제) 오류는 Retry 대신 "Edit sentence".
- Explore 카드 여백·글자 조정(문장 19 bold, 설명 onSurfaceVariant). 이전의 결과 자동 스크롤 코드 제거(필요 없어짐).
- 확인(16 Pro, 402×874): 저는 밥을 먹어요/Tense → 원문+칩+결과 3개가 스크롤 없이 한 화면 / 칩으로 Negation 전환 → 같은 화면에서 새 결과(요청 1건) / 뒤로 → 입력 모드, 문장 유지 / 매일 아침…+Past+Negative Combine → 원문·수식어·결과 한 화면.
- 테스트 추가: `test/features/lab/lab_screen_result_view_test.dart` (가짜 repository: 결과 모드에서 TextField 없음·결과 3개 화면 안, Edit → 문장 유지). analyze No issues, test/features/lab 3/3 통과.

### 09-30 · LAB-1.5.3 [FE] TTS → TtsHelper (fbae653)
- `hangeul_lab_provider.dart`: FlutterTts 필드·_initTts 제거 → `TtsHelper.speak(text)`, provider dispose 시 `TtsHelper.stop`. `lab_screen.dart`: FlutterTts 필드·initState 설정 제거 → 🔊 = `TtsHelper.speak(sentence)`, dispose/Edit 시 `TtsHelper.stop()`. lab 폴더에 flutter_tts 직접 사용 0건.
- 서버: 기존 :8084(19:41 기동)에 `/api/tts` 404 → lab-be 가 대기 상태라 PM 지시대로 **직접 재시작**(앱 java 프로세스만 종료, `scripts/run_backend.sh lab` 백그라운드, 20:06 기동). curl `/api/tts?text=가` → 200 audio/mpeg 21KB 1.8s.
- 확인(maru_lab.tts_cache): 0행 → curl "가"(1) → 앱 한글랩 ㅎ+ㅏ Combine → **"하" 행 생성**(20:09:41) → 그래머랩 강아지가 뛰어요/Negation 첫 카드 🔊 → **"강아지가 안 뛰어요." 행 생성**(20:10:29). flutter 로그에 기기 음성 폴백 메시지 0건. 소리 자체는 미확인(시뮬레이터).
- just_audio 네이티브 플러그인 때문에 앱 풀 재빌드. analyze No issues, test/features/lab 3/3 통과.

### 10-01 · LAB-1.6.1~1.6.3 [FE] 캐릭터 적용 P0 (5f797ec, f633627)
- 준비: main 동기화(07fd325) 후 pub get, 앱 완전 종료→재빌드(에셋 추가). 서버 :8084 는 가동 중(09-30 20:06 lab-fe 재시작분).
- C1 `hangeul_lab_screen.dart`: 결과 카드/안내 placeholder 위에 `MaruCharacter(rabbit, 72, mood: hasResult ? happy : idle, reactionKey: state.combinedResult)`. 위 여백 18(=0.25×72), Clip/고정높이 없음. 확인: 초기 idle → ㅁ+ㅏ+ㄴ Combine → 만 + happy 표정 → `apply_lab_C1.png`.
- C2 `lab_screen.dart` `_buildLoading`: CircularProgressIndicator → `MaruCharacter(turtle, thinking, 120)`, 단계 문구·경과초 유지. 확인: 캐시 없는 `오늘은 날씨가 좋아요`/Tense(Gemini 1회) 로딩 4s 시점 → `apply_lab_C2.png`.
- C3 같은 파일 Combine 카드 머리: ✨ 아이콘 → `MaruCharacter(turtle, talking, 64, settleToIdleAfter: 2000ms, reactionKey: _combineResult)`. 확인: 매일 아침 커피를 마셔요 + Past + Negative → `apply_lab_C3.png`.
- 텍스트 피드백 삭제 없음, 로직/API 변경 없음. import 는 `maru_character.dart` 하나만.
- 테스트: 캐릭터 루프가 무한이라 기존 위젯 테스트 3개의 `pumpAndSettle` 타임아웃 → 테스트 앱에 `MediaQuery(disableAnimations: true)`(명세 §2.5 정지 모드) 적용. analyze No issues, test/features/lab 3/3.

### 10-01 · LAB-1.6.4 [FE] 캐릭터 C4 (P1) (3a21b9a)
- 오류 뷰: 아이콘(cloud_off / edit_note) → `MaruCharacter(turtle, sad, 96, reactionKey: _errorMessage)`. 문구·Retry/Edit sentence 유지. 위 padding 24 = 0.25×96.
- 빈 상태: 🧪 아이콘 → `MaruCharacter(turtle, 96)`(idle), 안내 문구 유지.
- 확인: 입력 모드 빈 상태 → `apply_lab_C4_empty.png` / `hello world`→Tense 400 "Please enter a sentence in Korean." → sad 거북이 → `apply_lab_C4.png`. analyze No issues, test 3/3. 캐릭터 코드 문제 없음(REQUESTS 없음).

### 10-01 · LAB-1.6.5 [FE] 결과 문장 어절 단위 줄바꿈 (bbda55c)
- `lab/utils/korean_word_wrap.dart` `koreanKeepAll()`: 인접한 한글 글자 사이에 U+2060 WORD JOINER 삽입(MaruCharacterBubble 과 같은 규칙 — 캐릭터 코드는 private 라 lab 폴더에 같은 로직 복제). `_sentenceWithActions` 의 표시 Text 에만 적용 → Explore 카드·Combine 결과 모두. 복사·TTS 는 원문 `sentence` 그대로.
- 확인(16 Pro): 매일 아침 커피를 마셔요 + Past + Negative → "매일 아침 커피를 안 / 마셨어요"(이전 "안 마 / 셨어요") → `apply_lab_wrap.png`. 복사 → pbpaste 에 U+2060 없음. 🔊 → tts_cache 새 행 "매일 아침 커피를 안 마셨어요"(U+2060 없음).
- 테스트: `korean_word_wrap_test.dart` 추가, result_view 테스트 finder 를 표시 문자열로 갱신. analyze No issues, test/features/lab 5/5.

### 10-02 · LAB-1.8.1 [FE] Grammar Lab 입력 화면 재설계 (61873e8)
- 전: `screenshots/r4/before_1_grammar_input.png` — Try 칩 / Explore 칩 / Combine 접힘 + 버튼이 위아래로 나열, 기능 2개 구분 안 됨.
- 후 구조(`lab_screen.dart` `_buildComposeView`):
  1. **공통 문장 카드**(흰 카드 r22·primary α0.08 그림자): 거북이 idle 56(빈 상태 거북이 유지, 위 14 = 0.25×56) + "Your sentence" w800 + 입력창(연보라 채움·테두리 없음, 지우기 버튼은 글자 있을 때만, 글자수 카운터는 150자 넘을 때만) + Try 예문 칩(가로 스크롤 한 줄, StadiumBorder).
  2. **모드 카드 2개 나란히** "CHOOSE AN EXPERIMENT": Explore(분기 아이콘, "One rule, 3 variations") | Combine(레이어 아이콘, "Mix rules into 1 sentence"). 선택 카드 = primary 채움·흰 글자·체크.
  3. 모드별 옵션 카드: Explore = 2×2 규칙 타일(영어+한국어 용어 + 한 줄 힌트, 하나만 선택) / Combine = 그룹 4개(Tense·Politeness·Sentence type·Negation)별 ChoiceChip, 그룹당 1개, 다시 누르면 해제(드롭다운 4개 대체). 라벨 Declarative/Interrogative/Exclamatory → Statement/Question/Exclamation, 서버로 보내는 한국어 값은 그대로.
  4. **하단 고정 실행 버튼 1개**(FilledButton 54 r18, 홈 인디케이터 영역까지 흰 바): 라벨이 할 일을 말함 — "Explore Tense" / "Combine 2 rules" / "Apply 1 rule", 미선택이면 "Pick a rule to explore"/"Pick rules to combine"(비활성), 규칙은 골랐는데 문장 없으면 위에 "Type or pick a sentence first."
  - 페이지·AppBar 배경 `alphaBlend(primary α0.06, surface)`(미션·단어장 토큰). 결과 화면에서 규칙 칩 바꾸면 폼의 선택도 따라감. Edit 로 돌아오면 문장·모드·선택 유지.
- 확인(iPhone 16 Pro, :8084): `after_1_explore_ready.png`(저는 밥을 먹어요 + Tense → "Explore Tense"), `after_2_combine_ready.png`(강아지가 뛰어요 + Future + Polite → "Combine 2 rules"), 실행 → 캐시 HIT 결과 `after_3_combine_result.png`. Edit → 선택 유지 확인.
- 테스트: layout 테스트(320×568 + 키보드)를 Combine 모드 카드 기준으로, result_view 테스트를 "규칙 선택 → 실행 버튼(Key lab-run)" 흐름으로 갱신. analyze No issues, test/features/lab 5/5.

### 10-02 · LAB-1.8.2 [FE] 로딩 문구 컨셉화 (61873e8)
- `lab/widgets/lab_experiment_loading.dart` 신규: 거북이 thinking 120 + 옆에 플라스크 아이콘(거품 3개 올라가는 애니메이션, reduced motion 이면 정지). 제목 "Turtle is experimenting with your sentence…", 작업 pill("Combining 3 rules"/"Exploring tense variations"), 단계 문구 0–2s "Mixing grammar…" → 3–6s "Adding a pinch of politeness…" → 7–11s "Stirring the sentence endings…" → 12s~ "Almost done! New sentences take a little longer." + 3초부터 경과초. "Asking the AI…" 류 문구 제거.
- 확인: 캐시 없는 조합 강아지가 뛰어요 + Future·Polite·Question(Gemini 1회) → `after_4a_loading.png`(0s, Mixing grammar…), `after_4b_loading_stage2.png`(4s, Adding a pinch…), `after_4c_after_loading.png`(결과 "강아지가 뛸 거예요?").
- 한글랩 점검: 한글랩은 로컬 조합이라 로딩 문구 자체가 없음 → 바꿀 것 없음. (참고: 메뉴 화면 부제 "Explore grammar rules with our AI assistant." 는 그대로 둠)
- 이번 작업 Gemini 호출: 1회(위 로딩 캡처용). 나머지는 캐시 HIT.

### 10-02 · LAB-1.9.1 [FE] 화면 문구 Sentence Lab (89a66e2)
- `lab_screen.dart` AppBar `AI Grammar Lab` → `Sentence Lab`, `lab_menu_screen.dart` 카드 제목 동일. 메뉴 부제 → "Turtle experiments with your sentence — tense, politeness, negation." + 작게 "AI-powered".
- 용어 주석: `// Sentence Lab (UI name) == AI Grammar Lab (legacy code name)` (LabScreen 클래스 위, 메뉴 import 줄). 클래스·파일·API·테스트 이름은 그대로(D-24).
- `lib/` 전체 grep 결과 화면 문구 "AI Grammar Lab" 남은 곳 없음. 홈 카드 부제 "Ask AI about Korean grammar" 는 PM 소유 → REQUESTS R-005.
- 확인: 전 `screenshots/r5/before_1_menu.png`, 후 `after_1_rename_menu.png`, `after_3_sentence_lab_appbar.png`(AppBar Sentence Lab).

### 10-02 · LAB-1.9.2 [FE] Language Lab 메뉴 실험실 무드 (4fb6b24)
- `lab/widgets/lab_glassware.dart` 신규(패키지·이미지 없음, CustomPainter): `LabGlassware`(beaker·flask·tube, 물결치는 액체 + 위로 올라가며 사라지는 거품 3개) / `LabGraphPaper`(20px 모눈, 5칸마다 진한 선, 왼쪽 실험노트 여백선).
- `lab_menu_screen.dart` 재작성(StatefulWidget, `const LabMenuScreen()` 그대로라 홈 수정 불필요): 연보라 배경 위 모눈 전면 + "LAB NOTEBOOK / Pick an experiment bench / Two benches, two lab partners." + 선반 위 비커·플라스크. 카드 2개(흰 카드 r22, primary 그림자): 왼쪽 담당 캐릭터 72(한글랩 토끼 = tertiary 톤 "RABBIT · PLAYFUL", 문장 실험실 거북이 = primary 톤 "TURTLE · CAREFUL"), 오른쪽 위 시험관/플라스크 거품, 하단 pill(ㄱ + ㅏ = 가 / AI-powered) + 화살표.
- 거품은 AnimationController 1개(3s 반복)로 전부 구동, `disableAnimations` 이면 정지(정지 그림 유지).
- 실험복: CHR-1.8 아직 없음(`MaruOutfit` 미존재 확인) → 기본 옷. 교체는 1.9.3.
- 상단 캐릭터: 계획엔 "상단에 토끼·거북이" 였으나 카드마다 담당 캐릭터가 서 있어 상단에 또 넣으면 4마리가 됨 → 상단은 실험 소품만, 캐릭터는 카드에. PM 이 원하면 상단에도 추가 가능.
- 확인(16 Pro): `after_2_lab_menu.png`(최종), 카드 → Sentence Lab 이동 `after_3_sentence_lab_appbar.png`, 한글랩 이동 `after_4_hangeul_lab_nav.png`. 거품이 프레임마다 위치 바뀌는 것 확인.
- 테스트: `lab_menu_screen_test.dart` 추가(320×568: 넘침 없음, Sentence Lab/AI-powered 표시, AI Grammar Lab 없음, 탭 → LabScreen + AppBar Sentence Lab). 이 테스트가 작은 화면 pill 줄 넘침을 잡아 Flexible+ellipsis 로 고침. analyze No issues, test/features/lab 6/6. Gemini 호출 0회.

### 10-02 · LAB-1.9.2 후속 + LAB-1.9.3 [FE] 실험복(MaruOutfit.lab) 적용 (fe59a69 · 81970fe)
- main 동기화(5cd09f4, CHR-1.8: `MaruOutfit { normal, lab }` + 에셋 4장 rabbit_lab_idle·happy / turtle_lab_idle·thinking) 후 pub get, flutter run 새로 시작.
- `outfit: MaruOutfit.lab` 추가 7곳: 메뉴 카드(토끼·거북이, fe59a69) / Sentence Lab 문장 카드 거북이 56·오류 sad 96·Combine 결과 talking 64·빈 상태 96, 로딩 thinking 120, 한글랩 토끼 72(idle↔happy) (81970fe).
- 실험실 전용 확인: `grep -rln MaruOutfit.lab lib` → features/lab 4파일 + 캐릭터 팀 파일(dev 갤러리·placeholder_painter)뿐. 홈은 기본 옷 그대로(`after_outfit_8_home_normal_outfit.png`).
- 폴백(CHARACTER_API v1.3, 의상 우선): 거북이 sad·talking 실험복 에셋이 없어 `turtle_lab_idle` 로 표시 → 오류 화면에서 슬픈 표정이 사라짐(문구·버튼은 그대로). 에셋만 추가되면 코드 수정 없이 반영 → REQUESTS R-006(char-lead).
- 확인(16 Pro, 서버 :8084): `screenshots/r5/after_outfit_1_menu`, `2_hangeul_idle`, `3_hangeul_happy`(ㄱ+ㅏ=가), `4_sentence_idle`, `5_sentence_error_sad_fallback`("12345" → 400, Gemini 없음), `6_sentence_loading_thinking`, `7_sentence_result_talking_fallback`, `8_home_normal_outfit`. 같은 파일을 char-lead 리뷰용 `docs/features/character/screenshots/apply_lab_outfit_*.png` 로도 저장.
- Gemini 호출 1회(강아지가 뛰어요 + Past·Casual → 로딩 캡처용, 결과 "강아지가 뛰었어"). analyze No issues, test/features/lab 6/6.
