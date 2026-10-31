# 책자 · 포스터 산출물 (dlv-design)

| 파일 | 설명 |
|---|---|
| `book/MARU_책자.pptx` | 첨부1 양식 기반 7장(100×75cm, 양식과 동일 크기). 머리말·바닥글 모든 장 |
| `book/MARU_책자.pdf` | PowerPoint 로 내보낸 PDF — **맑은 고딕 포함**(인쇄·제출용 안전본) |
| `book/preview/book_NN.png` | 장별 미리보기 |
| `poster/MARU_포스터.pptx` | 첨부2 양식(42×60cm, 비율 그대로) 1장 — 시안 B 보라 히어로 |
| `poster/MARU_포스터.pdf`, `poster/MARU_포스터_preview.png` | PDF(글꼴 포함)·미리보기 |

## 다시 만들기
```
python3 docs/deliverables/book/_build/build_book.py
python3 docs/deliverables/poster/_build/build_poster.py
```
- 스크린샷 교체: 각 스크립트 맨 위 `SHOTS` 의 경로를 `docs/deliverables/screenshots/NN_*.png` 로 바꾸고 다시 실행 → `book/_build/topdf.sh <임시복사본.pptx> <out.pdf>` 로 PDF 내보내기(PowerPoint 필요, 다른 세션 문서와 안 섞이게 이름으로 지정).
- 10-03: 최종 스크린샷 키트(`docs/deliverables/screenshots/`)로 전부 교체 완료.

## 남은 일
- **포스터 QR**: 우상단 흰 사각형(도형 이름 `QR_자리`, 6.7×6.7cm) 위에 qr.naver.com 에서 만든 QR 이미지를 같은 크기로 올리면 됨.
- **글씨체 포함**: 글꼴은 양식 테마와 같은 **맑은 고딕**(윈도우 기본·맥 Office 내장)만 사용. 맥 PowerPoint 는 자동 글꼴 포함 저장이 안 돼서, pptx 에 `embedTrueTypeFonts` 표시만 해 둠 → 윈도우 PowerPoint 에서 한 번 열어 저장하면 포함됨(파일 > 옵션 > 저장 > "파일의 글꼴 포함" 확인). 인쇄소·제출은 PDF 를 쓰면 글꼴 문제 없음.

## 변경 내역
### 10-02 R4·R5 반영 (DLV-4.6.1)
근거: `CLAIMS.md`(10-02). pptx 텍스트 전수 검색(`markitdown` + grep: Grammar·그래머·문법 실험·123·67·107·라운드·난이도·Sentence·Explore·Combine·실험복·Easy) 결과:

| 위치 | 전 (10-01) | 후 (10-02) |
|---|---|---|
| 책자 2장 외부 서비스 | Gemini 2.5 Flash — "AI 문법 실험실" | "Sentence Lab (문장 실험)" |
| 책자 5장 실험실 칸 | "그래머랩 — AI 문법 변형" / "Gemini 2.5 Flash · 같은 요청은 DB 캐시" | "Sentence Lab · AI(Gemini) 기반" + Explore(시제·높임·부정·감정 → 변형 3개) / Combine(수식어 조합) + "분석 중 '거북이 실험 중' 로딩" |
| 책자 5장 실험실 칸 | 거북이(기본) 이미지 | **실험복 토끼·거북이** + "실험실의 실험복 캐릭터" |
| 책자 5장 미션 설명 | 레드·옐로카드 / AI 코치 판정 / 항상 피드백 | **난이도 3단계**(Easy·Normal·Hard, 기본 Easy — 어휘·최소 턴·토끼 답 길이·교정 강도) / 레드=큰 실수·옐로=작은 실수 / 판정·피드백 |
| 책자 6장 캐릭터 | "AI 생성 표정 이미지 15장 (토끼 8 · 거북이 7)" | "AI 생성 캐릭터 이미지 21장 = 기본 15 + 실험복 6" + 폴백 설명, 그림 띠 21장 |
| 책자 7장 수치 | "123 · 67" | **"135 · 83"** |
| 책자 7장 부제 | "…iPhone 실기기 설치와 Google 로그인까지 확인한 실제 서비스" | "Railway 운영 배포 · iPhone 실기기 동작 확인 · 사용자 피드백 **4라운드(R2~R5)** 반영" |
| 포스터 R 카드 | 4줄 | + "난이도 Easy · Normal · Hard" |
| 포스터 U 카드 | "AI 문법 변형 (Gemini)" / "같은 요청은 DB 캐시" | "Sentence Lab (AI · Gemini)" / "Explore · Combine 두 모드" / "같은 요청 캐시 HIT 1~2ms" + U 배지 옆 실험복 캐릭터(작게) |
| 포스터 기타 | 테스트 수치·피드백 라운드·Grammar 표기 없음 | 변경 없음 (기본 토끼·거북이 메인 유지) |

남은 검색 결과는 의도된 것: "짝맞추기 라운드"(게임 라운드), 4장 "난이도(D)"(FSRS), 4장 "Easy"(FSRS 평가 버튼).

임시 스크린샷 교체 (옛 화면 → R4·R5 시뮬레이터):
| 자리 | 전 | 후 |
|---|---|---|
| 책자 5장 미션 1 | `mission/r3_fe2/12_loading_magic.png` | `mission/r4_fe2/1_setup_difficulty.png` (난이도 선택) |
| 책자 5장 미션 3 | `mission/r3_fe2/8_report_p1_not_cleared.png` | `mission/r4_fe2/6_report_cleared_easy_badge.png` |
| 책자 5장 실험실 | `character/apply_lab_C3.png` ("AI Grammar Lab") | `lab/r5/after_outfit_4_sentence_idle.png` |
| 포스터 U 1 | `character/apply_lab_C1.png` | `lab/r5/after_outfit_3_hangeul_happy.png` |
| 포스터 U 2 | `character/apply_lab_C3.png` ("AI Grammar Lab") | `lab/r5/after_outfit_6_sentence_loading_thinking.png` |
- 그대로 둔 것: 레슨·단어 화면, 미션 레드카드(`MSN-1.7.3`), 포스터 미션 변신 로딩 — R4·R5 로 바뀐 화면이 아님. 홈 파스텔 카드는 책자·포스터에 홈 화면 자리가 없어 미사용.
- 확인: PowerPoint PDF 로 7장 + 포스터 렌더 확인(넘침·겹침 없음), `validate.py` 통과, 양식 크기 동일.

### 10-03 최종 스크린샷 키트 교체 (DLV-4.6.4)
키트: `docs/deliverables/screenshots/` (INDEX.md). 자리 크기·폰 프레임·둥근 모서리 그대로, 원본 비율 유지(폭 기준 축소). 포스터 크기(42×60cm)·`QR_자리` 그대로.

| 자리 | 전 파일 | 후 파일 |
|---|---|---|
| 책자 3장 레슨 1 | `character/apply_lesson_C1.png` (정답 라벨 보이는 옛 화면) | `07_lesson_morpheme_turtle.png` |
| 책자 3장 레슨 2 | `character/apply_lesson_C3.png` | `08_lesson_complete.png` |
| 책자 4장 단어 1 | `character/apply_vocab_C3_review_done.png` (All Caught Up) | `09_vocab_card_rating.png` — 캡션 "단어 카드 · 다음 간격" |
| 책자 4장 단어 2 | `character/apply_vocab_C2.png` | `10_vocab_match_complete.png` |
| 책자 5장 미션 1 | `mission/r4_fe2/1_setup_difficulty.png` | `02_mission_setup_difficulty.png` |
| 책자 5장 미션 2 | `mission/MSN-1.7.3_red_card.png` (옛 채팅 디자인) | `04a_mission_chat_red_card.png` |
| 책자 5장 미션 3 | `mission/r4_fe2/6_report_cleared_easy_badge.png` | `06_mission_certificate_cleared.png` — 캡션 "미션 수료증" |
| 책자 5장 실험실 | `lab/r5/after_outfit_4_sentence_idle.png` | `14_lab_sentence_result.png` |
| 책자 6장 캐릭터 칸 (신규) | (없음 — 캐릭터 2개만) | `01_home.png` 홈 화면 추가, 토끼·거북이는 옆에 작게 |
| 포스터 M 1·2 | `apply_lesson_C1.png` · `apply_lesson_C3.png` | `07_lesson_morpheme_turtle.png` · `08_lesson_complete.png` |
| 포스터 A 1·2 | `apply_vocab_C3_review_done.png` · `apply_vocab_C2.png` | `09_vocab_card_rating.png` · `10_vocab_match_complete.png` |
| 포스터 R 1·2 | `mission/r3_fe2/12_loading_magic.png` · `MSN-1.7.3_red_card.png` | `03_mission_loading_magic.png` · `04a_mission_chat_red_card.png` |
| 포스터 U 1·2 | `lab/r5/after_outfit_3_hangeul_happy.png` · `after_outfit_6_sentence_loading_thinking.png` | `12_lab_hangeul.png` · `13_lab_sentence_loading.png` |

- 같이 바꾼 것(하도윤 지시): 책자 7장 맨 아래 **"향후 계획 …" 문구 삭제** → 마무리 문구 "빠르게 체험하고 천천히 이해하는 한국어 학습, MARU".
- 참고: `09`·`10` 은 원본이 414×900px 로 작음(다른 건 1206px 이상). 책자·포스터 자리 크기에서는 인쇄 해상도에 문제 없지만, 더 크게 쓸 일이 있으면 재촬영 필요.
- 전/후 비교 이미지: `book/preview/before_after_1003.png`, `poster/before_after_1003.png`.
- 남은 일: 포스터 QR 삽입(DLV-4.2.3, URL 대기)만.
- 10-03 추가(하도윤 지시): 포스터에서 토끼 귀가 "MARU" 글자(U)를 가리던 문제 해결 — 제목 220pt → 195pt, 토끼를 오른쪽·아래로 약 1cm 이동. 크기·QR 자리·나머지 배치는 그대로.
- 10-04: **포스터 QR 삽입 완료**(DLV-4.2.3) — 하도윤이 준 QR(`poster/_build/qr_source.png`, `https://m.site.naver.com/2hUYX`)을 우상단 흰 칸(`QR_자리`) 안에 5.8cm 로 배치. 원본의 보라 테두리는 잘라내고 흑백으로 선명화(`assets/qr_clean.png`). 렌더링된 미리보기 PNG 에서 QR 인식 확인. QR 을 바꿀 땐 `qr_source.png` 교체 → `qr_clean.png` 다시 만들고 `build_poster.py` 실행.
