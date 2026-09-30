# MASTER PLAN (PM 관리)

- 마감: **2026-10-02** 제출 · 기능 동결 **2026-10-01 15:00**
- 1인 팀 하도윤 · 운영: Railway (`Maru2026` 서비스 = GitHub `oghdy/Maru2026` main, Postgres `ballast.proxy.rlwy.net`)
- 기능별 세부 계획: `features/<기능>/PLAN.md` — 여기엔 Step 단위 요약만.

---

## Phase 0 — 준비 (PM)
### Step 0.1 공통 기반
- [x] PM-0.1.1 서버 주소 `--dart-define` 화 (`API_BASE_URL` / `API_PORT`)
- [x] PM-0.1.2 DEBUG 띠 제거, 앱 이름 "Maru", 테마 시드 `0xFF6B4EFF`
- [x] PM-0.1.3 개발용 로그인 `DEV_JWT` + `scripts/dev_token.sh`, `scripts/run_backend.sh`
### Step 0.2 작업 체계
- [x] PM-0.2.1 루트/BE/FE `CLAUDE.md` (소유권·격리·문서 규칙)
- [x] PM-0.2.2 `docs/` 구조, 기능별 PLAN·API_CONTRACT·LOG
- [x] PM-0.2.3 베이스라인 커밋 — ✅ 8c0f8f3
- [x] PM-0.2.4 worktree 4개 + 기능별 DB 복제 4개 + `.env` 링크 (lab 슬롯으로 서버·토큰 스모크 테스트 통과)
- [x] PM-0.2.5 8개 세션 첫 프롬프트 전달 → `00_pm/SESSION_PROMPTS.md`

## Phase 1 — 기능 수정 (8 세션, ~10/1 15:00)
| 기능 | Step 1.1 | Step 1.2 | Step 1.3 | Step 1.4 |
|---|---|---|---|---|
| LSN | 현황 점검 | P0 버그·하드코딩 | 조립문제 데이터 품질 | 을/를 레슨(선택) |
| VOC | 현황 점검 | P0 버그·하드코딩 | UX 정리 | 표준 FSRS(선택) |
| MSN | 현황 점검 | 오류·상태 처리 | 판정·수료증 정직화 | UX 정리 |
| LAB | 현황 점검 | 오류·로딩 UX | 문구·디자인 정리 | (여유 시 QA 지원) |

### Step 1.P PM 공통 작업 — **위임: lesson 세션(작업 완료, 유휴)** · 브랜치 `feat/lesson` 에서 수행
> 🔒 PM 잠금 파일을 **아래 태스크에 한해** lesson-be / lesson-fe 에게 수정 허용 (D-08). 다른 기능 세션은 여전히 금지.

#### lesson-be 담당 (BE 공통)
- [x] PM-1.P.10 [BE] P0 R-002: `src/test/resources/application-test.yml` 에 테스트 전용 더미 `jwt.secret`(base64 32B+) → `.env` 없이 `./gradlew test` 전체 실행해 결과 보고 (타 기능 테스트 실패는 고치지 말고 목록만) — `3f341cb` (결과: LOG_be 09-30 PM 위임)
- [x] PM-1.P.1 [BE] P0 `AuthController` 토큰 검증 실패 시 200+`data:null` → 401 + 영어 메시지 (실사 §2-C `AuthController.java:109-112`) — `05bcde8`
- [x] PM-1.P.8 [BE] P1 `GlobalExceptionHandler`: `MethodArgumentTypeMismatchException`·`MissingServletRequestParameterException` → 400 (R-001) — `6bc1ee6`
- [x] PM-1.P.5 [BE] P1 보안: `DebugController` 삭제(또는 permitAll 제거+비활성), `SecurityConfig` 의 debug permitAll 제거, `JwtAuthenticationFilter` JWT 원문 INFO 로그 제거 (실사 §2-D) — `e67ea48`

#### lesson-fe 담당 (FE 공통)
- [x] PM-1.P.11 [FE] P0 R-003: 프로필 게이트(`/api/me`) 서버 연결 실패 시 영어 안내 + Retry + Log out (현재 무한 스피너), 공용 provider 자동 재시도 끄기(`retry: (_, __) => null`) — `97ce570`
- [x] PM-1.P.1f [FE] P0 로그인 실패 무한 로딩: `auth_repository.dart:30` `as String` 캐스팅 → 안전 처리, 실패 시 로그인 화면에 영어 오류 표시 (`auth_provider.dart`, `login_screen.dart:32-35`) — `589ccb7`
- [x] PM-1.P.2 [FE] P0 홈 프로필 아이콘 = 즉시 로그아웃 → 확인 다이얼로그 (실사 §8-P1#20, `home_screen.dart:46-50`) — `803fcba`
- [x] PM-1.P.4 [FE] P1 홈 통계·복습 배너 로딩/오류 상태 (SizedBox.shrink 숨김 제거), R-003 "1 words" 단수/복수 (`home_screen.dart`) — `786be53`
- [x] PM-1.P.3 [FE] P1 하단 탭 Stats/Settings "Coming Soon" → **Stats**: `/api/me/stats` 기반 최소 화면(스트릭·별·학습시간·완료 레슨), **Settings**: 닉네임·로그아웃·앱 버전. 1시간 넘으면 두 탭 숨김으로 대체 — `0a4e90b`
- [x] PM-1.P.6 [FE] P1 로그인 부제 "Korean Grammar Lab" → Maru 슬로건, Android 라벨 "maru" → "Maru" (실사 §8-P1#10) — `4250665`
- [x] PM-1.P.9 [FE] P1 테마 primary = 정확히 `0xFF6B4EFF` (`main.dart`, `fromSeed(...).copyWith(primary: ...)` 등) — `0f8c579`

#### PM 직접
- [x] PM-1.P.7 REQUESTS 처리 (상시) — R-001~003 답변 09-30 20:00

### Step 1.5 사용자 피드백 R2 (09-30 19:30) — 각 기능 PLAN Step 1.5
| # | 피드백 | 태스크 | 세션 |
|---|---|---|---|
| 1 | TTS 품질 | LSN-1.5.1(서버 TTS+캐시), LSN-1.5.2(공통 TtsHelper) → VOC-1.5.3, LAB-1.5.3 교체 | lesson-be, lesson-fe → vocab-fe, lab-fe |
| 2 | 한글 카드 `<1/5>` + Next 중복 | LSN-1.5.3 | lesson-fe |
| 3 | 한글랩 Reset 버튼 | LAB-1.5.1 | lab-fe |
| 4 | 그래머랩 결과 스크롤 | LAB-1.5.2 | lab-fe |
| 5 | 단어장·매치 미감 | VOC-1.5.1, VOC-1.5.2 | vocab-fe |
- 순서: LSN-1.5.1·1.5.2 완료 → PM 머지 → vocab/lab worktree 에 main 동기화 → VOC-1.5.3·LAB-1.5.3
- D-10: 재생 패키지 1개 추가 허용(lesson-fe 선택), OpenAI TTS 사용(키 기존)
- ⚠ 시각 정정: 세션 LOG 의 21~23시 기록은 추정 오기. 실제 R2 시작 09-30 19:33

### Step 1.6 캐릭터 토끼·거북이 (캐릭터 팀, 세부: `features/character/PLAN.md`)
- [~] PM-1.6.1 캐릭터 팀 킥오프: worktree·문서·char-lead 프롬프트 (D-11~14)
- [ ] PM-1.6.2 하도윤 GPT 이미지 14장 → `docs/features/character/raw/`
- [ ] PM-1.6.3 🚦 갤러리 승인 (하도윤)
- [ ] PM-1.6.4 feat/character 머지·동기화 → 기능 PLAN 에 적용 태스크 배포 (char-lead 요청 기반, 늦어도 10/1 10:00)
- [ ] PM-1.6.5 적용 결과 머지 (10/1 15:00 동결 전)

## Phase 2 — 통합·QA (PM, 10/1 15:00~18:00)
- [~] PM-2.1 머지 — 1차 22:10 (4브랜치), 2차 23:00 (mission·lab FE 완료분) 충돌 0, BE 107/107·analyze 0·FE test 12/12. **3차: mission-be MSN-1.2.6·1.3.5 후**
- [x] PM-2.2 기능별 SQL 패치를 원본 `maru` 에 적용 — `lsn_001→002→003→004`, `msn_001`, `lab_001` 적용 (백업: pg_dump 선행). 이후 새 패치 생기면 추가 적용
- [x] PM-2.3 전체 테스트 — BE 107/107 통과, `flutter analyze` 0건, `flutter test` 11/11 (옛 카운터 템플릿 테스트 삭제 ba17273)
- [ ] PM-2.4 E2E 시나리오: 로그인 → 한글 레슨 → 문법 레슨(조립) → 단어 학습/게임/오늘의 복습 → 미션 대화·수료증 → 한글 실험실 → AI 실험실
- [ ] PM-2.5 회귀 버그 → 해당 세션에 수정 지시

## Phase 3 — 배포 (PM) · ⚠ 09-30 23:00 확인: **Railway DB 가 비어 있음** (테이블만 있고 lessons·words·users 0건) → "패치 적용"이 아니라 **콘텐츠 데이터 이관**
- [x] PM-3.0 Railway DB 백업 (pg_dump, scratchpad) — 스키마만 존재 확인
- [ ] PM-3.1 **(승인 필요)** main → GitHub push → Railway `Maru2026` 자동 배포 → 새 엔티티로 스키마 갱신(ddl-auto)
- [ ] PM-3.2 **(승인 필요)** 로컬 `maru`(패치 6개 적용 완료본)에서 콘텐츠 테이블만 data-only 이관: `lessons`, `word_categories`, `words`, `ai_cache`(데모 예문 캐시). 사용자·진행·수료증·FSRS 기록은 옮기지 않음(개발 계정 데이터)
- [ ] PM-3.3 운영 API 스모크: `/api/units/{0,1}/lessons`, 단어 덱, lab 예문(캐시 HIT), 로그인 401 형식
- [ ] PM-3.4 `--dart-define=API_BASE_URL=<railway>` 로 iPhone 빌드 → 실제 로그인(하도윤) → 전 기능 1회 완주
- [ ] PM-3.5 Gemini API 키 재발급 여부 (lab-be 세션 도구 출력에 1회 노출) → 재발급 시 `.env` + Railway Variables 교체

## Phase 4 — 제출물 7종 (PM)
- [ ] PM-4.1 책자 제본용 PPT [첨부1]
- [ ] PM-4.2 팀별 포스터 (프로젝트명 크게) [첨부2]
- [ ] PM-4.3 작품명·팀명·팀원·지도교수·사진·기자재 수·소개말 [첨부3]
- [ ] PM-4.4 설계 경진대회 신청서 [첨부4]
- [ ] PM-4.5 참가신청 및 개인정보 동의서 PDF (1인 1부) [첨부5]
- [ ] PM-4.6 발표+시연 합본 영상 (≤10분)
- [ ] PM-4.7 최종보고서 갱신 (1학기 보고서 + 변경사항 / 또는 GitHub 링크)
