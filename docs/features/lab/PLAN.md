# LAB — Language Lab PLAN

- 세션: `lab-be`, `lab-fe` · worktree `/Users/hadohadopapi/Desktop/Maru-wt/lab` · 브랜치 `feat/lab`
- 서버 :8084 · DB `maru_lab` · 시뮬레이터 iPhone 16 Pro (iOS 18.5)
- 범위: Hangeul Lab(기기 내 유니코드 조합 + TTS) · AI Grammar Lab(Explore 4카테고리 / Combine 수식어) · Gemini(`gemini-2.5-flash`) · AI 캐시
- 발표 주장(맞춰야 할 것): "Explore: 3가지 변형", "Combine: 다중 수식어 한 문장", "캐시 키 정렬로 순서 무관 히트", "캐시 HIT 0.1초"
- 참고: 홈의 Language Lab 진입 버튼은 PM 소유. 작업량이 가장 가벼움 → 끝나면 STATUS 에 알리고 PM 지시로 QA 지원.
- 동결: 10/1 15:00 · 우선순위 P0 > P1 > P2 · Gemini 호출 비용 주의

## Phase 1 — 기능 수정

### Step 1.1 현황 점검
- [x] LAB-1.1.1 [BE] P0 서버 기동, `POST /api/lab/explore`·`/api/lab/combine` 캐시 HIT/MISS 각각 호출 → `API_CONTRACT.md` 에 현재 요청/응답 기록. `AiLabServiceTest`·`GeminiServiceTest`·`AiCacheRepositoryTest` 결과 기록
- [x] LAB-1.1.2 [FE] P0 Hangeul Lab·AI Grammar Lab(Explore 4종, Combine 조합) 점검, 새 문제는 태스크 추가 — (코드 변경 없음, LOG_fe 09-30 참고)

### Step 1.2 오류·로딩 (P0)
- [x] LAB-1.2.1 [BE] P0 Gemini 오류·타임아웃·JSON 파싱 실패 → 적절한 HTTP 오류 + 사용자용 메시지. 응답 개수·필드 검증(Explore 는 3개) — 0106947
- [x] LAB-1.2.2 [BE] P0 API 키를 URL 쿼리스트링 → `x-goog-api-key` 헤더로 (실사 §2-D, `GeminiService.java:38`). 오류 로그에 URL(키) 노출 금지 — 4430498
- [x] LAB-1.2.3 [BE] P1 입력 검증: 빈 문장·과도한 길이 거절, 캐시 키용 입력 정규화(trim·연속 공백) — b9eccb8 (+패치 lab_001)
- [x] LAB-1.2.4 [FE] P0 예외 원문 빨간 글씨 노출(`lab_screen.dart:416`) → 영어 안내 + Retry — be85157
- [x] LAB-1.2.5 [FE] P0 첫 요청(캐시 MISS 최대 ~30초) 로딩 UX: 진행 문구/스켈레톤, 중복 요청 방지 — b6bf419

### Step 1.3 문구·디자인 (P1)
- [x] LAB-1.3.1 [FE] P1 칩 "Tense (시제)" 식 병기 → 영어 라벨 + 작은 한국어 보조 등 일관된 규칙 (실사 §8-P1#9, `lab_screen.dart:24-27`) — 8b5fb0e
- [x] LAB-1.3.2 [FE] P1 Hangeul Lab `blueAccent`·파란 자모 카드 → theme 색 (실사 §8-P1#11) — 70c3d19
- [x] LAB-1.3.3 [FE] P1 Hangeul Lab: 받침 없음/있음 조합, 결과 발음 TTS, 작은 화면 레이아웃 확인 — 70c3d19
- [x] LAB-1.3.5 [FE] P1 (1.1.2 발견) 예문 칩: 한국어 키보드 없는 학습자도 탭으로 입력 가능하게 (입력창 아래 예문 2~3개) — 349cd87
- [x] LAB-1.3.6 [FE] P1 (1.1.2 발견) Grammar Lab 하드코딩 색(`Colors.deepPurple`, `Colors.blue.shade50/900`, `Colors.red`) → theme colorScheme — 444f6ff
- [x] LAB-1.3.7 [FE] P1 (1.1.2 발견) Grammar Lab 입력 영역이 스크롤 불가 Column → 키보드+Combine 펼침 시 작은 화면 overflow 위험. Explore 칩 4번째(Emotion)가 화면 밖(가로 스크롤)이라 안 보임 → Wrap — 8a887d0
- [x] LAB-1.3.8 [FE] P1 (API_CONTRACT §3 18:31 권장) 입력창 maxLength 200 + 서버 400 실제 문구 표시 확인 — 418e951
- [x] LAB-1.3.4 [BE] P2 캐시 HIT/MISS 소요 ms 를 INFO 로그로 (발표 "0.1초" 측정 근거, 입력 원문·키 제외) — b1069ea

### Step 1.4 여유 시
- [x] LAB-1.4.1 [FE] P2 결과 카드 "복사"/TTS 듣기 — 06c96b5
- [ ] LAB-1.4.2 [BE+FE] P2 PM 지시에 따른 QA 지원

### Step 1.5 사용자 피드백 R2 (09-30 19:30, 하도윤 직접 사용 후) — 원문: `/Users/hadohadopapi/Downloads/9_30_디테일하게_고쳐야할_부분들.pdf`
> 목표: "UI/UX 에서 사용자 경험 극대화". 스크린샷 기준 iPhone 16 Pro Max.
- [x] LAB-1.5.1 [FE] P0 Hangeul Lab: 조합 후 우상단 작은 Reset 대신 **큰 주 버튼이 "Combine!" → "Try another" (초기화)로 전환**. 선택을 바꾸면 다시 Combine 으로 (피드백 #3) — 85623a5
- [x] LAB-1.5.2 [FE] P0 AI Grammar Lab: 생성 후 결과를 보려고 아래로 스크롤해야 함 → **생성 후 한 화면에 결과가 예쁘게**: 예) 입력부를 한 줄 요약 바(원문 + Edit)로 접고 결과 카드가 화면을 채움 / 또는 결과 전용 화면·시트. 원문 vs 변형 비교가 한눈에, 로딩도 그 자리에서 (피드백 #4) — 1e3c7f3
- [x] LAB-1.5.3 [FE] P1 TTS 를 `TtsHelper.speak()` 로 교체 — main 동기화 완료. 대상: `hangeul_lab_provider.dart:43`, `lab_screen.dart:44` 의 직접 `FlutterTts` 제거. 한글랩 단일 자모는 서버가 표준 읽기(ㄱ→기역)로 처리 — fbae653

### Step 1.6 캐릭터 적용 (10-01, 메인 PM 배포 · 명세 `docs/features/character/CHARACTER_API.md` **§3.0 공통 규칙 + §3.4**)
> P0 마감 **10/1 13:00**, P1 은 여유 시, 동결 15:00. 캐릭터 코드(`lib/shared/characters/**`) 수정 금지 → 필요하면 REQUESTS(char-lead 처리).
> 시작 전: `flutter pub get` + **앱 완전 재시작**(assets 추가). 각 태스크 완료 시 스크린샷을 `docs/features/character/screenshots/apply_<기능>_<ID>.png` 로도 저장(char-lead 리뷰).
- [x] LAB-1.6.1 [FE] P0 §3.4 **C1** — 한글랩 결과 카드 위 토끼 72 (조합 성공 happy) · 스크린샷 `apply_lab_C1.png` — 5f797ec
- [x] LAB-1.6.2 [FE] P0 §3.4 **C2** — 그래머랩 로딩 스피너 → 거북이 thinking 120 · 스크린샷 `apply_lab_C2.png` — f633627
- [x] LAB-1.6.3 [FE] P0 §3.4 **C3** — Combine 결과 설명 카드 머리에 거북이 talking 64 · 스크린샷 `apply_lab_C3.png` — f633627
- [x] LAB-1.6.4 [FE] P1 §3.4 **C4** — 그래머랩 오류 → 거북이 sad 96, 빈 상태 → 거북이 idle 96 · 스크린샷 `apply_lab_C4.png` — 3a21b9a
- [x] LAB-1.6.5 [FE] P1 (char-lead S-005 제안) Combine·Explore 결과 한국어 문장이 음절 단위로 줄바꿈됨(`안 마 / 셨어요`) → **단어(어절) 단위 줄바꿈** (말풍선과 같은 U+2060 WORD JOINER 방식, 복사·TTS 에는 원문 사용). 스크린샷 `apply_lab_wrap.png` — bbda55c

### Step 1.8 사용자 피드백 R4 (10-02 16:50) — 원문 스크린샷: `docs/feedback/r4/` (1_grammar_lab_input · 2_mission_setup · 3_home_cards)
- [x] LAB-1.8.1 [FE] (61873e8) P0 **AI Grammar Lab 입력 화면 UI/UX 재설계** — 지금은 Try 칩 / Explore Variations 칩 / Combine Modifiers 접힘이 위아래로 나열돼 "기능 2개"가 한눈에 안 들어오고 생김새도 제각각. → **두 모드를 명확히 구분**(예: 상단 세그먼트 `Explore | Combine` 또는 나란히 놓인 큰 모드 카드 2개 — 각 모드가 무엇을 하는지 한 줄 설명 + 아이콘), 입력창은 모드 위 공통 카드, Try 예문은 입력창 안/아래 가볍게, 실행 버튼은 하단 고정 1개(모드별 라벨). 단어장·미션 리디자인 톤(흰 카드·라운드 20~22·연보라 배경·primary 그림자) 맞추기. 빈 상태 거북이는 유지. 전후 스크린샷
- [x] LAB-1.8.2 [FE] (61873e8) P0 로딩 문구 컨셉화: "AI 가 만들고 있음" 류 문구 제거 → **거북이가 문장으로 실험 중** 컨셉(예: "Turtle is experimenting with your sentence…", 단계 문구 "Mixing grammar…", "Adding a pinch of politeness…", "Almost done!"), 거북이 thinking 유지(필요하면 talking/magic 은 쓰지 말고 thinking + 화면 쪽 플라스크·거품 등 가벼운 장식은 lab 폴더 안에서). 한글랩 쪽 문구도 같은 톤인지 점검

### Step 1.9 사용자 피드백 R5 (10-02 17:40) — 실험실 리브랜딩 · 원문 `docs/feedback/r5/1_lab_menu.png`
> 용어(D-24): 화면 이름 **Sentence Lab** = 코드·이전 문서의 "AI Grammar Lab". **코드 식별자(클래스·파일·API 경로·`LAB` 태스크 코드)는 바꾸지 않는다** — 화면 문구만.
- [x] LAB-1.9.1 [FE] (89a66e2) P0 화면 문구 이름 변경: `AI Grammar Lab` → **`Sentence Lab`** (메뉴 카드 제목, 화면 AppBar). 메뉴 부제 "Explore grammar rules with our AI assistant." → 거북이 실험 컨셉 문구(예: "Turtle experiments with your sentence — tense, politeness, negation."), 설명 어딘가에 작게 **AI-powered** 표기 유지(정직성). 코드 주석에 용어표 한 줄(`// Sentence Lab (UI name) == AI Grammar Lab (legacy code name)`)
- [x] LAB-1.9.2 [FE] (4fb6b24) P0 **Language Lab 메뉴 화면 실험실 무드 리디자인**: 앱 톤(연보라·흰 카드·라운드 20~22) 유지 + 모눈종이/실험 노트 느낌 배경, 비커·플라스크 등 실험 소품(코드로 그리기, 새 패키지 금지), 카드에 은은한 거품 애니메이션(접근성 disableAnimations 존중), 상단에 실험복 토끼·거북이(아래 CHR-1.8 의 `outfit: MaruOutfit.lab` — 머지 전에는 기본 옷으로 만들고 PM 동기화 후 교체). 한글랩 = 토끼(장난꾸러기 실험), 문장 실험실 = 거북이(진중한 실험)로 카드별 담당 캐릭터
- [ ] LAB-1.9.3 [FE] P1 한글랩·문장 실험실 화면의 캐릭터도 실험복(outfit lab)으로 — CHR-1.8 머지 후
