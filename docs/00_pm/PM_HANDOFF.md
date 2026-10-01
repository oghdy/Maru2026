# PM HANDOFF — 메인 PM 인수인계서

> **이 파일 하나로 PM 을 이어받을 수 있게** 유지한다. PM 은 결정·머지·배포 직후 §3(현재 상태)·§6(열린 결정)을 갱신한다.
> 후임 PM 읽는 순서: 이 파일 → `STATUS.md` → `PM_SYNC.md`(최근 항목) → `REQUESTS.md`(대기) → `MASTER_PLAN.md`.
> 마지막 갱신: 2026-09-30 20:45 (main-pm #1)

---

## 1. 미션과 마감
- **MARU** = 외국인을 위한 한국어 학습 앱. 하도윤(컴퓨터공학과 20200679)의 **1인 팀 졸업작품** → 4학년 설계 경진대회 출품.
- **마감 2026-10-02** 제출 7종: ①책자 제본용 PPT ②포스터(프로젝트명 크게) ③작품명·팀명·팀원·지도교수·사진·기자재 수·소개말 ④설계 경진대회 신청서 ⑤참가신청·개인정보 동의서 PDF(1부) ⑥발표+시연 합본 영상(≤10분, 슬라이드+시연) ⑦최종보고서(1학기 보고서 갱신 또는 링크). 양식은 하도윤이 보유("밑에 있음") — Phase 4 에서 받기.
- **기능 동결 2026-10-01 15:00.** 이후 배포 → 스크린샷 → 제출물. 동결은 절대 미루지 말 것(제출물이 최종 화면에 의존).
- 1학기 자료: `/Users/hadohadopapi/Downloads/마루 최종발표.pdf`(62p), `/Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/[설계 프로젝트 경진대회] 전공종합설계(2) (002) 마루.pdf`(27p). 1학기 보고서 docx 흔적: `.claude/settings.local.json` 에 `마루_최종보고서.docx` 빌드 기록.
- 4대 기능 = MARU: **M**orpheme 레슨 · **A**daptive 단어(FSRS) · **R**oleplay 미션 · **U**pgrade 실험실. 학습 철학 🐰 토끼(빠른 체험) / 🐢 거북이(느린 분석·코칭).

## 2. 작업 체계 (이게 PM 의 핵심 자산)
- 규칙 원본: 루트 `CLAUDE.md`(소유권·격리·git·문서 규칙), `backend/maru/CLAUDE.md`, `frontend/maru/CLAUDE.md`
- **세션 구성**: main-pm(`Maru-main`, main) + 기능 4개 × BE/FE(`Maru-wt/{lesson,vocab,mission,lab}`, `feat/*`) + char-lead(`Maru-wt/character`, `feat/character`)
- **격리**: 기능마다 포트 8081~8084 · DB `maru_<기능>`(원본 `maru` 복제) · iOS 시뮬레이터 고정. 통합은 8080/`maru`
- **문서**: 전부 `Maru-main/docs/` 한 곳(worktree 사본 금지). Phase>Step>Task, ID `<코드>-P.S.T`. 세션은 LOG 의 ▶HANDOFF 로 컨텍스트 복구
- **지시 경로 (단일화)**: 사람 → main-pm → (PLAN 태스크 + 사람이 붙여넣는 프롬프트) → 기능 세션. char-lead ↔ main-pm 은 `PM_SYNC.md`. 세션 → PM 요청은 `REQUESTS.md`
- **세션에 지시하는 법**: 하도윤이 각 세션 창에 PM 이 써준 프롬프트를 붙여넣는다. 프롬프트는 짧게 — "PLAN Step X 의 태스크 ID 진행, 위임 범위, 순서, 끝나면 STATUS". 첫 프롬프트 원본은 `SESSION_PROMPTS.md`
- **위임(D-08)**: PM 잠금 파일 작업은 유휴 세션에 "이 태스크에 한해 허용"으로 맡긴다(지금까지 lesson-be/fe 가 수행)

## 3. 현재 상태 (2026-09-30 20:45)
- **Phase 1 기능 수정 + R2 사용자 피드백: 전부 완료·main 머지 4차까지** (main `49af250`). 충돌 0. BE test 120/120, `flutter analyze` 0, flutter test 전부 통과
  - LSN: 레슨 데이터·조립문제 파이프라인 재작성, 을/를 레슨 u1-l3 추가, 점수·별·이어하기, **서버 TTS(OpenAI gpt-4o-mini-tts, voice ash, DB 캐시) + 공통 TtsHelper(just_audio)**
  - VOC: **FSRS-4.5 표준 공식** 교체, 평가 오저장 버그 수정, 다음 간격 미리보기, 비주얼 리디자인·Match 애니메이션
  - MSN: 오류 처리, 서버 3-Zone 판정·실제 클리어 판정, 수료증 cleared/not cleared
  - LAB: 오류·로딩 UX, Gemini 키 헤더, 입력 검증, 한글랩 Try another, 그래머랩 결과 화면
  - PM 공통(위임): 로그인 오류, 로그아웃 확인, Stats/Settings 화면, 브랜드색, DebugController 삭제, 400 처리
- **진행 중**: 캐릭터 팀 킥오프(char-lead, Step 1.6). 하도윤이 GPT 로 이미지 14장 생성 중
- **대기 중(보류 결정)**: FSRS 시각화·py-fsrs 교차검증 (vocab 세션에 맡길지 하도윤 확인 필요)
- **로컬 DB `maru`**: 패치 `lsn_001~004`, `msn_001`, `lab_001` 적용됨. 백업 scratchpad `maru_before_integration.sql`
- **Railway**: 서비스 `Maru2026`(GitHub `oghdy/Maru2026` main push 시 자동 배포), Postgres `ballast.proxy.rlwy.net`. **10-01 20:37 배포 완료**: 서버 `https://maru2026-production.up.railway.app`, 콘텐츠 이관 완료(레슨 15·단어 5,561·덱 14·캐시). JWT 시크릿 로컬=운영. `.env` 의 `RAILWAY_DATABASE_URL`(값 출력 금지). **이후 main push = 운영 재배포**이니 docs 만 바뀐 커밋은 모아서 push

## 4. 절차 (명령 그대로)
**머지 (기능 브랜치 → main)**
```bash
cd ~/Desktop/Maru-main
git diff --name-only main...feat/<f>            # 소유권 확인
git -C ../Maru-wt/<f> status --short              # worktree 깨끗한지
git merge --no-ff -m "[PM-2.1] merge feat/<f> ..." feat/<f>
cd backend/maru && ./gradlew test --rerun-tasks   # 결과는 build/test-results/test/*.xml 집계
cd ../../frontend/maru && flutter pub get && flutter analyze && flutter test
```
**worktree 동기화 (main → 기능 브랜치)**: worktree 가 깨끗할 때만 `git -C ../Maru-wt/<f> merge main`. 이후 해당 세션에 "pub get + 서버 재시작" 지시. (`macos/Flutter/GeneratedPluginRegistrant.swift` 자동 변경은 main 에서 한 번 커밋, worktree 에선 `git checkout --` 로 버림)
**DB 패치**: `backend/db/patches/*.sql` 멱등. 적용 전 `pg_dump` 백업. lsn_001 은 isPublished 필터 코드와 함께 배포.
**통합 앱 실행(사람용)**: `scripts/run_backend.sh main` + `flutter run -d "iPhone 16 Pro Max" --dart-define=DEV_JWT=$(../../scripts/dev_token.sh maru)`
**Phase 3 배포 (승인 필요!)**: ① main push → Railway 배포 확인 ② 로컬 `maru` 에서 콘텐츠 테이블 data-only 이관(`lessons`, `word_categories`, `words`, `ai_cache`, `tts_cache`) — 사용자·진행·수료증·FSRS 기록 제외 ③ 운영 스모크 ④ `--dart-define=API_BASE_URL=<railway url>` 로 하도윤 iPhone 실기기 빌드, 하도윤이 실제 로그인

## 5. 하도윤 작업 스타일 (중요)
- 한국어 반말 섞인 캐주얼 대화. 답은 **짧고 표로**, 할 일은 "붙여넣을 프롬프트"로 줄 것
- **PM 은 직접 코딩하지 말고 지시·통합**을 원함(단 머지·문서·검증은 PM 이 직접)
- 문서는 **Phase > Step > Task** 구조 선호. 컨텍스트 유지용 문서를 중시(PM.md 류)
- 결정은 추천안 1개 + 이유로 제시. 되돌리기 어려운 것(push, 운영 DB, 외부 서비스)은 반드시 확인받기
- 시연 녹화는 **실제 iPhone**, 로그인은 하도윤이 직접, 녹화도 iPhone 화면 기록

## 6. 열린 결정·할 일 (우선순위 순)
| # | 항목 | 상태 |
|---|---|---|
| 1 | 캐릭터 갤러리 🚦 승인 → 기능 적용 태스크 배포(PM_SYNC 로 char-lead 요청 받음) | char-lead 진행 중 |
| 2 | FSRS 시각화(기억 강도·망각곡선) + py-fsrs 교차검증을 vocab 세션에 맡길지 | 하도윤 답 대기 |
| 3 | Railway 서버 URL, 배포 승인 | 하도윤 답 대기 |
| 4 | Gemini 키 재발급(lab-be 세션 도구 출력에 1회 노출), OpenAI 월 한도 설정 | 하도윤 권장 전달함 |
| 5 | TTS voice ash vs alloy 청취 비교 | 하도윤 |
| 6 | iOS 실기기 Google 로그인 검증(serverClientId 이슈 가능) — Phase 3.4 에서 | 미확인 |
| 7 | 삭제된 `/debug/merge` 의 word_categories 정리가 이관 데이터에 반영됐는지(로컬 14덱 정상) | Phase 3 |
| 8 | 캐릭터 이름(토끼·거북이) | 하도윤 |
| 9 | 제출물 양식 7종 수령 → Phase 4 | 10/1 오후 |

## 7. 발표·제출물 문구 원칙
- `deliverables/CLAIMS.md` 의 ✅ 표현만 사용. 특히: "이미 배운 건 분해 안 함"(❌) → "레슨 목표 문법만 분해", "1.5초대"(❌) → "한 턴 1.5~2초, 순차 대비 30~50% 단축", "FSRS 기반 추천"은 오늘의 복습에 한정, "4x4 게임"(❌) → 라운드당 5쌍, 캐시 HIT 1~2ms / MISS 3~5s

## 8. 교훈 (같은 실수 방지)
- 같은 worktree 의 BE/FE 는 git index 공유 → 커밋은 `git commit -- <경로>` 로만
- BE curl 테스트는 `dev_tester_be` 유저(FE 의 `dev_tester` 데이터 오염 사고 1회)
- 세션이 LOG 에 적는 시각은 추정일 수 있음 → 실제 시각은 `date` 로 확인(09-30 에 21~23시 오기 발생)
- 시뮬레이터 도구는 UDID 를 명시하지 않으면 다른 세션 기기를 잡음(2회 발생)
- Riverpod 3 는 실패 provider 를 ~40초 자동 재시도 → 앱 전역 `retry: null` 로 끔. 각 화면은 자체 오류 UI 필수
- Railway DB 는 비어 있었다 — "배포돼 있다"는 말은 항상 데이터까지 확인
