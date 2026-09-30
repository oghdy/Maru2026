# LAB — Language Lab — API CONTRACT (BE ↔ FE 약속)

> **BE 가 먼저 갱신**하고 FE 에 알린다 (LOG + STATUS 메모). 기존 필드 삭제·이름변경 대신 **필드 추가** 우선.
> 공통 응답: `ApiResponse<T>` = `{ "status": int, "message": string, "data": T }` · 인증: `Authorization: Bearer <JWT>`
> 로컬: `http://localhost:8084`

## 1. 현재 엔드포인트 (Step 1.1 에서 BE 가 실제 응답 보고 작성)
<!-- 엔드포인트마다: 메서드 경로 / 요청 예시 / 응답 예시(data 부분) / 오류 시 상태코드 -->
> 09-30 18:20 lab-be 가 :8084 에 실제 호출해서 기록 (LAB-1.1.1). **현재 코드 기준** — 1.2.x 에서 바뀌는 부분은 §1-3 참고.
> 두 엔드포인트 모두 인증 필요(토큰 없으면 403). 사용자별 데이터 없음 — 캐시는 모든 사용자 공유.

### 1-1. `POST /api/lab/explore` — 한 카테고리로 문장 변형 3개
요청:
```json
{ "inputText": "고양이가 자요", "category": "tense" }
```
- `category`: FE 는 `tense` · `politeness` · `negation` · `emotion` 을 보냄 (칩 라벨 첫 단어 소문자).
- 캐시 키 = (정규화된 `inputText`, `"explore:" + category`). 정규화·검증은 §1-5.

응답 `data` (배열, 보통 3개):
```json
[
  {"text":"고양이가 잤어요","type":"Past Tense","explanation":"Used to describe an action that has already happened."},
  {"text":"고양이가 자요","type":"Present Tense","explanation":"Used to describe an action that is currently happening or a habitual action."},
  {"text":"고양이가 잘 거예요","type":"Future Tense","explanation":"Used to describe an action that is expected or planned to happen in the future."}
]
```
- `text` 한국어, `type`·`explanation` 영어 (옛 캐시도 영어).

### 1-2. `POST /api/lab/combine` — 여러 수식어를 한 문장에
요청:
```json
{ "inputText": "고양이가 자요", "modifiers": ["과거", "반말", "부정문"] }
```
- `modifiers`: FE 는 한국어 값을 보냄 — 시제 `과거|미래|현재`, 높임 `반말|존댓말`, 문장 `의문문|감탄문|평서문`, 부정 `부정문|긍정문` (그룹당 최대 1개).
- 캐시 키 = (정규화된 `inputText`, `"combine:" + 정렬된 modifiers 를 ,로 연결`) → **순서 무관 HIT 확인함** (`["의문문","미래"]` 로 `combine:미래,의문문` 캐시 HIT).

응답 `data` (객체):
```json
{ "text":"고양이가 안 잤어", "englishTranslation":"The cat didn't sleep", "explanation":"This is an informal past tense negative statement, ..." }
```

### 1-3. 실측 (09-30 18:20, 로컬 :8084)
| 호출 | 결과 | 소요 |
|---|---|---|
| explore HIT (`라면 먹어요`/negation) | 200, 3개 | 2.3s (서버 기동 직후 첫 요청 — 워밍업) |
| explore MISS (`고양이가 자요`/tense) | 200, 3개 | **8.0s** |
| explore 같은 입력 재호출 (HIT) | 200 | **0.01s** |
| combine HIT (순서 뒤집어 보냄) | 200 | 0.07s |
| combine MISS (`과거,반말,부정문`) | 200 | 3.7s |

### 1-4. 현재 오류 동작 (문제 — LAB-1.2.1·1.2.3 에서 고침)
| 상황 | 현재 | 문제 |
|---|---|---|
| `inputText: ""` | **200** + `[{"text":"Error: Input sentence is empty.","type":"Input Error",...}]` | Gemini 가 만든 오류 문장을 정상 결과처럼 반환 **+ 캐시에 저장됨** |
| `modifiers` 누락/null | 500 `"An unexpected error occurred"` | 400 이어야 함 |
| Gemini 오류·타임아웃·JSON 깨짐 | 500 `"An unexpected error occurred"` (타임아웃 없음 → FE 60s receiveTimeout 까지 대기) | 원인 구분 불가 |
| 토큰 없음 | 403 (본문 없음) | (공통 보안 설정, PM 소유) |

### 1-5. 오류 응답 (LAB-1.2.1·1.2.3 적용됨, 09-30 18:31)
- 성공 응답 모양은 **그대로**. explore 는 이제 **항상 정확히 3개** (Gemini 가 더 주면 앞 3개, 덜 주거나 빈 필드면 오류).
- 오류는 `{status, message, data:null}` + 아래 HTTP 상태. `message` 는 **영어 사용자용 문장** → 그대로 보여주고 Retry 버튼 달면 됨.

| HTTP | message (그대로 표시 가능) | 언제 |
|---|---|---|
| 400 | 아래 표 참고 | 입력 문제 (LAB-1.2.3, b9eccb8) |
| 502 | `The AI returned an unexpected answer. Please try again.` | AI 응답 형식 깨짐·개수 부족·안전필터 차단 |
| 503 | `The AI service is unavailable right now. Please try again in a moment.` | Gemini HTTP 오류(쿼터 429 등)·네트워크 |
| 504 | `The AI took too long to respond. Please try again.` | 서버가 **40초** 뒤 끊음 (FE receiveTimeout 60s 보다 먼저) |

**400 상세 (서버가 Gemini 호출 전에 거절):**

| 조건 | message |
|---|---|
| `inputText` 없음/공백만 | `Please enter a sentence.` |
| 정규화 후 200자 초과 | `Please keep the sentence under 200 characters.` → FE 입력창 `maxLength: 200` 권장 |
| 한글이 한 글자도 없음 | `Please enter a sentence in Korean.` |
| `category` 가 `tense`·`politeness`·`negation`·`emotion` 아님 (대소문자·앞뒤 공백은 허용) | `Please choose one of the categories.` |
| `modifiers` 없음/빈 배열 | `Please select at least one modifier to combine.` |
| 목록에 없는 modifier | `Please choose modifiers from the list.` |
| 같은 그룹에서 2개 (예: 과거+미래) | `Please choose at most one option from each group.` |
| JSON 본문 깨짐·타입 틀림 | `Invalid request.` |

- 정규화: `inputText` 앞뒤 공백 제거 + 연속 공백/줄바꿈 → 공백 1개 후 캐시 조회. modifier 중복은 무시.

- 실패한 결과는 캐시에 저장하지 않으므로 Retry 하면 다시 Gemini 를 호출함.
- 확인: 가짜 Gemini(로컬 스텁)로 504(40.0s)·503(429)·502(형식 깨짐) 실제 서버 응답 확인.

## 2. 데이터 구조 (DB JSON·엔티티 중 FE 가 의존하는 것)
- 테이블 `ai_cache` (엔티티 `AiCache`): `input_text` TEXT · `transformation_type` VARCHAR(500) · `output_text` TEXT · `english_translation` · `explanation` · `created_at`. UNIQUE(`input_text`,`transformation_type`).
  - explore: `output_text` = 결과 JSON 배열 문자열 그대로 (`english_translation`·`explanation` null)
  - combine: `output_text` = 결과 문장, 번역·설명은 각 컬럼
- FE 는 DB 에 직접 의존하지 않음. `maru_lab` 캐시 39건 (explore 21, combine 18) — 발표 데모용 입력은 대부분 HIT.

## 3. 변경 이력
| 시각 | 변경 | 태스크 | 호환성 (FE 수정 필요?) |
|---|---|---|---|
| 09-30 18:30 | 오류 시 400/502/503/504 + 영어 message (이전: 전부 500 "An unexpected error occurred"). explore 결과 항상 3개. 서버 측 Gemini 타임아웃 40s | LAB-1.2.1 (0106947) | 호환. FE 는 `message` 표시 + Retry 권장 (1.2.4) |
| 09-30 18:31 | 입력 검증 400 (빈 문장·200자 초과·한글 없음·모르는 category/modifier·그룹 중복·깨진 JSON). 입력 정규화(trim·연속 공백) 후 캐시 조회. 패치 `lab_001` 로 도달 불가 캐시 행 삭제 | LAB-1.2.3 (b9eccb8) | 호환 (FE 가 보내는 값은 전부 허용). 권장: 입력창 maxLength 200 |
