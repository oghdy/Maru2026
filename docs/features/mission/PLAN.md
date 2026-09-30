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
- [ ] MSN-1.2.6 [BE] P1 (mission-fe 발견 09-30) `/chat` correction 필드가 JSON null 대신 **문자열 "null"** 로 오는 경우 있음 (예: severity none 인데 `turtleFeedbackEn:"null"`, immediate 인데 4필드 모두 "null"). 서버에서 "null"/빈 문자열 → null 정규화. FE 는 ece6742 에서 방어 처리함
- [x] MSN-1.2.4 [FE] P1 응답 대기 중 상대 "typing…" 버블, 설정 로딩 문구 "Getting ready to transform..." → 기능에 맞게 (실사 §8-P1#14,16, `mission_setup_screen.dart:79`, `mission_chat_screen.dart:363-370`) ✅ f4e66c8 (🐰 ••• 버블, 설정 로딩 'Creating your mission…' + 설명)

### Step 1.3 판정·수료증 정직화 (발표 "명확한 목표" 사실화)
- [x] MSN-1.3.1 [BE] P0 수료증 결과를 실제 판정으로: `clearance_system.txt` 의 `"result": "클리어"` 고정 제거 → 목표 달성 여부에 따라 cleared / not cleared(재도전 권유), 피드백(잘한 표현·고칠 표현·다음 목표)은 항상 제공 (실사 §3-C, §8-P1#17) — 587ae27
- [x] MSN-1.3.2 [BE+FE 조율] P0 발급 트리거: FE 가 `minTurns + 2` 도달 시 무조건 발급 요청하는 로직(`mission_chat_provider.dart:127-137`) → 거북이 판정(목표 달성 zone) 기반 종료 + 최대 턴 도달 시 종료. 규칙을 API_CONTRACT 에 먼저 합의 후 구현 — **BE 부분 완료 db3a180** (API_CONTRACT §1-7). FE 부분(강제발급 삭제, failed 도 /clearance) 남음 ✅ FE fac4381 (cleared/failed → 입력 잠금·자동 /clearance(missionStatus 전달), min+2 강제발급 삭제, Turn n/max 표시)
- [x] MSN-1.3.3 [FE] P0 수료증 화면·목록이 cleared/not cleared 를 구분해 표시 ✅ fac4381 (Cleared/Not cleared yet/Completed, 판정 이유·목표 표시, 'Try This Mission Again')
- [x] MSN-1.3.4 [BE] P2 미사용 `prompts/chat_turn_system.txt` 정리 — e92129f (삭제, 참조 0건 확인)
- [ ] MSN-1.3.5 [BE] P2 (mission-fe 발견) 수료증 `resultReason` 이 "The student only…" 3인칭 → 학습자에게 보이는 문장이라 "You …" 2인칭으로 (clearance 프롬프트)

### Step 1.4 UX 정리 (P1)
- [x] MSN-1.4.1 [FE] P1 `teal` 하드코딩 → theme 색, 한국어/영어 문구 혼용 정리. 추가: 즉시교정 배너에 `(honorific_mismatch)` 같은 코드값 노출 → 사람이 읽는 라벨, 대화 종료 후 전송 아이콘이 활성색 그대로 ✅ ece6742 (teal/grey→colorScheme, 교정 라벨 'Politeness level' 등, 비활성 전송 아이콘, "null" 문자열 방어, 배너 변화 시 자동 스크롤)
- [x] MSN-1.4.2 [FE] P1 수료증 목록 빈 상태·오류 상태 ✅ fac4381+82c39d4 (빈 상태 문구, 오류+Retry, Riverpod 자동재시도 끔, 서버 message 사용)
- [x] MSN-1.4.3 [BE] P2 병렬 호출 응답시간 측정 로그(발표 "1.5초대" 근거) — 요청당 소요 ms 를 INFO 로 (내용·키 제외) — e92129f
