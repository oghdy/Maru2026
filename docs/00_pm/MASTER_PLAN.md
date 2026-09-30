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
- [~] PM-0.2.5 8개 세션 첫 프롬프트 전달 → `00_pm/SESSION_PROMPTS.md`

## Phase 1 — 기능 수정 (8 세션, ~10/1 15:00)
| 기능 | Step 1.1 | Step 1.2 | Step 1.3 | Step 1.4 |
|---|---|---|---|---|
| LSN | 현황 점검 | P0 버그·하드코딩 | 조립문제 데이터 품질 | 을/를 레슨(선택) |
| VOC | 현황 점검 | P0 버그·하드코딩 | UX 정리 | 표준 FSRS(선택) |
| MSN | 현황 점검 | 오류·상태 처리 | 판정·수료증 정직화 | UX 정리 |
| LAB | 현황 점검 | 오류·로딩 UX | 문구·디자인 정리 | (여유 시 QA 지원) |

### Step 1.P PM 공통 작업 (P1 기간 병행)
- [ ] PM-1.P.1 로그인 실패 무한 로딩 수정 (실사 §2-C) — `AuthController` 200+null, `auth_repository` 캐스팅
- [ ] PM-1.P.2 홈 프로필 아이콘 → 로그아웃 확인 다이얼로그 (실사 §8-P1#20)
- [ ] PM-1.P.3 하단 탭 Stats/Settings "Coming Soon" 정리 (숨김 또는 최소 화면)
- [ ] PM-1.P.4 홈 통계·복습 배너 로딩/오류 상태 표시 (실사 §8-P1#14)
- [ ] PM-1.P.5 보안: `DebugController` 제거/보호, JWT 로그 제거 (실사 §2-D). Gemini 키 헤더 전달은 LAB-1.2.2 가 담당
- [ ] PM-1.P.6 로그인 화면 부제·Android 라벨 통일 (실사 §8-P1#10)
- [ ] PM-1.P.7 REQUESTS.md 처리 (상시)
- [ ] PM-1.P.8 `GlobalExceptionHandler`: 파라미터 타입 불일치(`MethodArgumentTypeMismatchException`) → 400 (R-001)
- [ ] PM-1.P.9 테마 primary 를 브랜드색 `0xFF6B4EFF` 정확히 쓰도록 (`fromSeed` 가 톤다운시킴 — lesson-fe 피드백)

## Phase 2 — 통합·QA (PM, 10/1 15:00~18:00)
- [ ] PM-2.1 머지 순서: lab → mission → vocab → lesson (위험 낮은 순). 각 머지 후 `compileJava` + `flutter analyze`
- [ ] PM-2.2 기능별 SQL 패치를 원본 `maru` 에 적용
- [ ] PM-2.3 전체 `./gradlew test`
- [ ] PM-2.4 E2E 시나리오: 로그인 → 한글 레슨 → 문법 레슨(조립) → 단어 학습/게임/오늘의 복습 → 미션 대화·수료증 → 한글 실험실 → AI 실험실
- [ ] PM-2.5 회귀 버그 → 해당 세션에 수정 지시

## Phase 3 — 배포 (PM)
- [ ] PM-3.1 Railway Postgres 백업 → SQL 패치 적용
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
