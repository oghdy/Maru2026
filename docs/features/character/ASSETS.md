# CHR — 캐릭터 에셋 (GPT 이미지 생성 가이드 + 체크리스트)

> 이미지는 **하도윤이 ChatGPT(이미지 생성)로 만든다.** Claude 세션은 이미지를 생성할 수 없다.
> 완성 이미지는 `docs/features/character/raw/` 에 아래 파일명으로 넣는다 → **char-asset** 세션이 후처리(배경 제거·크롭·baseline 정렬·512px·최적화)해서 `frontend/maru/assets/characters/` 로 옮긴다(스크립트 `tools/process_characters.py`).
> **마감: 10/1 08:00** (idle 2장은 확정되는 대로 먼저 넣으면 바로 갤러리에 반영). 못 만든 표정은 idle 이미지 + 모션으로 폴백되니 일부만 있어도 진행된다.

## 0. 캐릭터 설정 (역할 = 마루 학습 철학 "빠름과 느림")
| | 🐰 토끼 | 🐢 거북이 |
|---|---|---|
| 역할 | **연기자·체험 담당** — 먼저 덩어리로 부딪혀 보는 빠른 학습, 미션 대화 상대 | **코치·분석 담당** — 구조를 쪼개 보고, 틀리면 차분히 알려줌 |
| 성격 | 에너지 넘침, 장난스러움, 리액션 큼 | 차분함, 다정함, 지혜로움 |
| 소품 | 브랜드 보라색 목도리 | 동그란 안경 + 보라색 나비넥타이 |
| 이름 | (미정 — 하도윤 결정. 예: 토리 / 부기) | |

## 1. 공통 스타일 블록 (모든 프롬프트 앞에 그대로 붙인다)
```
Cute 2D mascot character for a Korean language learning app. Flat vector illustration,
soft rounded shapes, thick smooth dark-indigo outline (#2B1D5C), simple cel shading with only one
shadow tone, limited palette (cream white, soft pastels, brand accent purple #6B4EFF), big expressive
eyes, friendly and simple like a modern app mascot. Full body, front three-quarter view, centered,
character fills about 80% of the canvas height, feet on the same baseline near the bottom.
Transparent background, no text, no ground shadow, no props or effects outside the character.
Square 1024x1024 PNG.
```

## 2. 1단계 — 기본(idle) 2장 먼저 → 마음에 들 때까지 재생성 → 확정
**rabbit_idle.png**
```
[공통 스타일 블록]
Character: a small white rabbit with long upright ears (pale pink inside), round chubby body,
wearing a cozy scarf in purple #6B4EFF. Energetic and playful personality.
Pose: standing relaxed, gentle closed-mouth smile, arms down, looking at the viewer.
```
**turtle_idle.png**
```
[공통 스타일 블록]
Character: a small round turtle standing upright, soft green skin, rounded teal-green shell with a
simple hexagon pattern, small round glasses, purple #6B4EFF bow tie. Calm, kind, wise personality.
Pose: standing relaxed, gentle closed-mouth smile, arms down, looking at the viewer.
```

## 3. 2단계 — 표정 변형 (확정한 idle 이미지를 **첨부**하고 같은 대화에서 요청)
각 프롬프트 앞에 이 문장을 붙인다:
```
Using the attached image as the exact reference: keep the SAME character — identical proportions,
colors, outline, outfit, art style, size, canvas framing and transparent background.
Change ONLY the pose and facial expression as follows:
```
| 파일명 (토끼 → `rabbit_`, 거북이 → `turtle_`) | 요청 문장 |
|---|---|
| `*_blink.png` | Identical to the reference in every way, but with both eyes gently closed (for a blinking animation). Do not move anything else. |
| `*_happy.png` | Big open smile, sparkling eyes, both hands raised slightly in delight. |
| `*_sad.png` | Sympathetic sad look: small frown, eyes looking down, head slightly lowered (rabbit: ears drooping). Not crying. |
| `*_thinking.png` | Thinking: one hand on chin, eyes looking up to the side, slight head tilt. No question marks or symbols. |
| `*_talking.png` | Talking mid-sentence: mouth open, one hand gesturing outward, friendly. No speech bubble. |
| `*_cheer.png` | Celebrating: jumping with both arms up high, huge smile, eyes happily closed. No confetti or effects. |

## 4. 체크리스트 (파일을 넣으면 char-lead 가 상태 갱신)
| 파일 | raw 도착 | 후처리 | 앱 반영 |
|---|---|---|---|
| rabbit_idle | [x] | [x] | [x] |
| rabbit_blink | [x] | [x] 로컬 눈 패치(재생성본) | [x] |
| rabbit_happy | [x] | [x] | [x] |
| rabbit_sad | [x] | [x] | [x] |
| rabbit_thinking | [x] | [x] | [x] |
| rabbit_talking | [x] | [x] | [x] |
| rabbit_cheer | [x] | [x] | [x] |
| turtle_idle | [x] | [x] | [x] |
| turtle_blink | [x] | [x] 로컬 눈 패치(idle 위에 눈만 합성) | [x] |
| turtle_happy | [x] | [x] | [x] |
| turtle_sad | [x] | [x] | [x] |
| turtle_thinking | [x] | [x] | [x] |
| turtle_talking | [x] | [x] | [x] |
| turtle_cheer | [x] | [x] | [x] |

## 5. 품질 기준 (후처리 시 확인)
- 14장 모두 같은 캐릭터로 보일 것 (얼굴형·색·소품). 어긋나면 해당 장만 재생성 요청
- 투명 배경 (아니면 배경 제거). 발 위치(baseline)·캐릭터 크기 통일되게 크롭·정렬
- 최종: 512×512 PNG(또는 WebP), 장당 ≤150KB 목표. blink 는 idle 과 겹쳐도 어긋나지 않을 것
