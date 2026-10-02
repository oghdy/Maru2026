# PM HANDOFF — 메인 PM 인수인계서

> **이 파일 하나로 PM 을 이어받을 수 있게** 유지한다. PM 은 결정·머지·배포 직후 §3(현재 상태)·§6(열린 결정)을 갱신한다.
> 후임 PM 읽는 순서: 이 파일 → `STATUS.md` → `PM_SYNC.md`(최근 항목) → `REQUESTS.md`(대기) → `MASTER_PLAN.md`.
> 마지막 갱신: 2026-10-02 16:34 (main-pm #1) — **규칙: 머지·배포·결정·사용자 피드백 반영 직후 매번 §3·§6 갱신**

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

## 3. 현재 상태 (2026-10-01 21:16)
- **Phase 1 완료 · Phase 3 배포 완료 · Phase 4 제출물 착수**(`deliverables/PLAN.md`, 세션 프롬프트 `deliverables/PROMPTS.md`). 공식 마감 10/5, 목표 10/2. 졸업전시 11/6 → Phase 5(랜딩+웹 체험판)
- main 최신 머지: 12차(R3 전부). BE test 123/123, `flutter analyze` 0, flutter test 67(+2 skip). 5개 worktree 전부 clean·main 동기화
- 사용자 피드백 라운드: R2(09-30, TTS·카드 네비·랩 UX·단어장 미감) / R3(10-01, 정답 라벨·토끼 변신 로딩·레드/옐로카드·패널 접기·채팅 리디자인·리포트 톤·실제 문장만·홈 복습 카드) — 원문 이미지 `docs/feedback/r2·r3/`
- 기능 요약
  - LSN: 레슨 데이터·조립문제 파이프라인 재작성, 을/를 레슨 u1-l3, 점수·별·이어하기, **서버 TTS(OpenAI gpt-4o-mini-tts, voice ash, DB 캐시) + 공통 TtsHelper(just_audio)**, 🐢 단계 정답 라벨 제거
  - VOC: **FSRS-4.5 표준 공식**, 평가 오저장 버그 수정, 다음 간격 미리보기, 리디자인·Match 애니메이션
  - MSN: 3-Zone 판정·실제 클리어 판정, 리포트는 **사용자가 실제 보낸 문장만**(서버 검증), 레드/옐로카드, 접히는 미션 패널, 채팅방·설정·리포트 리디자인, 토끼 변신 로딩(`MaruMood.magic`)
  - LAB: 오류·로딩 UX, Gemini 키 헤더, 입력 검증, 한글랩 Try another, 그래머랩 결과 화면, 어절 줄바꿈
  - CHR: 토끼·거북이 캐릭터(표정 PNG 15장 + 코드 모션), 4기능 21지점 + 홈 인사 적용
  - PM 공통(위임): 로그인 오류, 로그아웃 확인, Stats/Settings, 브랜드색, DebugController 삭제, 400 처리, 홈 복습 카드 항상 표시
- **운영**: `https://maru2026-production.up.railway.app` (Railway `Maru2026`, main push = 자동 재배포 ~2분). Railway DB 콘텐츠 이관 완료(레슨 15·덱 14·단어 5,561·ai_cache·tts_cache). JWT 시크릿 로컬=운영. `.env` 의 `RAILWAY_DATABASE_URL`(값 출력 금지). 백업: scratchpad `railway_backup_*.sql`
- **하도윤 iPhone("Celular de dy", `00008150-001665980A13401C`)**: 운영 서버 연결 release 빌드 설치·**Google 로그인 성공**(10-01 21:00). 서명 팀 `T83VRYU86H`
- 로컬 DB `maru`: 패치 `lsn_001~004`, `msn_001`, `lab_001` 적용. 원격에 push 안 된 커밋: docs 만(push 하면 재배포되므로 모아서)
- 현재 켜진 세션: char-lead(버그 대기) 외 정리 권고(§6-4). 켜진 서버·시뮬레이터 없음

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
**iPhone 실기기 설치 (운영 서버)** — 케이블 연결·개발자 모드·Xcode Accounts 로그인 필요. 첫 실행 시 Rosetta(`sudo softwareupdate --install-rosetta --agree-to-license`, 하도윤이 직접), codesign 키체인 창 "항상 허용"
```bash
cd ~/Desktop/Maru-main/frontend/maru && set -a && source ../../.env && set +a && flutter run --release -d 00008150-001665980A13401C --dart-define=API_BASE_URL=https://maru2026-production.up.railway.app --dart-define=GOOGLE_SERVER_CLIENT_ID=$GOOGLE_CLIENT_ID
```
(`GOOGLE_SERVER_CLIENT_ID` 빠지면 iOS Google 로그인 401 — iOS 토큰 aud 가 서버 GOOGLE_CLIENT_ID 와 다름)
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
| 1 | **Phase 4 제출물**: PM 범위 = 책자·포스터·발표자료·보고서(③④⑤ 는 하도윤 개인). 세션: lesson-fe(SHOT)·dlv-design·dlv-talk·dlv-report. 양식 `deliverables/templates/` | 진행 중 |
| 1a | 지도교수 성함 → 책자 바닥글·보고서 표지 | 하도윤 답 대기 |
| 1b | Phase 4 조정(10-02): SHOT 세션 취소 — **시연·기능 설명은 하도윤이 시뮬레이터로 직접 녹화**(로컬 서버 `run_backend.sh main` + DEV_JWT, `xcrun simctl io ... recordVideo`), 스크린샷 6~8장도 하도윤이 찍어 `deliverables/screenshots/`. 발표자료 = 1학기 경진대회 구조(문제→해결→기술→[시연]→기대효과) 슬라이드만(dlv-talk). 보고서 = 1학기 docx 를 읽고 발전 부분만 수정(dlv-report). 세션 3개 프롬프트 `deliverables/PROMPTS.md` | 하도윤이 세션 실행 중 |
| 2 | **포스터 QR** = 학교 졸업작품 사이트 팀 페이지(qr.naver.com 생성, 학교 요구). 팀 페이지 URL 받으면 QR 생성해 포스터에 삽입 | URL 대기 |
| 3 | Phase 5 랜딩 페이지 + 웹 체험판(Flutter web 빌드 성공 확인됨): 게스트 로그인·CORS·호스팅·비용 제한. **11/6 졸업전시** 전 | 10/5 이후 계획 |
| 4 | 세션 정리 | 하도윤에게 권고 전달 |
| 5 | Gemini 키 재발급(09-30 lab-be 도구 출력 1회 노출)·OpenAI 월 한도 | 하도윤 권장 전달함, 처리 여부 미확인 |
| 6 | TTS 첫 생성이 iPhone 에서 8초 타임아웃 넘는 경우 있음 → 시연 전 사용할 화면의 발음 버튼 한 번씩 눌러 캐시 예열 | 시연 리허설 때 |
| 7 | 발표 스크린샷: 리포트 미달성은 `mission/screenshots/r3_fe2/8_report_p1_not_cleared.png`, 로딩은 역할 입력 후 촬영 | Phase 4 |
| 8 | FSRS 시각화·py-fsrs 교차검증 — 제안만 하고 보류(하도윤 답 없음) | 보류 |
| 9 | 캐릭터 이름(토끼·거북이) — 앱 문구는 "Tokki" 사용 중 | 하도윤 |

## 7. 발표·제출물 문구 원칙
- `deliverables/CLAIMS.md` 의 ✅ 표현만 사용. 특히: "이미 배운 건 분해 안 함"(❌) → "레슨 목표 문법만 분해", "1.5초대"(❌) → "한 턴 1.5~2초, 순차 대비 30~50% 단축", "FSRS 기반 추천"은 오늘의 복습에 한정, "4x4 게임"(❌) → 라운드당 5쌍, 캐시 HIT 1~2ms / MISS 3~5s

## 8. 교훈 (같은 실수 방지)
- 같은 worktree 의 BE/FE 는 git index 공유 → 커밋은 `git commit -- <경로>` 로만
- BE curl 테스트는 `dev_tester_be` 유저(FE 의 `dev_tester` 데이터 오염 사고 1회)
- 세션이 LOG 에 적는 시각은 추정일 수 있음 → 실제 시각은 `date` 로 확인(09-30 에 21~23시 오기 발생)
- 시뮬레이터 도구는 UDID 를 명시하지 않으면 다른 세션 기기를 잡음(2회 발생)
- Riverpod 3 는 실패 provider 를 ~40초 자동 재시도 → 앱 전역 `retry: null` 로 끔. 각 화면은 자체 오류 UI 필수
- Railway DB 는 비어 있었다 — "배포돼 있다"는 말은 항상 데이터까지 확인
- PM_HANDOFF §3·§6 이 하루 가까이 낡았던 적 있음(10-01) → 머지·배포·결정 직후 매번 갱신. 갱신 시각을 맨 위에 기록
- iOS 실기기: Rosetta·Xcode 계정 만료·개발자 모드·키체인 허용·Google serverClientId — 전부 §4 에 명령으로 정리
- 피드백 PDF 는 세션이 못 여는 경우가 있음(pdftoppm 없음) → PM 이 이미지로 풀어 `docs/feedback/rN/` 에 둔다
