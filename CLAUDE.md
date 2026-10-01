# MARU — 병렬 세션 공통 규칙 (모든 세션 필독)

MARU = 외국인을 위한 한국어 학습 앱 (졸업작품, 1인 팀 하도윤).
Flutter 앱(`frontend/maru`) + Spring Boot 3.5 / Java 17(`backend/maru`) + PostgreSQL. 운영 서버는 Railway(GitHub `main` push 시 자동 배포).
`frontend/lib`, `frontend/assets` 는 **옛 버전 앱**이다. 읽지도 고치지도 말 것 (실제 앱은 `frontend/maru`).

## 0. 지금 상황 (2026-09-30 ~ 10-02)
10/2 졸업작품 서류 제출을 위해 4개 기능을 병렬로 다듬는 중. **기능 동결: 2026-10-01 15:00** — 이후엔 버그 수정만.
버그 원본 목록: `docs/reference/MARU_실사보고서.md` (파일:라인 근거 포함). 발표 주장과 코드가 어긋난 부분이 많으니, 고치거나 문구를 정직하게 바꾸는 것이 목표.

## 1. 세션과 담당

| 세션 | 작업 폴더 (worktree) | 브랜치 | 기능코드 |
|---|---|---|---|
| **pm** | `/Users/hadohadopapi/Desktop/Maru-main` | `main` | PM |
| lesson-be / lesson-fe | `/Users/hadohadopapi/Desktop/Maru-wt/lesson` | `feat/lesson` | LSN |
| vocab-be / vocab-fe | `/Users/hadohadopapi/Desktop/Maru-wt/vocab` | `feat/vocab` | VOC |
| mission-be / mission-fe / mission-fe2 | `/Users/hadohadopapi/Desktop/Maru-wt/mission` | `feat/mission` | MSN |
| lab-be / lab-fe | `/Users/hadohadopapi/Desktop/Maru-wt/lab` | `feat/lab` | LAB |
| **char-lead** (캐릭터 팀 PM, 코딩 안 함) / char-dev / char-asset | `/Users/hadohadopapi/Desktop/Maru-wt/character` | `feat/character` | CHR |

같은 기능의 BE/FE 세션은 **같은 worktree** 를 쓴다. BE 는 `backend/` 만, FE 는 `frontend/` 만 수정한다.
세션은 첫 프롬프트에서 자기 이름(예: `lesson-be`)을 받는다. 모르면 사용자에게 물어볼 것.

## 2. 파일 소유권 (가장 중요)
자기 기능 소유 파일만 수정한다. **🔒 잠금 파일은 읽기만** — 수정이 필요하면 `docs/00_pm/REQUESTS.md` 에 요청을 쓰고, 그 부분은 우회해서 진행한다.
경로 기준: BE = `backend/maru/src/main/java/com/hdy/maru/`, FE = `frontend/maru/lib/`. 테스트 파일은 대상 클래스의 소유를 따른다.

### LSN (lesson)
- BE: `LessonController`, `LessonService`, `LessonRepository`, `entity/Lesson`, `dto/LessonContentDto`·`LessonResponseDto`·`StepDto`, `UserProgressController`·`UserProgressService`·`UserProgressRepository`·`entity/UserProgress`·`dto/UserProgress*`, `backend/lessons/**`, `backend/admin-tools/kiwi-generator/**`, `backend/admin-tools/update_lesson.py`
- FE: `features/lesson/**`, `features/progress/**`

### VOC (vocab)
- BE: `VocabularyController`, `VocabularyService`, `domain/fsrs/**`, `entity/FsrsProgress`·`Word`·`WordCategory` 와 각 Repository, `dto/ReviewRequestDto`·`WordCategoryDto`·`WordDueDto`·`WordGameDto`·`WordLessonDto`·`VocabularyGameTileDto`, `backend/admin-tools/vocab-pipeline/**`, `backend/maru/vocabulary_schema.sql`
- FE: `features/vocabulary/**`

### MSN (mission)
- BE: `MissionChatController`, `ChatTurnService`, `MissionSetupService`, `MissionSuggestionService`, `MissionClearanceService`, `OpenAiService`, `util/PromptLoader`, `util/JsonListConverter`, `entity/MissionClearance`·`MissionClearanceRepository`, `dto/ChatTurn*`·`MissionSetup*`·`MissionClearance*`·`Suggestion*`, `src/main/resources/prompts/**`
- FE: `features/mission_chat/**`

### LAB (lab)
- BE: `AiLabController`, `AiLabService`, `GeminiService`, `entity/AiCache`·`AiCacheRepository`, `dto/AiLab*`
- FE: `features/lab/**`

### CHR (character — 토끼·거북이 캐릭터)
- char-lead 는 팀 PM(지시·검수·문서만, 코드 수정 안 함). char-dev = `lib/shared/characters/**`·`lib/dev/**`·`test/shared/characters/**`, char-asset = `assets/characters/**`·pubspec `assets:` 줄. 둘 다 같은 worktree, 파일 안 겹침
- FE: `lib/shared/characters/**`, `lib/dev/**`(갤러리 단독 엔트리), `assets/characters/**`, `test/shared/characters/**`, `pubspec.yaml` 의 `assets:` 블록 한 줄(위임 D-12)
- 문서: `docs/features/character/**`
- 기능 화면에 캐릭터를 넣는 건 **각 기능 FE 세션**이 한다(메인 PM 이 태스크로 배포). char-lead 는 기능 폴더를 수정하지 않는다.

### 🔒 PM 전용 (공유 파일 — 기능 세션은 수정 금지)
- BE: `config/**`, `security/**`, `AuthController`, `MeController`, `DebugController`, `UserStats*`(Controller/Service/Repository/entity/dto), `entity/User`·`UserRepository`, `dto/ApiResponse`·`AuthRequestDto`, `exception/**`, `MaruApplication`, `application.yaml`, `build.gradle`, `settings.gradle`
- FE: `main.dart`, `core/**`, `screens/**`(홈·하단탭·로그인), `features/auth/**`, `features/profile/**`, `features/stats/**`, `pubspec.yaml`·`pubspec.lock`, `android/`·`ios/` 등 네이티브 폴더
- 루트: `CLAUDE.md`, `scripts/**`, `.gitignore`, `docs/00_pm/**`(단 `STATUS.md` 자기 줄, `REQUESTS.md` 추가는 허용)

### 공유 계약 (바꾸지 말 것)
- `UserStatsService.recordStudyActivity(String oauthId)` — LSN·VOC 가 호출. 시그니처 고정.
- `ApiResponse<T>` 응답 포맷 `{status, message, data}` — 모든 컨트롤러 공통.
- `core/network/dio_client.dart` 의 `dioProvider` — 모든 FE 가 사용. 새 엔드포인트 상수는 `core/constants/api_constants.dart` 가 아니라 **자기 feature 폴더 안**에 둔다.
- 홈 화면(`screens/home/home_screen.dart`)의 진입 버튼·배너는 PM 소유. 진입 방식 변경이 필요하면 요청.

## 3. 격리된 실행 환경 (기능마다 포트·DB·시뮬레이터 분리)

| 기능 | 서버 포트 | 로컬 DB | iOS 시뮬레이터 (FE) |
|---|---|---|---|
| lesson | 8081 | `maru_lesson` | iPhone 17 Pro `3ABA3DBC-D969-440C-A263-37FF2FAB32A5` |
| vocab | 8082 | `maru_vocab` | iPhone 17 `191ABCE7-4D9F-4C4C-8131-DCA87EA480B1` |
| mission | 8083 | `maru_mission` | iPhone Air `FE45C935-622A-40E5-B04A-DD243006175D` |
| lab | 8084 | `maru_lab` | iPhone 16 Pro (iOS 18.5) `63ED4387-61F6-4693-97C4-FF0DB9A24257` |
| character | (서버 불필요) | - | iPhone 16 Plus `50FB788C-2FB3-4D74-8673-5FFFAAD456C8` |
| pm (통합)·사람 | 8080 | `maru` | iPhone 16 Pro Max / Pixel_2_API_35 |

- 서버: worktree 루트에서 `scripts/run_backend.sh <feature>` (BE 세션이 띄우고, 백그라운드로 실행해 둔다)
- 앱 로그인: 소셜 로그인 대신 개발용 토큰 → `TOKEN=$(scripts/dev_token.sh maru_<feature>)` 후 `flutter run -d <UDID> --dart-define=API_PORT=<port> --dart-define=DEV_JWT=$TOKEN`
- 원본 DB `maru` 와 Railway 는 **PM 만** 건드린다. 다른 기능의 DB·포트·시뮬레이터 사용 금지.

## 4. 데이터·스키마 변경 규칙
- DB 데이터(레슨 JSON, 단어 등)를 바꾸면 반드시 **재실행 가능한 SQL 패치**로 남긴다: `backend/db/patches/<기능코드소문자>_<NNN>_<설명>.sql` (예: `lsn_001_fix_u1l1_quiz.sql`). 멱등(두 번 실행해도 결과 동일)하게. 자기 DB에 적용해 검증. PM이 나중에 Railway에 그대로 적용한다. **psql로 손으로만 고치고 끝내는 것 금지.**
- JPA `ddl-auto: update` 사용 중 → 스키마 변경은 **추가만**(새 nullable 컬럼, 새 테이블). 컬럼 이름 변경·삭제·타입 변경 금지. 변경 시 해당 기능 `API_CONTRACT.md` 에 기록.
- API 응답 모양을 바꾸면 BE 가 먼저 `docs/features/<기능>/API_CONTRACT.md` 를 갱신하고 FE 에 알린다(LOG + STATUS 메모). 가능하면 필드 **추가**로 해결하고 기존 필드는 유지.

## 5. Git 규칙
- 자기 worktree·브랜치에서만 작업. **push·merge·rebase·main checkout 금지** (합치기와 배포는 PM).
- 커밋은 자기 경로만 명시해서: `git add <파일들>` (❌ `git add -A`, `git add .`, `git commit -a`). 같은 worktree 를 쓰는 짝 세션의 파일을 stage·stash·reset·checkout 하지 말 것.
- 커밋 메시지: `[LSN-1.2.3] 한 줄 요약` (태스크 ID 필수). 태스크 하나 끝날 때마다 커밋.
- `.env`, 키, 토큰은 절대 커밋·출력하지 않는다.

## 6. 작업 문서 규칙 (컨텍스트를 잃지 않기 위한 장치)
- 문서는 **항상 main 체크아웃의 절대경로**에서 읽고 쓴다: `/Users/hadohadopapi/Desktop/Maru-main/docs/...`
  worktree 안의 `docs/` 복사본은 **읽지도 쓰지도 말 것** (오래된 사본이다).
- 구조: Phase > Step > Task. ID `<기능코드>-<P>.<S>.<T>`. 체크박스 `[ ]` 대기 `[~]` 진행 `[x]` 완료 `[!]` 막힘.
- 세션 시작 시(그리고 컨텍스트 요약 후) 읽는 순서:
  1. `docs/features/<기능>/LOG_<be|fe>.md` 의 **▶ HANDOFF** 섹션
  2. `docs/features/<기능>/PLAN.md`
  3. `docs/features/<기능>/API_CONTRACT.md`
  4. `docs/00_pm/REQUESTS.md` 에서 자기 앞으로 온 답변
- 태스크를 시작하면 PLAN 의 체크박스를 `[~]`, 끝나면 `[x]` + 커밋 해시. 자기 태그(`[BE]`/`[FE]`)의 태스크만 체크한다.
- 태스크 하나 끝날 때마다 LOG 에 기록을 추가하고 HANDOFF 를 덮어쓴다. `docs/00_pm/STATUS.md` 의 자기 줄도 갱신.
- 계획에 없는 문제를 발견하면: 자기 영역이면 PLAN 에 태스크를 추가(ID 이어서)하고 진행, 남의 영역이면 REQUESTS.md 에 기록.
- **PM 간 소통**(main-pm ↔ char-lead)은 `docs/00_pm/PM_SYNC.md`. 기능 세션은 메인 PM 의 지시(PLAN 태스크)만 따른다.
- 메인 PM 인수인계서: `docs/00_pm/PM_HANDOFF.md` (PM 교체·컨텍스트 요약 후 가장 먼저 읽는 파일)

## 7. 제품 규칙
- 앱 UI 문구는 **영어**(외국인 학습자 대상). 학습 콘텐츠의 한국어는 그대로. 오류 문구에 예외 원문(`DioException...`) 노출 금지 — 사용자용 문장 + 재시도.
- 색상은 하드코딩 대신 `Theme.of(context).colorScheme.primary` 계열 사용 (브랜드 시드 `0xFF6B4EFF`, PM 이 `main.dart` 에서 설정).
- 발표·보고서에 쓸 수 있도록 **사실과 다른 동작을 사실로 만들거나, 정직하게 표시**하는 방향으로 고친다 (예: 가짜 점수 고정값 제거).
- 새 패키지 추가 금지(필요하면 REQUESTS). 대규모 리팩터링·파일 이동 금지 — 이틀짜리 스프린트다.

## 8. 완료 기준 (태스크 공통)
- BE: `./gradlew compileJava` 통과 + 관련 테스트 `./gradlew test --tests '<대상>'` 통과(깨진 기존 테스트는 LOG 에 기록) + 실제 서버에 curl 로 확인.
- FE: `flutter analyze lib/features/<자기폴더>` 새 경고 없음 + 시뮬레이터에서 해당 화면 직접 확인.
- LOG 에 무엇을 어떻게 확인했는지 적는다. 확인 못 했으면 "미확인"이라고 쓴다.
