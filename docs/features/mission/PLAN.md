# MSN — Mission Chat PLAN

- 세션: `mission-be`, `mission-fe` · worktree `/Users/hadohadopapi/Desktop/Maru-wt/mission` · 브랜치 `feat/mission`
- 서버 :8083 · DB `maru_mission` · 시뮬레이터 iPhone Air
- 범위: 미션 설정 → 대화(토끼 연기 🐰 / 거북이 채점 🐢, 병렬 호출) → 힌트 → 수료증 발급·목록 · OpenAI(gpt-4o) · prompts
- 발표 주장(맞춰야 할 것): "제한된 대화·명확한 목표", "3-Zone 판정", "잘한 것·틀린 것·다음 목표 피드백 + 클리어증", "병렬 비동기 1.5초대"
- 참고: 홈의 Mission Chat 진입 버튼·트로피 아이콘은 PM 소유.
- 동결: 10/1 15:00 · 우선순위 P0 > P1 > P2 · OpenAI 호출 비용 주의(테스트는 짧게)

## Phase 1 — 기능 수정

### Step 1.1 현황 점검
- [x] MSN-1.1.1 [BE] P0 서버 기동, `/api/v1/mission-chat/{setup,chat,suggestion,clearance,clearances}` 실제 호출 → `API_CONTRACT.md` 에 현재 요청/응답 기록 (특히 turn 응답의 zone/상태 값 목록). `MissionChatControllerTest`·`MissionChatDtoTest` 결과 기록 — 문서만(API_CONTRACT §1), 테스트 6/6 통과
- [x] MSN-1.1.3 [BE] P0 **가장 먼저**: `MissionChatDtoTest.java:20`·`MissionChatControllerTest.java:37` 컴파일 오류(`MissionSetupRequestDto.formality()` 없음) 수정 → 모든 세션의 `./gradlew test` 차단 해소 (R-001) — f98f31a
- [x] MSN-1.1.2 [FE] P0 설정 → 대화 → 수료증 → 목록 완주 점검, 새 문제는 태스크 추가 ✅ fd58a75 (새 문제 1.1.4~1.1.8)
- [x] MSN-1.1.4 [FE] P0 (1.1.2 발견) history 에 userMessage 중복 → **FE 수정 안 함**: API_CONTRACT 1-2 대로 BE MSN-1.2.5 에서 서버측 중복 제거. FE 는 계약대로 이번 userMessage 포함 전송 유지
- [x] MSN-1.1.5 [FE] P1 (1.1.2 발견) 거북이 즉시 교정(immediate)으로 막힌 문장이 이후 history·턴 수에 포함됨 → 화면엔 흐리게 "Not sent" 표시, history 제외 ✅ fd58a75
- [x] MSN-1.1.6 [FE] P0 (1.1.2 발견) `clearancesProvider`(FutureProvider) 가 새 수료증 발급 후 갱신 안 됨 → 발급 후 invalidate 는 fd58a75 에 포함(시뮬레이터 확인). 남은 것: 목록 당겨서 새로고침(1.4.2 와 함께) ✅ fac4381 (발급 후 invalidate + 당겨서 새로고침)
- [x] MSN-1.1.7 [FE] P1 (1.1.2 발견) 힌트 로딩 시트를 사용자가 내려서 닫으면 이후 `Navigator.pop` 이 채팅 화면 자체를 닫음 (`mission_chat_screen.dart:67`) → 한 시트 안에서 FutureBuilder 로 로딩/오류/결과 ✅ 0f3ece2 (시트 하나에서 로딩/오류+Retry/결과, 로딩 중 닫아도 채팅 유지)
- [x] MSN-1.1.8 [FE] P1 (1.1.2 발견) 수료증 목록에서 항목 탭 시 `notifier.state =` 직접 대입(analyze 경고 2건) → 수료증 화면이 clearance 를 인자로 받도록 ✅ fac4381 (수료증 화면이 clearance 인자로 받음, analyze 경고 0)

### Step 1.2 오류·상태 처리 (P0)
- [x] MSN-1.2.1 [BE] P0 OpenAI 오류·타임아웃·JSON 파싱 실패 시 적절한 HTTP 오류 + 사용자용 메시지 (200+null 금지) — 1a0fd31
- [x] MSN-1.2.2 [FE] P0 대화 중 오류 → 채팅에 오류 표시 + 재전송 버튼 (실사 §2-C, `mission_chat_provider.dart:139-144`, `mission_chat_screen.dart`) ✅ fd58a75
- [x] MSN-1.2.3 [FE] P0 `failed` 상태 처리 분기 추가 (실사 §2-A) ✅ fd58a75 (현재 '실패 배너 → See Feedback' 로 수료증 요청. 1.3.1/1.3.3 후 결과 표시 연결)
- [x] MSN-1.2.5 [BE] P0 `/chat` 사용자 메시지 중복 전송 수정: FE history 에 이번 userMessage 가 이미 포함 → `ChatTurnService` 가 또 붙여서 AI 가 같은 문장을 2번 받음. history 마지막이 같은 user 메시지면 붙이지 않기 (FE 수정 불필요, 발견: 1.1.1) — 5aee88d
- [x] MSN-1.2.6 [BE] P1 (mission-fe 발견 09-30) `/chat` correction 필드가 JSON null 대신 **문자열 "null"** 로 오는 경우 있음 (예: severity none 인데 `turtleFeedbackEn:"null"`, immediate 인데 4필드 모두 "null"). 서버에서 "null"/빈 문자열 → null 정규화. FE 는 ece6742 에서 방어 처리함 — 1453137
- [x] MSN-1.2.4 [FE] P1 응답 대기 중 상대 "typing…" 버블, 설정 로딩 문구 "Getting ready to transform..." → 기능에 맞게 (실사 §8-P1#14,16, `mission_setup_screen.dart:79`, `mission_chat_screen.dart:363-370`) ✅ f4e66c8 (🐰 ••• 버블, 설정 로딩 'Creating your mission…' + 설명)

### Step 1.3 판정·수료증 정직화 (발표 "명확한 목표" 사실화)
- [x] MSN-1.3.1 [BE] P0 수료증 결과를 실제 판정으로: `clearance_system.txt` 의 `"result": "클리어"` 고정 제거 → 목표 달성 여부에 따라 cleared / not cleared(재도전 권유), 피드백(잘한 표현·고칠 표현·다음 목표)은 항상 제공 (실사 §3-C, §8-P1#17) — 587ae27
- [x] MSN-1.3.2 [BE+FE 조율] P0 발급 트리거: FE 가 `minTurns + 2` 도달 시 무조건 발급 요청하는 로직(`mission_chat_provider.dart:127-137`) → 거북이 판정(목표 달성 zone) 기반 종료 + 최대 턴 도달 시 종료. 규칙을 API_CONTRACT 에 먼저 합의 후 구현 — **BE 부분 완료 db3a180** (API_CONTRACT §1-7). FE 부분(강제발급 삭제, failed 도 /clearance) 남음 ✅ FE fac4381 (cleared/failed → 입력 잠금·자동 /clearance(missionStatus 전달), min+2 강제발급 삭제, Turn n/max 표시)
- [x] MSN-1.3.3 [FE] P0 수료증 화면·목록이 cleared/not cleared 를 구분해 표시 ✅ fac4381 (Cleared/Not cleared yet/Completed, 판정 이유·목표 표시, 'Try This Mission Again')
- [x] MSN-1.3.4 [BE] P2 미사용 `prompts/chat_turn_system.txt` 정리 — e92129f (삭제, 참조 0건 확인)
- [x] MSN-1.3.5 [BE] P2 (mission-fe 발견) 수료증 `resultReason` 이 "The student only…" 3인칭 → 학습자에게 보이는 문장이라 "You …" 2인칭으로 (clearance 프롬프트) — 326c19b

### Step 1.4 UX 정리 (P1)
- [x] MSN-1.4.1 [FE] P1 `teal` 하드코딩 → theme 색, 한국어/영어 문구 혼용 정리. 추가: 즉시교정 배너에 `(honorific_mismatch)` 같은 코드값 노출 → 사람이 읽는 라벨, 대화 종료 후 전송 아이콘이 활성색 그대로 ✅ ece6742 (teal/grey→colorScheme, 교정 라벨 'Politeness level' 등, 비활성 전송 아이콘, "null" 문자열 방어, 배너 변화 시 자동 스크롤)
- [x] MSN-1.4.2 [FE] P1 수료증 목록 빈 상태·오류 상태 ✅ fac4381+82c39d4 (빈 상태 문구, 오류+Retry, Riverpod 자동재시도 끔, 서버 message 사용)
- [x] MSN-1.4.3 [BE] P2 병렬 호출 응답시간 측정 로그(발표 "1.5초대" 근거) — 요청당 소요 ms 를 INFO 로 (내용·키 제외) — e92129f

### Step 1.6 캐릭터 적용 (10-01, 메인 PM 배포 · 명세 `docs/features/character/CHARACTER_API.md` **§3.0 공통 규칙 + §3.3**)
> P0 마감 **10/1 13:00**, P1 은 여유 시, 동결 15:00. 캐릭터 코드(`lib/shared/characters/**`) 수정 금지 → 필요하면 REQUESTS(char-lead 처리).
> 시작 전: `flutter pub get` + **앱 완전 재시작**(assets 추가). 각 태스크 완료 시 스크린샷을 `docs/features/character/screenshots/apply_<기능>_<ID>.png` 로도 저장(char-lead 리뷰).
- [x] MSN-1.6.1 [FE] P0 §3.3 **C1** — 상대 메시지 🐰 아바타 → 토끼 40 · 스크린샷 `apply_mission_C1.png` ✅ 763a5ca
- [x] MSN-1.6.2 [FE] P0 §3.3 **C2** — 입력 중 버블 🐰 → 토끼 thinking 40 · 스크린샷 `apply_mission_C2.png` ✅ 763a5ca
- [x] MSN-1.6.3 [FE] P0 §3.3 **C3** — 교정 박스 🐢 → 거북이 40 · 스크린샷 `apply_mission_C3.png` ✅ 763a5ca
- [x] MSN-1.6.4 [FE] P0 §3.3 **C4** — 즉시 교정 배너 🐢 → 거북이 thinking 48 (새 교정마다 반응) · 스크린샷 `apply_mission_C4.png` ✅ 8a94d90 (+ 실제 AI 교정 예시 apply_mission_C4_real_correction.png)
- [x] MSN-1.6.5 [FE] P0 §3.3 **C5** — 수료증 1페이지 상단: cleared → 토끼 cheer+거북이 happy / not → 토끼 sad+거북이 idle · 스크린샷 `apply_mission_C5.png` ✅ b93560a (cleared: apply_mission_C5.png — cleared 는 프록시로 강제, not cleared: apply_mission_C5_not_cleared.png — 실제 BE 판정)
- [x] MSN-1.6.6 [FE] P1 §3.3 **C6** — 수료증 판정 이유·Tutor's Note 🐢 → 거북이 40 · 스크린샷 `apply_mission_C6.png` ✅ 58b7f1d (+ apply_mission_C6_tutor_note.png)
- [x] MSN-1.6.7 [FE] P1 §3.3 **C7** — 미션 설정 로딩 🐰 → 토끼 thinking 120 · 스크린샷 `apply_mission_C7.png` ✅ c3b7d4b
- [x] MSN-1.6.8 [FE] P1 §3.3 **C8** — 실패 배너 🐢 → 거북이 sad 40 (버튼·Not sent 이모지는 유지) · 스크린샷 `apply_mission_C8.png` ✅ ad0cbcb

### Step 1.7 사용자 피드백 R3 (10-01 12:30) — 원문: `/Users/hadohadopapi/Downloads/2번째_수정사항.pdf` (스크린샷 포함)
> 세션 3개가 같은 worktree 를 **파일 기준으로 나눠** 작업:
> - `mission-be`: `backend/**` (미션 소유 BE 파일)
> - `mission-fe`: 채팅 화면 — `screens/mission_chat_screen.dart`, `widgets/chat_bubble_widget.dart`, `widgets/typing_bubble_widget.dart`, `widgets/suggestion_sheet.dart`, `providers/mission_chat_provider.dart`, `models/**`, `repositories/**`
> - `mission-fe2` (새 세션): `screens/mission_setup_screen.dart`, `screens/mission_clearance_screen.dart`, `screens/mission_clearance_list_screen.dart` (+ 이 화면 전용 새 위젯 파일은 `widgets/setup_*`, `widgets/clearance_*` 이름으로)
> - 위 목록 밖의 미션 파일이 필요하면 짝 세션과 STATUS 메모로 먼저 조율. 커밋은 `git commit -- <경로>` 만.

#### mission-be
- [x] MSN-1.7.1 [BE] P0 (피드백 #5) 수료증 "Great Expressions / 고칠 표현"에 **사용자가 보내지 않은 문장**(Help me Turtle 제안 문장)이 나옴 → ① history 에서 role=user 문장만 뽑아 번호 목록으로 AI 에 후보 제공, 프롬프트에 "후보 문장만 원문 그대로 인용" 명시 ② AI 응답의 각 인용 문장이 실제 사용자 문장에 포함되는지 서버에서 검증(공백·문장부호 정규화), 아니면 제거 ③ 테스트 추가. API 모양 변경 없음 ✅ a186f8c
#### mission-fe (채팅 화면)
- [ ] MSN-1.7.2 [FE] P0 (피드백 #5 FE) Help me Turtle 제안 문장이 `/chat`·`/clearance` history 에 사용자/상대 발화로 섞이지 않게 (제안은 화면 표시 전용)
- [ ] MSN-1.7.3 [FE] P0 (피드백 #3) 교정 카드 색: **치명적·즉시 교정 = 🟥 레드카드(빨강 계열)**, **사소한 실수(side) = 🟨 옐로카드(노랑 계열)** 로 원래 설계 복원 + 카드 라벨("Red card"/"Yellow card") 표시. 현재는 둘 다 분홍
- [ ] MSN-1.7.4 [FE] P0 (스크린샷 발견) 교정 문구에서 자모 낱글자(예: 'ㅛ') 주변이 깨진 글자(▯)로 표시됨 → 원인(줄바꿈용 U+2060 삽입 등) 찾아 수정. 한글 자모·영문·따옴표 혼합 문장으로 확인
- [ ] MSN-1.7.5 [FE] P0 (피드백 #3) 상단 미션 설명 패널 **접기/펼치기**: 기본 접힘 = 미션 제목 + Turn n/max + 목표 한 줄(말줄임), 탭/화살표로 전체 펼침
- [ ] MSN-1.7.6 [FE] P0 (피드백 #3) **채팅방 전체 비주얼 리디자인** — 단어장 리디자인 수준의 미감(`docs/features/vocab/screenshots/r2/` 참고): 헤더·말풍선(상대/나)·번역 버튼·교정 카드·입력창·Help me Turtle 버튼·여백·타이포. 캐릭터 아바타 유지. 전후 스크린샷 LOG 에
#### mission-fe2 (설정·리포트 화면, 새 세션)
- [x] MSN-1.7.7 [FE] P0 (피드백 #2) 미션 생성 로딩 = **"장난꾸러기 토끼가 사용자가 고른 역할로 변신 중"** 컨셉: 문구에 사용자가 입력한 역할 사용(예: "Tokki is transforming into a café barista…"), 변신 연출(빙글 회전·펑 연기·반짝이). 캐릭터는 `MaruMood.magic`(캐릭터 팀이 추가 중, CHR-1.7) — 머지 전엔 `thinking` 으로 만들고 PM 이 동기화 알리면 교체 ✅ 33f2780 (mission-fe2: widgets/setup_transform_loading.dart, 지금은 thinking + 화면 쪽 회전·펑·반짝이 임시 연출 — magic 머지 시 `_transformMood`=magic, `_screenEffects`=false 두 줄 교체. 시뮬레이터 미확인)
- [x] MSN-1.7.8 [FE] P0 (피드백 #4) 리포트에서 미달성(cleared=false)일 때 **토끼가 울지 않게**: 토끼 thinking(또는 idle) + 거북이 응원 톤, 문구 "Almost there!" 류의 긍정 톤. cleared=true 는 지금처럼 cheer ✅ 880e8bf (mission-fe2: 미달성 = rabbit thinking + turtle happy(entrance), 앱바 'Almost there!', 응원 문장, Result 'Almost there — one more try!'. 시뮬레이터 미확인)
- [x] MSN-1.7.9 [FE] P1 미션 설정 폼·리포트 4페이지·수료증 목록을 채팅방(MSN-1.7.6)과 같은 디자인 톤으로 정리 (mission-fe 와 색·라운드·타이포 맞추기 — STATUS 메모로 조율) ✅ 337a365 (mission-fe2: 공용 `widgets/clearance_style.dart` — 흰 카드 r24·보라 그림자·primary 그라데이션 히어로·아이콘 타일·pill. 설정 = 히어로+토끼, 관계 3택 타일, 친밀도 칩, 역할/성격 입력+추천 칩(서버로 보내는 값 동일). 리포트 = 미션 제목 헤드라인·결과 pill·정보 묶음·페이지별 섹션 헤더·Next Goal 그라데이션·애니 점 표시. 목록 = 실제 개수 히어로 + 카드·상태 pill·빈 상태 토끼. 위젯 테스트 393/320w overflow 없음. 시뮬레이터 미확인, mission-fe 채팅 톤 확정 후 색 미세조정 가능)
