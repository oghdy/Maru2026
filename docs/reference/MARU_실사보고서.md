# MARU 코드베이스 실사 보고서

- 작성일: 2026-09-15
- 대상: `/Users/hadohadopapi/Desktop/Maru-main` (git HEAD `121abe7`, 커밋 안 된 변경 1건: `frontend/maru/android/app/build.gradle.kts`)
- 용도: '모두의 창업' 2기 신청서의 "동작하는 MVP" 근거 검증

---

## 0. 한눈에 보기

| 영역 | 판정 | 한 줄 요약 |
|---|---|---|
| Flutter 앱 + Spring Boot + PostgreSQL | **구현됨, 로컬에서 동작한 흔적 있음** | 로컬 DB에 사용자 3명, 레슨 완료 8건, 미션 수료증 15건, 단어 복습 기록 306건이 남아 있음 |
| 배포 | **근거 없음** | 앱의 서버 주소가 `localhost` / `10.0.2.2`(에뮬레이터 전용)로 고정. 실서버 URL은 코드 어디에도 없음 |
| 형태소 조립 레슨 | **구현됨, 규모는 아주 작음** | 문법 레슨 2개, 조립 문제 4개. 이 중 Kiwi로 만든 문제는 2개뿐 |
| Kiwi 파이프라인 | **오프라인 관리 도구로만 존재** | 서버·앱은 Kiwi를 호출하지 않음. 미리 만든 JSON을 DB에서 읽기만 함 |
| FSRS 단어 복습 | **부분적** | 상태·안정성·난이도 필드와 복습일 계산은 있음. 계산식은 FSRS가 아니라 단순 배수 규칙 |
| 롤플레잉 대화 | **구현됨** | OpenAI gpt-4o 호출. 하드코딩된 AI 응답은 없음 |
| 한글 조합 실습 | **구현됨** | 서버 없이 기기에서 유니코드로 조합하고 TTS로 읽어줌 |
| 데모 장면 (a) 는/은 2단계 조립 | **나옴** | Unit 1 → "My Name is..." 7·8번째 단계 |
| 데모 장면 (b) 을/를, 배운 부분 미분해 | **안 나옴** | 을/를 레슨이 DB·CSV·JSON 어디에도 없음 |
| 데모 장면 (c) 처음 보는 단어로 조립 | **안 나옴** | 해당 기능·단계 유형 자체가 없음 |

---

## 조사 방법과 한계

- **읽은 것**: 소스 전체(Flutter `frontend/maru/lib` 74개 파일, Spring `backend/maru/src` 112개 파일, Python `backend/admin-tools`), 레슨 JSON, 설정 파일, 로컬 로그.
- **로컬 PostgreSQL(`maru` DB)**: 읽기 전용 세션(`default_transaction_read_only=on`)으로 개수와 집계만 조회. 개인정보 컬럼(이메일 등)은 조회하지 않음.
- **Kiwi 엔진**: 저장소에 커밋된 venv로 `core_engine.KiwiEngine`을 샘플 문장에 한 번 실행해 출력을 확인. 바이트코드 생성을 끄고 실행했고, `__pycache__`는 원래 있던 것(최종 수정 5월 26일)임을 확인함.
- **하지 않은 것**: 앱·서버 빌드와 실행, 테스트 실행(빌드 산출물이 생기므로 규칙상 제외), 실기기 확인, Railway 등 외부 서버 확인.
- 그래서 이 보고서의 "동작"은 **① 코드 경로가 끝까지 이어져 있고 ② 로컬 DB에 실행 흔적이 있다**는 뜻입니다. 녹화 전에 반드시 직접 한 번 완주해 보세요.
- 시크릿: 저장소 루트와 `vocab-pipeline/`에 `.env` 파일이 **존재함**(git 추적 안 됨). `frontend/maru/android/app/google-services.json`은 **git에 추적됨**. 값은 옮기지 않았습니다.

### 저장소 구조 주의
- `frontend/maru/`가 실제 앱입니다.
- `frontend/lib/`, `frontend/assets/unit0/`은 **이전 버전 Flutter 프로젝트**(한글 레슨 12개 JSON, 5,113줄)입니다. `frontend/maru`에서 참조하지 않으므로 MVP 근거로 쓰면 안 됩니다.
- `backend/lessons/unit1/lesson1.json`은 **DB에 들어 있는 u1-l1과 다릅니다**. DB 쪽은 이후 Kiwi 결과로 덮어써졌습니다(5장 참고).

---

## 1. 실제 동작 기능 목록 (끝까지 완주 가능한 경로)

전제 조건(모든 서버 기능 공통):
- 로컬에 Spring 서버(8080)와 PostgreSQL(`localhost:5432/maru`)이 떠 있어야 합니다.
- 환경변수 `JWT_SECRET`이 필요합니다. 기본값이 비어 있어 `JwtProvider` 생성자에서 기동이 실패합니다.
- 미션 대화는 `OPENAI_API_KEY`, AI 문법 실험실은 `GEMINI_API_KEY`가 필요합니다.
- 앱은 **Android 에뮬레이터 또는 iOS 시뮬레이터**에서만 서버에 닿습니다(`core/network/dio_client.dart:16`). 실기기에서 `localhost`는 폰 자신을 가리키므로 연결되지 않습니다.

| # | 기능 | 시작 → 종료 화면 경로 | 호출 엔드포인트 (구현 위치) | 판정 |
|---|---|---|---|---|
| 1 | 로그인 | `LoginScreen` → Google/Apple 버튼 → `ProfileGate` → (닉네임 없으면 `ProfileSetupScreen`) → `MainScreen`(홈) | `POST /api/auth/google`, `/api/auth/apple` (`AuthController`), `GET /api/me`, `PUT /api/me/profile` (`MeController`) | 구현됨. 로컬 DB에 google 2명, apple 1명 가입. **iOS Google 로그인은 설정 누락 의심**(2장) |
| 2 | 한글 레슨 (Unit 0) | 홈 → Korean Lessons → Select a Unit → Unit 0 → `LessonListScreen` → `LessonScreen`(소개 카드 → 따라 읽기 → 듣고 고르기) → 마지막 단계 후 목록으로 복귀 | `GET /api/units/0/lessons` (`LessonController`), `POST /api/progress/lessons/{id}` (`UserProgressController`) | 구현됨. 12개 레슨. 완료 화면 단계가 없어 바로 목록으로 돌아감. 완료 기록 5건(u0_l1, l2, l6, l9, l12) |
| 3 | 문법 레슨 (Unit 1) | 위와 같은 경로 → Unit 1 → "My Name is..."(9단계) / "What do you do?"(8단계) → 완료 화면 → 목록 | 위와 같음 | 구현됨. 완료 기록: u1-l1, lesson2 |
| 4 | 단어장 학습 | 홈 → Vocabulary Review → `VocabularyCategoryScreen`(덱 14개) → `VocabularyLessonListScreen` → 하단 시트 "Word Study" → `VocabularyLearningScreen`(카드 뒤집기 + Again/Hard/Good/Easy) → "Lesson Completed!" | `GET /api/v1/vocabulary/decks`, `/decks/{id}/lessons`, `/due`, `POST /review` (`VocabularyController`) | 구현됨 |
| 5 | 단어 짝맞추기 게임 | 위 하단 시트 → "Match Madness" → `VocabularyGameScreen`(5쌍씩 라운드) → "Amazing Match!" → Finish | `GET /api/v1/vocabulary/game/{deckId}` | 구현됨. 화면을 닫을 때 생명주기 버그 있음(2장) |
| 6 | 오늘의 복습 | 홈 배너(복습할 단어가 1개 이상일 때만 보임) → `DailyReviewScreen` → "All Caught Up!" → Return Home | `GET /api/v1/vocabulary/daily-review`, `POST /review` | 구현됨. 로컬 복습 기록 306건(마지막 2026-06-16) |
| 7 | 롤플레잉 미션 대화 | 홈 → Mission Chat → `MissionSetupScreen`(관계·친밀도·역할·성격) → `MissionChatScreen` → 클리어 → `MissionClearanceScreen`(4페이지 수료증) → Return to Home | `POST /api/v1/mission-chat/setup`, `/chat`, `/suggestion`, `/clearance` (`MissionChatController`) | 구현됨. 수료증 15건(2026-05-18~06-16) |
| 8 | 수료증 목록 | 홈 우측 상단 트로피 아이콘 → `MissionClearanceListScreen` → 항목 탭 → 수료증 | `GET /api/v1/mission-chat/clearances` | 구현됨 |
| 9 | 한글 조합 실습 | 홈 → Language Lab → Hangeul Lab → 초성·중성·(종성) 선택 → Combine! → 결과 글자 + 발음 | 없음. 기기에서 계산(`HangeulCombiner.combine`) | 구현됨. 서버 없이도 동작 |
| 10 | AI 문법 실험실 | 홈 → Language Lab → AI Grammar Lab → 문장 입력 → 카테고리 칩(Explore) 또는 조합(Combine) → 결과 카드 | `POST /api/lab/explore`, `/api/lab/combine` (`AiLabController` → `AiLabService` → `GeminiService`) | 구현됨. DB 캐시 39건(explore 21, combine 18) |
| 11 | 홈 학습 통계 | 홈 상단 스트릭(불꽃)·별 개수 | `GET /api/me/stats` (`UserStatsController`) | 구현됨. 별 점수는 사실상 고정값(3장) |

**완주할 수 없는 경로**
- Unit 2 "Self Introduction", Unit 3 "Ordering Food" → DB에 레슨 0개라서 "No lessons found."만 나옵니다.
- 하단 탭 Stats, Settings → "Coming Soon" 문구만 있습니다.

---

## 2. 미완성 목록

### 2-A. UI는 있는데 로직이 없음
| 항목 | 근거 |
|---|---|
| Stats·Settings 탭 | `screens/home/main_screen.dart:18-19` — `Text('Stats (Coming Soon)')`, `Text('Settings (Coming Soon)')` |
| Unit 2·3 카드 | `lesson/screens/unit_selection_screen.dart:36-50`에 카드가 하드코딩됨. DB `lessons`에는 unit_id 0, 1만 있음 |
| 프로필 아이콘 | `screens/home/home_screen.dart:46-50` — 누르면 확인 없이 **즉시 로그아웃**. 프로필 화면은 없음 |
| 레슨 완료 체크 표시(단어장) | `VocabularyService.getLessonsByDeckId`에서 `isCompleted(false)` 고정, `// TODO` 주석 있음 (211행) |
| 듣기 퀴즈 점수 | `practice_step_widget.dart:221` — `'Score: 0/6'` 고정 문자열, 값이 갱신되지 않음 |
| 레슨 완료 화면 내용 | `completion_step_widget.dart`가 DB의 `text`, `highlights`를 **읽지 않음**. 제목이 항상 "Basic Vowels Mastered!" |
| 단계 제목·안내문 | `StepModel.title`, `instruction`을 파싱만 하고 어떤 위젯에도 표시하지 않음. "Sentence Building #1" 같은 제목이 화면에 나오지 않음 |
| 직접 입력 연습(user_input) | `practice_step_widget.dart:457-489` — 입력을 템플릿에 끼워 보여줄 뿐 정답 검사가 없음. 빈 입력으로도 Next 가능 |
| 미션 "failed" 상태 | 서버 프롬프트는 `failed`를 돌려줄 수 있지만 `mission_chat_provider.dart`에 처리 분기가 없음 |
| 레슨 중간 진행 저장 | `user_progress_provider.dart:28` — `currentStep: 999` 고정. 레슨을 중간에 나가면 처음부터 다시 해야 함 |

### 2-B. 로직은 있는데 화면에 연결되지 않음 (호출되지 않는 코드)
| 항목 | 근거 |
|---|---|
| "복습 기한 단어 + 신규 단어 혼합" 큐 | `VocabularyService.getDueWords` — 호출하는 곳 0곳. 실제 단어 학습은 `getDueWordsByLesson`을 쓰는데, 이 메서드는 기한과 무관하게 등급·ID 순으로 30개씩 자름 |
| 무작위 8단어 게임 | `VocabularyService.getRandomWordsForGame`, `WordGameDto`, `WordRepository.findRandomWordsByCategory` — 미사용 |
| `FsrsProgressRepository.findDueCardsByCategory`, `WordRepository.findUnstudiedWordsByCategoryForUser` | 위의 미사용 메서드에서만 호출됨 |
| FSRS 가중치 배열 | `FsrsAlgorithm.java:15-18`의 `w[]` 17개 값 — 계산에 전혀 쓰이지 않음 |
| 프롬프트 파일 | `prompts/chat_turn_system.txt` — 참조 0곳(실제로는 `rabbit_reply_system.txt`와 `turtle_eval_system.txt`를 씀) |
| 레슨 공개 여부 | `Lesson.isPublished`를 조회 조건에 쓰지 않음. DB에서 `lesson2`는 `is_published`가 NULL인데도 앱에 노출됨 |
| 목업 레슨 카드 | `lesson_list_screen.dart:90` `_buildMockLessonCard` — 미사용 |
| 관리용 디버그 API | `DebugController` (`/api/v1/admin/debug/*`) — 앱과 연결 없음. 대신 보안 문제가 있음(아래) |
| 이전 버전 한글 앱 | `frontend/lib/**` 전체 — `frontend/maru`와 연결 없음 |

### 2-C. 에러 처리가 없어 특정 상황에서 멈추거나 깨지는 지점
| 위험 | 상황 → 결과 | 근거 |
|---|---|---|
| **Google 로그인 무한 로딩** (코드상 추론) | 서버 검증 실패 시 `AuthController`는 HTTP 200에 `data: null`을 돌려줌 → `auth_repository.dart:30`의 `as String`에서 TypeError 발생(DioException이 아니라 잡히지 않음) → `loginWithBackend`가 `loading` 상태로 멈춤 → `login_screen.dart:32-35`는 로그만 찍음 → 스피너가 영원히 돎 | `AuthController.java:109-112`, `auth_provider.dart:31-41` |
| **iOS Google 로그인** (설정상 추정, 실기기 미확인) | `Info.plist`에 `GIDClientID` 없음, `GoogleService-Info.plist` 없음, 코드에서 `clientId`도 넘기지 않음. 예외가 나도 `catch`에서 로그만 찍어서 버튼이 조용히 반응하지 않을 가능성이 큼 | `ios/Runner/Info.plist`, `login_screen.dart:14-16` |
| **조립 문제에서 같은 형태소가 두 번 필요하면 풀 수 없음** (코드상 추론) | Kiwi 엔진이 선택지를 텍스트 기준으로 중복 제거함(`core_engine.py:96-123`). 앱은 한 번 놓은 선택지를 트레이에서 뺌(`agglutinative_step_widget.dart:135-139`). 예: "친구는 학생이고 저는 의사예요."(JX) → '는' 칸은 2개인데 선택지는 1개. **현재 DB의 4문제에는 해당 사례 없음** | 엔진 실행 결과로 확인 |
| 미션 대화 중 서버·AI 오류 | 상태만 `error`로 바뀌고 채팅 화면에는 오류 표시 분기가 없음. 사용자 메시지만 남고 답이 오지 않음 | `mission_chat_provider.dart:139-144`, `mission_chat_screen.dart` |
| 짝맞추기 화면 닫기 | `dispose()`에서 `super.dispose()` 대신 `super.initState()`를 호출. 디버그 모드에서 프레임워크 assertion 오류 발생(화면에 보이는지는 미확인) | `vocabulary_game_screen.dart:34-37` |
| AI 실험실 실패 | 예외 원문(`Exception: Error exploring AI Lab: DioException ...`)을 빨간 글씨로 그대로 출력. 캐시에 없는 첫 요청은 최대 30초 정도 걸릴 수 있음(`dio_client.dart:22` 주석) | `lab_screen.dart:416` |
| 삭제된 사용자 | `/api/me`가 404 → "User profile not found."만 표시되고 로그아웃 버튼이 없어 막다른 화면 | `profile_gate.dart:33-35` |
| 홈 통계 로딩 실패 | 오류가 나도 조용히 숨김(`SizedBox.shrink`). 서버가 꺼져 있어도 홈이 멀쩡해 보임 | `home_screen.dart:82-83, 91-92` |
| 서버 기동 | `JWT_SECRET` 환경변수가 없으면 기동 실패 | `application.yaml` (`jwt.secret` 기본값 비어 있음), `JwtProvider.java:24-25` |

### 2-D. 보안·운영 문제 (심사 질의 대비)
- `DebugController`의 `GET /api/v1/admin/debug/merge`는 **인증 없이**(`SecurityConfig.java:44` `permitAll`, 주석 "임시 디버그용") 여러 테이블에 `UPDATE`와 `DELETE FROM word_categories`를 실행합니다. 서버를 공개 배포하면 누구나 데이터를 바꿀 수 있습니다.
- `JwtAuthenticationFilter.java:33`이 요청마다 JWT 원문을 INFO 로그로 남깁니다.
- `GeminiService.java:38`은 API 키를 URL 쿼리스트링에 붙여 호출합니다.
- CORS 허용 출처가 localhost 계열뿐입니다(`SecurityConfig.java:56-57`).
- Android 릴리스 빌드가 디버그 키로 서명됩니다(`build.gradle.kts` `signingConfig = signingConfigs.getByName("debug")`). 스토어 배포 준비가 안 된 상태입니다.

---

## 3. 하드코딩·더미 데이터 — "이거 실제 데이터인가요?"에 무너질 지점

### 3-A. 레슨 콘텐츠
| 겉보기 | 실제 | 근거 |
|---|---|---|
| 레슨 목록·단계가 서버 DB에서 동적으로 내려옴 | **사실.** `lessons.content`(JSONB)를 그대로 반환함 | `LessonService.getLessonsByUnitId` |
| 그 콘텐츠를 누가 만들었나 | Unit 1 소개·연습·완료 단계는 **사람이 쓴 JSON**(`backend/lessons/unit1/*.json`을 `update_lesson.py`로 DB에 넣음). u1-l1 조립 2문제만 Kiwi로 생성. lesson2 조립 2문제는 **손으로 작성**(선택지 ID가 `o_s1_1` 형식이라 엔진 출력과 다름) | DB 조회, `batch_merger.py` |
| Unit 0 한글 레슨 12개 | DB에 있음. 넣은 스크립트는 저장소에 없음. `spring.log`(2026-02-28)에 `DummyDataConfig: Lessons already exist. Skipping dummy data initialization.` 기록이 있으나 해당 클래스는 현재 소스에 없음 → **출처 확인 불가** | `backend/maru/spring.log` |
| 유닛 카드 4개 | 제목·부제·번호가 앱 코드에 고정. DB의 `unit_title`과도 어긋남(DB: unit 1에 "Basic Greetings"와 "Introduce Yourself" 혼재) | `unit_selection_screen.dart:20-50` |
| **레슨 완료 화면** | 모든 레슨에서 "Basic Vowels\nMastered!", "1 × Basic Vowels Completed"가 나옴. Unit 0에는 완료 단계가 없어서, **실제로는 Unit 1 문법 레슨에서만 이 문구가 보임** | `completion_step_widget.dart:41, 67` |
| 한글 소개 카드 설명 | 모든 자모·받침 카드에 "Shape: \| + • (right) [Example]", "Mouth shape: Open your mouth wide", "This is the most basic vowel!"이 똑같이 나옴. 자음 레슨에도 "Let's learn the basic vowels one by one" | `introduction_step_widget.dart:75-81, 183-196` |
| 듣기 퀴즈 | 항목이 3~8개로 달라도 문제 수는 항상 5개("Question n/5"). 매 문제 무작위라 중복 출제 가능. 오답이어도 다음으로 넘어감. 자음 레슨에서도 "find the correct vowel" | `practice_step_widget.dart:79-89, 211, 238, 342` |

### 3-B. 형태소 분해 결과
- **런타임에 계산하지 않습니다.** 앱이 보여주는 분해 결과는 모두 DB에 저장된 JSON입니다.
- 탭하면 뜻이 뜨는 "Grammar Analysis" 패널의 뜻풀이는 `generate_morphology.py`에 박힌 규칙표에서 나옵니다. `POS_MAP` 품사 태그 34개, `TOKEN_SPECIFIC_MAP` 단어 약 27개, `CHUNK_OVERRIDE_MAP` 2개입니다. 표에 없는 토큰은 품사명이나 "word"로 표시됩니다.
- 시연 중 눈에 띌 실제 DB 값(u1-l1, lesson2):
  - "Sarah" → **word**, ":" → **word**, "=" → **word**, "(" "topic" ")" → 각각 **word**
  - "Sarah예요." / "유미예요." / "의사예요" → 토큰 **"이예요"**(표준 표기가 아님) → "am/is/are"
  - "민수" → 어떤 곳은 "Proper Noun", 어떤 곳은 "Noun", lesson2에서는 "Minsu" (실행 시점마다 표가 달라서 생긴 불일치)
- **조립 문제 오답 선택지(u1-l1, Kiwi 생성)**: 어절 마지막 글자를 "고"로 바꾸는 규칙(`core_engine.py:105`) 때문에 **"Sarah입니다고", "유미예요고", "이름고", "제고", "저고"** 같은 비문이 트레이에 나옵니다. 거북이 단계 오답은 품사별 고정 목록(`core_engine.py:15-21`)에서 뽑습니다.
- **u1-l1 거북이 단계 정답에 마침표 "."가 별도 블록으로 들어 있고, "유미예요." 분해 정답이 "유미 + 이예요 + ."입니다.** 바로 다음 레슨(lesson2)이 이에요/예요 구분을 가르치므로, 한국어를 아는 심사위원이면 바로 알아챕니다.

### 3-C. AI 응답
- **하드코딩된 AI 응답이나 가짜 응답은 찾지 못했습니다.** 미션 대화는 OpenAI(`OpenAiService`, 기본 모델 `gpt-4o`), 문법 실험실은 Gemini(`GeminiService`, 기본 URL `gemini-2.5-flash`)를 실제로 호출합니다.
- 다만 **수료증은 사실상 항상 발급됩니다.** 앱이 사용자 턴 수가 `minTurns + 2`에 도달하면 목표 달성과 무관하게 발급을 요청하고(`mission_chat_provider.dart:127-137`), 프롬프트도 `"result": "클리어"`로 고정되어 있습니다(`clearance_system.txt`).
- "AI 캐시로 비용 90% 절감, 2,000ms→100ms"(`frontend/FINAL_PRESENTATION_FLOW.md`)는 이를 측정한 코드나 로그가 없습니다. 캐시 자체(`AiCache`, 입력 문장 완전 일치 조회)는 구현되어 있습니다.

### 3-D. 학습 통계
| 값 | 실제 | 근거 |
|---|---|---|
| 레슨 점수 | **항상 100** | `lesson_screen.dart:39` `score: 100, // Assuming full score for now` |
| 별 개수 | 점수 80 이상이면 3개 → **첫 완료 시 무조건 3개**. 홈의 별 = 완료 레슨 수 × 3 | `UserProgressService.java:65-67` |
| 스트릭(연속 학습일) | **실제 계산됨.** 레슨 완료나 단어 평가가 있으면 서버 날짜 기준으로 갱신 | `UserStatsService.recordStudyActivity` |
| 학습 시간 | 서버에 누적되지만 화면 어디에도 표시되지 않음. 레슨 1회가 60초 미만이면 0분으로 계산 | `UserProgressService.java:97` |
| 짝맞추기 게임 | "Round n/6", 진행 바 `/30`, "You mastered all 30 words" 고정. 덱의 마지막 묶음처럼 단어가 30개 미만이면 틀린 숫자가 나옴 | `vocabulary_game_screen.dart:80, 105, 259` |
| 덱 이름 영어 번역 | 서버 값을 앱에서 switch문으로 바꿈 | `vocabulary/models/word_category.dart:17-78` |
| 로컬 DB 기록 | 사용자 3명(개발자 계정으로 보임). "사용자 데이터"로 제시하면 안 됨 | DB 집계 |

### 3-E. 환경 하드코딩
- 앱 서버 주소: `dio_client.dart:16` (`http://localhost:8080` / `http://10.0.2.2:8080`)
- 서버 DB: `application.yaml`의 `jdbc:postgresql://localhost:5432/maru`와 로컬 사용자명
- Python 도구: DB 접속 정보가 모두 localhost로 고정(`db_connector.py:10`, `update_lesson.py:7-11`, `update_levels.py:7-12`). 절대경로도 고정(`inject_morphology.py:6`, `update_levels.py:22`). 기본 실행 대상도 고정(`batch_merger.py:103` → unit 1, "u1-l1"; `update_lesson.py:68` → DB id 3)

---

## 4. 콘텐츠 규모 (실제 숫자)

기준: 로컬 PostgreSQL `maru` DB. 앱이 실제로 읽는 곳이며, 2026-09-15 읽기 전용으로 조회했습니다. 저장소 JSON 파일과 다른 곳은 따로 표시했습니다.

### 4-A. 레슨
| 구분 | 레슨 수 | 단계 수 |
|---|---|---|
| Unit 0 (한글) | **12** | **37** (레슨당 2~4개: 소개·따라 읽기·듣기 퀴즈) |
| Unit 1 (문법) | **2** | **17** (u1-l1 9개, lesson2 8개) |
| Unit 2, 3 | **0** | 0 (앱에 카드만 있음) |
| **합계** | **14** | **54** |

Unit 0 세부 항목:
- 자모·음절 항목 **고유 80개** = 단독 자모 37개 + 음절·단어 43개
- 단독 자모는 모음 21개 전부, 자음 19개 중 16개. ㅇ·ㅈ·ㅎ는 '아·자·하' 음절로만 등장합니다.
- 듣기 퀴즈는 12개 레슨 모두 `listen_match` 1종입니다.

Unit 1 세부 항목:
| 항목 | u1-l1 "My Name is..." | lesson2 "What do you do?" | 합계 |
|---|---|---|---|
| 대화·예문 문장 | 6 | 4 | **10** |
| 문법 설명용 행 ("저는 = I (topic)" 등) | 2 | 2 | **4** |
| 어휘 소개 항목 | 0 | 4 (학생, 선생님, 의사, 회사원) | **4** |
| 빈칸 고르기(fill_blank) | 3 | 2 | **5** |
| 직접 입력(user_input) | 1 | 0 | **1** |
| **조립 문제(agglutinative_quiz)** | **2** (Kiwi 생성) | **2** (수작업) | **4** |
| 조립 문제 형태소 칸 수 | 5, 6 | 4, 4 | 19 |
| 조립 문제 선택지 수 | 12, 16 | 8, 8 | 44 |

조립 문제 4개의 문장:
1. 저는 Sarah입니다.
2. 제 이름은 유미예요.
3. 저는 학생이에요.
4. 저는 의사예요.

### 4-B. 문법·조사 항목
- **명시적으로 가르치는 문법: 2개**
  - 주제 조사 **은/는** (u1-l1 "Grammar: Topic Particle 은/는")
  - 서술 표현 **이에요/예요** (lesson2 "Grammar: 이에요 / 예요")
- 등장하는 서술 표현은 **입니다, 이에요, 예요** 3개입니다. 입니다는 u1-l1의 패턴·완료 문구에 나옵니다.
- 소유격 '의'는 '제 = 저 + 의' 분해로만 등장합니다. DB의 u1-l1 조립 문제에서는 '제'가 분해되지 않습니다.
- **을/를: 0건.** DB 레슨 전체 텍스트에서 "을/를"과 "JKO" 태그 모두 0회입니다. `curriculum.csv`와 `backend/lessons/`에도 없습니다.
- Kiwi 엔진이 오답을 만들어 줄 수 있는 품사 태그는 **5종**(EP, EF, JKO, JKS, JX)입니다(`core_engine.py:15-21`). 실제 커리큘럼에서 쓴 태그는 **2종**(JX, EF)입니다.
- `curriculum.csv`는 **데이터 2행**이고 둘 다 레슨 `u1-l1`입니다.

### 4-C. 단어
| 항목 | 수 |
|---|---|
| 단어(`words`) | **5,561** |
| 덱(`word_categories`) | **14** (DB상 전부 `Beginner`로 표시) |
| 원천 등급 A / B / C / 없음 | **862 / 1,963 / 2,713 / 23** |
| 가장 큰 덱 "기타/사물" | **2,222** (전체의 40.0%) |
| 가장 작은 덱 "동물/식물" | **34** |
| 예문 없음 | 1 |
| 음성 URL / 이미지 URL 있음 | **0 / 0** (발음은 기기 TTS) |
| 같은 한국어 표기가 중복된 단어 | 11종 |
| 덱 안의 30단어 묶음 "Lesson" 수 | **193** |

덱별 단어 수: 기타/사물 2,222 · 동작/상태 1,254 · 장소 461 · 시간 358 · 감정 287 · 음식 192 · 직업/사회 184 · 가족/인물 157 · 신체 138 · 학교/교육 106 · 숫자/수량 67 · 날씨/자연 55 · 쇼핑/경제 46 · 동물/식물 34

- 출처: 국립국어원 「한국어 학습용 어휘 목록.xls」를 `vocab-pipeline`(Gemini로 번역·분류·예문 생성)으로 적재.
- 원본 XLS의 행 수는 **확인 불가**입니다. xlrd 모듈이 없고, 규칙상 설치하지 않았습니다.
- Gemini 번역·예문을 사람이 검수했다는 기록은 **확인 불가**입니다.
- B·C등급(중·고급) 단어 4,676개가 모두 'Beginner' 덱 안에 들어 있습니다.

### 4-D. 미션 시나리오
- **미리 만들어 둔 시나리오: 0개.** 매번 LLM이 새로 생성합니다(`mission_setup_system.txt` 규칙 4번 "Generate a UNIQUE mission every time").
- 사용자 입력: 관계 3가지 × 친밀도 3가지(드롭다운) + 역할·성격 자유 입력(`mission_setup_screen.dart:19-24`).
- 최소 턴 수는 LLM이 4~12 사이로 정합니다.
- 사용 중인 프롬프트 파일 5개(미사용 1개 별도).

### 4-E. 실험실
- AI 문법 실험실 Explore 카테고리: **4개** (Tense, Politeness, Negation, Emotion)
- Combine 수식어: 드롭다운 4개, 선택값 **10개** (시제 3, 높임 2, 문장 유형 3, 부정 2)
- 한글 조합: 초성 19 × 중성 21 × 종성 28(받침 없음 포함) = 11,172자 조합 가능

### 4-F. 로컬 사용 흔적 (개발 DB)
| 항목 | 수 | 기간 |
|---|---|---|
| 사용자 | 3 (google 2, apple 1) | |
| 레슨 완료 기록 | 8 (u0 5개, u1-l1, lesson2, 옛 ID `unit1_lesson1`) | 2026-02-28~06-06 |
| 단어 복습 기록 | 306 (사용자 2명, 상태 Learning 19 / Review 279 / Relearning 8) | 마지막 2026-06-16 |
| 미션 수료증 | 15 | 2026-05-18~06-16 |
| AI 캐시 | 39 | 2026-03-08~06-16 |

---

## 5. 형태소 파이프라인 검증

### 5-A. Kiwi는 어디서 호출되는가
- **Spring 서버에는 Kiwi가 없습니다.** `build.gradle` 의존성에 형태소 분석기가 없고, `backend/admin-tools` 밖에서 "kiwi" 문자열 검색 결과가 0건입니다.
- **Flutter 앱에도 없습니다.** 앱은 `LessonRepository.getLessonsByUnitId` → `GET /api/units/{id}/lessons` → `StepRenderer`로 **저장된 JSON을 그릴 뿐**입니다.
- Kiwi(`kiwipiepy==0.17.1`)는 **개발자 PC에서 수동으로 돌리는 Python 스크립트 2개**에서만 쓰입니다.

| 스크립트 | 하는 일 | 입력 → 출력 | 제약 |
|---|---|---|---|
| `kiwi-generator/inject_morphology.py` (+ `generate_morphology.py`) | 소개 단계 문장을 어절로 나누고 토큰·뜻을 붙임(탭하면 뜨는 분석 패널용 `chunks`) | 레슨 JSON 파일 → 같은 파일에 덮어씀 | 대상 경로가 **절대경로로 고정**(`lesson2.json`). 완료 메시지는 "lesson1.json"이라고 잘못 출력. 뜻은 규칙표 기반 |
| `kiwi-generator/batch_merger.py` (+ `core_engine.py`) | `curriculum.csv`의 문장으로 2단계 조립 문제를 생성하고 **DB 레슨 행에 직접 병합** | CSV → `lessons.content`(기존 조립 단계 삭제 후 완료 단계 앞에 삽입) | 실행 대상이 `__main__`에 **(1, "u1-l1")로 고정**. DB는 localhost 고정. 레슨 행이 없으면 "Lesson not found in DB!"로 종료 |
| `admin-tools/update_lesson.py` | JSON 파일 전체를 DB 레슨 행에 덮어씀 | JSON → `lessons.content` | DB의 **숫자 PK**(기본 3)로 지정. **batch_merger 이후에 실행하면 Kiwi 조립 문제가 사라짐** |

### 5-B. 런타임 계산인가, 미리 만든 데이터인가
- **미리 만든 데이터입니다.**
- DB에 저장된 u1-l1 조립 문제는 제가 엔진을 직접 돌린 출력과 일치합니다. 선택지 ID 없음, 요소 ID `e1`/`e2`, "Sarah입니다고", "." 칸, "이예요"가 모두 같습니다. 즉 과거에 `batch_merger.py`가 실행되어 DB에 기록된 결과입니다.
- lesson2 조립 문제와 저장소의 `backend/lessons/unit1/lesson1.json` 조립 문제는 ID 형식(`e_s1_1`, `o_s1_1`)으로 보아 **사람이 쓴 것**입니다.

### 5-C. 엔진의 분해 규칙 (`KiwiEngine.process_sentence`)
1. 문장을 띄어쓰기로 나눠 어절마다 칸 1개를 만듭니다. 모든 어절이 문제 칸입니다(`isTarget=True`).
2. **토끼 단계(1단계)**: 정답은 어절 통째입니다.
3. **거북이 단계(2단계)**:
   - 어절 안에 CSV `Target_POS`의 태그가 하나라도 있으면 → 그 어절을 **Kiwi 형태소 전부로 분해**합니다(목표 형태소만 떼는 것이 아님).
   - 예외: 서술격 '이' + 어미가 '입니다/예요/이에요/이야'가 되면 하나로 합칩니다.
   - 태그가 없으면 → 통째로 둡니다.
4. 분해 단계는 **항상 정확히 2단계**입니다. 앱 위젯(`AgglutinativeStepWidget`)이 `isTurtleMode` 참/거짓 두 상태만 가집니다.

엔진 직접 실행 결과(읽기 전용):
| 문장 / Target_POS | 거북이 단계 정답 |
|---|---|
| 저는 Sarah입니다. / JX,EF | [저, 는] [Sarah, 입니다, .] |
| 저는 사과를 먹어요. / **JKO** | **[저는]** [사과, 를] **[먹어요.]** |
| 친구는 학생이고 저는 의사예요. / JX | [친구, 는] [학생이고] [저, 는] [의사예요.] → '는' 선택지가 1개뿐이라 앱에서 풀 수 없음 |
| (테스트 파일) 어제 친구를 만났었어 / EP | [어제] [친구를] [만나, 었었, 어] (`test_core_engine.py`) |

→ Target_POS를 JKO로 주면 "저는"을 분해하지 않는 동작 자체는 **엔진에서 재현됩니다.** 다만 이유는 "학습자가 이미 배워서"가 아니라 "이 문장의 지정 태그가 그 어절에 없어서"입니다. 학습 이력은 전혀 참조하지 않습니다.

### 5-D. 새 레슨을 추가하려면 정확히 무엇을 건드려야 하나
1. **DB에 레슨 행을 직접 INSERT** (`lesson_id`, `unit_id`, `unit_title`, `order_num`, `title`, `content`). 저장소에 이를 하는 스크립트나 SQL이 없습니다.
2. 소개·연습·완료 단계 JSON을 **손으로 작성**합니다. 이 단계들을 생성하는 도구는 없습니다.
3. (선택) 탭 분석용 `chunks`: `inject_morphology.py`의 **고정 경로를 코드에서 수정**한 뒤 실행합니다.
4. `update_lesson.py <json경로> <DB의 숫자 id>`로 DB에 반영합니다.
5. `curriculum.csv`에 `UnitID, LessonID, Sentence, Translation, Target_POS` 행을 추가합니다. Target_POS는 세종 품사 태그(JX, JKO 등)를 알아야 씁니다.
6. `batch_merger.py` 실행 — **`__main__`의 `(1, "u1-l1")`을 코드에서 수정**하거나 별도 호출 코드가 필요합니다.
7. 출력 검수: 구두점 칸, '이예요' 같은 비표준 형태, "~고" 오답 선택지, 중복 형태소 문제를 사람이 확인해야 합니다.
8. 앱 쪽:
   - Unit 1에 넣으면 앱 코드 수정은 없습니다(목록이 DB 기반).
   - **Unit 4 이상**은 `unit_selection_screen.dart`의 카드 목록을 수정해야 합니다.
   - 완료 화면 문구가 "Basic Vowels Mastered!"로 고정된 문제는 남습니다.

**결론**
- 앱·서버 코드는 수정하지 않아도 됩니다. JSON이 기존 단계 유형(`agglutinative_quiz` 등)을 따르면 그대로 렌더링됩니다.
- **파이프라인 스크립트는 현재 상태로는 코드를 고쳐야 하고**, DB 행 생성과 결과 검수는 수작업입니다.

---

## 6. 신청서 문장 사실 확인

### (1) "Flutter 클라이언트, Spring Boot 서버, PostgreSQL을 기반으로 형태소 조립 레슨, FSRS 기반 단어 복습, 롤플레잉 대화, 한글 조합 실습까지 구현해 배포했습니다."
**판정: [부분적으로 사실]**

| 구성 요소 | 확인 결과 |
|---|---|
| Flutter / Spring Boot / PostgreSQL | 사실 (`frontend/maru/pubspec.yaml`, `backend/maru/build.gradle` Spring Boot 3.5.11, `org.postgresql:postgresql`) |
| 형태소 조립 레슨 | 사실. 단 레슨 2개, 조립 문제 4개 |
| FSRS 기반 단어 복습 | 부분적. 아래 (3) 참고 |
| 롤플레잉 대화 | 사실 (`MissionChatController`, 수료증 15건) |
| 한글 조합 실습 | 사실 (`HangeulLabScreen`, `HangeulCombiner`) |
| **배포** | **근거 없음.** 앱의 서버 주소는 `localhost`/`10.0.2.2`로 고정(`dio_client.dart:16`). 서버 DB 설정도 localhost. Railway 관련 커밋 3건(`8eb1978`, `834840d`, `9818e00`)은 빌드 설정 변경뿐이고 배포 URL·배포 설정 파일은 없음. Android 릴리스는 디버그 키로 서명. 스토어·TestFlight 흔적 없음 |

**대신 쓸 문장**
> Flutter 앱과 Spring Boot·PostgreSQL 서버로 형태소 조립 레슨(문법 레슨 2개·조립 문제 4개와 한글 기초 레슨 12개), 간격 반복 단어 복습(단어 5,561개), AI 롤플레잉 대화(GPT-4o), 한글 조합 실습을 구현했으며, 개발 환경(에뮬레이터·시뮬레이터 + 로컬 서버)에서 전 기능이 동작하는 MVP를 보유하고 있습니다.

(선정 전에 실제로 서버를 배포하고 앱 주소를 바꾼다면, 그때 "배포"라고 쓰세요.)

### (2) "형태소 분석기 Kiwi를 연동한 파이프라인으로, 커리큘럼 데이터를 교체하면 코드 수정 없이 새 레슨의 조립 문제가 생성됩니다."
**판정: [부분적으로 사실]**

- **사실인 부분**
  - Kiwi 기반 생성기가 있습니다(`core_engine.KiwiEngine`, `batch_merger.ContentMerger`).
  - 생성된 JSON은 앱·서버 코드 변경 없이 화면에 반영됩니다.
  - 기존 레슨 `u1-l1`에 대해서는 CSV만 바꿔 다시 실행하면 문제가 교체됩니다.
- **근거가 부족한 부분**
  - "연동"이라는 표현은 서비스 안에서 Kiwi가 돈다는 인상을 주는데, 실제로는 **오프라인 수동 스크립트**입니다.
  - **새 레슨**에는 DB 행 수동 INSERT와 스크립트 코드 수정(`batch_merger.py:103` 대상 고정, `inject_morphology.py:6` 경로 고정)이 필요합니다.
  - 현재 CSV는 2문장이고, 이 파이프라인으로 만든 조립 문제는 2개뿐입니다(나머지 2개는 수작업).
  - 생성 결과에 비표준 형태("이예요")와 비문 오답("Sarah입니다고")이 섞여 있어 사람 검수가 필요합니다.

**대신 쓸 문장**
> 형태소 분석기 Kiwi를 활용한 콘텐츠 생성 도구를 자체 개발해, 커리큘럼 문장과 목표 문법 태그를 입력하면 2단계 조립 문제 데이터를 자동 생성하고, 앱 업데이트 없이 서버 데이터만으로 레슨에 반영할 수 있는 구조를 만들었습니다(현재 1개 레슨에 적용, 검수·자동화 고도화 예정).

### (3) "FSRS 알고리즘을 기반으로 학습자의 기억 상태에 맞춰 복습 단어를 추천합니다."
**판정: [부분적으로 사실]**

- **있는 것**
  - 단어별 상태(New/Learning/Review/Relearning), 안정성·난이도·반복 횟수·실패 횟수 저장(`FsrsProgress`)
  - 4단계 평가(Again/Hard/Good/Easy)에 따른 다음 복습일 계산
  - 복습일이 지난 단어만 모아 보여주는 "오늘의 복습"(`findDueCardsByUser`)
- **FSRS가 아닌 것** (`FsrsAlgorithm.java`)
  - 클래스 주석은 "FSRS V4 핵심 구현체"지만, FSRS 가중치 배열 `w[]`를 **한 번도 사용하지 않습니다.**
  - 초기 안정성·난이도는 평가별 고정표입니다(Good → 4.0/5.0). 주석에 "TDD 스펙을 맞추기 위한 간소화 식"이라고 적혀 있습니다.
  - 복습 성공 시 안정성 = 이전 값 × 1.2(Hard) / 2.0(Good) / 3.0(Easy) 고정 배수입니다.
  - 난이도는 ±1씩 선형으로 바뀝니다. 주석은 "HARD면 난이도 증가"인데 실제 식에서 Hard는 변화 0입니다.
  - 인출 가능성(retrievability) 계산, 경과 시간 반영, 목표 기억률 설정이 없습니다.
- **추천에 쓰이지 않는 곳**
  - 덱 안의 "Word Study"는 복습일과 무관하게 등급·ID 순으로 30개씩 보여줍니다(`getDueWordsByLesson`).
  - 이미 학습한 단어는 이 모드에서 평가해도 **무시**됩니다(`VocabularyService.submitReview` 63-68행).
  - 기한 단어와 신규 단어를 섞는 `getDueWords`는 호출되지 않습니다.

**대신 쓸 문장**
> FSRS의 기억 모델(안정성·난이도·학습 상태)을 차용한 간격 반복 스케줄러를 구현해, 학습자의 단어별 4단계 자기 평가에 따라 다음 복습일을 계산하고 복습 시점이 된 단어를 '오늘의 복습'으로 제시합니다. (선정 후 FSRS 표준 공식과 파라미터 적용 예정)

### (4) "레슨의 학습 목표에 따라 문장을 어느 수준까지 분해할지 결정된다."
**판정: [부분적으로 사실]**

- **레슨 단위로 분해 깊이를 지정하는 구조는 없습니다.**
  - `lessons` 테이블·`Lesson` 엔티티·레슨 JSON 어디에도 학습 목표나 분해 깊이 필드가 없습니다.
  - 앱의 조립 문제는 모든 레슨에서 **항상 2단계**(어절 → 형태소)입니다(`AgglutinativeStepWidget`의 `isTurtleMode` 하나).
- **있는 것은 문장 단위의 "분해할 어절 선택"입니다.**
  - `curriculum.csv`의 행마다 `Target_POS`를 지정합니다.
  - 그 태그가 들어 있는 어절만 거북이 단계에서 **형태소 전부로** 분해하고, 나머지 어절은 통째로 둡니다(`core_engine.py:50-75`).
  - 즉 "어느 **어절**을 분해하느냐"는 달라지지만, "어느 **수준**까지"는 고정입니다(통째 또는 완전 분해).
- 실제 데이터에서도 이 구조는 1개 레슨(u1-l1, Target_POS=JX,EF → 사실상 모든 어절 분해)에만 쓰였습니다.
- 수작업 레슨 lesson2는 학습 목표가 이에요/예요인데도 "저는"을 다시 "저 + 는"으로 분해합니다.

**대신 쓸 문장**
> 조립 문제는 문장마다 목표 문법(예: 주제 조사 '은/는')을 지정하면, 해당 문법이 포함된 어절만 형태소 단위로 분해하고 나머지 어절은 통째로 제시하도록 생성됩니다. 이를 통해 학습 초점을 목표 문법에 맞춥니다.

---

## 7. 데모 가능성 평가 (90초 영상)

공통 준비:
- 로컬 서버와 DB를 켜고 **Android 에뮬레이터 또는 iOS 시뮬레이터**에서 녹화합니다.
- 로그인은 이미 되어 있는 계정으로 시작하세요(Google 로그인 실패 시 무한 로딩 위험).
- 홈 우측 상단 사람 아이콘은 **누르면 즉시 로그아웃**되니 피하세요.

### (a) 조사 '는/은' 레슨의 2단계 조립
**나옵니다.**

- **경로**: 홈 → Korean Lessons → Select a Unit → **Unit 1** → **My Name is...** → 단계 1~6 통과 → **7단계(Step 7/9) "저는 Sarah입니다."** → 토끼 단계에서 [저는][Sarah입니다.] 끌어놓기 → Check → 거북이 단계에서 [저][는][Sarah][입니다][.] → Check & Finish → 8단계 "제 이름은 유미예요."
- **대안**: 좀 더 깔끔한 문제는 **What do you do?(lesson2)의 6·7단계**입니다("저는 학생이에요." → [저][는][학생][이에요.]). 이 문제는 수작업이라 "Kiwi로 생성"이라고 설명하면 안 됩니다.
- **7단계까지 가려면** 소개 4단계, 빈칸 3문제, 입력 1문제를 먼저 지나야 합니다. 건너뛰기 기능이 없어 영상 편집(컷)이 필요합니다.
- **위험 지점**
  1. 거북이 단계 트레이에 **"."가 형태소 블록**으로, 오답 후보로 "네", "고", "은"이 나옵니다. 토끼 단계엔 **"Sarah입니다고", "저고"** 같은 비문이 나옵니다.
  2. 8단계 정답이 **"유미 + 이예요 + ."**입니다. 틀린 표기가 정답이라 영상에 나오면 안 됩니다. 7단계에서 끊으세요.
  3. 토끼 단계를 맞히면 초록 대신 보라색 스낵바 "✅ Great! Now try breaking it down further!"가 3초간 하단(Check 버튼 부근)을 가립니다.
  4. 마지막 단계를 끝내면 완료 화면에 **"Basic Vowels Mastered!"**가 뜹니다. 녹화를 여기까지 이어가지 마세요.
  5. 선택지가 많은 문제(8단계, 16개)는 작은 화면에서 레이아웃이 넘칠 수 있습니다. 스크롤이 없는 `Column` + `Spacer` 구조라 이렇게 추정하며, 실측은 못 했습니다. 큰 화면 기기로 녹화하세요.
  6. 디버그 빌드에서는 우측 상단에 **"DEBUG" 띠**가 보입니다. `main.dart`에 `debugShowCheckedModeBanner` 설정이 없습니다. iOS 시뮬레이터는 debug 모드로만 실행되므로, 코드를 고치지 않으려면 Android 에뮬레이터에서 `--profile`이나 `--release`로 실행해야 띠가 사라집니다.
  7. 화면 안내문이 영어 번역("I am Sarah.")만 보여주고 한국어 원문은 보여주지 않습니다. 설명 자막이 필요합니다.

### (b) 조사 '을/를' 레슨에서 이미 배운 부분은 분해하지 않는 모습
**현재 코드와 데이터로는 나오지 않습니다.**

- **빠진 것**
  1. **을/를 레슨 자체가 없습니다.** DB, `curriculum.csv`, `backend/lessons/` 모두 0건입니다.
  2. **"이미 배운 것"을 판단하는 로직이 없습니다.** 학습자별 문법 습득 기록이 없고(`UserProgress`는 레슨 완료 여부만 저장), 분해 여부는 CSV 문장별 태그로 미리 고정됩니다.
  3. 새 레슨을 넣으려면 DB 행 INSERT, `batch_merger.py` 대상 수정, 실행이 필요합니다(5-D).
- **엔진으로 가능한 것**: `Target_POS=JKO`로 "저는 사과를 먹어요."를 생성하면 거북이 단계가 [저는][사과, 를][먹어요.]가 되어 **"저는"이 통째로 남습니다**(직접 실행해 확인). 영상용 레슨을 만들 수는 있지만, 이 동작을 "학습자가 은/는을 배웠기 때문"이라고 설명하면 사실과 다릅니다. 정확한 설명은 "이 문제의 목표 문법이 을/를이기 때문"입니다.
- **추가 위험**
  - 활용형 어절에 목표 태그가 겹치면 "먹 + 어요", "좋아하 + 어요"처럼 학습자에게 어색한 조각이 나옵니다(태그를 JKO 하나로 제한하면 회피 가능).
  - 현재 lesson2는 은/는을 **다시 분해**하고 있어, 영상의 주장과 반대 사례가 앱 안에 있습니다.

### (c) 처음 보는 단어로 새 문장을 조립하는 단계
**나오지 않습니다.**

- **빠진 것**
  - 해당 단계 유형이 없습니다. `StepRenderer`는 `introduction/intro`, `practice/quiz`, `completion`, `agglutinative_quiz`만 처리합니다.
  - 기존 조립 문제 4개는 모두 같은 레슨 소개 단계에 이미 나온 단어(Sarah, 유미, 학생, 의사)를 씁니다.
  - 학습자가 본 단어와 안 본 단어를 구분해 문장을 고르는 로직이 없습니다.
  - 서버에 형태소 분석기가 없어 새 문장을 그 자리에서 분해할 수도 없습니다.
- **가장 가까운 기존 기능** (모두 "조립"은 아님)
  - AI Grammar Lab: 자유 문장을 AI가 시제·높임 등으로 **변형**
  - u1-l1 6단계 "Make Your Own": `저는 {input}입니다.` 템플릿에 이름을 **끼워 넣기**(정답 검사 없음)
- **만들 방법**: 코드 수정 없이 데이터만으로 흉내 내려면, 소개 단계에 나오지 않은 단어가 들어간 문장을 CSV에 추가해 조립 문제를 생성하면 됩니다(5-D 절차, 스크립트 수정 필요). 이 경우 "처음 보는 단어"는 사람이 고른 것이지 시스템이 판단한 것이 아니므로, 영상 설명도 그렇게 해야 합니다.

---

## 8. UI 완성도 — "아직 정제되지 않았다"고 느껴지는 부분

영상에 나올 가능성 순으로 정렬했습니다.

### P0 — 데모 핵심 화면에 그대로 노출
| # | 문제 | 화면 | 근거 |
|---|---|---|---|
| 1 | 문법 레슨 완료 화면에 **"Basic Vowels Mastered!" / "1 × Basic Vowels Completed"** | Unit 1 레슨 마지막 단계 | `completion_step_widget.dart:41, 67` |
| 2 | 조립 문제에 **"." 블록, "이예요", "Sarah입니다고"·"유미예요고"·"이름고"** 같은 비문 선택지 | u1-l1 7·8단계 | DB `lessons.content`, `core_engine.py:105` |
| 3 | 디버그 빌드의 **"DEBUG" 띠** | 모든 화면 | `main.dart`에 `debugShowCheckedModeBanner: false` 없음 |
| 4 | 단계 제목("Sentence Building #1", "Grammar: Topic Particle 은/는")이 표시되지 않음. 상단엔 레슨 제목만 | 레슨 전 단계 | `StepModel.title/instruction` 미사용 |
| 5 | 탭 분석 패널에 **"Sarah → word", ": → word", "= → word"** | u1-l1 소개 단계 1~4 | DB `chunks` |
| 6 | 토끼→거북이 전환 스낵바가 하단 Check 버튼을 3초간 가림 | 조립 문제 | `agglutinative_step_widget.dart:104-115` |
| 7 | 한글 소개 카드 설명이 모든 글자에 똑같이 "Open your mouth wide", "This is the most basic vowel!". 자음 레슨 제목도 "Let's learn the basic vowels" | Unit 0 모든 레슨 | `introduction_step_widget.dart:75-81, 183-196` |
| 8 | 듣기 퀴즈 "Score: 0/6" 고정, "Question n/5" 고정, 자음 레슨에서도 "find the correct vowel" | Unit 0 퀴즈 | `practice_step_widget.dart:211, 221, 238` |

### P1 — 보이면 어색하지만 편집으로 피할 수 있음
| # | 문제 | 근거 |
|---|---|---|
| 9 | **영어·한국어 혼용**: 화면 문구는 영어인데 일부 오류 문구만 한국어("레슨 데이터를 불러오지 못했습니다.", "세션이 만료되었습니다."). 실험실 칩은 "Tense (시제)" 병기 | `lesson_list_screen.dart:33-39`, `dio_client.dart:53`, `lab_screen.dart:24-27` |
| 10 | **앱 이름 불일치**: "Maru" / "Maru Grammar Lab"(MaterialApp) / "Korean Grammar Lab"(로그인 부제) / Android 라벨 소문자 "maru" | `main.dart:25`, `login_screen.dart:60`, `AndroidManifest.xml:3` |
| 11 | **색상 체계 불일치**: 로그인·한글 실험실 `blueAccent`, 홈·레슨 목록 `deepPurple`, 레슨 `0xFF6B4EFF`, 단어장 `0xFF6C63FF`, 미션 `teal`. 연습 문제 선택지 테두리만 `Colors.blue`, 자모 카드도 파란색 | 각 화면 파일 |
| 12 | Unit 2·3 진입 시 "No lessons found." 한 줄 | `lesson_list_screen.dart:47` |
| 13 | Unit 0 레슨 제목에 괄호 숫자("Basic Vowels (5)"), 영어·한국어가 섞인 unit_title | DB `lessons.title` |
| 14 | **로딩 상태 부족**: 홈 통계·복습 배너는 로딩과 오류 모두 빈칸. 미션 대화 응답 대기는 전송 버튼 자리의 작은 스피너뿐(입력 중 표시 없음). AI 실험실 첫 요청은 오래 걸릴 수 있음 | `home_screen.dart:82-92`, `mission_chat_screen.dart:363-370` |
| 15 | **예외 원문 노출**: AI 실험실, 단어장, 짝맞추기 오류 시 `Exception: ... DioException ...` 문자열을 그대로 표시 | `lab_screen.dart:416`, `vocabulary_game_screen.dart:91`, `daily_review_screen.dart:63` |
| 16 | 미션 준비 로딩 문구 "Getting ready to transform..."이 기능과 맞지 않음 | `mission_setup_screen.dart:79` |
| 17 | 수료증이 목표 달성과 무관하게 "Cleared 🎉"로 발급됨(시연 중 일부러 엉뚱하게 답해도 결국 발급) | `mission_chat_provider.dart:127-137` |
| 18 | 짝맞추기 "Round n/6", "You mastered all 30 words"가 단어 30개 미만 묶음에서도 표시 | `vocabulary_game_screen.dart:80, 259` |
| 19 | 단어 카드 화면만 검은 배경이라 앱 톤과 따로 놂 | `vocabulary_learning_screen.dart:35`, `daily_review_screen.dart:38` |
| 20 | 홈 사람 아이콘 = 즉시 로그아웃(녹화 중 실수 위험) | `home_screen.dart:46-50` |

### P2 — 영상에는 안 보이지만 정리가 필요한 것
- `withOpacity` 사용 중단 경고 다수(콘솔)
- `pubspec.yaml` 설명이 "A new Flutter project.", README는 Flutter 기본 템플릿
- Flutter 테스트 `test/widget_test.dart`가 기본 카운터 템플릿이라 현재 앱과 맞지 않아 실패할 것으로 보임(실행하지 않음)
- 서버 테스트 로그 `backend/maru/test_output.log`(2026-03-04): 22개 중 1개 실패(`LessonControllerTest`). 현재 테스트 메서드는 50개이며 최신 결과는 **확인 불가**

---

## 9. 2~3개월 개선 가능성

### 9-A. 3개월 안에 해결 가능한 것
| 과제 | 내용 | 비고 |
|---|---|---|
| **실제 배포** | 앱 서버 주소를 환경별로 분리, 서버·DB 클라우드 배포, HTTPS, CORS 정리, 릴리스 서명, 내부 테스트 트랙·TestFlight | 신청서의 "배포" 문구를 사실로 만드는 최우선 과제 |
| 보안 정리 | 디버그 API 제거 또는 관리자 인증, JWT 로그 제거, Gemini 키를 헤더로 전달 | 수일 규모 |
| 하드코딩 UI 제거 | 완료 화면·소개 카드·퀴즈 문항 수·점수를 콘텐츠 기반으로, 단계 제목 표시, 유닛 목록 DB화 | 수일~2주 |
| 명백한 버그 | 로그인 실패 무한 로딩, 미션 대화 오류 UI, 짝맞추기 `dispose`, `isPublished` 필터, iOS Google 로그인 설정, 레슨 점수·중간 진행 저장 | 1~2주 |
| Kiwi 출력 후처리 | 구두점 칸 제외, 서술격 병합 규칙 보강("이예요"→"예요"), 오답 선택지 생성 규칙 교체, 선택지 고유 ID 부여(중복 형태소 문제 해소) | 1~3주 |
| 파이프라인 도구화 | 스크립트 인자화, 레슨 행 생성 포함, 결과 검수 리포트·미리보기, 실행 순서 충돌(update_lesson ↔ batch_merger) 제거 | 2~3주 |
| 표준 FSRS 적용 | 공개된 FSRS 공식·기본 파라미터로 `FsrsAlgorithm` 교체, 덱 학습에도 기한 기반 큐 적용(이미 작성된 `getDueWords` 활용) | 알고리즘 교체는 가능. **효과 검증은 사용자 데이터가 없어 불가** |
| 조사·문법 레슨 확장 | 을/를, 이/가, 에/에서, 도, 과거형 등 10개 안팎 | 콘텐츠 작성·검수 인력 확보가 관건 |
| Stats·Settings 화면, 문구 언어 통일, 디자인 토큰 정리 | | 2~3주 |
| 단어 데이터 정리 | 'Beginner' 일괄 표기를 등급별 덱으로 분리, "기타/사물" 2,222개 재분류 | 재분류는 가능하나 번역·예문 **전수 검수**는 인력 규모에 따라 부분 완료 |

### 9-B. 3개월로는 부족한 것 (구조적 문제)
| 과제 | 왜 구조적인가 |
|---|---|
| **"이미 배운 문법은 분해하지 않는" 학습자 맞춤 분해** | 지금은 분해 여부를 오프라인 CSV에서 문장별로 미리 고정합니다. 학습자별 문법 습득 모델, 문법 항목과 형태소 태그의 대응표, 요청 시점의 문제 생성(서버에서 형태소 분석)이 모두 새로 필요합니다. 3개월이면 프로토타입까지는 가능하지만 교육적으로 검증된 수준은 어렵습니다 |
| **"처음 보는 단어로 새 문장 조립"** | 새 문장 생성(LLM 또는 템플릿), 서버측 형태소 분석(Kiwi는 Python/C++라 Spring과 별도 서비스 필요), 자동 정답·오답 생성과 품질 검증이 한꺼번에 필요합니다. 생성 문장의 문법 정확도를 사람 검수 없이 보장할 방법이 현재 없습니다 |
| **형태소 분석 단위 ≠ 교육 문법 단위** | Kiwi는 "만나/었었/어", "좋아하/어요", "ᆸ니다" 같은 분석용 단위를 냅니다. 한국어 교육에서 가르치는 단위(-았었-, -아요, -습니다)로 바꾸는 규칙 체계는 사례를 쌓아야 하는 장기 작업입니다 |
| 체계적 커리큘럼 규모 | 현재 문법 레슨 2개입니다. 초급(TOPIK 1~2급) 수준만 해도 수십 개 문법 항목이 필요하고, 한국어교육 전문가 검수가 필요합니다 |
| 학습 효과 입증 | 현재 사용자는 로컬 개발 계정 3명입니다. 기억 유지율·학습 성과를 주장하려면 실사용자 모집과 수개월 추적이 필요합니다 |
| AI 대화 교정 정확도 | 교정은 전적으로 LLM 프롬프트에 의존하며, 정확도를 평가하는 데이터셋이나 측정 코드가 없습니다 |

---

## 신청서에 쓰면 안 되는 주장

현재 코드와 데이터가 뒷받침하지 못하는 주장들입니다. 오디션에서 "실제로 되나요?"라는 질문을 받으면 무너질 순서대로 정렬했습니다.

| # | 쓰면 안 되는 주장 | 왜 근거가 부족한가 | 대신 쓸 수 있는 문장 |
|---|---|---|---|
| 1 | "**배포했습니다**" / "서비스 운영 중" / "누구나 설치해 쓸 수 있습니다" | 앱의 서버 주소가 `localhost`·`10.0.2.2`로 고정(`dio_client.dart:16`)되어 실기기에서는 서버에 닿지 않습니다. 서버 DB 설정도 localhost이고, 배포 URL·배포 설정이 저장소에 없습니다. 릴리스 APK는 디버그 키 서명입니다 | "개발 환경(에뮬레이터·로컬 서버)에서 전 기능이 동작하는 MVP를 보유하고 있으며, 선정 후 클라우드 배포와 베타 테스트를 진행합니다." |
| 2 | "**FSRS 알고리즘 기반** 복습" | `FsrsAlgorithm`은 FSRS 가중치를 쓰지 않고 고정 배수(×1.2/×2/×3)와 고정 초기값으로 계산합니다. 덱 학습 화면은 복습 기한을 쓰지 않습니다 | "FSRS의 기억 모델(안정성·난이도·상태)을 차용한 간격 반복 스케줄러로 단어별 다음 복습일을 계산합니다." |
| 3 | "커리큘럼 데이터만 교체하면 **코드 수정 없이 새 레슨이 생성**됩니다" | 새 레슨에는 DB 행 수동 INSERT와 스크립트 수정(`batch_merger.py:103` 대상 고정, `inject_morphology.py:6` 경로 고정)이 필요합니다. 소개·연습 단계는 손으로 씁니다. 파이프라인으로 만든 조립 문제는 2개뿐입니다 | "Kiwi 기반 생성 도구로 조립 문제 데이터를 만들면 앱·서버 코드 변경 없이 레슨에 반영되는 구조를 갖추었습니다(현재 1개 레슨 적용)." |
| 4 | "Kiwi 형태소 분석기가 **서비스에 연동**되어 문장을 실시간 분석합니다" | 서버·앱에 Kiwi가 없습니다. 개발자 PC에서 수동으로 돌린 결과를 DB에 저장해 둔 것입니다 | "Kiwi를 활용한 오프라인 콘텐츠 생성 도구를 자체 개발했습니다." |
| 5 | "**학습자가 이미 배운 부분은 분해하지 않습니다**" / "학습자 수준에 맞춰 분해합니다" | 학습자별 문법 습득 기록이 없고, 분해 여부는 CSV 문장별 태그로 미리 정해집니다. 을/를 레슨도 없습니다. 오히려 lesson2는 이미 배운 '는'을 다시 분해합니다 | "문제마다 목표 문법을 지정해, 그 문법이 포함된 어절만 형태소로 분해하도록 생성합니다." |
| 6 | "**레슨의 학습 목표에 따라 분해 수준(깊이)이 결정**됩니다" | 레슨 단위 설정 필드가 없고, 분해는 모든 문제에서 2단계(어절 → 형태소 전체)로 고정입니다 | 위 5번 대체 문장 |
| 7 | "**처음 보는 단어로 새 문장을 조립**하는 단계가 있습니다" | 해당 단계 유형·기능이 없습니다(`StepRenderer`). 조립 문제 4개는 모두 같은 레슨에서 이미 소개한 단어만 씁니다 | (현재 기능으로는 대체 불가) "향후 개발 계획: 학습한 문법을 새로운 어휘에 적용하는 전이 학습 단계" |
| 8 | "**을/를 등 다양한 조사**를 학습합니다" / "조사별 레슨 제공" | 명시적으로 가르치는 조사는 은/는 1개, 서술 표현은 이에요/예요(+입니다)뿐입니다. 을/를은 0건입니다 | "주제 조사 '은/는'과 서술 표현 '입니다/이에요/예요'를 다루는 문법 레슨 2개를 구현했습니다." |
| 9 | "AI 캐시로 **API 비용 90% 절감, 응답 2초→0.1초**" (`frontend/FINAL_PRESENTATION_FLOW.md`) | 측정 코드·로그·벤치마크가 없습니다. 캐시는 입력 문장이 완전히 같을 때만 적중합니다 | "동일 요청의 AI 결과를 DB에 캐시해 재요청 시 외부 API 호출을 생략합니다." |
| 10 | "**Gemini 1.5** 연동" (같은 문서) | 코드 기본값은 `gemini-2.5-flash`입니다(`GeminiService.java:30`) | "Google Gemini API(기본 gemini-2.5-flash)" |
| 11 | "**상용화 수준** 아키텍처" / "견고한 풀스택" | 인증 없는 데이터 변경 API(`DebugController`), JWT 원문 로그, localhost 고정 설정, 핵심 화면의 하드코딩 문구가 있습니다 | "Flutter·Spring Boot·PostgreSQL 기반 풀스택 MVP" |
| 12 | "**앱 업데이트 없이 콘텐츠를 무한 확장**" | 기존 단계 유형의 데이터만 서버에서 바꿀 수 있습니다. 새 단계 유형, 새 유닛 카드, 완료 화면 문구는 앱 코드 수정이 필요합니다 | "레슨 콘텐츠를 서버 JSON으로 관리해, 기존 문제 유형 안에서는 앱 업데이트 없이 레슨을 추가·수정할 수 있습니다." |
| 13 | "학습 성취도(점수·별)를 **평가**합니다" | 레슨 점수는 항상 100(`lesson_screen.dart:39`), 별은 첫 완료 시 무조건 3개입니다 | "레슨 완료 기록과 연속 학습일(스트릭)을 서버에 저장합니다." |
| 14 | "**미션을 성공해야** 수료증을 받습니다" / "AI가 대화 목표 달성을 판정합니다" | 사용자 턴이 `minTurns + 2`에 도달하면 달성 여부와 무관하게 발급 요청하고, `failed` 상태는 처리하지 않습니다 | "대화가 끝나면 AI가 좋은 표현과 고칠 표현을 정리한 피드백 수료증을 발급합니다." |
| 15 | "AI가 **정확하게** 한국어 오류를 교정합니다" | 교정 정확도를 측정한 데이터·코드가 없습니다. 프롬프트 기반입니다 | "대화 중 존댓말·문법 오류를 AI 튜터가 실시간으로 지적하고 올바른 표현을 제안합니다." |
| 16 | "**Google·Apple 로그인**(iOS·Android 모두) 지원" | iOS에는 Google 로그인 필수 설정(`GIDClientID`/`GoogleService-Info.plist`)이 없습니다. Google 검증 실패 시 무한 로딩 버그가 있습니다 | "Google(Android)·Apple 소셜 로그인과 JWT 기반 인증을 구현했습니다." |
| 17 | "**테스트로 검증된** 코드" | 최근 서버 테스트 로그(2026-03-04)에 실패 1건이 있고 최신 결과는 없습니다. Flutter 테스트는 기본 템플릿이라 현재 앱과 맞지 않습니다 | (언급하지 않거나) "핵심 알고리즘·서비스에 단위 테스트를 작성했습니다." |
| 18 | "**수천 명의 학습 데이터**" / 사용자 수·학습 기록을 실사용 지표로 제시 | 로컬 DB 사용자는 3명(개발 계정으로 보임)입니다 | (사용 지표는 쓰지 않음) |
| 19 | "한글 12개 레슨 + 문법 레슨 등 **풍부한 커리큘럼**" | 한글 레슨 12개(37단계)는 있으나 문법 레슨은 2개, Unit 2·3은 빈 카드입니다. 한글 레슨의 설명 문구는 모든 글자에 동일한 고정 문장입니다 | "한글 기초 12개 레슨(자모·음절 80개 항목)과 문법 레슨 2개, 국립국어원 학습용 어휘 기반 단어 5,561개를 구축했습니다(번역·예문은 AI 생성, 검수 예정)." |

---

### 신청서 작성 시 쓸 수 있는 "안전한" 사실 요약
- Flutter 앱 + Spring Boot 서버 + PostgreSQL 풀스택 MVP. 개발 환경에서 로그인부터 레슨, 단어 복습, AI 대화, 수료증까지 전 흐름이 이어집니다.
- 한글 기초 레슨 12개, 문법 레슨 2개, 형태소 2단계 조립 문제 4개.
- 국립국어원 학습용 어휘 목록 기반 단어 5,561개(14개 주제 덱), 간격 반복 복습.
- GPT-4o 기반 역할극 미션 대화(존댓말·문법 교정, 피드백 수료증).
- Gemini 기반 문법 변형 실험실(DB 캐시), 기기 내 한글 조합 실습.
- Kiwi 형태소 분석기를 활용한 조립 문제 생성 도구(오프라인, 1개 레슨 적용).
