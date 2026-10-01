# MSN — Mission Chat — BE 세션 로그 (`mission-be`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음 — MSN-1.7.1 완료 (a186f8c). Step 1.7 의 [BE] 태스크는 이것 하나
- 다음 할 일: FE 짝(mission-fe/fe2) 피드백·버그 대응, PM 통합 때 회귀 수정
- 막힌 것 / 기다리는 것: 없음
- 실행 중인 것: `scripts/run_backend.sh mission` 백그라운드, :8083, DB maru_mission (10-01 12:34 재시작, 1.7.1 반영). 테스트 토큰 `scripts/dev_token.sh maru_mission dev_tester_be`
- 테스트 실행: VocabularyServiceTest 컴파일 문제 해소됨 → exclude 스크립트 불필요. `./gradlew test --tests 'com.hdy.maru.service.MissionClearanceServiceTest' --tests 'com.hdy.maru.controller.MissionChatControllerTest' --tests 'com.hdy.maru.dto.MissionChatDtoTest'`
- 마지막 커밋: a186f8c
- 짝 세션에게: 10-01 12:34 서버 재시작. /clearance 의 goodExpressions.expression·incorrectExpressions.wrong 은 이제 history 의 role=user 문장에 실제로 있는 것만 나옴(API 모양 동일). 제안 문장을 history 에서 빼는 건 FE 1.7.2

## 기록 (시간순 추가만, 수정 금지)

### 09-30 17:34 MSN-1.1.3 ✅ (f98f31a)
- `MissionChatDtoTest`·`MissionChatControllerTest` 의 `.formality(...)` → `.personality(...)` 로 교체.
- 컨트롤러 테스트가 실제 OpenAI 를 부르던 구조 → 서비스 4개 `@MockitoBean`, principal 은 JwtAuthenticationFilter 와 같은 String(oauthId) 로 주입, `@ActiveProfiles("test")`(H2), 테스트 환경에 JWT_SECRET 이 없어 더미 `jwt.secret` properties 주입.
- 결과: MissionChatControllerTest 4/4, MissionChatDtoTest 2/2 통과. H2 가 Lesson 의 JSONB DDL 을 못 만드는 경고는 있으나 무관. 전체 test 컴파일은 VocabularyServiceTest(VOC) 오류만 남음 → REQUESTS R-002.

### 09-30 17:34 MSN-1.1.1 ✅ (문서만)
- :8083 에서 dev_tester_be 로 setup/chat(정상·반말)/suggestion/clearance/clearances + 오류 케이스 curl. 결과 API_CONTRACT §1.
- 실측: setup 6.7s, chat 2.5~3.1s(병렬 2회), suggestion 1.4s, clearance 2.9s. → 발표 "1.5초대"는 현재 chat 기준 사실 아님(1.4.3 에서 로그로 측정 예정).
- 발견: (1) FE history 에 이번 user 메시지가 포함되어 BE 가 또 붙임 → 중복 (MSN-1.2.5 추가). (2) immediate 여도 rabbitReply 가 옴(별도 호출). (3) 2턴·목표 미달 대화도 수료증 발급됨(id 16, dev_tester_be). (4) 필드 누락 시 500 "An unexpected error occurred", 토큰 없으면 403.

### 09-30 17:38 MSN-1.2.1 ✅ (1a0fd31)
- 새 `service/MissionChatException`(HttpStatus + 사용자용 영어 메시지) + `MissionChatController` 로컬 `@ExceptionHandler` (exception/** 는 PM 잠금이라 컨트롤러 로컬 처리). 잘못된 JSON 바디도 컨트롤러에서 400.
- `OpenAiService`: 공유 RestTemplate(config, 잠금)에 타임아웃이 없어 자체 RestTemplate(connect 5s / read 30s) 사용. 타임아웃·I/O → 504, OpenAI HTTP 오류 → 502, 키 없음 → 503, 응답 구조 이상 → 502. 로그에 키·응답 원문 없음(상태코드만).
- 서비스: 입력 검증(400), AI JSON 파싱 실패·필수 필드 누락 → 502, 병렬 호출 CompletionException 언래핑, `Map.of` null NPE 제거(HashMap), missionStatus 화이트리스트, clearance 는 AI 호출 전에 유저 조회(404).
- 검증: compileJava OK. 테스트 ChatTurnServiceTest 5/5(신규), MissionChatControllerTest 6/6, MissionChatDtoTest 2/2. curl: 누락 필드 4 엔드포인트·깨진 JSON → 400 + 메시지, 정상 chat 200. 잘못된 OpenAI 키로 서버 잠깐 띄워 chat/setup → 502 확인(로그에 키 없음). 타임아웃 504 는 단위테스트로만 확인(실제 타임아웃 미재현).
- 서버 재시작 17:38.

### 09-30 17:40 MSN-1.2.5 ✅ (5aee88d)
- `ChatTurnService`: history 마지막이 같은 내용의 user 메시지면 다시 붙이지 않음. zone 판정 턴 수 = fullHistory 의 user 수(이번 턴 포함) — FE 가 포함해 보내든 안 보내든 같은 값.
- 검증: ChatTurnServiceTest 7/7(중복 제거·턴 카운트 테스트 추가), 서버 재시작 후 FE 모양 요청 curl 200, OpenAI 요청 2회(토끼·거북이)만.

### 09-30 17:40 MSN-1.3.1/1.3.2 설계 → API_CONTRACT §1-7 (제안)
- 서버 강제 3-Zone + maxTurns(=min+3) 하드캡, /chat 에 userTurn·minTurns·maxTurns·zone 추가. /clearance 는 거북이 코치 AI 가 goal 기준 판정 → cleared/resultReason/goalCondition 추가(nullable 컬럼). FE 강제발급(min+2) 삭제 요청.

### 09-30 17:43 MSN-1.3.2 BE ✅ (db3a180) — FE 부분 남음
- `ChatTurnService.applyZoneRules`: LLM missionStatus 위에 서버가 3-Zone 강제 (A→in_progress, B→cleared|in_progress, C→cleared|failed, t≥maxTurns(=min+3) 미완료→failed). 덮어쓸 때 INFO 로그. 응답에 userTurn/minTurns/maxTurns/zone 추가. minTurns≤0 → 5.
- rabbit 프롬프트: 턴 수가 이번 턴 포함임을 명시, 하드 리밋 표시, Zone C failed 시 마무리 대사.

### 09-30 17:43 MSN-1.3.1 ✅ (587ae27)
- `clearance_system.txt` 의 `"result": "클리어"` 고정 제거 → 코치 AI 가 goal/language 조건으로 `cleared|not_cleared` + result_reason 판정. 좋은/틀린 표현 0~4 / 0~3 (틀린 것 억지 생성 금지). not cleared 면 next_practice = 재도전 조언.
- 서버 가드: user 턴 < min-1 이면 cleared=false. result 누락/이상 → 502, 저장 안 함.
- 엔티티 nullable 컬럼 cleared/result_reason/goal_condition 추가 + 패치 `backend/db/patches/msn_001_clearance_result_columns.sql`(ADD COLUMN IF NOT EXISTS, maru_mission 에 2회 적용 확인). 예전 행은 NULL = 판정 전.
- 요청 DTO 에 선택 `missionStatus`(힌트).
- 검증: 테스트 23/23 (ChatTurnServiceTest 9, MissionClearanceServiceTest 6 신규, Controller 6, Dto 2). curl(dev_tester_be): ① 2턴 목표 미달 → cleared=false + 피드백(id 17) ② 스크립트 대화 5턴 → t=1~4 zone A in_progress, t=5 zone B cleared → clearance cleared=true(id 18). chat 1턴 1.4~1.6s(이번 측정; 앞선 측정 2.5~3.1s — OpenAI 변동 큼).

### 09-30 17:45 MSN-1.4.3 + MSN-1.3.4 ✅ (e92129f)
- `ChatTurnService` 턴마다 INFO `Chat turn timing: total=..ms rabbit=..ms turtle=..ms (sequential would be ~..ms) turn=N`, `OpenAiService` 호출마다 `OpenAI call (gpt-4o) took ..ms`. 내용·키 없음.
- 실측(5회, turn 1, gpt-4o): total 1550/1806/1976/2153/2230ms, 순차 합산 2585~4130ms → 병렬로 약 30~50% 단축. 앞선 스크립트 대화 5턴은 1.4~1.6s. **발표 문구 제안: "토끼·거북이 병렬 호출로 한 턴 약 1.5~2초 (순차 대비 30~50% 단축)"** — "1.5초대" 단정은 과장.
- `prompts/chat_turn_system.txt` 삭제 (코드 참조 0건 grep 확인; 토끼/거북이 분리 전 단일 프롬프트).
- 검증: compileJava, 테스트 23/23, 서버 재시작 후 curl 5회 + 로그 확인.

### 09-30 19:43 PM 지시: main 동기화 후 서버 재시작 + MSN-1.2.6, MSN-1.3.5
- MSN-1.2.6 ✅ (1453137): `ChatTurnService.nullableText` 가 "null"/"none"/빈 문자열(trim) → null. severity·issue_type·mission_status 도 같은 경로로 읽고 기본값. immediate/side 인데 correctExpression·turtleFeedback 둘 다 null 이면 severity=none 으로 내림(안내 없이 입력을 막지 않도록, WARN 로그). setup adjustmentNotice·clearance resultReason 도 정규화. 거북이·토끼 프롬프트에 "JSON null 사용, immediate/side 면 교정·피드백 필수" 명시.
- MSN-1.3.5 ✅ (326c19b): clearance 프롬프트 result_reason·turtle_comment 를 "You …" 2인칭으로 지시(“the student” 금지, 예시 포함). 서버 가드 문구도 "You ended the conversation before reaching the mission goal."
- 검증: 테스트 25/25 (ChatTurnServiceTest 11 — "null" 정규화·빈 immediate 테스트 추가, Clearance 6, Controller 6, Dto 2). 재시작 후 curl: chat 정상 → correction 전부 JSON null, 반말 → immediate + 교정 채워짐, 2턴 clearance → cleared=false, resultReason "You did not manage to …", turtleComment "You started well …".

### 10-01 12:35 MSN-1.7.1 ✅ (a186f8c) — 수료증에 사용자가 보내지 않은 문장 인용 버그
- `MissionClearanceService.userSentences(history)`: role=user 문장만(trim, 빈 것 제외) → `clearance_system.txt` 의 새 `{{student_messages}}` 섹션에 번호 목록으로 주입. 프롬프트: "이 목록만 인용 가능, expression·wrong 은 VERBATIM(전체 또는 정확한 일부), history 의 다른 줄(페르소나·힌트 제안) 인용 금지".
- 서버 검증 `isQuotedFromUser`: NFC + 공백·문장부호·기호 제거 + 소문자 후, 인용이 어떤 사용자 문장에 포함되면 통과. good_expressions(expression)·incorrect_expressions(wrong) 중 불통과 항목은 제거(INFO 로그 "Dropped ..."). 전부 빠지면 빈 배열 — FE 는 이미 빈 배열 처리함.
- 테스트: MissionClearanceServiceTest +3 (정규화 매칭, 제안/페르소나/지어낸 문장 제거, 프롬프트에 user 문장만 번호 목록) → Clearance 9 / Controller 6 / Dto 2 전부 통과.
- curl (재시작 후, 1회): history 에 assistant "Suggestion: 아이스 아메리카노 한 잔 주시겠어요?" 를 섞어 보냄 → goodExpressions "네 따뜻한 거 주세요", incorrectExpressions wrong "커피 하나 줘" — 둘 다 실제 user 문장, 제안 문장 인용 없음. 응답 필드 구성 동일.

