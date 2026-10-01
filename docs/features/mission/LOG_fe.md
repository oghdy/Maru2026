# MSN — Mission Chat — FE 세션 로그 (`mission-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음. **Step 1.7 내 태스크(1.7.2~1.7.6) 전부 완료** — 마지막 1516ebe
- 다음 할 일: 대기. mission-fe2 가 1.7.9(설정·리포트 톤 맞추기) 하면서 요청하는 것 있으면 처리
- 막힌 것 / 기다리는 것: 없음
- 실행 중인 것: BE :8083 (mission-be), 테스트 프록시 :8093(플래그 전부 제거). iPhone Air 앱의 flutter run 은 13:30경 종료됨 — 다시 띄우려면 `flutter run -d FE45C935-… --dart-define=API_PORT=8083 --dart-define=DEV_JWT=$TOKEN`
- 주의: 재시작 신호(kill -USR1/-USR2)는 `ps -eo pid,args | grep flutter_tools.snapshot | grep <UDID>` 로 찾은 pid 에만. 셸까지 잡으면 flutter run 이 죽음
- 마지막 커밋: 1516ebe
- 짝 세션에게(mission-fe2): 채팅 디자인 토큰 = 페이지 배경 `Color.alphaBlend(primary α0.06, surface)`, 카드 흰색(surface)·라운드 20~22·그림자 `primary α0.08~0.10 blur 14~18 y4~6`, 칩 `primaryContainer`·StadiumBorder, 제목 w800. 레드/옐로 카드는 `widgets/chat_correction_card.dart`(리포트에서 써도 됨)

## 기록 (시간순 추가만, 수정 금지)

### 09-30 19:40 · MSN-1.1.2 코드 점검 (시뮬레이터 확인 전)
- 흐름 코드 읽기: 설정 → 대화 → 수료증 → 목록. 새 문제 5건 → PLAN 1.1.4~1.1.8 추가.
- 1.1.4(history 중복)는 API_CONTRACT 1-2 확인 결과 BE MSN-1.2.5 담당 → FE 는 계약대로 유지(처음엔 FE 에서 제외했다가 되돌림). 1.2.2/1.2.3/1.1.5 구현: provider 에서 `error` 상태 제거(오류는 errorMessage+failedAction 로), 전송 실패 메시지에 Retry, 수료증 발급 실패 배너+Retry, 설정 실패 스낵바+Retry, `failed` → "Mission not completed" 배너(See Feedback / New Mission), 사용자 문구는 예외 원문 대신 영어 안내문(`missionErrorMessage`).
- `flutter analyze lib/features/mission_chat`: 새 경고 없음(기존 3건: list_screen state 대입 2 → 1.1.8, clearance_screen withOpacity 1 → 1.3.3 때 정리).
- 시뮬레이터: **미확인** (도구 접근 권한 대기).

### 09-30 21:25 · MSN-1.1.2 / 1.1.5 / 1.2.2 / 1.2.3 완료 — fd58a75
- 시뮬레이터(iPhone Air, 프록시 :8093 경유)에서 확인:
  - 설정 → 대화: 정상 (미션 생성 ~7s, 턴 ~3s, 힌트 시트 정상)
  - 설정 실패(프록시 끔): 처음엔 스낵바+Retry 였으나 4초 후 사라져 Retry 를 못 누름 → 폼 안 **고정 오류 카드 + Retry** 로 변경. Retry → 미션 생성 성공 확인
  - 전송 실패: 내 문장 흐리게 + "Couldn't send · Retry" + 상단 오류 배너(닫기). Retry → 정상 답변, 배너 사라짐
  - `failed`(프록시로 missionStatus 강제): "Mission not completed" 배너, 입력·힌트 비활성, New Mission / See Feedback
  - 수료증 발급 실패(프록시 500): "Couldn't create your feedback report…" + Retry, 대화 유지. Retry → 수료증 화면
  - 수료증 목록: 방금 발급한 수료증 바로 보임(invalidate 동작)
  - 즉시교정(프록시로 severity=immediate): 문장 흐리게 + "🐢 Not sent — try saying it again", 다음 요청 history 에서 제외됨(flutter 로그의 요청 본문으로 확인)
- 확인된 남은 문제: 수료증 화면이 failed 여도 "Mission Cleared! 🎉 / Cleared" (→1.3.3), 즉시교정 배너 코드값 노출·종료 후 전송 아이콘 색(→1.4.1에 추가)
- analyze: 새 경고 없음 (기존 3건 유지: list_screen 2 → 1.1.8, clearance_screen withOpacity 1)

### 09-30 21:50 · MSN-1.3.2(FE) / 1.3.3 / 1.1.6 / 1.1.8 / 1.4.2 — fac4381, 82c39d4
- API_CONTRACT §1-7(BE 구현 완료) 기준으로 구현. /chat 새 필드(userTurn·maxTurns·zone), /clearance 새 필드(cleared·resultReason·goalCondition) 사용.
- 시뮬레이터 확인(프록시로 상태 강제, 판정은 실제 BE):
  - failed 턴 → 입력 잠김, "Mission not completed. Preparing your feedback..." → 결과 화면 "Mission Result / MISSION REPORT / Not cleared yet — try again" + 실제 BE 판정 이유·목표, 빈 교정 목록 문구, 'Try This Mission Again' → 같은 미션 Turn 0/10 으로 재시작
  - cleared(+force_cleared=true) → "Mission Cleared! 🎉 / CERTIFICATE OF COMPLETION", 금색 테두리
  - 미션 카드 "Turn n/max" 표시 (setup 직후 0/10, 한 턴 후 1/10)
  - 목록: Not cleared/Cleared/Completed 배지, 항목 → 결과 화면 → 뒤로 = 목록으로 복귀(전엔 홈으로)
  - 목록 오류(force_500 /clearances): 처음엔 Riverpod 3 자동 재시도로 ~10회 스피너 → retry 끔(82c39d4) → 즉시 오류+Retry, Retry 로 복구. 오류 문구는 계약 §1-6 대로 서버 message 사용
- 미확인: 목록 당겨서 새로고침 제스처 자체(오류 테스트 중 스피너만 봄), 목록 빈 상태(이 계정은 수료증 있음), 실제 LLM 이 cleared 를 주는 긴 대화(비용상 프록시로 대체)
- analyze: No issues found

### 09-30 22:15 · MSN-1.2.4 / 1.1.7 / 1.4.1 — f4e66c8, 0f3ece2, ece6742
- 1.2.4: 응답 대기 중 🐰 ••• 버블(프록시 delay 로 확인), 설정 로딩 "Creating your mission..." + 설명문 (확인)
- 1.1.7: 힌트 시트를 한 개로(로딩/오류+Retry/결과). 로딩 중 바깥 탭으로 닫고 응답 도착 → 채팅 화면 유지 확인(예전엔 pop 됨). 시트 오류(force_500 /suggestion) → Retry → 제안 표시, 제안 탭 → 입력칸 채움+시트만 닫힘 확인. 중간에 `setState(() => _future = …)` 가 Future 반환 assertion → 블록으로 수정
- 1.4.1: teal/grey → colorScheme (설정 버튼·말풍선·미션카드 보라 계열 확인), 즉시교정 배너 "(Politeness level)", 대화 종료 시 전송 아이콘 회색, 배너 생길 때 마지막 메시지가 가려지던 문제 → 상태 변화 시 자동 스크롤(확인)
- 발견: BE 가 correction 필드를 문자열 "null" 로 보내는 경우 있음 → 화면에 "null" 노출됐음. FE 방어(_text) 추가 + PLAN MSN-1.2.6 [BE] 추가. resultReason 3인칭 → MSN-1.3.5 [BE] 추가
- analyze: No issues found
- 미확인(전 기간): 실제 LLM 이 cleared 를 주는 긴 대화(프록시로 대체), 목록 빈 상태, 다크모드

### 10-01 12:45 · MSN-1.6.1~1.6.8 캐릭터 적용 — 763a5ca, 8a94d90, b93560a, 58b7f1d, c3b7d4b, ad0cbcb
- 명세 CHARACTER_API §3.0·§3.3 그대로. import 는 barrel 하나, 캐릭터 코드 수정 없음, 로직·상태 변경 없음(기존 상태에 mood 만 연결)
- pub get + 앱 완전 재실행 후 확인. 서버가 꺼져 있어 scripts/run_backend.sh mission 으로 직접 기동
- 이벤트를 프록시(:8093)로 강제해 시뮬레이터에서 직접 발생 → 스크린샷 docs/features/character/screenshots/apply_mission_C1~C8.png (+ C4_real_correction, C5_not_cleared, C6_tutor_note)
  - C1 상대 아바타 rabbit idle 40 / C2 입력 중 rabbit thinking 40 (지연 8s 중 캡처) / C3 side 교정 turtle idle 40
  - C4 즉시 교정 turtle thinking 48, reactionKey = 교정 객체(새 응답마다 새 객체). 실제 AI 교정(반말 지적)으로도 확인
  - C5 not cleared = 실제 BE 판정으로 sad rabbit + idle turtle / cleared = 프록시 강제로 cheer rabbit + happy turtle(entrance). 위 여백 28 + 아래 16, 고정 높이·Clip 없음
  - C6 판정 이유·Tutor's Note turtle idle 40 / C7 설정 로딩 rabbit thinking 120 (위 여백 30) / C8 실패 배너 turtle sad 40, 'Help me Turtle' 버튼·'🐢 Not sent' 이모지는 명세대로 유지
- analyze: No issues found
- 참고: BE 가 resultReason 을 이제 2인칭("You …")으로 줌(1.3.5 반영된 듯)
- 미확인: 애니메이션 자체(정지 스크린샷만), 접근성 reduce-motion


### 10-01 13:00 · [mission-fe2] MSN-1.7.7 / 1.7.8 — 33f2780, 880e8bf
- 1.7.7: `widgets/setup_transform_loading.dart` 새로 만듦(설정 화면 settingUp 때 표시). 문구 "MAGIC IN PROGRESS / Tokki is transforming into “<입력한 역할>”..." (역할 빈칸이면 "your conversation partner"), 2.6s 주기마다 단계 문구 변경(Waving the magic wand… → Almost ready to chat!), 가는 진행 바 + "Your mission and partner are being created. This takes a few seconds."(정직 표시 유지)
  - 캐릭터: rabbit `thinking` 120 (magic 아직 없음). 임시 연출은 화면 쪽: Y축 360° 회전 → 펑 연기(구름 9개) + 반짝이 버스트 → 주변을 도는 반짝이 7개. reduce motion 이면 정지
  - **magic 머지 후 교체할 것**: 파일 상단 `_transformMood = MaruMood.magic`, `_screenEffects = false` (CHARACTER_API v1.2 C7: 변신 연출은 캐릭터가 하므로 화면에서 따로 그리지 말 것)
  - 위젯 테스트 `test/features/mission_chat/setup_transform_loading_test.dart` 2개 통과(역할 문구·단계 문구 전환·빈 역할·reduce motion 예외 없음)
- 1.7.8: 미달성 리포트 = rabbit thinking 110 + turtle happy 110(entrance), 앱바 "Almost there!", 제목 아래 "You're so close! Check the turtle's tips and give it another go.", Result 줄 "Almost there — one more try!". cleared=true 는 그대로
- analyze: No issues found
- **미확인(시뮬레이터)**: iPhone 16 부팅 명령과 /setup 지연용 테스트 프록시(:8094)가 Claude Code 권한 분류기에 막힘 → 사용자에게 확인 요청함. 화면 스크린샷 없음

### 10-01 13:20 · [mission-fe2] MSN-1.7.9 디자인 정리 — 337a365
- 기준: vocab r2 스크린샷 톤(흰 카드·큰 라운드·그라데이션 히어로). mission-fe 채팅 리디자인 값이 아직 없어 이 톤으로 먼저 맞춤. 공용 스타일 `widgets/clearance_style.dart`(missionCardDecoration r24·primary α.08 그림자, missionHeroGradient, MissionIconTile, MissionPill, MissionSectionHeader)
- 설정: 배경 surfaceContainerLow, 히어로 "Set your scenario" + 토끼 happy 56(compact), 관계 = 드롭다운 → 3개 선택 타일(이모지·제목·"Use respectful Korean" 힌트, **서버로 보내는 문자열은 그대로**), 친밀도 = 칩, 역할 "Who should Tokki become?"/성격 = 채운 입력칸 + 추천 칩(탭하면 입력), 시작 버튼 56 높이 r18
- 리포트: 미션 제목 헤드라인 + 결과 pill + Goal/Partner/Turns 묶음, 페이지 2·3·4 섹션 헤더(아이콘 타일·개수), 표현·교정 항목을 각각 둥근 카드로(교정 ✕ error 취소선 / ✓ primary), Tutor's Note 거북이 + Next Goal 그라데이션 카드, 페이지 점 = 활성 시 길어지는 pill. cleared=true 금색 테두리 유지. 캐릭터 2개는 좁은 폭에서 72~110 으로 축소(320w 에서 넘침 발견 → 수정)
- 목록: 히어로 "Your mission reports · n missions · m cleared"(실제 개수), 카드 = 아이콘 타일·제목·상대·날짜·상태 pill, 빈 상태 = 토끼 idle 120 + "No missions yet"
- 위젯 테스트 `test/features/mission_chat/setup_and_report_layout_test.dart` 13개 + 로딩 2개 = 15개 통과 (393×852, 320×640 에서 overflow 없음, 칩 탭 → 입력, 미달성 문구, 4페이지 스와이프, 목록 개수)
- analyze: No issues found
- **미확인**: 시뮬레이터 화면(부팅 권한 막힘), 다크모드, 실제 미션 생성 중 로딩 화면

### 10-01 12:50 · [mission-fe2] 시뮬레이터 확인 (iPhone 16 6E1100F0, :8083) — 6a64df4
- PM 허가로 flutter pub get → flutter run. 실제 미션 생성 1회(OpenAI 1콜, 역할 칩 "Cafe staff"·성격 "Friendly") 중 simctl 연속 캡처. 리포트는 기존 수료증 목록에서 열어 확인(추가 OpenAI 호출 없음)
- 확인됨:
  - 설정 폼: 히어로+토끼, 관계 타일 3개(선택 테두리·체크), 친밀도 칩, 역할/성격 추천 칩 탭 → 입력칸 채워짐, Start 버튼 — `docs/features/mission/screenshots/r3_fe2/1_setup_top.png`, `2_setup_inputs.png`
  - 로딩(1.7.7): "Tokki is transforming into “Cafe staff”...", Y축 회전(측면 프레임) → 펑 구름 → 반짝이, 단계 문구 "Waving the magic wand..." → "Picking the right costume...", 생성 후 채팅 화면으로 정상 전환 — `3_loading_spin.png`, `4_loading_poof.png`, `5_loading_sparkle_step2.png`, `6_chat_after_setup.png`
  - 목록: "6 missions · 0 cleared"(실제 개수), 카드·Not cleared pill — `7_certificate_list.png`. 미달성 아이콘 타일이 회색이라 칙칙해서 primary 틴트로 변경(6a64df4, hot reload 후 재캡처)
  - 리포트 미달성(1.7.8): 토끼 thinking + 거북이 happy, 앱바 "Almost there!", 응원 문장·pill — `8_report_p1_not_cleared.png`; 2~4페이지 — `9_report_p2.png`, `10_report_p3.png`, `11_report_p4.png`
- 테스트 15개 통과, analyze No issues
- 미확인: cleared=true 리포트 실제 화면(이 계정 수료증 6개 모두 미달성 — 위젯 테스트로만 확인), 다크모드, magic 표정(머지 대기)
- 색: mission-fe 가 STATUS 에 채팅 톤을 아직 안 올려서 현재 상태로 커밋. 올라오면 clearance_style.dart 에서 맞춤

### 10-01 13:15 · Step 1.7 시작 (R3) — MSN-1.7.2 확인, MSN-1.7.4 646f6ba
- 환경: main 동기화 후 pub get + 앱 재실행. scratchpad 가 비워져 테스트 프록시(:8093) 재작성(force_feedback 플래그 추가, /chat·/clearance 요청 본문을 requests.log 에 기록).
  ⚠ 재시작 신호는 `flutter_tools.snapshot` 프로세스에만 보낼 것 — `pgrep -f "run -d …"` 는 감싼 셸까지 잡아 flutter run 을 죽임(오늘 앱이 몇 번 꺼진 원인)
- 1.7.2: 코드상 제안은 입력칸만 채우고 messages/history 경로 없음. 시뮬레이터: 제안 시트 열고 → 닫고 → '안녕하세요' 직접 입력 전송 → /chat 본문 = [assistant 첫 인사, user 안녕하세요] 뿐(제안 2개 없음). 제안을 골라 그대로 보내는 건 실제 발화라 포함(의도). 수료증 엉뚱한 문장은 AI 인용 문제 → BE 1.7.1
- 1.7.4: iPhone Air(iOS 26)에선 재현 안 됨. 사용자 기기와 같은 iOS 18.5 가 필요해 **표에 배정 안 된 iPhone 16e(24BD252A, iOS 18.5)** 를 잠깐 빌려 재현 후 shutdown. 프록시로 교정문에 후보 문자 주입:
  - 호환 자모 ㅛ(U+315B)·조합형 단독(U+116D)·U+2060 → 정상
  - **필러+조합형(U+115F U+116D)** → 사용자 스크린샷과 같은 ▯ (원인 확정), 중성필러 U+1160·반각 자모 U+FFD2 도 ▯
  - 수정: models/korean_text.dart `cleanKoreanText` — 조합형 시퀀스는 완성형 음절로, 단독·반각 자모는 호환 자모로, 필러·zero-width 제거. 모든 AI 텍스트 필드(교정·토끼 답·설정·제안·수료증 모델)에 적용. `flutter test test/features/mission_chat/korean_text_test.dart` 7/7. 수정 후 iOS 18.5 에서 ▯ 0개 확인

### 10-01 13:20 · MSN-1.7.3 dee49a6, MSN-1.7.5 f803129
- 1.7.3: 새 위젯 `widgets/chat_correction_card.dart` (채팅 전용 새 파일은 `chat_*` 이름 — fe2 의 setup_/clearance_ 와 안 겹치게). 즉시교정 = Red card(빨강, 거북이 thinking 48·reactionKey 유지), side = Yellow card(노랑, 거북이 idle 40). 이슈 라벨 칩(Politeness level 등). ChatMessage 에 turtleIssueType 추가(side 카드 라벨용, history JSON 엔 안 나감). 시뮬레이터: 사용자 원문 '아이스티 주세요ㅛ' 입력 → 프록시로 side/immediate 강제 → 노랑·빨강 카드 확인
- 1.7.5: `widgets/chat_mission_panel.dart` — 기본 접힘(MISSION 라벨·제목 1줄·Turn n/max 칩·진행바·목표 1줄), 탭하면 설명·전체 목표 펼침(AnimatedSize). 접힘/펼침 둘 다 확인
- analyze: No issues found

### 10-01 13:25 · MSN-1.7.6 채팅방 리디자인 — 1516ebe
- 참고: vocab r2(라벤더 배경 + 흰 카드 + 그림자 + 굵은 제목 + 칩). 캐릭터 아바타 유지
- 바뀐 것: 페이지 라벤더 배경 / 헤더 'Mission Chat' + 'Tokki as <역할>' / 미션 카드(1.7.5) / 상대 말풍선 = 흰색+그림자+꼬리 모서리 6 / 내 말풍선 = 보라 그라데이션+그림자 / 번역 = 전체폭 버튼 → 작은 'Translate' 알약, 펼치면 왼쪽 선 인용 스타일 / 입력바 = 위 라운드 26 흰 시트 + 'Help me Turtle' 칩 + 알약 입력칸(여러 줄) + 둥근 ↑ 전송 버튼 / 대화 종료 시 'Conversation finished' / 실패·오류 배너 라운드 통일
- 전후 스크린샷 (docs/features/mission/screenshots/):
  - before: MSN-1.7.6_before_chat.png (R3 전, 분홍 교정·큰 미션 패널·회색 말풍선)
  - after: MSN-1.7.6_after_1_start.png(시작), _after_2_chat.png(번역 펼침+내 말풍선+옐로카드), _after_3_ended.png(실패 배너+오류 Retry+입력 비활성)
- 시뮬레이터 iPhone Air 에서 시작·대화·번역 토글·옐로카드·실패/오류 상태 확인. analyze: No issues found
- 미확인: 다크모드, 작은 화면(iPhone SE)


### 10-01 20:05 · [mission-fe2] MSN-1.7.7 magic 교체 + 화면 확인 — 0ff44eb
- main 동기화(d8a58b7: MaruMood.magic, rabbit_magic.png) 후 flutter pub get → 앱 완전 재시작(새 flutter run)
- `widgets/setup_transform_loading.dart`: mood = `MaruMood.magic`, 화면 쪽 회전·펑·반짝이 코드(`_MagicPainter`, `_spinTransform`, `_screenEffects`) **삭제** — CHARACTER_API v1.2 C7 대로 연출은 캐릭터가 함(이중 연출 없음). 캐릭터 위 여백 60·아래 24(점프·연기 공간). 문구·단계 문구·진행 바는 유지
- 시뮬레이터(iPhone 16, :8083 PM 기동) 실제 미션 생성 1회(OpenAI 1콜): 마술봉 든 rabbit_magic 표정 + "MAGIC IN PROGRESS / Tokki is transforming into your conversation partner..." 확인 → 생성 후 채팅 화면 정상 전환
  - 역할 칩 탭이 스크롤 직후라 안 먹어서 역할 빈칸으로 생성됨 → 빈 역할 대체 문구가 실기기에서 확인된 셈. 역할 입력 시 문구는 이전 확인(12:50, "Cafe staff") 그대로
  - 스크린샷: `docs/features/mission/screenshots/r3_fe2/12_loading_magic.png`, `13_chat_after_magic_setup.png`, char-lead 리뷰용 `docs/features/character/screenshots/apply_mission_magic.png`
- 위젯 테스트 15개 통과, analyze No issues
- **미확인**: magic 의 회전·펑·반짝이 순간 프레임 — 생성이 빨라(~2초) 연속 캡처 시작 전에 끝남. 정지 프레임 1장만 있음. 연출 자체는 캐릭터 팀 필름스트립(dev_CHR-1.7.3_rabbit_magic_*) 참고. 추가 OpenAI 호출은 하지 않음
