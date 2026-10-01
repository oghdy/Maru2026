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
4. **기술**: Flutter + Spring Boot + PostgreSQL(JSONB) · Railway 배포 · Kiwi 형태소 파이프라인 · FSRS-4.5 · OpenAI(대화·TTS)/Gemini(문법) · AI 캐시 · 자동 테스트(서버 123·앱 67)
5. **결과·기대효과**: 실제 배포·실기기 동작, 정직한 수치(CLAIMS)

## Phase 4 Tasks (ID: DLV-4.x)
### Step 4.0 소재 (먼저)
- [-] DLV-4.0.1 [SHOT] (취소: 하도윤이 시연 녹화하며 iPhone 스크린샷 6~8장 직접 촬영 → `screenshots/`) 최종 앱 스크린샷 키트 — iPhone 16 Pro Max 시뮬레이터(통합 main, 로컬 `maru`, DEV_JWT), 상태바 깔끔(9:41·배터리 100%: `xcrun simctl status_bar ... override`), 화면당 1장 고해상도 PNG → `docs/deliverables/screenshots/NN_<화면>.png` + `INDEX.md`(파일·설명·추천 용도). 필수 목록은 아래 §SHOT
### Step 4.1 책자 PPT (첨부1 양식 기반)
- [x] DLV-4.1.1 [BOOK] 슬라이드 구성안(7장 내외: 필요성 및 배경 / 시스템 구성도 / 주요 기술 ×3(레슨·단어 FSRS·미션+실험실) / 캐릭터·UX / 결론 및 기대효과) → `book/OUTLINE.md`
- [~] DLV-4.1.2 [BOOK] 양식 pptx 로 제작 → `book/MARU_책자.pptx` + PDF 미리보기. 머리말 "2026년 졸업작품 · MARU", 바닥글 "팀원 하도윤 · 지도교수 ○○○". 글씨체 포함 저장. 맞춤법·오탈자 점검
### Step 4.2 포스터 (첨부2 양식, 42×60cm 비율 고정)
- [x] DLV-4.2.1 [POSTER] 레이아웃 시안 2개(텍스트 와이어) → 하도윤 선택
- [ ] DLV-4.2.2 [POSTER] 제작 → `poster/MARU_포스터.pptx` + PNG/PDF 미리보기. 필수: 팀명·팀원·**프로젝트명 크게**·소개·예시화면 + **QR 자리**(학교 졸업작품 사이트 팀 페이지 — URL 확정 전 자리만, `qr.naver.com` 으로 생성 예정). 캐릭터 크게 활용
### Step 4.3 발표·시연 영상용 발표자료 (≤10분)
- [ ] DLV-4.3.1 [TALK] 발표 슬라이드(앞 3~4분) — 1학기 최종발표 구조 기반, 2학기 변화(캐릭터·FSRS-4.5·배포·피드백 반영) 반영, CLAIMS 준수 → `talk/MARU_발표.pptx`
- [-] DLV-4.3.2 [TALK] (취소: 시연·기능 설명은 하도윤이 직접) → 대신 슬라이드 발표 대본 `talk/NOTES.md`
### Step 4.4 최종보고서
- [ ] DLV-4.4.1 [REPORT] 1학기 `마루_최종보고서.docx` 기반 개정판 → `report/MARU_최종보고서_2학기.docx`: 2학기 변경(캐릭터·TTS·FSRS-4.5·조립 파이프라인 재작성·미션 판정·배포·테스트·사용자 피드백 3라운드·병렬 세션 개발 방법) 반영, 사실과 다른 1학기 문장 정정(CLAIMS ❌ 목록), 목차·그림 번호 갱신
- [ ] DLV-4.4.2 [REPORT] (선택) GitHub README 정비 — 제출 시 "깃허브 링크" 대체 가능
### Step 4.5 PM 검수
- [ ] DLV-4.5.1 [PM] 4종 교차 검수: 수치·용어 일치, CLAIMS 위반 0, 오탈자, 양식 준수 → 하도윤 최종 확인

## §SHOT 필수 스크린샷 목록
홈(캐릭터 인사·복습 카드) · 한글 레슨 카드 · 한글 듣기 퀴즈 · 문법 레슨 조립 🐰 단계 · 조립 🐢 단계(거북이 힌트 말풍선) · 레슨 완료(토끼 cheer 점프) · 단어장 덱 그리드 · 단어 카드(평가 버튼 + 다음 간격) · Match 게임 · Match 완료 · 미션 설정 · 미션 로딩(토끼 magic, **역할 입력: café barista**) · 미션 채팅(레드카드·옐로카드 각 1) · 수료증 cleared · 수료증 not cleared(안 우는 토끼) · 한글랩 · 그래머랩 결과 · Stats · 캐릭터 갤러리 그리드(12표정)
