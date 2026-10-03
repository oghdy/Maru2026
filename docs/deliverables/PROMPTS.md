# Phase 4 세션 프롬프트 (PM 작성)

## dlv-design (새 세션 · 폴더: Maru-main) — 책자 + 포스터
```
너는 MARU 졸업작품 제출물 중 "책자 PPT"와 "포스터"를 만드는 `dlv-design` 세션이야. 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/book/ 와 docs/deliverables/poster/ 에만. 앱 코드는 절대 수정하지 마. git 커밋도 하지 마(PM이 함).
먼저 읽어: docs/deliverables/PLAN.md(공통 입력·메시지 골격·DLV-4.1·4.2), docs/deliverables/CLAIMS.md(쓸 수 있는 문장만 — ❌ 표현 금지), docs/00_pm/PM_HANDOFF.md §1·§3, 공식 양식 docs/deliverables/templates/ 의 첨부1·첨부2(pptx·pdf). 1학기 발표 /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_진짜_최종발표.pptx 는 내용·도식 참고용.
할 일: ① 책자 OUTLINE.md(양식 7장 구조: 필요성 및 배경 / 시스템 구성도 / 주요 기술 ×3 / 결론 및 기대효과 — 발표 내용에 맞게 제목 조정 가능) ② 책자 pptx(양식 파일 기반, 머리말 "2026년 졸업작품 · MARU (마루)", 바닥글 "팀원 하도윤 · 지도교수 {미정}") ③ 포스터 레이아웃 시안 2개를 텍스트 와이어로 먼저 나(하도윤)에게 보여주고 선택 받기 ④ 포스터 pptx(42×60cm 양식 그대로, 비율 변경 금지, 프로젝트명 크게, 팀명·팀원·소개·예시화면, 우상단 QR 자리 비워두기, 토끼·거북이 캐릭터 크게: docs/features/character/raw/*.png 고해상도 사용).
예시 화면은 하도윤이 iPhone 에서 찍어 docs/deliverables/screenshots/ 에 넣을 예정이야. 그 전에는 docs/features/*/screenshots/ (세션들이 찍어둔 시뮬레이터 화면)에서 골라 임시로 넣고, 실기기 스크린샷이 오면 교체.
pptx 작업은 pptx 스킬을 써. 글씨체 포함 저장, 맞춤법·오탈자 점검, 결과물마다 PNG/PDF 미리보기를 만들어 내가 볼 수 있게 해. 브랜드 색 #6B4EFF 중심. 진행은 PLAN 체크박스([~]/[x])와 STATUS.md 에 dlv-design 줄을 추가해서 기록.
```

## dlv-talk (새 세션 · 폴더: Maru-main) — 발표 슬라이드 (영상 앞부분)
```
너는 MARU 졸업작품 "발표·시연 동영상(10분 이내)"의 발표 슬라이드를 만드는 `dlv-talk` 세션이야. 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/talk/ 에만. 앱 코드 수정·git 커밋 금지.
영상 구성: [슬라이드 발표: 문제 제기 → 해결 방안 → 기술 스택·시스템 구성] → [시연 영상: 하도윤이 iPhone 으로 녹화하며 직접 기능 설명] → [기대효과·마무리 슬라이드]. 너는 슬라이드 부분만 만든다(시연은 만들지 않음).
먼저 읽어: docs/deliverables/PLAN.md(메시지 골격), docs/deliverables/CLAIMS.md(쓸 수 있는 문장만 — ❌ 표현 금지), docs/00_pm/PM_HANDOFF.md §1·§3.
원본(구조·디자인 이어받기): 1학기 설계 경진대회 발표 /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/[설계 프로젝트 경진대회] 전공종합설계(2) (002) 마루.pdf 와 원본 pptx /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/전종설(2)_마루_발표자료/전종설(2)_마루_발표자료.pptx (복사해서 작업, 원본 수정 금지). 기술 슬라이드는 /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_진짜_최종발표.pptx 참고.
할 일: ① talk/OUTLINE.md — 슬라이드별 제목·핵심 문장·예상 시간(슬라이드 부분 합계 3~4분, 시연 자리 5~6분 확보) ② talk/MARU_발표.pptx — 1학기 흐름을 살리되 2학기 변화(토끼·거북이 캐릭터, FSRS-4.5, 조립 문제 "레슨 목표 문법만 분해", 미션 토끼 변신·레드/옐로카드·실제 판정, 서버 TTS, Railway 배포, 자동 테스트 수치) 반영, 1학기의 사실과 다른 표현은 CLAIMS 대로 정정, 시연 영상 들어갈 자리에 "시연" 구분 슬라이드 1장 ③ talk/NOTES.md — 슬라이드별 발표 대본(하도윤이 읽을 문장).
pptx 스킬 사용, 글씨체 포함 저장, 미리보기 PNG 생성. 캐릭터 이미지 docs/features/character/raw/*.png 활용 가능. 진행은 PLAN 체크박스와 STATUS.md 에 dlv-talk 줄로 기록.
```

## dlv-report (새 세션 · 폴더: Maru-main) — 최종보고서
```
너는 MARU 졸업작품 "전공종합설계 최종보고서"를 **이미 쓴 1학기 보고서를 고쳐서** 완성하는 `dlv-report` 세션이야. 새로 쓰지 말고, 1학기 보고서를 읽고 2학기에 발전·변경된 부분만 수정·추가해. 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/report/ 에만. 앱 코드 수정·git 커밋 금지. 원본 docx 는 복사해서 작업(원본 수정 금지).
먼저 읽어: docs/deliverables/PLAN.md(DLV-4.4), docs/deliverables/CLAIMS.md(쓸 수 있는 문장·❌ 금지 표현), docs/00_pm/PM_HANDOFF.md 전체, docs/00_pm/DECISIONS.md, docs/00_pm/INTEGRATION_LOG.md, 각 기능 docs/features/*/PLAN.md 와 API_CONTRACT.md(구현 근거), docs/reference/MARU_실사보고서.md(1학기 대비 무엇이 고쳐졌는지).
원본: /Users/hadohadopapi/Desktop/hdy/2026_1학기/전종설(2)/마루_최종제출/마루_최종보고서.docx (장별: .../마루_보고서/*.docx).
할 일: ① report/OUTLINE.md — 1학기 목차 기준으로 2학기 개정 계획(장별로 유지/수정/추가) ② report/MARU_최종보고서_2학기.docx — 2학기 변경 반영(캐릭터 시스템, 서버 TTS, FSRS-4.5, Kiwi 파이프라인 재작성·목표 문법 분해, 미션 판정·리포트 정직화, 오류 처리·보안, Railway 배포·데이터 이관, 자동 테스트 수치, 사용자 피드백 3라운드, 병렬 세션 개발 방법론), 1학기의 사실과 다른 문장 정정, 목차·그림/표 번호 갱신, 스크린샷은 docs/deliverables/screenshots/ 사용 ③ 변경 요약표(1학기 → 2학기) 부록.
docx 스킬 사용, 서식은 원본 유지. 결과는 PDF 미리보기도 만들어. 진행은 PLAN 체크박스와 STATUS.md 에 dlv-report 줄로 기록.
```

---
# Step 4.6 — R4·R5 반영 패스 (10-02 20:13, PM)
> 세션이 살아 있으면 그대로 붙여넣기. 닫혔으면 위 첫 프롬프트 대신 이것만 새 세션에 붙여넣어도 됨(읽을 파일 포함).

## 공통 머리말 (3개 모두 앞에 포함됨)
앱이 10-02 에 R4·R5 피드백으로 바뀌었고 운영 재배포까지 끝났어. 네 1차본(10-01)은 그 이전 내용이라 반영 패스가 필요해. 근거는 **docs/deliverables/CLAIMS.md (10-02 갱신)** 와 docs/deliverables/PLAN.md Step 4.6. 바뀐 점: ①"AI Grammar Lab" → **Sentence Lab**(Explore/Combine 두 모드, "거북이 실험 중" 로딩, 설명에 AI(Gemini) 기반 명시) ②미션 **난이도 Easy/Normal/Hard(기본 Easy)** — 토끼 답이 짧아지고 최소 턴·교정 강도가 난이도별 ③실험실 화면에 **실험복 토끼·거북이**(이미지 docs/features/character/raw/ 와 frontend/maru/assets/characters/ 의 *_lab_*) ④홈 4개 카드 파스텔 ⑤테스트 **서버 135·앱 83**(123·67, 107·11 은 전부 교체) ⑥피드백 **4라운드(R2~R5)**, 운영 재배포. 새 화면 참고: docs/features/lab/screenshots/r4·r5/, docs/features/mission/screenshots/r4_fe2/, docs/features/lesson/screenshots/r4_PM-1.8.1_after.png. 앱 코드 수정·git 커밋 금지.

## dlv-design → DLV-4.6.1
```
[DLV-4.6.1] 너는 dlv-design 세션(책자·포스터). 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/book/·poster/ 에만. 앱 코드 수정·git 커밋 금지.
앱이 10-02 에 R4·R5 피드백으로 바뀌어서 10-01 1차본에 반영 패스가 필요해. 먼저 읽어: docs/deliverables/CLAIMS.md(10-02 갱신), docs/deliverables/PLAN.md Step 4.6, docs/deliverables/PROMPTS.md 맨 아래 "공통 머리말".
할 일: ① 책자·포스터 전체에서 "Grammar Lab"·테스트 수치(123·67 등)·피드백 라운드 수 찾아 교체(pptx 텍스트 전수 검색 결과를 표로 남겨) ② 미션 설명에 난이도 3단계 한 줄, 실험실 설명에 Sentence Lab(Explore/Combine) 반영 ③ 실험실/주요기술 칸에 실험복 캐릭터 쓸지 검토 — 포스터는 기본 토끼·거북이가 메인이니 무리하게 바꾸지 말고 들어갈 자리가 있으면 작게 ④ 임시 스크린샷 중 옛 화면(그래머랩·미션 설정)이 있으면 위 r4/r5 시뮬레이터 화면으로 임시 교체 ⑤ PDF·PNG 미리보기 재생성, book/README.md 에 변경 내역. QR·최종 iPhone 스크린샷은 여전히 대기(DLV-4.2.3).
끝나면 PLAN 4.6.1 [x], STATUS.md dlv-design 줄 갱신(시각은 `date`).
```

## dlv-talk → DLV-4.6.2
```
[DLV-4.6.2] 너는 dlv-talk 세션(발표 슬라이드). 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/talk/ 에만. 앱 코드 수정·git 커밋 금지.
앱이 10-02 에 R4·R5 피드백으로 바뀌어서 10-01 1차본에 반영 패스가 필요해. 먼저 읽어: docs/deliverables/CLAIMS.md(10-02 갱신), docs/deliverables/PLAN.md Step 4.6, docs/deliverables/PROMPTS.md 맨 아래 "공통 머리말".
할 일: ① MARU_발표.pptx·NOTES.md·OUTLINE.md 에서 "Grammar Lab"·테스트 수치·피드백 라운드 수 전수 교체 ② 미션 슬라이드에 "난이도 3단계 — 초급자는 Easy 로 짧은 대화부터"(문제 정의의 '초급자에게 어렵다'와 연결), 실험실 슬라이드는 Sentence Lab(Explore/Combine) + 실험복 캐릭터 ③ 사용자 피드백 반영을 보여주는 슬라이드가 있으면 R2~R5 4라운드 핵심 1줄씩 ④ DEMO 구분 슬라이드/NOTES 에 하도윤 시연 순서 추천(홈 → 레슨 → 단어 → 미션 Easy 선택·레드/옐로카드·수료증 → Sentence Lab → 마무리)과 각 30~60초 배분 — 총 영상 10분 이내 유지 ⑤ 미리보기 PDF/PNG 재생성.
끝나면 PLAN 4.6.2 [x], STATUS.md dlv-talk 줄 갱신(시각은 `date`).
```

## dlv-report → DLV-4.6.3
```
[DLV-4.6.3] 너는 dlv-report 세션(최종보고서 개정판). 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/report/ 에만. 앱 코드 수정·git 커밋 금지.
앱이 10-02 에 R4·R5 피드백으로 바뀌어서 10-01 개정판에 반영 패스가 필요해. 먼저 읽어: docs/deliverables/CLAIMS.md(10-02 갱신), docs/deliverables/PLAN.md Step 4.6, docs/deliverables/PROMPTS.md 맨 아래 "공통 머리말", 근거 문서 docs/features/mission/API_CONTRACT.md §1-8(난이도), docs/features/lab/PLAN.md Step 1.8·1.9, docs/features/character/CHARACTER_API.md(MaruOutfit), docs/00_pm/DECISIONS.md D-24·D-25, docs/00_pm/INTEGRATION_LOG.md 마지막 항목들.
할 일: ① 본문·표·그림 캡션·부록 변경요약표에서 "Grammar Lab"(→ Sentence Lab, 첫 등장에 "구 AI Grammar Lab" 병기 허용)·테스트 수치(135·83)·피드백 라운드(3→4) 교체 ② 미션 장에 난이도 설계 절 추가(표: 어휘 수준·최소 턴·토끼 답 길이·교정 강도·수료 판정 — API_CONTRACT §1-8 그대로) ③ 실험실 장에 Explore/Combine 모드 UI 재설계와 거북이 실험 로딩, 캐릭터 장에 실험복 의상(21장 = 기본 15 + 실험복 6, 폴백) ④ 피드백 절에 R4·R5 항목 추가 ⑤ OUTLINE 하단 "확인 필요 4건" 중 해결된 것 정리(테스트 수치 = 135·83 확정) ⑥ 목차·그림/표 번호 갱신 후 PDF 재생성, 쪽수 보고.
끝나면 PLAN 4.6.3 [x], STATUS.md dlv-report 줄 갱신(시각은 `date`).
```

---
# DLV-4.6.5 — "최소 턴" 문구 정정 (10-03 21:11, PM · D: 코드 유지, 문구만)
근거: CLAIMS.md MSN 절(10-03). 3-Zone 규칙상 목표를 이루면 기준 턴 −1 부터 클리어 가능 → "최소 턴 3~4" 는 사실과 다름. 세 세션 공통 프롬프트(아래 [세션명] 만 바꿔 붙여넣기).
```
[DLV-4.6.5] 문구 정정 1건. docs/deliverables/CLAIMS.md 의 Mission Chat 절(10-03 갱신)을 다시 읽어.
미션 난이도 설명에서 "최소 턴"·"최소 N턴"·"minTurns 3~4" 같은 표현을 네 산출물 전체(pptx/docx 본문·표·캡션·대본·OUTLINE)에서 찾아 "목표 대화 길이(Easy 3~4턴 / Normal 4~6턴 / Hard 5~10턴 안팎)" 로 바꿔. 표의 행 이름이 "최소 턴"이면 "목표 대화 길이(기준 턴)"로. "N턴 이상 대화해야 클리어"처럼 읽히는 문장은 "목표를 이루면 기준 턴 무렵에 마무리, 기준 +3턴 안에 반드시 종료"로. 3-Zone 설명("서버가 강제, 최대 기준+3턴 안에 종료")은 그대로 둬.
바꾼 곳을 "위치 → 전 → 후" 표로 보고하고 PDF·미리보기 재생성. 해당 표현이 없으면 "없음"이라고 보고. 앱 코드 수정·git 커밋 금지. STATUS.md 자기 줄 갱신(시각은 `date`).
```

---
# DLV-4.7.1 — 발표자료 전면 통일 (10-03, PM · 하도윤 요청: 톤 통일 + "최종본" 느낌 + 사진 최신화)
```
[DLV-4.7.1] 너는 dlv-talk 세션(발표 슬라이드). 작업 폴더 /Users/hadohadopapi/Desktop/Maru-main, 산출물은 docs/deliverables/talk/ 에만. 앱 코드 수정·git 커밋 금지. 지금 파일은 talk/_backup_1003/ 에 복사해 두고 시작해.
문제: 지금 발표자료는 1학기 슬라이드(1~7·15~17장) 뒤에 새 슬라이드를 붙인 거라 앞뒤 디자인 톤이 다르다. 그리고 이번 제출·영상이 **최종**인데 "2학기 변화", "1학기 대비" 같은 중간보고 느낌이 남아 있다. 전체를 MARU 컨셉 하나로 다시 만든다.

A. 디자인 통일 (전 장을 같은 시스템으로 새로 제작 — 1학기 슬라이드를 그대로 재사용하지 말 것. 내용·도표의 논지만 가져와 새 디자인으로 다시 그림)
- 컨셉: 앱·포스터와 같은 MARU 무드. 브랜드 보라 #6B4EFF, 남색 #2B1D5C, 연보라 카드 #F0EDFF, 포인트 노랑·민트·핑크, 둥근 카드, 토끼·거북이 캐릭터(docs/features/character/raw/*.png, 실험실 내용엔 *_lab_*). 참고: docs/deliverables/poster/MARU_포스터_preview.png, screenshots/01_home.png
- 글꼴 한 종류로 통일(한글·영문 모두, 포함 저장 가능한 것). 제목 위치·크기, 여백, 쪽번호, 섹션 표시(문제 → 해결 → 기술 → 시연 → 기대효과)를 전 장 동일 규칙으로. 표지·섹션 구분·본문·마무리 4종 레이아웃만 사용
- 문제 제기 장(K-컬처, 시장 규모, 교착어, FSI, 기존 앱)의 사진·그래프도 새 스타일로 다시 그리거나 같은 카드 틀에 넣어 이질감 없애기. 출처 표기는 유지

B. "최종본" 내용 정리
- 빼기: "1학기/2학기", "지난 학기 대비", "바뀐 점", "설계에서 실제 동작으로", "개선했다/고쳤다" 식의 변천사 서술, 향후 계획·추후 과제·로드맵 일체. 전수 검색해서 슬라이드·노트·NOTES.md·OUTLINE.md 모두 0건으로
- 바꾸기: 현재 11장(2학기 변화+수치) → "완성도와 검증" 한 장(완성된 사실만: 한 턴 1.5~2초·순차 대비 30~50% 단축, 캐시 HIT 1~2ms, 자동 테스트 서버 135·앱 83, Railway 운영 배포·실기기 동작). 현재 12장(피드백 4라운드) → "사용자 검증: 실제로 써 보며 4차례 다듬었다"로 짧게(또는 완성도 장에 합치기 — 네 판단, 이유를 말해줘)
- 마무리: 기대효과 → '마루' 의미 한 장 → 감사합니다. 지금의 마루 2장(15·16)은 한 장으로 합쳐. 근거 없는 포부·미래 약속 문장 금지
- 말투는 전부 "MARU 는 ~한다"(완성된 제품 소개). 모든 문장은 docs/deliverables/CLAIMS.md(10-03 갱신) ✅ 표현만 — 특히 "최소 턴" ❌ → "목표 대화 길이(Easy 3~4턴 안팎)", Sentence Lab, 테스트 135·83

C. 사진 최신화
- 앱 화면은 전부 docs/deliverables/screenshots/ 키트에서(INDEX.md 먼저 읽기). 레슨 = 07_lesson_morpheme_turtle.png(지금 쓰는 apply_lesson_C1 은 옛 화면), 미션 = 02·04a·06, 단어 = 09, 실험실 = 11~14, 홈 = 01. 폰 프레임·크기 규칙 통일

D. 진행 순서
1) 새 OUTLINE(장별 제목·핵심 문장·시간) + 디자인 시안 3장(표지, 문제 제기 1장, 기능 소개 1장)을 PNG 로 먼저 나(하도윤)에게 보여주고 확인받기
2) 확인 후 전체 제작. 시간 배분 유지: 슬라이드 앞 ≈3분 20초 + 시연 4분 30초 + 마무리 ≈40초, 영상 총 10분 이내. 시연 구분(DEMO) 장 유지
3) NOTES.md 대본을 새 장 구성에 맞춰 다시 쓰기(시연 표는 유지, 팁 추가: Easy 미션은 인사·주문으로 시작해 3턴 이상, 레드카드는 반말 한 번)
4) 미리보기 PDF·PNG 재생성, 전 장을 나란히 놓은 한 장짜리 모아보기(contact sheet) PNG 도 만들어 톤이 통일됐는지 직접 확인하고 보여줘
끝나면 docs/deliverables/PLAN.md 의 DLV-4.7.1 [x](4.6.5 도 함께 처리됨으로 표시), docs/00_pm/STATUS.md dlv-talk 줄 갱신(시각은 `date`).
```
