# PM HANDOFF — 메인 PM 인수인계서

> **이 파일 하나로 PM 을 이어받을 수 있게** 유지한다. PM 은 결정·머지·배포 직후 §3(현재 상태)·§6(열린 결정)을 갱신한다.
> 후임 PM 읽는 순서: 이 파일 → `STATUS.md` → `PM_SYNC.md`(최근 항목) → `REQUESTS.md`(대기) → `MASTER_PLAN.md`.
> 마지막 갱신: 2026-10-02 20:09 (main-pm #1, 컨텍스트 압축 직전 전체 갱신) — **규칙: 머지·배포·결정·사용자 피드백 반영 직후 매번 §3·§6 갱신**

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

## 3. 현재 상태 (2026-10-02 20:09)
- **앱: 기능 개발 사실상 종료.** 사용자 피드백 R2~R5 전부 반영·main 머지(통합 16회, 충돌 0)·**운영 재배포 완료**(main `1f1f047`, 10-02 20:00). 최신 테스트: BE 135/135, flutter test 83(+2 skip), analyze 0
- 피드백 라운드(원문 이미지 `docs/feedback/r2~r5/`)
  - R2(09-30): 서버 TTS·카드 네비·한글랩 Try another·그래머랩 결과 화면·단어장 리디자인
  - R3(10-01): 정답 라벨 제거·토끼 변신 로딩(`MaruMood.magic`)·레드/옐로카드·미션 패널 접기·채팅 리디자인·리포트 안 우는 토끼·실제 보낸 문장만·홈 복습 카드 상시
  - R4(10-02): 그래머랩 Explore/Combine 모드 카드 재설계·"거북이 실험 중" 로딩·**미션 난이도 easy/normal/hard(기본 easy, 토끼 답 길이 상한)**·홈 파스텔 카드
  - R5(10-02): **"AI Grammar Lab" → 화면 이름 `Sentence Lab`**(코드 이름 유지, D-24)·실험실 메뉴 실험노트 무드·**실험복 의상 `MaruOutfit.lab`**(토끼=장난꾸러기, 거북이=모범생, 실험실 화면 7곳)·홈 Language Lab 부제
- 기능 요약: LSN(레슨 파이프라인·을/를 u1-l3·점수/별/이어하기·서버 TTS) / VOC(FSRS-4.5·리디자인·Match) / MSN(3-Zone·실제 판정·실제 문장만 리포트·난이도·레드/옐로카드·변신 로딩) / LAB(Sentence Lab·한글랩) / CHR(캐릭터 21 PNG: 기본 15 + 실험복 6, `MaruMood`·`MaruOutfit` API) / PM 공통(로그인 오류·Stats/Settings·홈)
- **운영**: `https://maru2026-production.up.railway.app`. Railway DB 패치 적용분: 콘텐츠 이관(09-30)·`msn_002`(10-02). 하도윤 iPhone 사용 기록 있음(백업 scratchpad `railway_backup_r45_*.sql` 1.6MB). JWT 시크릿 로컬=운영
- **iPhone**: 예전 빌드 설치돼 있음 → **R4·R5 반영하려면 재빌드 필요**(§4 명령)
- **제출물(Phase 4)**: 공식 마감 **10/5**. 4종 1차본 완성(10-01 22:4x, **R4·R5 이전 내용**) — `deliverables/book·poster·talk·report/`(pptx·pdf·OUTLINE). 커밋됨. 남은 것 §6
- 세션 상황: 기능·캐릭터 세션은 모두 할 일 없음(버그 대기). 서버·시뮬레이터는 PM 이 띄운 것 없음. 제출물 세션 dlv-design(QR 대기)·dlv-talk(완료)·dlv-report(완료·검수 대기)
- 5개 worktree 전부 main 동기화·clean. 원격 main = 로컬 main 에서 docs 커밋만 뒤처짐(push 하면 재배포되므로 다음 배포 때 같이)

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
| 1 | **iPhone 재빌드**(R4·R5 반영) → 하도윤 **시연 녹화 + 스크린샷 6~8장**(`deliverables/screenshots/`) | 하도윤 |
| 2 | **제출물 R4·R5 반영 패스**: 4종 모두 R4 이전 작성 → ①"AI Grammar Lab"→**Sentence Lab**(D-24) ②미션 난이도·토끼 짧은 답 ③실험복 캐릭터·실험실 무드 ④홈 파스텔 카드 ⑤테스트 수치 BE 135·앱 83 ⑥재배포 사실. 스크린샷 오면 예시화면 교체. → dlv-design·dlv-talk·dlv-report 에 지시(세션 살아 있으면 이어서, 없으면 재개 프롬프트) | **다음 PM 작업** |
| 3 | **DLV-4.5.1 PM 교차 검수**: 4종 수치·용어·CLAIMS 위반·오탈자·양식 준수 → 하도윤 최종 확인 | 2 이후 |
| 4 | 포스터 QR(DLV-4.2.3): 학교 졸업작품 사이트 팀 페이지 URL → qr.naver.com | URL 대기 |
| 5 | 지도교수 성함(책자 바닥글·보고서 표지) | 하도윤 답 대기 |
| 6 | (선택) DLV-4.4.2 GitHub README 정비 | 여유 시 |
| 7 | Phase 5(11/6 졸업전시 전): 랜딩 페이지 + 웹 체험판(게스트 로그인·CORS·Flutter web 호스팅·AI 사용 제한) | 10/5 이후 계획 |
| 8 | Gemini 키 재발급·OpenAI 월 한도 — 하도윤 처리 여부 미확인 | 권장만 함 |
| 9 | TTS 첫 생성 8초 타임아웃 가능 → 시연 전 발음 버튼 예열 | 녹화 전 |
| 10 | FSRS 시각화(보류), 캐릭터 이름(앱은 "Tokki") | 보류 |

## 7. 발표·제출물 문구 원칙
- **이름**: 실험실 문장 기능 = `Sentence Lab`(문장 실험실) — "AI Grammar Lab" 은 옛 이름(D-24). 설명엔 "AI(Gemini) 기반" 명시
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
- 제출물은 앱보다 먼저 만들어져 **뒤처질 수 있다** — 앱이 바뀌면(R4·R5 처럼) 제출물 반영 패스를 반드시 할 일로 등록
- 세션이 시뮬레이터를 못 켜면(권한) PM 이 `xcrun simctl boot <UDID>` 로 켜주면 됨. 다른 세션 기기를 잡는 실수가 계속 나오니 프롬프트에 UDID 명시
- Railway 재배포 절차(검증됨): pg_dump 백업 → 새 패치 적용 → push → `curl` 로 새 동작 확인(배포 중 502 1회는 정상)
