# REQUESTS — 세션 → PM 요청함

> 잠금 파일 수정이 필요할 때, 다른 기능에 영향이 있을 때, 막혔을 때 **아래에 추가**한다 (위 항목 수정 금지).
> PM 이 `상태`와 `답변`을 채운다. 요청한 세션은 작업 재개 전 여기서 답변을 확인.

```markdown
### R-000 · <요청 세션> · <YYYY-MM-DD HH:MM>
- 종류: 잠금파일 수정 | 교차영향 | 막힘 | 결정필요
- 내용: 무엇이, 왜 필요한지 (파일:라인)
- 제안: 원하는 변경
- 상태: 대기 | 처리중 | 완료 | 반려
- 답변(PM):
```

---

### R-001 · lesson-be · 2026-09-30 16:45
- 종류: 교차영향
- 내용: `feat/lesson` 브랜치(= main 기준)에서 `./gradlew test --tests <아무거나>` 가 **테스트 컴파일 단계에서 실패**함. 원인 파일(타 기능 소유): `MissionChatDtoTest.java:20`·`MissionChatControllerTest.java:37` (`MissionSetupRequestDto.formality()` 없음), `VocabularyServiceTest.java` (컴파일 오류 10건). 이 때문에 모든 세션이 자기 테스트를 못 돌림.
- 우회(lesson-be): 저장소 밖 gradle init 스크립트로 세 파일을 test sourceSet 에서 제외하고 실행 (`./gradlew -I <scratch>/exclude-broken-tests.gradle test --tests ...`). 저장소 파일은 건드리지 않음.
- 제안: mission-be / vocab-be 가 각자 테스트를 현재 DTO/서비스에 맞게 고치도록 공지. 참고로 `GET /api/units/abc/lessons` 같은 타입 불일치가 GlobalExceptionHandler 에서 500 으로 처리됨(400 이 맞음) — lesson 은 컨트롤러 로컬에서 처리 예정, 공통 처리는 PM 판단.
- 상태: 완료
- 답변(PM): 09-30 20:00 · VOC-1.1.3(8a78d48)·MSN-1.1.3(f98f31a) 완료 → main 머지 후 해소. 09-30 18:50 · 테스트 컴파일 오류는 VOC-1.1.3 / MSN-1.1.3 (각 세션 첫 태스크, P0)으로 배정. 두 태스크가 끝나 main 에 머지되기 전까지는 lesson-be 의 exclude init 스크립트 우회 방식을 계속 사용. 타입 불일치 400 공통 처리(GlobalExceptionHandler)는 PM-1.P.8 로 PM 이 처리.

### R-002 · mission-be · 2026-09-30 17:40
- 종류: 교차영향 (R-001 후속 보고)
- 내용: MSN-1.1.3 완료(f98f31a, feat/mission). Mission 테스트 2개 컴파일 오류 해소, `MissionChatControllerTest` 는 AI 서비스 4개를 `@MockitoBean` 으로 막아 OpenAI 호출 없이 동작(4/4), `MissionChatDtoTest` 2/2. 테스트 환경엔 `JWT_SECRET` 이 없어 `JwtProvider` 생성이 실패하므로 해당 테스트에 더미 `jwt.secret` 을 `@SpringBootTest(properties=...)` 로 주입함. 다른 `@SpringBootTest` 테스트(UserStatsControllerTest 등)도 같은 이유로 실패할 수 있음 → `application-test.yml`(PM 소유 아님? test resources) 에 더미 `jwt.secret` 추가를 PM 이 검토하면 좋겠음.
- 남은 컴파일 오류: `VocabularyServiceTest.java` 만 (VOC-1.1.3).
- 상태: 처리중
- 답변(PM): 09-30 20:00 · 아래 vocab-be R-002 와 동일 건. PM-1.P.10 으로 lesson-be 에 위임(application-test.yml 더미 키).

### R-002 · vocab-be · 2026-09-30 17:33
- 종류: 잠금파일 수정
- 내용: `@SpringBootTest` 테스트(예: `VocabularyIntegrationTest`)는 test 프로파일(`src/test/resources/application-test.yml`)에 `jwt.secret` 이 없어서 `JWT_SECRET` 환경변수가 없으면 컨텍스트 로드 실패(`WeakKeyException`). 로컬은 `.env` 를 source 해서 우회 가능하지만 PM 통합 `./gradlew test` 나 CI 에선 실패.
- 제안: `application-test.yml` 에 테스트 전용 더미 키 추가 (예: `jwt.secret: <base64 32바이트 이상 임의값>`). 운영 키 아님.
- 참고(R-001): VOC-1.1.3 완료(8a78d48) — Vocabulary 쪽 테스트 컴파일 오류 0건. 남은 컴파일 오류는 Mission 2건뿐.
- 상태: 처리중
- 답변(PM): 09-30 20:00 · 승인. PM-1.P.10 으로 lesson-be 에 위임. 머지 전까지는 각자 .env source 우회 유지.


### R-003 · vocab-fe · 2026-09-30 18:17
- 종류: 잠금파일 수정
- 내용: (1) 홈 "Daily Word Review" 배너가 1개일 때 "1 words ready to review" (`screens/home/home_screen.dart` `_buildDailyReviewBanner`). (2) 서버에 연결 못 하면 앱 시작(프로필 게이트, `/api/me`)에서 스피너만 계속 돎 — 오류 문구·재시도 없음(iPhone 17 에서 API_PORT 를 닫힌 포트로 실행해 확인). 참고: Riverpod 3 는 실패한 FutureProvider 를 기본 최대 10회(약 40초) 재시도하며 그동안 loading 상태라, 홈 통계/배너 provider 도 같은 영향이 있을 수 있음.
- 제안: (1) `count == 1 ? 'word' : 'words'`. (2) 게이트 오류 시 영어 안내 + Retry, 필요하면 해당 provider 에 `retry: (_, __) => null`. vocab 쪽 provider(`dailyReviewCountProvider` 포함)는 VOC-1.2.6 에서 이미 자동 재시도 끔.
- 상태: 처리중
- 답변(PM): 09-30 20:00 · 승인. (1)→PM-1.P.4, (2)→PM-1.P.11 로 lesson-fe 에 위임.

### R-0xx · lab-fe · 2026-09-30 20:14
- 종류: 잠금파일 수정 (참고)
- 내용: main(TtsHelper, just_audio 추가) 동기화 후 `flutter pub get` 하면 `frontend/maru/macos/Flutter/GeneratedPluginRegistrant.swift` 가 재생성됨(audio_session·just_audio 등록 추가). 네이티브 폴더는 PM 소유라 feat/lab 에 커밋하지 않고 작업트리에 unstaged 로 남겨 둠.
- 제안: main 에서 pub get 후 재생성된 파일을 PM 이 커밋(macOS 빌드 안 하면 무시해도 무방).
- 상태: 대기
- 답변(PM):

### R-004 · lesson-fe · 2026-10-01 00:41
- 종류: 교차영향 (char-lead 참고, 막힘 아님 — lesson 은 우회 완료)
- 내용: (1) 캐릭터를 **처음 보여주는 순간 PNG 디코드 전이라 그림자만 보이고 몸이 빈칸**(MaruCharacterBubble 안 🐰, 약 0.5초). API §2.5 의 "첫 build 때 precache" 로는 첫 프레임에 못 맞춤. lesson 은 단계 진입 시 `MaruCharacter.precache(context, rabbit/turtle)` 를 미리 불러 해결. (2) 말풍선이 한글 음절 사이에 WORD JOINER(U+2060)를 넣어서 위젯 테스트의 `find.textContaining('친구')` 같은 한글 검색이 실패함. 또 캐릭터가 무한 루프라 `pumpAndSettle` 이 타임아웃 → 테스트에 `MediaQuery(disableAnimations: true)` 필요.
- 제안: (1) 이미지가 준비되기 전엔 그림자도 숨기거나 페이드인, 또는 문서 §1 에 "화면 진입 시 precache 권장" 명시. (2) CHARACTER_API 에 테스트 팁 2줄(U+2060 제거 후 비교, disableAnimations) 추가하면 다른 FE 세션 시간 절약. 참고 코드: `test/features/lesson/agglutinative_step_widget_test.dart` 의 `_bubbleText`.
- 상태: 완료
- 답변(PM): 10-01 12:02 · CHR-1.6.4.2(add2fbb) main 머지로 해결
- 답변(char-lead · 10-01 01:00): 수용. (1) 캐릭터 코드 수정 → CHR-1.6.4.2(char-dev): 이미지 첫 프레임 전엔 그림자까지 숨기고 준비되면 페이드인 + 매니페스트 로드 시 전체 precache. 재머지는 PM_SYNC S-005 로 요청. 그 전까지 `MaruCharacter.precache` 우회 유지(해도 무해). (2) CHARACTER_API §1·§3.0 에 precache 권장·테스트 팁 추가함.

### R-005 · lab-fe · 2026-10-02 18:05
- 종류: 문구 (PM 소유 파일, 막힘 아님)
- 내용: 홈 화면(`screens/home/home_screen.dart`) Language Lab 카드 부제가 "Ask AI about Korean grammar" — R5 리브랜딩(D-24, Sentence Lab = 거북이 실험)과 어긋나고, 한글랩(로컬, AI 없음)까지 포함하는 메뉴를 AI 질문으로만 설명함.
- 제안: 예) "Experiment with letters and sentences" 정도. 메뉴 화면은 LAB-1.9.2(4fb6b24)에서 바뀜.
- 상태: 대기
- 답변(PM):
