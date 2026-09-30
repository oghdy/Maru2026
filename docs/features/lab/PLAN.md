# LAB — Language Lab PLAN

- 세션: `lab-be`, `lab-fe` · worktree `/Users/hadohadopapi/Desktop/Maru-wt/lab` · 브랜치 `feat/lab`
- 서버 :8084 · DB `maru_lab` · 시뮬레이터 iPhone 16 Pro (iOS 18.5)
- 범위: Hangeul Lab(기기 내 유니코드 조합 + TTS) · AI Grammar Lab(Explore 4카테고리 / Combine 수식어) · Gemini(`gemini-2.5-flash`) · AI 캐시
- 발표 주장(맞춰야 할 것): "Explore: 3가지 변형", "Combine: 다중 수식어 한 문장", "캐시 키 정렬로 순서 무관 히트", "캐시 HIT 0.1초"
- 참고: 홈의 Language Lab 진입 버튼은 PM 소유. 작업량이 가장 가벼움 → 끝나면 STATUS 에 알리고 PM 지시로 QA 지원.
- 동결: 10/1 15:00 · 우선순위 P0 > P1 > P2 · Gemini 호출 비용 주의

## Phase 1 — 기능 수정

### Step 1.1 현황 점검
- [x] LAB-1.1.1 [BE] P0 서버 기동, `POST /api/lab/explore`·`/api/lab/combine` 캐시 HIT/MISS 각각 호출 → `API_CONTRACT.md` 에 현재 요청/응답 기록. `AiLabServiceTest`·`GeminiServiceTest`·`AiCacheRepositoryTest` 결과 기록
- [x] LAB-1.1.2 [FE] P0 Hangeul Lab·AI Grammar Lab(Explore 4종, Combine 조합) 점검, 새 문제는 태스크 추가 — (코드 변경 없음, LOG_fe 09-30 참고)

### Step 1.2 오류·로딩 (P0)
- [x] LAB-1.2.1 [BE] P0 Gemini 오류·타임아웃·JSON 파싱 실패 → 적절한 HTTP 오류 + 사용자용 메시지. 응답 개수·필드 검증(Explore 는 3개) — 0106947
- [x] LAB-1.2.2 [BE] P0 API 키를 URL 쿼리스트링 → `x-goog-api-key` 헤더로 (실사 §2-D, `GeminiService.java:38`). 오류 로그에 URL(키) 노출 금지 — 4430498
- [x] LAB-1.2.3 [BE] P1 입력 검증: 빈 문장·과도한 길이 거절, 캐시 키용 입력 정규화(trim·연속 공백) — b9eccb8 (+패치 lab_001)
- [x] LAB-1.2.4 [FE] P0 예외 원문 빨간 글씨 노출(`lab_screen.dart:416`) → 영어 안내 + Retry — be85157
- [x] LAB-1.2.5 [FE] P0 첫 요청(캐시 MISS 최대 ~30초) 로딩 UX: 진행 문구/스켈레톤, 중복 요청 방지 — b6bf419

### Step 1.3 문구·디자인 (P1)
- [x] LAB-1.3.1 [FE] P1 칩 "Tense (시제)" 식 병기 → 영어 라벨 + 작은 한국어 보조 등 일관된 규칙 (실사 §8-P1#9, `lab_screen.dart:24-27`) — 8b5fb0e
- [x] LAB-1.3.2 [FE] P1 Hangeul Lab `blueAccent`·파란 자모 카드 → theme 색 (실사 §8-P1#11) — 70c3d19
- [x] LAB-1.3.3 [FE] P1 Hangeul Lab: 받침 없음/있음 조합, 결과 발음 TTS, 작은 화면 레이아웃 확인 — 70c3d19
- [x] LAB-1.3.5 [FE] P1 (1.1.2 발견) 예문 칩: 한국어 키보드 없는 학습자도 탭으로 입력 가능하게 (입력창 아래 예문 2~3개) — 349cd87
- [x] LAB-1.3.6 [FE] P1 (1.1.2 발견) Grammar Lab 하드코딩 색(`Colors.deepPurple`, `Colors.blue.shade50/900`, `Colors.red`) → theme colorScheme — 444f6ff
- [x] LAB-1.3.7 [FE] P1 (1.1.2 발견) Grammar Lab 입력 영역이 스크롤 불가 Column → 키보드+Combine 펼침 시 작은 화면 overflow 위험. Explore 칩 4번째(Emotion)가 화면 밖(가로 스크롤)이라 안 보임 → Wrap — 8a887d0
- [x] LAB-1.3.8 [FE] P1 (API_CONTRACT §3 18:31 권장) 입력창 maxLength 200 + 서버 400 실제 문구 표시 확인 — 418e951
- [x] LAB-1.3.4 [BE] P2 캐시 HIT/MISS 소요 ms 를 INFO 로그로 (발표 "0.1초" 측정 근거, 입력 원문·키 제외) — b1069ea

### Step 1.4 여유 시
- [x] LAB-1.4.1 [FE] P2 결과 카드 "복사"/TTS 듣기 — 06c96b5
- [ ] LAB-1.4.2 [BE+FE] P2 PM 지시에 따른 QA 지원
