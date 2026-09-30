# backend/maru — BE 세션 규칙 (루트 CLAUDE.md 가 우선)

Spring Boot 3.5.11, Java 17 (`/opt/homebrew/opt/openjdk@17`), Gradle wrapper, Lombok, JPA(`ddl-auto: update`), PostgreSQL.
패키지 루트: `src/main/java/com/hdy/maru/` — controller / service / entity / repository / dto / domain / config / security / util / exception.

## 실행
- 서버: worktree 루트에서 `scripts/run_backend.sh <feature>` → 기능별 포트·DB 로 bootRun (`.env` 의 `JWT_SECRET`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_CLIENT_ID` 자동 로드). Bash `run_in_background` 로 띄워 두고 FE 짝 세션도 같은 서버를 쓴다.
- 코드 수정 후 재시작 필요(devtools 자동 재시작에 의존하지 말 것). 재시작할 땐 FE 세션 LOG/STATUS 에 알린다.
- 확인: `TOKEN=$(scripts/dev_token.sh maru_<feature>)` → `curl -s -H "Authorization: Bearer $TOKEN" localhost:<port>/api/...`

## 빌드·테스트
- `./gradlew compileJava` / `./gradlew test --tests 'com.hdy.maru.service.LessonServiceTest'` 처럼 **자기 기능 테스트만** 좁혀 실행.
- 전체 `./gradlew test` 는 PM 통합 단계에서만. 기존 실패 테스트(예: `LessonControllerTest`)는 원인 파악 후 자기 소유면 수정, 아니면 LOG 기록.

## 코드 규칙
- 응답은 기존처럼 `ApiResponse<T>` 로 감싼다. 오류는 적절한 HTTP 상태 + `ApiResponse.error(...)` — "200 인데 data=null" 금지.
- 로그에 토큰·API 키·개인정보 출력 금지.
- AI 호출(OpenAI/Gemini)은 타임아웃·파싱 실패를 잡아 사용자용 메시지로 변환.
- DB 데이터 변경은 `backend/db/patches/` SQL 로 (루트 CLAUDE.md §4). Python admin-tools 의 DB 접속·경로 하드코딩은 인자/환경변수로 바꿔 쓰되, 기본값이 원본 `maru` DB 를 가리키지 않도록 주의(자기 기능 DB 사용).
