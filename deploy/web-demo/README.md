# MARU 웹 체험판 배포 묶음

한 도메인에서 `/` = 랜딩(`site/index.html`), `/app/` = Flutter 앱(`site/app/`)을 내보내는 정적 서버다. API 는 별도 서비스인 체험판 서버가 맡는다.

외부 작업(Railway 생성, 키 입력, push)은 하도윤 승인 후 PM 이 한다. `main` 에 합치거나 push 하지 않는다. 운영이 자동 배포된다.

## 구성
| 파일 | 역할 |
|---|---|
| `Dockerfile` | `nginx:alpine` + `nginx.conf.template` + `site/` |
| `nginx.conf.template` | 포트 `PORT`, gzip(`application/wasm` 포함), `/app/` SPA fallback, 짧은 캐시 |
| `site/index.html`, `site/assets/` | 랜딩 |
| `site/app/` | `scripts/build_web_demo.sh` 의 결과. Railway 가 Flutter 없이 받도록 git 에 커밋한다 |

## 배포 순서
1. **체험판 서버**: `feat/web-demo` 브랜치에서 별도 Railway 서비스와 DB 를 만들고 아래 환경 변수를 넣어 배포한다. 콘텐츠 테이블을 이관한다. 주소를 확인한다.
2. **정적 서비스 생성**: 같은 저장소로 서비스를 하나 더 만든다. Root Directory `deploy/web-demo`, 브랜치 `feat/web-demo`, 빌더 Dockerfile, Watch Paths `deploy/web-demo/**`. 공개 도메인을 먼저 만들어 둔다. 환경 변수는 필요 없다(`PORT` 는 Railway 가 넣는다).
3. **CORS**: 체험판 서버의 `MARU_CORS_EXTRA_ORIGINS` 에 2번 도메인을 넣는다. `https://` 포함, 끝 슬래시 없음.
4. **앱 빌드**: `scripts/build_web_demo.sh https://<체험판 서버 주소>` 실행 후 `git add deploy/web-demo/site/app` 하고 커밋, 브랜치 push. 빌드 결과에는 서버 주소만 들어가고 비밀값은 없다.
5. **스모크**: 아래 점검표.

서버 주소가 바뀌면 4번을 다시 한다. 빌드 결과가 커밋에 쌓이므로 필요할 때만 다시 빌드한다.

## 체험판 서버 환경 변수 (이름만, 값은 Railway 에만)
필수:
- `MARU_DEMO_ENABLED=true`
- `SPRING_JPA_OPENINVIEW=false` (AI 대기 중 DB 연결 점유 방지)
- `MARU_CORS_EXTRA_ORIGINS` (정적 서비스 도메인)
- `MARU_CORS_MAX_AGE_SECONDS=1800`
- `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD` (체험판 전용 DB)
- `JWT_SECRET` (운영과 다른 값)
- `OPENAI_API_KEY`, `GEMINI_API_KEY`

조정할 수 있는 값(`MARU_DEMO_*` 한도, AI 끄기 스위치 `MARU_DEMO_AI_ENABLED`)은 `docs/features/web-demo/API_CONTRACT.md` §4.

## 스모크 점검표
- `/` 랜딩 표시, 응답 헤더에 `Content-Encoding: gzip`
- `/app` → `/app/` 리다이렉트, 위치에 내부 포트 없음
- `/app/main.dart.js` 가 gzip 으로 내려옴
- `/app/아무경로` → 앱 index.html, `/app/assets/없는파일` → 404
- 체험 버튼 → 로딩 화면 → 게스트 자동 입장 → 홈, 캐릭터 표시
- 브라우저 콘솔에 CORS 오류 없음

## 로컬 확인
```sh
docker build -t maru-web-demo deploy/web-demo
docker run --rm -p 8090:8080 maru-web-demo
```
