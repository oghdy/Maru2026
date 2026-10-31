# Phase 4 — 제출물 PLAN (PM 관리)

- 공식 마감 **10/5(월)**, 팀 목표 **10/2(목) 안**. 1인 팀 하도윤.
- 이 PLAN 범위: ①책자 PPT ②포스터 ⑥발표·시연 영상용 발표자료 ⑦최종보고서. (③④⑤ 서류는 하도윤 개인 작성)
- 이후(11/6 졸업전시 전): 랜딩 페이지 + 웹 체험판 → Phase 5 (별도 계획)

## 공통 입력 (모든 세션이 먼저 읽기)
| 자료 | 위치 |
|---|---|
| **쓸 수 있는 문장만** (사실 검증된 표현, ❌ 금지 표현) | `docs/deliverables/CLAIMS.md` ← 반드시 준수 |
| 프로젝트 현재 상태·기능 요약 | `docs/00_pm/PM_HANDOFF.md` §1·§3 |
| 공식 양식 | `docs/deliverables/templates/첨부1_책자양식.pptx`·`.pdf`, `첨부2_포스터양식.pptx`·`.pdf` |
| 1학기 발표(디자인·논리 원본) | `/Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_진짜_최종발표.pptx`, `.../[설계 프로젝트 경진대회] 전공종합설계(2) (002) 마루.pdf` |
| 1학기 최종보고서 | `/Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_최종보고서.docx` (장별 원본: `.../마루_보고서/*.docx`) |
| 캐릭터 원본(고해상도 1254px, 투명) | `docs/features/character/raw/*.png` · 앱용 512px `frontend/maru/assets/characters/` |
| 앱 스크린샷(최신) | `docs/deliverables/screenshots/` (DLV-4.0 이 채움) + 기능별 `docs/features/*/screenshots/` |
| 브랜드 | 메인 보라 `#6B4EFF`, 외곽선 남색 `#2B1D5C`, 노랑 `#FFC83D`·민트 `#4CD4B0`·핑크 `#FF8FB1`(포인트), 폰트 Pretendard/Noto Sans KR 권장(양식에 글씨체 포함 저장) |
| 메타 | 작품명 **MARU (마루) — 외국인을 위한 한국어 학습 앱** · 팀 MARU · 팀원 하도윤(컴퓨터공학과 20200679) · 지도교수 **{미정: 하도윤 확인}** · 운영 `https://maru2026-production.up.railway.app` |

## 메시지 골격 (모든 산출물 공통 스토리)
1. **문제**: 한국어는 교착어(조사·어미가 붙음) → 기존 앱은 암기·객관식 중심, 구조를 체험하지 못함
2. **해결 MARU 4기능**: **M**orpheme 레슨(🐰 덩어리 → 🐢 목표 문법만 분해) · **A**daptive 단어(FSRS-4.5) · **R**oleplay 미션(토끼가 역할로 변신해 대화, 거북이가 레드/옐로카드 교정) · **U**pgrade 실험실(한글 조합·AI 문법 변형)
3. **캐릭터**: 🐰 빠른 체험(연기) / 🐢 느린 분석(코칭) — 학습 철학이 캐릭터로 살아 움직임
4. **기술**: Flutter + Spring Boot + PostgreSQL(JSONB) · Railway 배포 · Kiwi 형태소 파이프라인 · FSRS-4.5 · OpenAI(대화·TTS)/Gemini(문법) · AI 캐시 · 자동 테스트(서버 135·앱 83)
5. **결과·기대효과**: 실제 배포·실기기 동작, 정직한 수치(CLAIMS)

## Phase 4 Tasks (ID: DLV-4.x)
### Step 4.0 소재 (먼저)
- [-] DLV-4.0.1 [SHOT] (취소: 하도윤이 시연 녹화하며 iPhone 스크린샷 6~8장 직접 촬영 → `screenshots/`) 최종 앱 스크린샷 키트 — iPhone 16 Pro Max 시뮬레이터(통합 main, 로컬 `maru`, DEV_JWT), 상태바 깔끔(9:41·배터리 100%: `xcrun simctl status_bar ... override`), 화면당 1장 고해상도 PNG → `docs/deliverables/screenshots/NN_<화면>.png` + `INDEX.md`(파일·설명·추천 용도). 필수 목록은 아래 §SHOT
### Step 4.1 책자 PPT (첨부1 양식 기반)
- [x] DLV-4.1.1 [BOOK] 슬라이드 구성안(7장 내외: 필요성 및 배경 / 시스템 구성도 / 주요 기술 ×3(레슨·단어 FSRS·미션+실험실) / 캐릭터·UX / 결론 및 기대효과) → `book/OUTLINE.md`
- [x] DLV-4.1.2 [BOOK] 양식 pptx 로 제작 → `book/MARU_책자.pptx` + PDF 미리보기. 머리말 "2026년 졸업작품 · MARU", 바닥글 "팀원 하도윤 · 지도교수 ○○○". 글씨체 포함 저장. 맞춤법·오탈자 점검 — ✅ 10-01 dlv-design: `book/MARU_책자.pptx`·`.pdf`·`preview/`, 지도교수 한경수 교수. 임시 스크린샷(4.2.3 에서 교체)
### Step 4.2 포스터 (첨부2 양식, 42×60cm 비율 고정)
- [x] DLV-4.2.1 [POSTER] 레이아웃 시안 2개(텍스트 와이어) → 하도윤 선택
- [x] DLV-4.2.2 [POSTER] 제작 → `poster/MARU_포스터.pptx` + PNG/PDF 미리보기. 필수: 팀명·팀원·**프로젝트명 크게**·소개·예시화면 + **QR 자리**(학교 졸업작품 사이트 팀 페이지 — URL 확정 전 자리만, `qr.naver.com` 으로 생성 예정). 캐릭터 크게 활용
- [x] DLV-4.2.3 [POSTER] QR 이미지 삽입(팀 페이지 URL 대기) + 최종 스크린샷 교체(DLV-4.0.1 후) — 책자도 같이 교체. 방법: `book/README.md` — ✅ 10-04 QR 삽입(인식 확인), 스크린샷은 4.6.4 에서 교체 완료
### Step 4.3 발표·시연 영상용 발표자료 (≤10분)
- [x] DLV-4.3.1 [TALK] 발표 슬라이드(앞 3~4분) — 1학기 최종발표 구조 기반, 2학기 변화(캐릭터·FSRS-4.5·배포·피드백 반영) 반영, CLAIMS 준수 → `talk/MARU_발표.pptx` ✅ 10-01 22:45 (16장 3분 38초 + `OUTLINE.md`·`NOTES.md`·미리보기 PDF/PNG, 커밋 없음)
- [-] DLV-4.3.2 [TALK] (취소: 시연·기능 설명은 하도윤이 직접) → 대신 슬라이드 발표 대본 `talk/NOTES.md`
### Step 4.4 최종보고서
- [x] DLV-4.4.1 [REPORT] 1학기 `마루_최종보고서.docx` 기반 개정판 → `report/MARU_최종보고서_2학기.docx`: 2학기 변경(캐릭터·TTS·FSRS-4.5·조립 파이프라인 재작성·미션 판정·배포·테스트·사용자 피드백 3라운드·병렬 세션 개발 방법) 반영, 사실과 다른 1학기 문장 정정(CLAIMS ❌ 목록), 목차·그림 번호 갱신 — ✅ 77쪽 docx+pdf (10-01, 커밋 없음)
- [ ] DLV-4.4.2 [REPORT] (선택) GitHub README 정비 — 제출 시 "깃허브 링크" 대체 가능
### Step 4.5 PM 검수
- [ ] DLV-4.5.1 [PM] 4종 교차 검수: 수치·용어 일치, CLAIMS 위반 0, 오탈자, 양식 준수 → 하도윤 최종 확인

### Step 4.6 R4·R5 반영 패스 (10-02 PM 등록 — 4종 모두 R4 이전 작성)
공통 변경점: ①"AI Grammar Lab"→**Sentence Lab**(Explore/Combine, 거북이 실험 중 로딩) ②미션 **난이도 Easy/Normal/Hard**(기본 Easy, 토끼 답 짧게) ③**실험복 캐릭터**(실험실 화면) ④홈 파스텔 카드 4개 ⑤테스트 **서버 135·앱 83** ⑥운영 재배포·피드백 R2~R5(4라운드). 근거 = CLAIMS.md
- [x] DLV-4.6.1 [BOOK][POSTER] dlv-design: 책자·포스터 문구/수치 반영 + 실험복 캐릭터 활용 검토 — ✅ 10-02 dlv-design: 변경표 `book/README.md`
- [x] DLV-4.6.2 [TALK] dlv-talk: 슬라이드·NOTES·OUTLINE 반영(시연 순서에 난이도 선택·Sentence Lab 포함) ✅ 10-02 20:24 — 17장(피드백 4라운드 장 신설), 슬라이드 4:01 + 시연 4:30 ≈ 8:31, 미리보기 재생성, 커밋 없음
- [x] DLV-4.6.3 [REPORT] dlv-report: 본문·표·그림·부록 변경요약표 반영, PDF 재생성 — ✅ 82쪽 (10-02 20:24, 커밋 없음)
- [x] DLV-4.6.5 [REPORT] (10-03 하도윤 지시) 개정판 → **졸업작품 최종보고서** 문체로 전면 재작성: 변경 이력 서술·부록 A/B 삭제, 5장 최신 화면만, 프롬프트 절 재작성 → `report/MARU_최종보고서.docx`·`.pdf` 68쪽 (10-03 21:02, 커밋 없음)
- [x] DLV-4.6.4 [ALL] 하도윤 iPhone 스크린샷(`screenshots/`) 도착 시 임시 화면 교체(4.2.3 과 함께) — ✅ 10-03 dlv-design: 책자·포스터 교체 완료(표 `book/README.md`), 책자 7장 향후 계획 문구 삭제
- [ ] DLV-4.6.5 [ALL] "최소 턴" → "목표 대화 길이(기준 턴 안팎)" 문구 정정(CLAIMS 10-03, 코드는 유지 — D-26). 책자 5장에 해당 표현 있음 확인, 발표·보고서는 세션이 전수 검색 — **발표(talk)는 DLV-4.7.1 에서 함께 처리됨**(10-03 21:28: "목표 대화 길이 · Easy 3~4턴 안팎"으로 표기, 옛 표현 0건). 책자는 dlv-design 확인 필요

### Step 4.7 발표자료 전면 통일 (10-03 하도윤 요청)
- [x] DLV-4.7.1 [TALK] 전 장을 MARU 컨셉 한 디자인으로 재제작(1학기 슬라이드 재사용 금지) · "최종본" 서술(학기 비교·변천사·향후 계획 제거) · 사진은 `screenshots/` 키트 · 시안 3장 → 하도윤 확인 → 전체. 프롬프트 = PROMPTS.md 맨 아래 ✅ 10-03 21:28 — 17장 전면 재제작(맑은 고딕 한 종류·4레이아웃·키트 화면), 슬라이드 3:59 + 시연 4:30 ≈ 8:29, NOTES 재작성, PDF·PNG·모아보기, 제작 스크립트 `talk/_build/`, 커밋 없음

## §SHOT 필수 스크린샷 목록
홈(캐릭터 인사·복습 카드) · 한글 레슨 카드 · 한글 듣기 퀴즈 · 문법 레슨 조립 🐰 단계 · 조립 🐢 단계(거북이 힌트 말풍선) · 레슨 완료(토끼 cheer 점프) · 단어장 덱 그리드 · 단어 카드(평가 버튼 + 다음 간격) · Match 게임 · Match 완료 · 미션 설정 · 미션 로딩(토끼 magic, **역할 입력: café barista**) · 미션 채팅(레드카드·옐로카드 각 1) · 수료증 cleared · 수료증 not cleared(안 우는 토끼) · 한글랩 · 그래머랩 결과 · Stats · 캐릭터 갤러리 그리드(12표정)
