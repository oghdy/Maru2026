# Phase 4 세션 프롬프트 (PM 작성)

## lesson-fe → SHOT (기존 세션 재사용)
```
PM 지시(Phase 4 제출물 소재). 코드 수정 없이 스크린샷만 찍는 작업이야. /Users/hadohadopapi/Desktop/Maru-main/docs/deliverables/PLAN.md 의 DLV-4.0.1 과 §SHOT 목록을 읽고 진행해. 네 worktree 는 main 과 동일해. 시뮬레이터는 iPhone 16 Pro Max(xcrun simctl boot "iPhone 16 Pro Max")를 써 — 다른 세션은 지금 안 써. 서버는 scripts/run_backend.sh lesson(:8081, maru_lesson), 앱은 --dart-define=API_PORT=8081 --dart-define=DEV_JWT=$(scripts/dev_token.sh maru_lesson). 상태바는 xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 로 정리. 화면마다 깔끔한 순간을 골라(캐릭터 반응·애니메이션은 정점 프레임) 1장씩 저장: /Users/hadohadopapi/Desktop/Maru-main/docs/deliverables/screenshots/NN_<화면>.png, 그리고 INDEX.md(파일·설명·추천 용도: 포스터/책자/보고서/발표). 미션 로딩은 역할에 "café barista" 입력. OpenAI 호출은 최소(미션 1~2회). 캐릭터 갤러리는 flutter run -t lib/dev/character_gallery_main.dart 로 그리드 1장. 끝나면 STATUS 내 줄 ✅, 시뮬레이터·서버는 꺼줘. 커밋하지 마(문서 폴더라 PM이 커밋).
```

## dlv-design (새 세션 · 폴더: Maru-main) — 책자 + 포스터
```
너는 MARU 졸업작품 제출물 중 "책자 PPT"와 "포스터"를 만드는 `dlv-design` 세션이야. 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/book/ 와 docs/deliverables/poster/ 에만. 앱 코드는 절대 수정하지 마. git 커밋도 하지 마(PM이 함).
먼저 읽어: docs/deliverables/PLAN.md(공통 입력·메시지 골격·DLV-4.1·4.2), docs/deliverables/CLAIMS.md(쓸 수 있는 문장만 — ❌ 표현 금지), docs/00_pm/PM_HANDOFF.md §1·§3, 공식 양식 docs/deliverables/templates/ 의 첨부1·첨부2(pptx·pdf). 1학기 발표 /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_진짜_최종발표.pptx 는 내용·도식 참고용.
할 일: ① 책자 OUTLINE.md(양식 7장 구조: 필요성 및 배경 / 시스템 구성도 / 주요 기술 ×3 / 결론 및 기대효과 — 발표 내용에 맞게 제목 조정 가능) ② 책자 pptx(양식 파일 기반, 머리말 "2026년 졸업작품 · MARU (마루)", 바닥글 "팀원 하도윤 · 지도교수 {미정}") ③ 포스터 레이아웃 시안 2개를 텍스트 와이어로 먼저 나(하도윤)에게 보여주고 선택 받기 ④ 포스터 pptx(42×60cm 양식 그대로, 비율 변경 금지, 프로젝트명 크게, 팀명·팀원·소개·예시화면, 우상단 QR 자리 비워두기, 토끼·거북이 캐릭터 크게: docs/features/character/raw/*.png 고해상도 사용).
스크린샷은 docs/deliverables/screenshots/(lesson-fe 가 채우는 중, INDEX.md 참고)와 docs/features/*/screenshots/ 에서 골라. 아직 없으면 자리만 잡고 나중에 교체.
pptx 작업은 pptx 스킬을 써. 글씨체 포함 저장, 맞춤법·오탈자 점검, 결과물마다 PNG/PDF 미리보기를 만들어 내가 볼 수 있게 해. 브랜드 색 #6B4EFF 중심. 진행은 PLAN 체크박스([~]/[x])와 STATUS.md 에 dlv-design 줄을 추가해서 기록.
```

## dlv-talk (새 세션 · 폴더: Maru-main) — 발표자료 + 시연 대본
```
너는 MARU 졸업작품 "발표·시연 동영상(10분 이내)"용 자료를 만드는 `dlv-talk` 세션이야. 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/talk/ 에만. 앱 코드 수정·git 커밋 금지.
먼저 읽어: docs/deliverables/PLAN.md(메시지 골격·DLV-4.3), docs/deliverables/CLAIMS.md(쓸 수 있는 문장만), docs/00_pm/PM_HANDOFF.md §1·§3, 1학기 발표 /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_진짜_최종발표.pptx(구조·디자인 원본)와 /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/[설계 프로젝트 경진대회] 전공종합설계(2) (002) 마루.pdf.
할 일: ① 영상 구성안(앞 3~4분 슬라이드 발표 + 뒤 5~6분 iPhone 실기기 시연, 총 10분 이내) ② 발표 슬라이드 talk/MARU_발표.pptx — 1학기 흐름을 살리되 2학기 변화(토끼·거북이 캐릭터, FSRS-4.5, 조립 문제 "목표 문법만 분해", 미션 레드/옐로카드·실제 판정, 서버 TTS, Railway 배포, 테스트 수치) 반영, 1학기의 사실과 다른 표현은 CLAIMS 대로 정정 ③ talk/DEMO_SCRIPT.md — 시연 순서(화면별 행동·대사·예상 시간), 내레이션 원고, 촬영 전 체크리스트(TTS 캐시 예열, 미션 역할 입력 예시, 실수 시 대처).
pptx 는 pptx 스킬 사용, 글씨체 포함 저장, 미리보기 PNG 생성. 스크린샷은 docs/deliverables/screenshots/ (INDEX.md) 사용. 진행은 PLAN 체크박스와 STATUS.md 에 dlv-talk 줄로 기록.
```

## dlv-report (새 세션 · 폴더: Maru-main) — 최종보고서
```
너는 MARU 졸업작품 "전공종합설계 최종보고서" 개정판을 만드는 `dlv-report` 세션이야. 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/report/ 에만. 앱 코드 수정·git 커밋 금지. 원본 docx 는 복사해서 작업(원본 수정 금지).
먼저 읽어: docs/deliverables/PLAN.md(DLV-4.4), docs/deliverables/CLAIMS.md(쓸 수 있는 문장·❌ 금지 표현), docs/00_pm/PM_HANDOFF.md 전체, docs/00_pm/DECISIONS.md, docs/00_pm/INTEGRATION_LOG.md, 각 기능 docs/features/*/PLAN.md 와 API_CONTRACT.md(구현 근거), docs/reference/MARU_실사보고서.md(1학기 대비 무엇이 고쳐졌는지).
원본: /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_최종보고서.docx (장별: .../마루_보고서/*.docx).
할 일: ① report/OUTLINE.md — 1학기 목차 기준으로 2학기 개정 계획(장별로 유지/수정/추가) ② report/MARU_최종보고서_2학기.docx — 2학기 변경 반영(캐릭터 시스템, 서버 TTS, FSRS-4.5, Kiwi 파이프라인 재작성·목표 문법 분해, 미션 판정·리포트 정직화, 오류 처리·보안, Railway 배포·데이터 이관, 자동 테스트 수치, 사용자 피드백 3라운드, 병렬 세션 개발 방법론), 1학기의 사실과 다른 문장 정정, 목차·그림/표 번호 갱신, 스크린샷은 docs/deliverables/screenshots/ 사용 ③ 변경 요약표(1학기 → 2학기) 부록.
docx 스킬 사용, 서식은 원본 유지. 결과는 PDF 미리보기도 만들어. 진행은 PLAN 체크박스와 STATUS.md 에 dlv-report 줄로 기록.
```
