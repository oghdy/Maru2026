# VOC — Vocabulary — API CONTRACT (BE ↔ FE 약속)

> **BE 가 먼저 갱신**하고 FE 에 알린다 (LOG + STATUS 메모). 기존 필드 삭제·이름변경 대신 **필드 추가** 우선.
> 공통 응답: `ApiResponse<T>` = `{ "status": int, "message": string, "data": T }` · 인증: `Authorization: Bearer <JWT>`
> 로컬: `http://localhost:8082`

## 1. 현재 엔드포인트 (VOC-1.1.1, 09-30 17:35 실측 · 유저 dev_tester_be · DB maru_vocab)
모든 엔드포인트는 인증 필요(토큰 없으면 **403**, 본문 없음). 베이스: `/api/v1/vocabulary`

### 1-1. `GET /decks?level=Beginner`
- `level` 기본값 `Beginner` (DB 14개 덱 모두 Beginner). `deck_order` 오름차순.
- data: `WordCategoryDto[]`
```json
[{"id":13,"title":"쇼핑/경제","level":"Beginner","totalWords":46},
 {"id":14,"title":"가족/인물","level":"Beginner","totalWords":157}, ...]   // 14개, totalWords 합계 5561
```
- `title` 은 한국어 원문. 영어 표기는 FE 가 switch 로 변환(`word_category.dart`).

### 1-2. `GET /decks/{deckId}/lessons`
- 덱을 30단어씩 끊은 "레슨" 목록 (순서 = `/due` 페이징과 동일: 등급 A→B→C, id). 마지막 레슨은 나머지 개수.
- data: `WordLessonDto[]`
```json
[{"lessonNumber":1,"totalWords":30,"studiedWords":30,"completed":true,"isCompleted":true},
 {"lessonNumber":2,"totalWords":16,"studiedWords":0,"completed":false,"isCompleted":false}]
```
- `studiedWords`: 이 레슨에서 사용자가 한 번 이상 평가(학습 기록 state>0)한 단어 수. **(VOC-1.2.3 추가)**
- `isCompleted` = `studiedWords == totalWords`. **(VOC-1.2.3: 실제 계산 + `isCompleted` 키 추가)** `completed` 는 같은 값, 하위 호환용으로 유지.
- 참고: Word Study 에서 이미 학습한 단어는 LESSON 모드 평가가 저장되지 않지만(가드) 이미 기록이 있으므로 카운트에는 포함됨.
- 없는 deckId → `200`, `data: []`.

### 1-3. `GET /due?deckId={id}&lessonNumber=1&limit=30`
- 이름과 달리 **복습 기한과 무관**: 덱 단어를 등급(A→B→C)·id 순으로 정렬해 `lessonNumber` 번째 `limit` 개 페이지를 반환. 학습 기록이 있으면 그 state/reps 를 붙임.
- data: `WordDueDto[]`
```json
[{"id":1403,"koreanWord":"도시","primaryMeaning":"city","exampleSentence":"서울은 한국의 큰 도시에요.",
  "exampleTranslation":"Seoul is a big city in Korea.","partOfSpeech":"Noun","audioUrl":null,"state":0,"reps":0}, ...]
```
- `state`: 0 New · 1 Learning · 2 Review · 3 Relearning. `audioUrl` 은 전 단어 null (발음은 기기 TTS).
- `nextIntervals` **(VOC-1.3.3 추가)**: 평가 버튼별 "지금 누르면 다음 복습까지" 라벨. 실제 스케줄 계산과 같은 식.
  ```json
  "nextIntervals": {"AGAIN":"5m","HARD":"1d","GOOD":"4d","EASY":"14d"}
  ```
  라벨 형식: `Nm`(분) · `Nh` · `Nd` · `Nmo` · `N.Ny`. 키 순서 AGAIN→EASY.
  **`null`** = Word Study 에서 이미 학습했고 복습일 전인 단어(평가해도 반영 안 됨, §1-6 가드) → 버튼에 간격 표시하지 말 것.
- 범위 밖 lessonNumber → `200`, `data: []`. `lessonNumber=0` → **400** `"Page index must not be less than zero"`.

### 1-4. `GET /daily-review?limit=30`
- 사용자의 모든 덱에서 `next_review_date <= now` 인 카드. 정렬: state 오름차순 → next_review_date 오름차순.
- data: `WordDueDto[]` (1-3 과 같은 모양, `nextIntervals` 항상 채워짐). 없으면 `[]`.

### 1-5. `GET /game/{deckId}?lessonNumber=1`
- 해당 레슨(30단어, `/due` 와 같은 순서) 단어마다 타일 2개(KOREAN, ENGLISH). **섞지 않음**(단어 순서대로 KR, EN 교대). 5쌍씩 라운드 구성·셔플은 FE 몫.
- **(VOC-1.2.5)** 같은 레슨 안에서 뜻(대소문자·앞뒤 공백 무시)이나 한국어 표기가 겹치는 단어는 먼저 나온 것만 사용 → 게임 단어 수가 레슨 단어 수보다 **적을 수 있음**(예: 덱12 레슨2 = 30단어 중 29쌍, "시/도시 = city" 중복 제거). 193개 레슨 중 98곳에 이런 중복 있음.
- data: `VocabularyGameTileDto[]`
```json
[{"id":"1403_KR","pairId":1403,"text":"도시","type":"KOREAN","totalWords":29},
 {"id":"1403_EN","pairId":1403,"text":"city","type":"ENGLISH","totalWords":29}, ...]
```
- `totalWords` **(VOC-1.2.5 추가)**: 이 게임의 짝 수(= 타일 수 / 2). 모든 타일에 같은 값. "Round n/N" 은 `ceil(totalWords / 5)`, 진행바·완료 문구도 이 값 사용. 5 미만(최소 1)일 수 있음.
- 오류: 단어 없는 레슨·없는 덱 → **404** `"No words found for this lesson."` / `lessonNumber < 1` → **400** `"lessonNumber must be 1 or greater."` (이전: 500)

### 1-6. `POST /review`
- 요청:
```json
{"wordId":1403,"rating":3,"reviewMode":"LESSON"}   // rating 1 AGAIN · 2 HARD · 3 GOOD · 4 EASY / reviewMode "LESSON" | "DAILY_REVIEW"
```
- 응답 **(VOC-1.3.2: `null` → 객체)**: `200`
```json
{"applied":true,"state":2,"nextReviewDate":"2026-10-14T17:42:33.326896"}
```
  - `applied`: 이번 평가가 스케줄에 반영됐는지. `false` = Spacing Integrity Guard 로 무시됨. `state`·`nextReviewDate` 는 반영 후(또는 무시된 경우 기존) 값. 시간은 서버 로컬(KST) ISO, 타임존 표기 없음.
- 동작: FSRS 카드 갱신 + 오늘 학습 활동 기록(스트릭, 가드로 무시돼도 기록).
  - **Spacing Integrity Guard (VOC-1.3.2 에서 조건 변경)**: `reviewMode:"LESSON"` 이고 이미 학습한 단어(state>0)이며 **아직 복습일 전**이면 평가를 저장하지 않음 → `applied:false`. 복습일이 지난 단어는 LESSON 모드에서도 정식 복습으로 반영(이전: LESSON 모드면 기한과 무관하게 무시). 새 단어·`DAILY_REVIEW` 는 항상 반영.
  - 이유: Word Study 는 레슨 단어를 기한과 무관하게 다시 보여주므로, 기한 전 재평가(벼락치기)로 간격이 흐트러지지 않게 막되, 기한이 지난 단어의 실제 기억 결과는 버리지 않기 위함.
- 오류 **(VOC-1.2.8)**: rating 1~4 밖 → **400** `"rating must be 1 (Again) to 4 (Easy)."` (이전: 조용히 GOOD) / wordId 누락 → **400** `"wordId is required."` / 없는 wordId → **404** `"Word not found."` (이전: 500). `reviewMode` 는 `"LESSON"` 만 특별 취급, 그 외 값·누락은 DAILY_REVIEW 처럼 동작.

## 2. 데이터 구조 (DB JSON·엔티티 중 FE 가 의존하는 것)
- `words` 5,561 · `word_categories` 14 (전부 level=Beginner) · 레슨 = 덱 내 30단어 페이지(DB 테이블 아님, 193개).
- `fsrs_progress(user_id, word_id UNIQUE)`: state, stability, difficulty, reps, lapses, last_review, next_review_date.
- 스케줄러(`FsrsAlgorithm`) **(VOC-1.3.1)**: FSRS-4.5 표준 공식 + 기본 파라미터 17개, 목표 기억률 0.9. 경과일로 기억률 R 계산.
  - 새 카드: AGAIN → Learning, **5분 뒤**(오늘의 복습에 재등장) · HARD → 1일 · GOOD → 4일 (S=3.7145, D=5.1618) · EASY → 14일.
  - 복습 카드: AGAIN → Relearning(lapses+1), 5분 뒤 / 그 외 → Review, 간격 = 새 안정성(일), HARD ≤ GOOD < EASY 보장. 같은 날 다시 GOOD 하면 안정성 거의 그대로.
  - 예: GOOD 후 4일 뒤 GOOD → S 3.71 → 14.81, 다음 복습 15일 뒤 (실측).

## 3. 변경 이력
| 시각 | 변경 | 태스크 | 호환성 (FE 수정 필요?) |
|---|---|---|---|
| 09-30 17:35 | 현재 구조 최초 기록 | VOC-1.1.1 | - |
| 09-30 17:36 | `/decks/{id}/lessons`: `studiedWords` 추가, `isCompleted` 키 추가(실제 계산), `completed` 유지 | VOC-1.2.3 | FE 는 기존 `isCompleted` 읽기 그대로 동작. 진행 표시는 `studiedWords/totalWords` 사용 가능 (1.2.4) |
| 09-30 17:38 | `/game`: 타일에 `totalWords` 추가, 모호한 중복 짝 제거(단어 수 30 미만 가능), 범위 밖 404·lessonNumber<1 400 (기존 500) | VOC-1.2.5 | 기존 파싱은 그대로 동작. 1.2.2 는 `totalWords` 로 라운드·진행 계산 권장, 404 는 영어 안내 처리(1.2.6) |
| 09-30 17:40 | `POST /review` 입력 검증: 잘못된 rating·누락 wordId 400, 없는 wordId 404 | VOC-1.2.8 | 정상 요청은 변화 없음. FE 는 1~4 만 보내므로 영향 없음 |
| 09-30 17:42 | FSRS 계산식 교체(응답 모양 변화 없음). 새 카드 GOOD 다음 복습 +4일 동일, HARD +1일(이전 +2), EASY +14일(이전 +6) | VOC-1.3.1 | 없음 |
| 09-30 17:44 | `POST /review` data: `null` → `{applied,state,nextReviewDate}`. 가드 조건: 기한 전 재평가만 무시(기한 지난 단어는 LESSON 모드에서도 반영) | VOC-1.3.2 | 없음(FE 는 응답 data 를 읽지 않음). 원하면 applied=false 일 때 "Already scheduled" 같은 표시 가능 |
| 09-30 17:46 | `/due`·`/daily-review` 단어에 `nextIntervals` 추가 (가드 대상은 null) | VOC-1.3.3 | 추가 필드. 1.3.4 에서 버튼 라벨로 사용 |
| 09-30 17:48 | 미사용 코드 삭제(엔드포인트 영향 없음): 랜덤 8단어 게임·기한+신규 혼합 큐 | VOC-1.4.2 | 없음 |
