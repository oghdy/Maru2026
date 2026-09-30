# LAB — Language Lab — FE 세션 로그 (`lab-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음. **[FE] 태스크 전부 완료** (1.1.2, 1.2.4 be85157, 1.2.5 b6bf419, 1.3.1 8b5fb0e, 1.3.2+1.3.3 70c3d19, 1.3.5 349cd87, 1.3.6 444f6ff, 1.3.7 8a887d0, 1.3.8 418e951, 1.4.1 최신)
- 다음 할 일: PM 지시에 따른 QA(1.4.2). PM 2차 머지 대기
- 막힌 것 / 기다리는 것: 없음
- 실행 중인 것: 없음 — `flutter run` 이 09-30 18:5x "Lost connection to device" 로 종료됨(앱이 닫힘). 다시 필요하면 CLAUDE.md §3 명령으로 재실행 (`--pid-file` 붙이면 `kill -USR1` 로 hot reload). 서버 :8084 는 lab-be
- 마지막 커밋: 1.4.1 (PLAN 참고)
- 짝 세션에게: FE 는 400(Retry 없음)/502/503/504(Retry) 의 `message` 를 그대로 표시, 그 외는 FE 일반 문구. `maru_lab` 에 내가 만든 `explore:bogus` 캐시 1건(lab_001 패치로 이미 지워졌을 수 있음).
- 미확인: TTS 실제 소리(시뮬레이터), 실제 작은 기기(위젯 테스트 320×568 로 대체 확인)

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
