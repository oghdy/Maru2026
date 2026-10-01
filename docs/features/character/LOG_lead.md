# CHR — char-lead 세션 로그

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후/후임 인수 시 여기부터)
- 현재 태스크: 없음 — Step 1.6 캐릭터 전 태스크 완료(CHR-1.6.4.3 ✅). PM_SYNC S-006 재머지 요청(add2fbb) main-pm 응답 대기
- 다음 할 일: 버그 수정 대기 모드. 기능 세션·main-pm 이 캐릭터 버그를 PM_SYNC/REQUESTS 로 주면 char-dev(코드)·char-asset(이미지)에 지시 → 검수 → 재머지 요청. 동결 15:00 이후 버그만
- 이력 요약: 규격 v1.0(09-30 22:50) → 갤러리·에셋 14/14 → 🚦 승인(10-01 00:10) → main 머지 07fd325 → 기능 적용 21/21 리뷰 합격(S-005) → R-004 수정 add2fbb(S-006)
- 에셋: 14/14. 캐릭터 교체 시 raw 에 같은 파일명으로 넣고 `docs/features/character/tools/process_characters.py` 실행 → 커밋(기능 코드 0줄)
- 막힌 것 / 기다리는 것: main-pm S-006
- 실행 중인 것: 갤러리(char-dev, iPhone 16 Plus) — 필요 없으면 종료해도 됨
- 메인 PM 에게: S-006 [응답필요]

## 기록 (시간순 추가만)

### 09-30 22:55 · CHR-1.6.0.1 완료
- CHARACTER_API v1.0 확정: 연출 원칙 5개(§0), 공개 API 보강(`reactionKey` — 같은 기분 재반응 / `settleToIdleAfter` — 기능 세션이 타이머 안 짜도 되게 / `entrance`·`interactive`·`semanticLabel`·`precache`, Bubble `side`·`typewriter`·`onTypingDone`), 기분×캐릭터별 모션 수치 표(§2.3), 바닥 그림자, cheer 파티클, 에셋 폴백(없는 표정 → idle 이미지 → 플레이스홀더)을 **범위 축소 장치**로 명시, compact 모드(≤56dp)
- 판단 근거: blink PNG 는 idle 눈이라 다른 표정 위에 덮으면 표정이 깨짐 → 깜빡임은 idle 전용. talking 입 벙긋(idle↔talking 교대)은 팔 포즈가 달라 튐 → 몸 들썩임+지터로 대체
- PLAN: 태스크 세분화(1.6.1.4 Bubble, 1.6.1.5 파티클·fidget(P1), 1.6.1.6 에셋 파이프라인), 역산 일정표, 범위 축소 4단계
- PROMPTS.md 신설: char-dev·char-asset 첫 프롬프트
- ASSETS.md: 후처리 담당 char-asset 으로 정정, raw 마감 10/1 08:00

### 09-30 23:12 · raw idle 2장 검수 → 승인
- rabbit_idle / turtle_idle: 1254², RGBA 투명 배경 ✅, 스타일·팔레트·외곽선 일관 ✅, 브랜드 보라 소품 ✅, 40dp 축소에서도 식별 ✅ (screenshots/lead_idle_review_sizes.png)
- 주의: 토끼가 캔버스 높이 97%(귀 끝 상단 여백 1.6%) → 변형(cheer·happy 만세)에서 귀·팔 잘릴 위험. 하도윤에게 "zoom out slightly" 문장 추가 안내. 거북이는 85%로 여유
- 캐릭터 간 크기 차(토끼>거북이)는 후처리에서 각자 idle 기준 ~80% 로 맞춤

### 09-30 23:35 · 1차 검수 (char-dev P0 3개 + char-asset 1.6.1.6·1.6.2.1 1차) → 합격 + 경미한 수정
- 커밋 범위: `git diff --stat main..HEAD` 13파일, 전부 소유 경로(lib/shared/characters, lib/dev, test/shared/characters, assets/characters, pubspec +2). worktree clean, pubspec.lock·Registrant 미포함 ✅
- 코드: 공개 API §1 일치, barrel + src 구조, 캐릭터당 Ticker 1개(Timer 없음), AnimatedBuilder+Transform 만 매 프레임, 표정 바뀔 때만 setState, RepaintBoundary, 매니페스트 조회로 폴백(예외 없음), 반응은 현재 포즈에서 이어서 시작 ✅
- 시뮬레이터 직접 확인(iPhone 16 Plus): Stage·Grid·Sizes·Bubbles·Scenario, 실제 idle PNG 표시, 한글 keep-all 줄바꿈 ✅. 필름스트립으로 🐰 happy 2회 점프·cheer 큰 점프+회전·sad 가라앉음, 🐢 절반 높이·회전 없음 확인 ✅
- 발견: 갤러리 Sizes 180dp 가 가로 스크롤로 잘림 / 새 PNG 반영 시 static 매니페스트 캐시 가능성 / 연속 정답 재반응 미확인 → CHR-1.6.1.7 지시
- char-asset: contact sheet·크기 확인. 토끼 흰 스티커 테두리는 수용(재생성 안 함)
- 필름스트립 기준 모션 수치 조정 전부 승인 → CHARACTER_API §5 기록
- 후속 지시: PROMPTS.md "09-30 23:35" 2건

### 09-30 23:50 · raw 14장 직접 검수
- 14장 전부 같은 캐릭터(얼굴·색·소품 일치) ✅. sad 표현 특히 좋음. rabbit_cheer·turtle_cheer 한 발 점프 포즈 수용
- rabbit_blink: ^^ 감은 눈 자체는 OK(120ms 노출), 전신이 다시 그려져 idle 대비 3.5% 어긋남 → 하도윤에게 ChatGPT 선택 영역 편집(눈만)으로 재생성 안내. char-asset 에 머리 영역 로컬 정렬 + 눈 패치 feather 합성 재시도 지시
- 폴백: blink 최종 불가 시 해당 캐릭터만 깜빡임 생략(숨쉬기·잔동작 유지) — 승인 차단 요소 아님

### 09-30 23:58 · 2차 검수 (char-dev 1.6.1.7·1.6.1.5·1.6.1.3) → 합격
- 커밋 d21f4fc·7a80ddb·c5478df·0ad33b8 소유 경로만. 직접 실행: `flutter analyze lib/shared/characters lib/dev test/shared/characters` No issues, `flutter test test/shared/characters` 18 passed (+2 skip)
- 스크린샷: Sizes 한 화면(8개), cheer 파티클 정점 부채꼴+낙하 확인
- char-dev 대기(코드 동결). 에셋 반영은 R(hot restart)
- 하도윤: rabbit_blink 브러시 없이 강한 편집 프롬프트 전달(PROMPTS.md). 실패해도 승인 비차단

### 10-01 00:05 · 🚦 승인 요청 (CHR-1.6.2.2)
- 직접 시뮬레이터에서 촬영: Stage(토끼 cheer·거북이 idle), Grid 12표정 동시, Sizes(거북이 blink 순간 포착 → turtle_blink 동작 확인), typewriter 중간(거북이 talking·말풍선 크기 고정), Scenario Wrong(토끼 sad + 거북이 thinking 힌트), Complete(토끼 공중·그림자 축소). 파티클은 char-dev 슬로모션 필름스트립
- 관찰(비차단): 포즈가 크게 다른 표정 전환(sad→cheer) 시 150ms 크로스페이드 중 두 포즈가 잠깐 겹쳐 보임 → 승인 후 선택 조정안(크로스페이드 90ms)으로 제시

### 10-01 00:25 · 🚦 승인 → CHR-1.6.3.1 §3 구체화 → PM_SYNC S-004
- 하도윤 승인(00:10). 캐릭터 교체 시 영향 질문 → PNG 동일 파일명 교체·스크립트 재실행만, 기능 코드 0줄(공개 API 고정), 방식 변경(Rive 등)도 `lib/shared/characters` 내부만 — 답변함
- rabbit_blink 재생성분 bf572dc 확인: idle 대비 차이 bbox 가 눈 영역(2242px)뿐 → 14/14
- 기능 화면 조사(Explore): 레슨 agglutinative 피드백 박스·완료 아이콘, 단어장 Match 라운드 라벨·GameOver·요약, 미션 🐰🐢 이모지 11곳·수료증, 실험실 한글 결과·로딩·설명 카드
- §3 v1.1 작성: 공통 규칙 8, 기능별 P0 3~5개·P1, 공수 40~60분/기능, PM 화면 제외
- PM_SYNC S-004: 머지(bf572dc, 28파일 소유 경로만) + pub get·완전 재시작 + P0 13:00 마감 + 리뷰용 스크린샷 경로

### 10-01 01:00 · CHR-1.6.4.1 기능 적용 리뷰 → PM_SYNC S-005
- 스크린샷 31장 전수(기능별 몽타주로 확인) + 기능 브랜치 diff 검사(src import 0, 캐릭터·assets·pubspec 수정 0). 레슨 4·단어장 3·미션 8·실험실 4 + 홈 1 전부 합격
- vocab game_screen diff 348줄 → `-w` 로 확인: dart format + Round 라벨 위치 이동, 로직 동일
- mission C8 오류 배너 = 프록시 강제 500(LOG_fe 확인)
- REQUESTS R-004(lesson-fe): 첫 표시 빈칸 → CHR-1.6.4.2 char-dev 지시, 문서 팁 추가
- 선택 제안: LAB Combine 결과 한국어 음절 줄바꿈(P2)

### 10-01 01:25 · CHR-1.6.4.2 검수 → 합격 · CHR-1.6.4.3 재머지 요청(S-006)
- add2fbb: 4파일 소유 경로, analyze 0, test 23 통과(직접 실행). 콜드 스타트 슬로모션 스크린샷: 몸·그림자 동시 페이드인
- 판단: cacheWidth 축소 디코드 폐지(512px 공유, ~16MB) 승인 — 측정 근거(말풍선 빈칸 106ms→1ms), 14장 규모라 메모리 부담 작음. CHARACTER_API §2.5·§5 갱신
- `--dart-define=GALLERY_SLOWMO=true` 갤러리 옵션 추가(기본 off) 수용

