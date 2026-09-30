# LSN — Korean Lesson — API CONTRACT (BE ↔ FE 약속)

> **BE 가 먼저 갱신**하고 FE 에 알린다 (LOG + STATUS 메모). 기존 필드 삭제·이름변경 대신 **필드 추가** 우선.
> 공통 응답: `ApiResponse<T>` = `{ "status": int, "message": string, "data": T }` · 인증: `Authorization: Bearer <JWT>`
> 로컬: `http://localhost:8081`
> 1·2절은 2026-09-30 16:35 `maru_lesson` DB 에 대한 **실제 curl 응답**으로 작성 (LSN-1.1.1). "⚠️" = 알려진 문제(괄호 = 담당 PLAN 태스크).

## 1. 현재 엔드포인트

### 1-1. `GET /api/units/{unitId}/lessons` — 유닛의 레슨 목록 (단계 JSON 포함)
- 인증: 현재 **토큰 없이도 200** (SecurityConfig 에서 열려 있음, PM 소유). 앱은 토큰을 붙여 호출.
- 정렬: `orderNum` 오름차순. **`is_published = true` 인 레슨만** 반환 (NULL/false 는 숨김, LSN-1.2.10). lesson2 는 패치 `lsn_001` 로 true.
- 결과 규모: unit 0 → 12개, unit 1 → **3개**(`u1-l1`, `lesson2`, `u1-l3` — LSN-1.4.1), unit 2·3 → `data: []` (200)
- 오류: `unitId` 가 숫자가 아니면 **400** `{"status":400,"message":"unitId must be a number","data":null}` (LSN-1.2.14)

응답 `data[]` 한 개 (LessonResponseDto):
```jsonc
{
  "lessonId": "u1-l1",               // 문자열 ID. progress API 의 {lessonId} 로 그대로 사용
  "unitId": 1,
  "unitTitle": "Introduce Yourself",  // unit 0 = "Basics of Hangeul", unit 1 = "Introduce Yourself" 로 통일 (LSN-1.2.12)
  "orderNum": 1,
  "title": "My Name is...",           // unit 0 괄호 숫자 제거됨 ("Basic Vowels") (LSN-1.2.12)
  "description": "Learn how to introduce yourself ...",
  "difficultyLevel": 1,
  "estimatedMinutes": 15,
  "isPublished": true,                // 목록에는 true 만 나옴
  "content": { "steps": [ /* StepDto, 2절 */ ] }
}
```

### 1-2. `POST /api/progress/lessons/{lessonId}` — 진행/완료 저장 (upsert)
- 인증 필수. 토큰 없으면 **403 + 빈 body** (SecurityConfig, PM 소유).
- 요청 (모든 필드 선택):
```json
{ "status": "completed", "currentStep": 2, "score": 100, "timeSpentSeconds": 45 }
```
  `status`: `"in_progress"` | `"completed"`
- 응답 `data` (UserProgressResponseDto):
```json
{ "lessonId": "u0_l1", "status": "completed", "currentStep": 3, "score": 90, "starsEarned": 3, "attempts": 4, "timeSpentSeconds": 130 }
```
`score`/`starsEarned` 는 in_progress 만 보낸 경우 null.
- 동작 (UserProgressService, LSN-1.2.11 이후):
  - (user, lessonId) 행이 없으면 생성. 호출마다 `attempts + 1`. `currentStep` 은 보낸 경우 덮어씀.
  - `status` 누락 시 기존 값 유지. **한 번 completed 가 된 레슨은 in_progress 를 보내도 completed 유지**(완료 수 중복 방지).
  - `timeSpentSeconds` 는 요청마다 **누적**(완료 여부 무관). 응답에 누적값 `timeSpentSeconds` 추가.
  - completed 요청 시: 별 = score ≥80 → 3, ≥60 → 2, 그 외 1 (score 누락 = 0점 → 1개). **score·starsEarned 는 최고 기록 유지**, 별이 늘어난 만큼만 `user_stats.total_stars_earned` 에 가산.
  - 처음 completed 일 때만 `completedAt` 기록·완료 수 +1. completed 요청마다 스트릭 갱신(`recordStudyActivity`, 하루 1회만 반영).
  - `user_stats.total_study_minutes` = 사용자 전체 레슨 누적 초 합 / 60 (버림) — 요청마다 다시 계산.
  - 예: 65점 완료 → 별 2, 다시 90점 → 별 3(통계 +1), 다시 30점 → score 90·별 3 유지.
- 오류 (LSN-1.2.14): 없는 lessonId → **404** `{"status":404,"message":"Lesson not found: NOPE"}` (저장 안 함) · status 가 in_progress/completed 외 → **400** · score 가 0~100 밖 → **400** · 토큰 없음 → 403 빈 body
- ⚠️ 앱은 현재 score 100 고정 전송(LSN-1.2.6) → 실제 정답률(0~100)을 보내면 별이 그대로 반영됨.

### 1-3. `GET /api/progress/lessons?unitId={n}` — 내 레슨별 진행 기록 (LSN-1.2.15)
- 인증 필수(없으면 403). `unitId` 선택 — 없으면 전체 유닛. 숫자가 아니면 400.
- **기록이 있는 레슨만** 반환. 목록에 없는 레슨 = 시작 안 함(not_started). 순서 보장 없음 → lessonId 로 매칭.
- 응답 `data` = UserProgressResponseDto 배열 (1-2 응답과 같은 모양):
```json
[ { "lessonId": "u0_l1", "status": "completed", "currentStep": 1, "score": 90, "starsEarned": 3, "attempts": 5, "timeSpentSeconds": 135 } ]
```
- 이어하기(1.2.13): `status == "in_progress"` 면 `currentStep` 부터. completed 레슨은 다시 풀어도 status 는 completed 로 유지되니, 이어하기 여부는 FE 가 판단(예: completed 면 처음부터).

## 2. 데이터 구조 (DB JSON·엔티티 중 FE 가 의존하는 것)

### 2-1. StepDto (content.steps[] 한 개) — 직렬화 규칙
BE 는 DB JSONB 를 `StepDto` 로 읽었다가 다시 내보낸다. **항상 7개 키가 모두 나온다**(없으면 null):
`stepId, orderNum, stepType, title, instruction, contentObj, content`
- DB 에 `step_type` 으로 저장돼 있어도 응답은 **`stepType`** (camelCase).
- DB 에서 본문이 `contentObj` 키에 있으면 → 응답 `contentObj`, `content` 키에 있으면 → 응답 `content`. 다른 하나는 null.
- **FE 규칙: 본문 = `contentObj ?? content`** (현재 `StepModel.fromJson` 이 이미 이렇게 함)
- `stepId`·`orderNum` 은 unit 0 만 있음. unit 1 은 둘 다 null → 순서는 배열 인덱스로.
- `title`·`instruction`: **모든 단계에 있음** (LSN-1.3.5 이후 조립 단계도 "Sentence Building #n" / `Build the sentence: "I am Sarah."`). 그래도 FE 는 null 이면 표시 생략.

현재 데이터에 존재하는 stepType 과 본문 위치:

| 유닛 | stepType | 본문 키 | 개수 |
|---|---|---|---|
| 0 | `intro` | contentObj | 13 |
| 0 | `practice` | contentObj | 12 |
| 0 | `quiz` | contentObj | 12 |
| 0 | `completion` | contentObj (LSN-1.2.12 추가, 각 레슨 마지막) | 12 |
| 1 | `intro` | content | 8 |
| 1 | `practice` | content | 3 |
| 1 | `agglutinative_quiz` | **contentObj** (두 레슨 모두 파이프라인 생성, LSN-1.3.5) | 4 |
| 1 | `completion` | content | 2 |

Unit 0 completion 단계(LSN-1.2.12): `stepId` = `l1_done` 등, title = "<레슨 제목> Complete!", instruction 고정 문구, 본문은 unit 1 과 같은 `{text, highlights}` (highlights = 그 레슨에서 배운 글자 최대 6개).

### 2-2. Unit 0 (한글) 본문
**intro / practice** — 자모·음절 카드
```json
{ "items": [ { "jamo": "ㄱ", "romanization": "g" }, { "jamo": "가", "romanization": "ga" } ] }
```
- item 키는 `jamo`, `romanization` 두 개뿐. 발음 설명·입모양 등 **설명 필드는 없다** (카드 고정 문구 문제 LSN-1.2.3 → 필요하면 LSN-1.2.12 로 필드 추가 요청).
- `jamo` 에 단독 자모("ㄱ", "ㅏ")와 음절·단어("가", "닭")가 섞인다. 자음/모음/음절 구분 필드 없음 → FE 가 유니코드 범위로 판별 가능(자모 U+3131–U+3163, 음절 U+AC00–U+D7A3).

**quiz** — 듣고 고르기
```json
{ "quizType": "listen_match", "items": ["가", "나", "다", "라", "마", "바", "사"] }
```
- `items` 는 **문자열 배열**(3~8개). 12개 레슨 모두 `quizType = "listen_match"`.
- 문제 수·정답 관련 필드 없음 → 문제 수 = items 수 기준(LSN-1.2.4).

### 2-3. Unit 1 (문법) 본문
**intro**
```jsonc
{
  "sentences": [
    { "korean": "안녕하세요! 제 이름은 Sarah예요.", "english": "Hello! My name is Sarah.", "tts": true,
      "chunks": [ { "display": "이름은",
                    "tokens": [ { "text": "이름", "meaning": "name" }, { "text": "은", "meaning": "topic marker" } ] } ] }
  ],
  "explanation": { "title": "What is 는?",
                   "patterns": [ { "pattern": "는 / 은", "usage": "It marks the topic of the sentence.", "level": "Essential" } ] }
  // explanation.patterns 는 u1-l1 4번째 단계에만 있음
}
```
- `chunks` = 탭 분석(Tap-to-Translate)용. `display` 는 원문 그대로(구두점 포함), `tokens` 에는 기호 없음 (LSN-1.3.4).
  - **`tokens: []` 인 청크 = 탭 분석 없음** (설명 행 "저는 = I (topic)" 의 `=`, `I`, `(topic)`). FE 는 탭 불가/흐리게 처리.
  - 화자 표시 "민수:" → `[{text:"민수", meaning:"Minsu (speaker)"}]`, 이름 → "Sarah (name)", 서술격은 원문 표기(예요/이에요/입니다).
  - 같은 `display`("저는")가 한 단계에 여러 번 나올 수 있음 → 선택 키는 문장·청크 인덱스로 (FE 1.2.17).

**practice**
```json
{ "exercises": [
  { "type": "fill_blank", "sentence": "저 [ ? ] Tom입니다.", "options": ["은", "는"], "answer": "는",
    "instruction": "I am Tom.", "feedback": { "correct": "Correct! 저 + 는" } },
  { "type": "user_input", "template": "저는 {input}입니다.", "instruction": "Complete the sentence with your name.",
    "feedback": { "correct": "Great job! That's how you introduce yourself." } }
] }
```
- `fill_blank` 빈칸 표기는 문자열 `"[ ? ]"`. 오답 피드백 필드(`feedback.incorrect`)는 없다.
- `user_input` 은 정답 필드 없음.

**agglutinative_quiz** — 2단계 조립 (🐰 어절 → 🐢 목표 형태소만 분리) — LSN-1.3.5 이후 모양 (두 레슨 동일)
```json
{
  "sentence": "저는 학생이에요.", "translation": "I am a student.",
  "elements": [
    { "id": "e1", "isTarget": true, "correct_rabbit": ["저는"], "correct_turtle": ["저는"],
      "turtle_explanation": "Keep '저는' as one block — it is not this lesson's focus." },
    { "id": "e2", "isTarget": true, "correct_rabbit": ["학생이에요"], "correct_turtle": ["학생", "이에요"],
      "turtle_explanation": "'이에요' means 'am/is/are'. After a consonant use 이에요, after a vowel use 예요." }
  ],
  "options": [ { "id": "o1", "text": "예요", "mode": "turtle" }, { "id": "o4", "text": "학생이에요", "mode": "rabbit" },
               { "id": "o5", "text": "저는", "mode": "turtle" }, { "id": "o7", "text": "저는", "mode": "rabbit" } ]
}
```
- `elements[]` = 문장의 어절 칸(순서대로), 모두 `isTarget: true`. `correct_rabbit`/`correct_turtle` 은 **텍스트 배열**(ID 아님). element 에 `text`/`type` 키는 이제 없음.
- 🐢 정답: 목표 문법 형태소만 떨어지고 나머지는 통째 (u1-l1 = 은/는, lesson2 = 이에요/예요 → lesson2 의 '저는' 은 🐢 에서도 한 블록).
- **`options[].id` 는 모든 선택지에 있고 문제 안에서 유일**. **같은 텍스트 선택지가 여러 개 있을 수 있음**:
  - 🐢 에서 통째로 남는 어절은 rabbit/turtle 둘 다 같은 텍스트로 있음 ("저는" rabbit o7 + turtle o5)
  - 같은 형태소가 두 번 필요한 문장이면 그 수만큼 들어감 ('는' ×2)
  - → FE 는 **option id 로 사용 여부를 추적**하고, 정답 판정은 텍스트로 (LSN-1.3.6)
- 구두점 블록 없음. 🐰 정답에도 마침표 없음("Sarah입니다"). `sentence` 는 원문(마침표 포함).
- 오답: 🐢 = 이형태/같은 범주(은↔는, 도, 이에요↔예요, 입니다), 🐰 = 목표 형태만 틀린 어절("저은", "학생예요").
- `turtle_explanation` 은 영어. 오답 힌트로 써도 됨(FE 1.2.18).

**completion**
```json
{ "text": "You've learned '저는 [Name]입니다.'\nKeep practicing this pattern!", "highlights": ["은/는", "입니다"] }
```
- 화면 제목은 **step 의 `title`**("Lesson 1 Mastered!"), 부제는 `instruction`.
- 모든 레슨(unit 0 12개 + unit 1 2개)의 completion 에 `text`·`highlights` 가 있음 (LSN-1.2.12).

단계 순서(unit 1): u1-l1 = intro×4 → practice(Pattern Practice, 4문항: '는'×3 + '은'×1) → practice(Make Your Own) → 조립×2 → completion. lesson2 = intro×3 → practice → intro(Vocabulary) → 조립×2 → completion. 그래도 FE 는 없을 때 title/instruction 만 표시하도록 방어.

## 3. 변경 이력
| 시각 | 변경 | 태스크 | 호환성 (FE 수정 필요?) |
|---|---|---|---|
| 09-30 16:40 | 1·2절 현재 구조 최초 기록 (API 변경 없음) | LSN-1.1.1 | 없음 |
| 09-30 16:50 | 레슨 목록 `is_published=true` 만 반환 (+패치 lsn_001) | LSN-1.2.10 | 없음 (lesson2 는 패치로 계속 보임) |
| 09-30 16:50 | progress: 별 80/60 기준, 최고 점수·별 유지, completed 유지, 학습시간 매 요청 누적, 응답에 `timeSpentSeconds` **추가** | LSN-1.2.11 | 없음 (필드 추가만). 1.2.6 에서 실제 점수 보내면 별 반영 |
| 09-30 16:55 | progress 404(없는 레슨)·400(status/score), lessons 400(unitId 문자) | LSN-1.2.14 | 없음 (앱은 정상 값만 보냄). 오류 시 message 는 개발용 영어 — 화면엔 사용자용 문구로 |
| 09-30 17:05 | 데이터 패치 lsn_002: unit 0 제목 괄호 제거, unit 1 unitTitle 통일, lesson2 메타·completion 채움, **unit 0 전 레슨에 completion 단계 추가** | LSN-1.2.12 | FE: unit 0 레슨 끝에 완료 화면이 새로 나옴 (1.2.1 의 text/highlights 사용 위젯으로 표시). 유닛 카드 unit 1 제목 = 'Introduce Yourself' (unit 2 카드 'Self Introduction' 과 겹치니 1.2.8 에서 정리 권장) |
| 09-30 17:15 | **새 엔드포인트** `GET /api/progress/lessons?unitId=` | LSN-1.2.15 | FE 1.2.16(목록 완료 표시)·1.2.13(이어하기)에서 사용 |
| 09-30 18:10 | 패치 lsn_003: unit 1 두 레슨 content 재생성. **조립 문제 모양 통일**(contentObj, option id 전부, element text/type 없음, 구두점 블록 없음, 영어 설명, 목표 형태소만 분리), 조립 단계 title/instruction 채움, chunks 정리(`tokens: []` 청크 생김), u1-l1 Pattern Practice 4문항 | LSN-1.3.5 (1.3.1~1.3.4, 1.3.7) | **예**: 1.3.6 option id 기준 추적 + 같은 텍스트 선택지 허용. `tokens: []` 청크 탭 처리 |
| 09-30 18:35 | 패치 lsn_004: **새 레슨 `u1-l3` "What do you like?"** (을/를, unit 1 orderNum 3). 조립 3문제: '저는/민수는' 통째, '커피를/빵을/물을' 만 분해 | LSN-1.4.1 | 코드 수정 불필요(기존 단계 유형만). FE 1.4.2 완주 확인 |
