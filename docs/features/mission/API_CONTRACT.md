# MSN — Mission Chat — API CONTRACT (BE ↔ FE 약속)

> **BE 가 먼저 갱신**하고 FE 에 알린다 (LOG + STATUS 메모). 기존 필드 삭제·이름변경 대신 **필드 추가** 우선.
> 공통 응답: `ApiResponse<T>` = `{ "status": int, "message": string, "data": T }` · 인증: `Authorization: Bearer <JWT>`
> 로컬: `http://localhost:8083`

## 1. 현재 엔드포인트 (Step 1.1 에서 BE 가 실제 응답 보고 작성)
> 09-30 17:35 mission-be 가 :8083 에서 dev_tester_be 로 실제 호출해 기록 (MSN-1.1.1). 모든 요청 JSON, 인증 필수(없으면 **403**, 바디 없음).
> 서버는 **stateless** — 대화 상태는 FE 가 들고 매 요청마다 `setup` + `conversationHistory` 를 통째로 보낸다.
> JSON 키는 camelCase. 공통 타입:
> - `Setup` = `/setup` 응답의 `data` 객체 그대로
> - `Msg` = `{ "role": "user" | "assistant", "content": "한국어 문장" }` (그 외 키 보내지 말 것 — OpenAI 로 그대로 전달됨)

### 1-1. `POST /api/v1/mission-chat/setup` — 페르소나·미션 생성 (OpenAI 1회, 실측 ~6.7s)
요청:
```json
{ "hierarchy": "윗사람", "intimacy": "초면", "role": "카페 직원", "personality": "친절한" }
```
- `hierarchy`: 윗사람 / 동년배·친구 / 아랫사람, `intimacy`: 초면 / 아는 사이 / 친한 사이 (프롬프트에 문자열 그대로 들어감, 서버 검증 없음)
- `role`, `personality`: 자유 입력, null 가능 (null → "any role"/"natural")
- ⚠ 예전 필드 `formality` 는 **없음** (보내도 무시)

응답 `data`:
```json
{
  "persona": { "role": "카페 직원", "personality": "친절한", "speechStyle": "친근한 톤으로 존댓말",
               "honorificLevel": "존댓말", "firstMessage": "안녕하세요! 어떤 음료 드시겠어요?",
               "firstMessageEn": "Hello! What kind of drink would you like?" },
  "mission": { "title": "Inquiring About a New Beverage", "description": "...(영어)",
               "clearCondition": { "goalCondition": "...(영어)", "languageCondition": "...(영어)" },
               "minTurns": 6 },
  "adjustmentNotice": "카페 직원은 손님한테 반말하기 어렵잖아~ ... 🐰"   // 없으면 null
}
```
- `minTurns`: 4~12 (LLM 이 난이도로 결정, 파싱 실패 시 5)

### 1-2. `POST /api/v1/mission-chat/chat` — 한 턴 (토끼 🐰 + 거북이 🐢 OpenAI 2회 **병렬**, 실측 2.5~3.1s)
요청:
```json
{ "userMessage": "새로 나온 음료가 있어요?",
  "conversationHistory": [ Msg... ],
  "setup": Setup }
```
- 현재 FE 는 `conversationHistory` 에 **이번 userMessage 까지 이미 포함**해서 보냄. 현 BE 는 거기에 userMessage 를 한 번 더 붙임 → AI 가 같은 문장을 두 번 받음 (버그, MSN-1.2.5 에서 BE 가 중복 제거로 수정 예정 — FE 수정 불필요)
- 턴 수(zone 판정용 `current_turn`) = history 안의 `role=="user"` 개수 (현 FE 전송 방식이면 이번 턴 포함)

응답 `data`:
```json
{
  "rabbitReply": "네, 새로 나온 음료로 '시나몬 바닐라 라떼'가 있어요! ...",   // 페르소나 대사 (null 가능)
  "rabbitReplyEn": "Yes, we have a new drink ...",
  "correction": {
    "severity": "none",            // "none" | "side" | "immediate"
    "issueType": "none",           // "none" | "honorific_mismatch" | "grammar_error" | "vocabulary" | "pragmatic" | "off_topic"
    "userInputProblematic": null,  // 문제된 사용자 표현
    "correctExpression": null,     // 고친 표현
    "turtleFeedback": null,        // 거북이 코멘트 (한국어)
    "turtleFeedbackEn": null
  },
  "missionStatus": "in_progress"   // "in_progress" | "cleared" | "failed"
}
```
- **severity 의미**: `none` 문제없음 / `side` 대화는 이어가되 옆에 교정 / `immediate` 존댓말 오류·주제 이탈 → 다시 말하게 함
- ⚠ 토끼와 거북이는 **따로** 호출되므로 `immediate` 여도 `rabbitReply` 가 채워져 옴 (실측). FE 는 immediate 면 rabbitReply 를 버리는 현재 방식 유지.
- **missionStatus 는 토끼 호출이 3-Zone 규칙으로 결정** (`rabbit_reply_system.txt`), `min=minTurns`, `t=current_turn`:
  - Zone A `t < min-1` → 항상 `in_progress`
  - Zone B `min-1 ≤ t ≤ min+1` → 목표·언어 조건 충족 시 `cleared`(마무리 대사), 아니면 `in_progress`
  - Zone C `t > min+1` → 목표 미달 `failed`, 달성 `cleared`
  - MSN-1.3.2 이후 서버가 규칙을 강제함 (§1-7 B)
- FE 현재 처리: `cleared` → `/clearance` 호출. `failed` 분기 없음. 추가로 user 턴 ≥ `minTurns+2` 면 무조건 `/clearance` (MSN-1.3.2 에서 변경 예정)

### 1-3. `POST /api/v1/mission-chat/suggestion` — 거북이 힌트 (OpenAI 1회, 실측 ~1.4s)
요청: `{ "setup": Setup, "conversationHistory": [ Msg... ] }`
응답 `data`: `{ "suggestions": [ { "korean": "새로운 음료에 어떤 성분이 들어가나요?", "english": "What ingredients are in the new beverage?" } ] }` (2~3개)

### 1-4. `POST /api/v1/mission-chat/clearance` — 수료증 생성 + DB 저장 (OpenAI 1회, 실측 ~2.9s)
요청: `{ "setup": Setup, "conversationHistory": [ Msg... ] }`
응답 `data`:
```json
{
  "id": 16, "missionTitle": "Inquiring About a New Beverage", "persona": "카페 직원", "totalTurns": 2,
  "goodExpressions": [ { "expression": "새로 나온 음료가 있어요?", "reason": "...(영어)" } ],
  "incorrectExpressions": [ { "wrong": "우유는 뭐 써요?", "correct": "어떤 우유 쓰시나요?", "explanation": "...(영어)" } ],
  "turtleComment": "Great job ...", "nextPractice": "Practice ...",
  "clearedAt": "2026-09-30T17:33:07.721717"     // 서버 로컬시간, 타임존 없음
}
```
- ~~판정 없이 무조건 저장~~ → MSN-1.3.1 에서 `cleared`/`resultReason`/`goalCondition` 추가됨 (§1-7 D)
- `totalTurns` = history 의 user 메시지 수

### 1-5. `GET /api/v1/mission-chat/clearances` — 내 수료증 목록
응답 `data`: `[ 1-4 와 같은 객체, ... ]` (clearedAt 내림차순). 없으면 `[]`.

### 1-6. 오류 응답 (MSN-1.2.1 이후, 09-30 17:38 반영 · 서버 재시작됨)
모든 오류는 `{"status": <HTTP코드>, "message": "<사용자에게 그대로 보여줘도 되는 영어 문장>", "data": null}`. **200 + data=null 은 없음.**
| HTTP | 상황 | message |
|---|---|---|
| 400 | setup/userMessage 누락, 잘못된 JSON 바디 | `Some mission information is missing. Please start the mission again.` |
| 400 | `/setup` 에 hierarchy·intimacy 누락 | `Please choose the relationship and how close you are.` |
| 403 | 토큰 없음/만료 (바디 없음, Security 가 처리) | - |
| 404 | 토큰의 유저가 DB 에 없음 (`/clearance`, `/clearances`) | `Your account could not be found. Please sign in again.` |
| 502 | OpenAI HTTP 오류(401/429/5xx 등) | `The AI service is having trouble. Please try again in a moment.` |
| 502 | AI 가 JSON 을 깨뜨리거나 필수 필드(rabbit_reply, first_message, certificate, suggestions) 누락 | `The AI gave an unexpected answer. Please try again.` |
| 503 | 서버에 OpenAI 키 없음 | `The conversation partner is not available right now. Please try again later.` |
| 504 | OpenAI 연결 5s / 응답 30s 타임아웃 | `The AI took too long to respond. Please try again.` |
- FE 권장: 400·404 → 재시도 무의미(설정 화면으로/재로그인), 502·503·504 → 같은 요청 **재전송 버튼**. `message` 는 그대로 표시 가능 (없으면 자체 문구).
- `/chat` 실패 시 서버에 저장되는 것 없음 → 같은 요청 그대로 재전송하면 됨. `/clearance` 는 성공 시에만 DB 저장.
- `missionStatus` 가 AI 에서 알 수 없는 값으로 오면 서버가 `in_progress` 로 바꿈 (항상 3개 값 중 하나 보장). `severity` 도 3개 값 중 하나가 아니면 502.

## 1-7. 판정·종료·수료증 규칙 (MSN-1.3.1/1.3.2 — **BE 구현·서버 반영 완료 09-30 17:43**)
> FE 이견 있으면 LOG_fe/STATUS 메모로. 기존 필드·기존 FE 동작은 그대로 동작함(호환).

**A. `/chat` 응답에 필드 추가**
```json
{ ...기존 필드...,
  "userTurn": 5,      // 이번 턴 포함 사용자 턴 수 t
  "minTurns": 4,      // setup.mission.minTurns (0 이하면 5)
  "maxTurns": 7,      // = minTurns + 3. 이 턴에 도달하면 서버가 반드시 cleared/failed 로 끝냄
  "zone": "B"         // "A" | "B" | "C"
}
```
**B. 서버가 강제하는 3-Zone (LLM 판단 위에 덮어씀)**
| zone | 조건 | 서버 규칙 |
|---|---|---|
| A | `t < min-1` | 무조건 `in_progress` (LLM 이 cleared/failed 줘도 무시) |
| B | `min-1 ≤ t ≤ min+1` | LLM 판단: 목표 달성 `cleared`, 아니면 `in_progress` (`failed` 는 `in_progress` 로) |
| C | `t ≥ min+2` | LLM 판단: `cleared` / `failed`. 단 `t ≥ maxTurns` 인데 `in_progress` 면 서버가 `failed` |
- 즉 **대화는 반드시 maxTurns 안에 끝남**. `cleared` 또는 `failed` 가 오면 대화 종료.

**C. 종료 → 수료증 (FE 변경 요청: MSN-1.3.2 FE 부분)**
- `missionStatus` 가 `cleared` 또는 `failed` 이면 FE 는 입력을 막고 `/clearance` 호출 (failed 도 호출 — 피드백은 항상 준다).
- FE 의 `userTurnCount >= minTurns + 2` 강제 발급 로직은 **삭제** (서버가 maxTurns 로 보장).
- `/clearance` 요청에 선택 필드 추가: `"missionStatus": "cleared" | "failed"` (마지막 /chat 값. 없어도 동작)

**D. `/clearance` 응답(·`/clearances` 항목)에 필드 추가**
```json
{ ...기존 필드...,
  "cleared": false,                 // AI 코치가 대화 전체를 보고 목표 달성 판정. null = 판정 도입 전(예전) 수료증
  "resultReason": "You asked about the drink but never found out what milk it uses.",  // 판정 이유(영어 1문장), 예전 것 null
  "goalCondition": "You successfully gain a clear understanding of ..."               // 미션 목표(영어), 예전 것 null
}
```
- 판정: 수료증 AI(거북이 코치)가 `goalCondition`·`languageCondition` 기준으로 `cleared`/`not cleared` 결정. `missionStatus` 는 참고용 힌트일 뿐.
- 서버 가드: 사용자 턴 < `minTurns - 1` 이면 AI 판정과 무관하게 `cleared=false` ("The conversation ended before the goal could be reached.")
- 피드백(goodExpressions, incorrectExpressions, turtleComment, nextPractice)은 **항상** 옴. not cleared 면 nextPractice 가 재도전 조언.
- goodExpressions 0~4개, incorrectExpressions 0~3개 (틀린 게 없으면 빈 배열 — 예전처럼 억지로 1개 만들지 않음). FE 는 빈 배열 처리 필요.
- FE 표시(1.3.3): `cleared == true` → "Mission Cleared", `false` → "Not cleared yet — try again", `null` → "Completed"(예전 기록).

## 2. 데이터 구조 (DB JSON·엔티티 중 FE 가 의존하는 것)
- 테이블 `mission_clearances`: id, user_id, mission_title, persona, total_turns, good_expressions(TEXT, JSON 배열), incorrect_expressions(TEXT, JSON 배열), turtle_comment, next_practice, cleared_at
- (MSN-1.3.1 추가된 nullable 컬럼) `cleared` BOOLEAN, `result_reason` TEXT, `goal_condition` TEXT — 패치 `backend/db/patches/msn_001_clearance_result_columns.sql`
- 미션·대화 자체는 DB 에 저장하지 않음 (stateless)

## 3. 변경 이력
| 시각 | 변경 | 태스크 | 호환성 (FE 수정 필요?) |
|---|---|---|---|
| 09-30 17:38 | 오류 응답 정리: 400/404/502/503/504 + 사용자용 영어 message (§1-6). 성공 응답 모양 변경 없음 | MSN-1.2.1 | 아니오 (오류 표시·재전송은 FE 1.2.2 에서 활용) |
| 09-30 17:40 | `/chat` user 메시지 중복 제거, `current_turn` = 이번 턴 포함 | MSN-1.2.5 | 아니오 |
| 09-30 17:40 | (제안) §1-7 판정·종료 규칙, /chat·/clearance 필드 추가 | MSN-1.3.1/1.3.2 | 추가 필드만 — 기존 FE 동작 유지. 종료 트리거 변경은 FE 작업 필요 |
| 09-30 17:43 | §1-7 구현: /chat `userTurn`·`minTurns`·`maxTurns`·`zone` 추가 + 서버 강제 3-Zone. /clearance 요청 `missionStatus`(선택), 응답 `cleared`·`resultReason`·`goalCondition` 추가 | MSN-1.3.1/1.3.2 | 기존 FE 그대로 동작. FE 작업: failed→/clearance, min+2 강제발급 삭제, cleared 표시(1.3.3), incorrectExpressions 빈 배열 |
