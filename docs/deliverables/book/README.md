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
- 스크린샷 교체: 각 스크립트 맨 위 `SHOTS` 의 경로를 `docs/deliverables/screenshots/NN_*.png` 로 바꾸고 다시 실행 → PowerPoint 로 열어 PDF 로 내보내기.
- 지금은 기능 세션 스크린샷(`docs/features/*/screenshots/`, 상태바 시각 제각각)을 임시로 사용. 최종 키트가 나오면 교체.

## 남은 일
- **포스터 QR**: 우상단 흰 사각형(도형 이름 `QR_자리`, 6.7×6.7cm) 위에 qr.naver.com 에서 만든 QR 이미지를 같은 크기로 올리면 됨.
- **글씨체 포함**: 글꼴은 양식 테마와 같은 **맑은 고딕**(윈도우 기본·맥 Office 내장)만 사용. 맥 PowerPoint 는 자동 글꼴 포함 저장이 안 돼서, pptx 에 `embedTrueTypeFonts` 표시만 해 둠 → 윈도우 PowerPoint 에서 한 번 열어 저장하면 포함됨(파일 > 옵션 > 저장 > "파일의 글꼴 포함" 확인). 인쇄소·제출은 PDF 를 쓰면 글꼴 문제 없음.
- 테스트 수치 "서버 123 · 앱 67" 은 PM_HANDOFF §3(12차 머지) 기준. CLAIMS.md 는 아직 "107 · 11" → PM 확인 후 필요하면 `build_book.py` page7 수정.
