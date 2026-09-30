# VOC — Vocabulary — BE 세션 로그 (`vocab-be`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음 — PLAN 의 [BE] 태스크 전부 완료 (1.1.1, 1.1.3, 1.2.3, 1.2.5, 1.2.8, 1.3.1, 1.3.2, 1.3.3, 1.4.2)
- 다음 할 일: vocab-fe 요청 대응, PM 통합 때 회귀 수정. 새 문제 발견 시 PLAN 에 태스크 추가
- 막힌 것 / 기다리는 것: R-002(테스트용 JWT_SECRET, PM) — 우회 중
- 실행 중인 것: `scripts/run_backend.sh vocab` 백그라운드 (:8082, DB maru_vocab), 09-30 17:45 재시작(최종 코드)
- 테스트 실행법: backend/maru 에서 `set -a; source ../../.env; set +a` 후 `./gradlew -I <scratch>/exclude-broken-tests.gradle test --tests ...` (init 스크립트 = MissionChatDtoTest·MissionChatControllerTest 제외, MSN-1.1.3 머지 전까지)
- 마지막 커밋: 288c58d [VOC-1.4.2]
- PM 에게: 실사 §6-(3) 관련 사실 변화 — (1) FsrsAlgorithm 이 FSRS-4.5 표준식+기본 w[] 로 계산(1.3.1), (2) Word Study 에서도 기한 지난 단어는 정식 복습 반영(1.3.2), (3) 미사용 getDueWords 등 삭제(1.4.2). 덱 Word Study 는 여전히 "등급·ID 순 30개 레슨"이고 기한 기반 추천 큐는 아님 — 발표 문구는 "오늘의 복습은 FSRS 복습 기한 기반" 으로 한정 권장.
- 짝 세션에게: API_CONTRACT §1 이 최신. 서버 최신 코드로 가동 중.

## 기록 (시간순 추가만, 수정 금지)

### 09-30 17:33 · VOC-1.1.3 ✅ (8a78d48)
- `VocabularyServiceTest`: `FsrsProgress` import 누락 + 생성자에 `UserStatsService` 인자 누락 → mock 추가(가드 테스트에 `recordStudyActivity` 호출 검증 1줄 추가). 서비스 코드 변경 없음.
- 같이 발견해 수정(테스트만): `VocabularyControllerTest.getDueWords` 가 컨트롤러가 실제 호출하지 않는 `getDueWords` 를 mock → `getDueWordsByLesson` 으로. `VocabularyIntegrationTest`: 픽스처 User 에 `oauthProvider`(NOT NULL) 누락 → 추가, `@WithMockUser` principal 이 UserDetails 라 `@AuthenticationPrincipal String` 이 null → 400 이던 것을 JWT 필터와 같은 String principal 로 설정.
- 확인: `compileTestJava` 에서 Vocabulary 오류 0건 (남은 오류는 MissionChatDtoTest:20, MissionChatControllerTest:37 = MSN 소유).
- 테스트 결과(Mission 2개 제외 init 스크립트 + .env 로드): VocabularyServiceTest 5/5, FsrsAlgorithmTest 4/4, VocabularyControllerTest 4/4, VocabularyIntegrationTest 2/2, FsrsProgressRepositoryTest 2/2, WordRepositoryTest 1/1 → **18/18 통과**.
- 주의: `VocabularyIntegrationTest` 는 `JWT_SECRET` 환경변수 없으면 컨텍스트 로드 실패(WeakKeyException). test 프로파일에 값 없음 → R-002.

### 09-30 17:33 · VOC-1.1.1 ✅ (문서만)
- 서버 :8082 기동 확인. dev_tester_be 로 전 엔드포인트 curl → API_CONTRACT §1 작성.
- 발견: (1) 레슨 완료 JSON 키 `completed` vs FE `isCompleted` 불일치(+BE false 고정) → 1.2.3 에서 처리. (2) `GET /game/{deck}?lessonNumber=99` → 500 → 1.2.5. (3) `POST /review` rating 9 → 조용히 GOOD, 없는/누락 wordId → 500 → 새 태스크 VOC-1.2.8 추가. (4) `lessonNumber=0` → 400(OK). (5) 없는 deckId 레슨 → 200 [] (OK).
- curl 로 dev_tester_be 에 word 1403, 1404 평가 기록 생김(GOOD → state 2, S=4, +4일). dev_tester 데이터는 건드리지 않음.

### 09-30 17:36 · VOC-1.2.3 ✅ (787e014)
- 완료 정의: 레슨(덱 내 30단어 조각, `/due` 와 같은 정렬)의 모든 단어에 학습 기록(state>0)이 있으면 완료. 쿼리 2개(덱 단어 ID 정렬 목록 + 사용자 학습 단어 ID)로 계산 — 레슨마다 쿼리하지 않음.
- 추가: `WordRepository.findIdsByCategoryIdOrderByLevelAscIdAsc`, `FsrsProgressRepository.findStudiedWordIdsByCategory`, `WordLessonDto.studiedWords`, `isCompleted` JSON 키(`@JsonProperty`, 기존 `completed` 유지). 스키마 변경 없음.
- 테스트: `VocabularyServiceTest.getLessonsByDeckId_marksCompletedFromStudyRecords`(65단어 → 30/30/5, 학습 40개 → 완료 true/false/false) 추가. Vocabulary 관련 테스트 전부 통과(Service 6, Controller 4, Integration 2, repository 전부).
- curl(서버 재시작 후, dev_tester_be): 덱 13 레슨1 30단어를 LESSON/GOOD 으로 평가 → `{"lessonNumber":1,"totalWords":30,"studiedWords":30,"completed":true,"isCompleted":true}`, 레슨2 `studiedWords 0, false`. 덱 12 레슨2 `studiedWords 1`(앞서 평가한 1403).

### 09-30 17:38 · VOC-1.2.5 ✅ (fba1f23)
- 범위 밖·빈 레슨 → `NoSuchElementException` → 404 "No words found for this lesson." (기존 RuntimeException 500). `lessonNumber<1` → 400.
- 추가 발견·수정: 레슨 안에서 뜻이 같은 단어(시/도시=city, 골목/골목길=alley 등)가 **193개 레슨 중 98곳**. FE 는 pairId 로 정답 판정하므로 "시"↔"city"(도시의 타일)를 고르면 맞는데도 오답 처리됨 → 게임에서만 뒤에 나온 중복(뜻 또는 한국어 표기)을 제외. Word Study·레슨 완료 계산에는 영향 없음.
- `VocabularyGameTileDto.totalWords` 추가(모든 타일 동일 값). 5개 미만 묶음도 그대로 반환(최소 1쌍) — 라운드 분할은 FE.
- 테스트: `generateGameTiles_skipsAmbiguousPairs_andCarriesTotalWords`, `generateGameTiles_rejectsEmptyOrInvalidLesson` 추가 → VocabularyServiceTest 8/8, Controller 4/4, Integration 2/2.
- curl(재시작 후): 덱12 레슨2 → 58타일 totalWords 29, ENGLISH "city" 1개 / 레슨16(11단어) → 22타일 totalWords 11 / lessonNumber=99 → 404 / 0 → 400 / 없는 덱 → 404.

### 09-30 17:40 · VOC-1.2.8 ✅ (c6ab127)
- `ReviewRating.fromValue` 추가(범위 밖 → IllegalArgumentException=400). 컨트롤러: wordId 누락 → 400. 서비스: `existsById` 실패 → NoSuchElementException=404 (기존 FK/NPE 로 500).
- 테스트: Controller `submitReview_rejectsInvalidRating`, `submitReview_rejectsMissingWordId`, Service `submitReview_rejectsUnknownWord` 추가, 기존 submitReview 테스트 3개에 existsById 스텁 → Controller 6/6, Service 9/9, Integration 2/2, Fsrs 4/4.
- curl(재시작 후): rating 9 → 400, wordId 99999999 → 404, wordId 누락 → 400, 정상(1405, EASY, DAILY_REVIEW) → 200 · DB state 2 / S 6.

### 09-30 17:42 · VOC-1.3.1 ✅ (4a9e650)
- `FsrsAlgorithm` 전면 교체: FSRS-4.5 표준식(R(t,S)=(1+19/81·t/S)^-0.5, S0=w[G-1], D0=w4-(G-3)w5, 평균회귀 난이도, 성공/망각 안정성식, 목표 기억률 0.9 간격) + 기본 파라미터 17개(py-fsrs 3.x 기본값). 이전 w[](FSRS v4 기본값)는 계산에 안 쓰였음 → 이제 모든 계산이 w 사용.
- 앱 규칙: 분 단위 학습 단계 대신 AGAIN 만 5분 재시도(기존 동작 유지), 나머지 일 단위. HARD≤GOOD<EASY 간격 보정. lapses 는 복습 단계 카드의 AGAIN 만 셈(신규·Learning 실패 제외).
- `preview(card, now)` 추가 — 네 평가 결과를 한 번에 계산(`calculateNextState` 도 이걸 사용) → 1.3.3 에서 사용.
- 스키마 변경 없음. 기존 DB 값(S 1~216, D 1~9)은 FSRS 범위 안이라 이관 불필요.
- 테스트: `FsrsAlgorithmTest` 재작성 7개(초기값 정확값, R(S,S)=0.9, 간격 최소1/최대36500, AGAIN, 기한 복습·간격 순서, 간격 효과(늦게 성공할수록 S 증가 큼·같은 날 재복습 S 불변), D 범위). ServiceTest 기대값 4.0/5.0 → 3.7145/5.1618, 기존 카드에 last_review 설정. IntegrationTest 시간 경과 조작에 last_review 도 과거로(FSRS 는 경과일로 계산). → Fsrs 7/7, Service 9/9, Controller 6/6, Integration 2/2, repo 3/3.
- curl(재시작 후, dev_tester_be): 1406 LESSON GOOD → S 3.7145 D 5.1618 +4일 / 1407 AGAIN → Learning S 0.4872 D 7.6214 +5분 / 1406 을 4일 전 학습으로 조작 → daily-review 에 등장 → GOOD → S 14.8081, +15일. 손계산(R≈0.894 → S'≈14.80)과 일치.
- 미확인: 공식 참조 구현(py-fsrs)과 수치 교차 검증은 못 함(패키지 설치 안 함). 공식·파라미터는 FSRS-4.5 문서 기준.

### 09-30 17:44 · VOC-1.3.2 ✅ (45f987b)
- 가드 조건을 "LESSON + state>0" → "LESSON + state>0 + **next_review_date > now**" 로 좁힘. 기한 지난 단어는 Word Study 에서 평가해도 정식 복습 반영(이전엔 AGAIN 도 버려져 실제 망각 정보가 사라졌음). 기한 전 재평가는 계속 무시(발표의 Spacing Integrity Guard 의도 유지).
- 서비스 `submitReview` 반환 `FsrsProgress` → `ReviewOutcome(progress, applied)` 레코드. 컨트롤러 응답 data `null` → `ReviewResultDto{applied,state,nextReviewDate}`(새 DTO `dto/ReviewResultDto`). 서비스 Javadoc 에 가드 규칙·이유 문서화, API_CONTRACT §1-6 갱신.
- 테스트: 가드 테스트에 미래 next_review_date + applied=false 검증, 새 테스트 `submitReview_appliesInLessonMode_whenCardIsDue`, Controller submitReview 가 data 3필드 검증 → Service 10/10, Controller 6/6, Integration 2/2, Fsrs 7/7, repo 3/3.
- curl(재시작 후, dev_tester_be): 1406(복습일 +15일) LESSON AGAIN → `applied:false`, 그대로 / 1404 를 기한 지남으로 조작 후 LESSON GOOD → `applied:true`, +18일 / 새 단어 1408 EASY → `applied:true`, +14일.

### 09-30 17:46 · VOC-1.3.3 ✅ (262ce98)
- `WordDueDto.nextIntervals`(Map, 키 AGAIN/HARD/GOOD/EASY → "5m"/"1d"/"4d"/"14d") 추가, `@Builder(toBuilder=true)`. 값은 `FsrsAlgorithm.preview()` (실제 저장 계산과 동일 경로)로 계산.
- `/due`: 새 단어·기한 지난 단어는 채움, 이미 학습+기한 전(가드 대상)은 null. `/daily-review`: 항상 채움.
- 가드 조건을 `isStudiedAndNotDue()` 한 곳으로 모음(submitReview·getDueWordsByLesson 공용). 카드 파싱 `toCard()` 추출.
- 테스트: `getDueWordsByLesson_attachesIntervalPreview`, `formatInterval` 추가 → Service 12/12, Controller 6/6, Integration 2/2, Fsrs 7/7, repo 3/3.
- curl(재시작 후, dev_tester_be): 덱12 레슨2 — 1403(학습·기한 전) `null`, 1422(새 단어) `5m/1d/4d/14d`. 1407(AGAIN 후 Learning, S 0.49)을 기한 도래로 조작 → daily-review `5m/1d/2d/3d` (낮은 안정성에서 HARD<GOOD<EASY 순서 보정).

### 09-30 17:48 · VOC-1.4.2 ✅ (288c58d)
- 판단: 호출처 0 인 두 경로 삭제. ① 랜덤 8단어 게임(`getRandomWordsForGame`, `WordGameDto`, `WordRepository.findRandomWordsByCategory`) — 레슨 기반 `/game` 으로 대체됨. ② 기한+신규 혼합 큐(`getDueWords`, `FsrsProgressRepository.findDueCardsByCategory`, `WordRepository.findUnstudiedWordsByCategoryForUser`) — 화면 연결 없음, 동결 전 연결할 FE 작업 없음. 필요하면 `git show 288c58d^:<경로>` 로 복원.
- FE 영향 없음(FE 에 WordGameDto·해당 API 참조 없음 확인).
- 테스트: 서비스 랜덤게임 테스트 삭제. `FsrsProgressRepositoryTest` 2개는 실사용 쿼리 `findDueCardsByUser`(오늘의 복습)로 대상 변경. `WordRepositoryTest` 는 "레슨 완료 계산용 ID 순서 = /due 페이징 순서" 검증으로 교체(등급 섞인 35단어). → Service 11/11, Controller 6/6, Integration 2/2, Fsrs 7/7, repo 3/3. `compileTestJava` 남은 오류는 Mission 2건뿐.
- curl(재시작 후): decks 14 / lessons / due / daily-review / game / review 모두 200.

### 09-30 17:48 · [BE] 전체 요약
- vocab 테스트: 29개 전부 통과 (Service 11, Controller 6, Integration 2, FsrsAlgorithm 7, repo 3).
- 커밋: 8a78d48(1.1.3) 787e014(1.2.3) fba1f23(1.2.5) c6ab127(1.2.8) 4a9e650(1.3.1) 45f987b(1.3.2) 262ce98(1.3.3) 288c58d(1.4.2). 스키마·DB 데이터 변경 없음(패치 SQL 불필요).

