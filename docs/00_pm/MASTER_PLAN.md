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

## Phase 2 — 통합·QA (PM, 10/1 15:00~18:00)
- [~] PM-2.1 머지 (브랜치 간 파일 겹침 0건 확인) — 1차 09-30 22:10: lesson·vocab(완료분) + mission·lab(중간분) → main. **2차: mission-fe·lab-fe 완료 후 재머지**
- [x] PM-2.2 기능별 SQL 패치를 원본 `maru` 에 적용 — `lsn_001→002→003→004`, `msn_001`, `lab_001` 적용 (백업: pg_dump 선행). 이후 새 패치 생기면 추가 적용
- [x] PM-2.3 전체 테스트 — BE 107/107 통과, `flutter analyze` 0건, `flutter test` 11/11 (옛 카운터 템플릿 테스트 삭제 ba17273)
- [ ] PM-2.4 E2E 시나리오: 로그인 → 한글 레슨 → 문법 레슨(조립) → 단어 학습/게임/오늘의 복습 → 미션 대화·수료증 → 한글 실험실 → AI 실험실
- [ ] PM-2.5 회귀 버그 → 해당 세션에 수정 지시

## Phase 3 — 배포 (PM)
- [ ] PM-3.1 Railway Postgres 백업 → SQL 패치 적용 (`lsn_001~004`, `msn_001`, `lab_001`). ⚠ 삭제된 `/debug/merge` 가 하던 word_categories 정리가 Railway 에 반영됐는지 로컬 maru 와 덱 목록 비교
- [ ] PM-3.2 main push → Railway 자동 배포 확인, 운영 API 스모크 테스트
- [ ] PM-3.3 `API_BASE_URL=<railway>` 로 실기기/시뮬레이터 release·profile 빌드 확인

## Phase 4 — 제출물 7종 (PM)
- [ ] PM-4.1 책자 제본용 PPT [첨부1]
- [ ] PM-4.2 팀별 포스터 (프로젝트명 크게) [첨부2]
- [ ] PM-4.3 작품명·팀명·팀원·지도교수·사진·기자재 수·소개말 [첨부3]
- [ ] PM-4.4 설계 경진대회 신청서 [첨부4]
- [ ] PM-4.5 참가신청 및 개인정보 동의서 PDF (1인 1부) [첨부5]
- [ ] PM-4.6 발표+시연 합본 영상 (≤10분)
- [ ] PM-4.7 최종보고서 갱신 (1학기 보고서 + 변경사항 / 또는 GitHub 링크)
