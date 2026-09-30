# LAB — Language Lab — BE 세션 로그 (`lab-be`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음 — [BE] 태스크 1.1.1·1.2.1·1.2.2·1.2.3·1.3.4 전부 완료. 1.4.2 QA 지원은 PM 지시 대기
- 다음 할 일: PM 지시 대기. lab-fe 가 API 관련 요청하면 대응
- 막힌 것 / 기다리는 것: 없음. 테스트는 R-001 미머지라 scratchpad `exclude-broken-tests.gradle` 로 실행 (MissionChatDtoTest·MissionChatControllerTest·VocabularyServiceTest 제외) — lab 테스트 20/20
- 실행 중인 것: `scripts/run_backend.sh lab` (:8084, DB maru_lab) 백그라운드, 19:41 최신 main(859e25a) 동기화 후 재시작. curl 은 `dev_tester_be`
- 마지막 커밋: b1069ea [LAB-1.3.4]
- 짝 세션에게: API 변경은 API_CONTRACT §1-5·§3 참고 (성공 응답 모양은 처음과 동일)
- PM 에게: (1) 패치 `lab_001` Railway 적용 필요. (2) 발표 문구 근거: 서버 로그 `AI Lab timing: <type> cache=HIT|MISS <ms>` — 로컬 실측 HIT 1~2ms(서버) / 4~7ms(클라이언트 curl, 워밍업 후; 첫 요청 35ms·112ms), MISS explore 5.2s·combine 2.8s (Gemini 응답 시간이 대부분). "캐시 HIT 0.1초"는 **사실(로컬 기준 그보다 빠름)**, "2,000ms→100ms"·"비용 90% 절감"은 측정 근거 없음 → "MISS 3~8초 → HIT 0.1초 미만(로컬 실측)" 권장. Railway 에선 네트워크 지연이 더해지니 발표 전 1회 실측 권장. (3) "Explore: 3가지 변형"은 이제 서버가 보장(3개 미만이면 502, 캐시 안 함). "순서 무관 캐시 HIT" 사실(정렬 키, 실측 확인).

## 기록 (시간순 추가만, 수정 금지)

### 09-30 18:25 · LAB-1.1.1 [x] 현황 점검
- 서버 :8084 기동 (18:14). `dev_tester_be` 토큰으로 curl.
- explore HIT 0.01s(워밍업 후) / MISS 8.0s, combine HIT 0.07s(modifier 순서 뒤집어도 HIT — 정렬 키 확인) / MISS 3.7s. → API_CONTRACT §1 기록.
- 발견한 문제: (1) 빈 `inputText` → 200 + Gemini 가 만든 "Error: Input sentence is empty." 가 정상 결과처럼 반환되고 **캐시에 저장됨** (maru_lab 에 `input_text=''` 행 생김 — 1.2.3 에서 정리 패치). (2) `modifiers` null → 500. (3) Gemini 호출 타임아웃 없음(공유 `RestTemplateConfig` 기본값 = 무한) → 1.2.1 에서 GeminiService 전용 RestTemplate 로 우회 예정(config 는 PM 소유). (4) Gemini 응답 개수·필드 검증 없음, 동시 MISS 시 UNIQUE 충돌 → 500 가능. (5) `category` 문자열이 그대로 프롬프트·캐시 키에 들어감(검증 없음).
- 테스트: `AiLabServiceTest` 4/4, `GeminiServiceTest` 1/1, `AiCacheRepositoryTest` 1/1 통과 (`./gradlew -I <scratch>/exclude-broken-tests.gradle test --tests ...`, R-001 우회 방식).
- 커밋 없음 (코드 변경 없음, 문서만).

### 09-30 18:30 · LAB-1.2.1 [x] Gemini 오류·타임아웃·파싱 → HTTP 오류 (0106947)
- `GeminiService`: 공유 `RestTemplateConfig`(PM 소유, 타임아웃 없음)는 안 건드리고 `RestTemplateBuilder` 로 전용 RestTemplate 생성 — connect 5s / read 40s (FE receiveTimeout 60s 보다 먼저 끊음). Boot 3.5 기본 클라이언트가 JDK HttpClient 라 타임아웃이 `HttpTimeoutException` 으로 옴 → 둘 다 처리. `generationConfig.responseMimeType=application/json` 추가(마크다운·잡설 섞인 응답 방지). 후보/parts 없음(안전필터 차단) 시 NPE 대신 BAD_RESPONSE. 예외 메시지·URL 을 로그에 안 남김(키가 URL 에 있음 — 1.2.2 에서 헤더로).
- `AiLabService`: `AiLabException(HttpStatus, userMessage)` — TIMEOUT→504, UNAVAILABLE→503, 형식 오류→502. explore 는 3개 이상 + 각 필드 non-blank 여야 통과(앞 3개만 반환·저장), combine 은 3필드 non-blank. 실패 결과는 캐시 안 함. 캐시 행이 깨졌으면 MISS 처리 후 같은 행 덮어씀. 동시 MISS 로 UNIQUE 충돌 시 결과는 그대로 반환.
- `AiLabController`: 로컬 `@ExceptionHandler` (GlobalExceptionHandler 는 PM 소유라 손 안 댐).
- 테스트: `AiLabServiceTest` 10/10, `GeminiServiceTest` 5/5, `AiCacheRepositoryTest` 1/1 (테스트를 실제 ObjectMapper 기반으로 재작성).
- 실서버 확인: 로컬 가짜 Gemini 스텁(`--gemini.api.url=http://127.0.0.1:18084`)으로 재기동해 504(40.0s)·503(429)·502(1개짜리 배열, explore/combine) 확인, 캐시 미저장 확인. 이어서 실제 Gemini 로 재기동: explore MISS 5.4s(3개)·combine MISS 3.0s·HIT 0.01s.
- 주의/사고: 스텁 테스트 중 lab-fe(dev_tester) 요청 1건이 스텁에 걸려 504 받음. 또 스텁이 요청 경로(쿼리의 API 키 포함)를 scratchpad 로그에 찍어서 즉시 삭제함 — 커밋·문서엔 없음. 1.2.2 에서 키를 헤더로 옮기면 이런 노출 경로 자체가 사라짐.

### 09-30 18:35 · LAB-1.2.2 [x] Gemini API 키 → `x-goog-api-key` 헤더 (4430498)
- `GeminiService`: URL 에 `?key=` 붙이던 것 제거, 헤더로 전달. URL 은 `gemini.api.url` 그대로. 키는 `application.yaml` 의 `${GEMINI_API_KEY}` (변경 없음).
- 테스트: `GeminiServiceTest` 6/6 (URL 에 키 없음·헤더에 키 있음 검증 추가), `AiLabServiceTest` 10/10.
- 실서버: 재기동 후 실제 Gemini MISS(`강아지가 뛰어요`/negation) 200 → 헤더 인증 동작 확인. 서버 로그에 `AIza`/`key=` 0건.

### 09-30 18:31 · LAB-1.2.3 [x] 입력 검증·정규화 (b9eccb8)
- `AiLabService`: `normalizeInput`(strip + `\s+`→공백 1개, 빈 값·200자 초과·한글 없음 → 400), `validateCategory`(tense/politeness/negation/emotion, 소문자화), `validateModifiers`(FE 가 쓰는 10개 한국어 값만, 그룹당 1개, 중복 제거). category 가 프롬프트에 그대로 들어가던 문제 해소. 검증은 캐시 조회·Gemini 호출 전.
- `AiLabController`: 깨진 JSON 본문(`HttpMessageNotReadableException`) → 400 `Invalid request.` (전엔 GlobalExceptionHandler 500).
- 패치 `backend/db/patches/lab_001_delete_unreachable_ai_cache.sql`: 빈 입력·정규화 안 된 입력·한글 없는 입력 행 삭제 (이제 도달 불가). maru_lab 에 2회 실행 → DELETE 1 → DELETE 0 (멱등). 삭제된 1행은 1.1.1 에서 내가 빈 입력으로 만든 `explore:tense` 쓰레기 행. 남은 캐시 47건.
- 테스트: `AiLabServiceTest` 13/13, `GeminiServiceTest` 6/6, `AiCacheRepositoryTest` 1/1.
- 실서버 curl: 400 7종(빈·영어·201자·weather·modifiers 없음·과거+미래·past) + 깨진 JSON 2종 400, 정규화 HIT(`"  라면   먹어요 "`/`Negation` → 기존 캐시 HIT), modifier 중복 HIT 확인.

### 09-30 18:33 · LAB-1.3.4 [x] 캐시 HIT/MISS 소요 ms INFO 로그 (b1069ea)
- `AiLabService`: 검증 후 ~ 반환까지 서버 시간 `AI Lab timing: explore:tense cache=HIT 1ms` / `cache=MISS 5232ms` / `cache=MISS failed(504) ...`. transformation_type(카테고리·수식어)만 찍고 입력 문장은 안 찍음. `GeminiService`: `Gemini API responded in {}ms`.
- 테스트: `AiLabServiceTest` 13/13, `GeminiServiceTest` 6/6.
- 실측(로컬, 재기동 직후, 같은 요청 5회씩): explore HIT 35→2→1→1→1ms, combine(4 수식어) HIT 1ms×5. curl 기준 첫 요청 0.112s, 이후 4~7ms. MISS: explore:emotion 5232ms(Gemini 5196ms), combine:과거,의문문 2817ms(Gemini 2811ms). 로그에 입력 문장 0건 확인.
- 발표 주장 대조: "캐시 HIT 0.1초" → 로컬 실측으로 뒷받침(서버 1~2ms). "순서 무관 HIT" → 사실. "Explore 3가지" → 서버가 보장(1.2.1). "2,000ms→100ms"·"비용 90%" → 여전히 측정 근거 없음(HANDOFF 에 대체 문구 제안).
