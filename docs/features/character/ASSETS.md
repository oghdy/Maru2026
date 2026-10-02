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
| rabbit_magic (CHR-1.7) | [x] | [x] 배율 idle 고정·반짝이 유지 | [x] |
| turtle_idle | [x] | [x] | [x] |
| turtle_blink | [x] | [x] 로컬 눈 패치(idle 위에 눈만 합성) | [x] |
| turtle_happy | [x] | [x] | [x] |
| turtle_sad | [x] | [x] | [x] |
| turtle_thinking | [x] | [x] | [x] |
| turtle_talking | [x] | [x] | [x] |
| turtle_cheer | [x] | [x] | [x] |
| rabbit_lab_idle (CHR-1.8) | [x] | [x] 배율 idle 고정·거품 방울 유지 (3985429) | [ ] char-dev R |
| rabbit_lab_happy (CHR-1.8) | [x] | [x] 배율 idle 고정·거품 유지 (3985429) | [ ] char-dev R |
| turtle_lab_idle (CHR-1.8) | [x] | [x] 배율 idle 고정 (3985429) | [ ] char-dev R |
| turtle_lab_thinking (CHR-1.8) | [x] | [x] 배율 idle 고정·방울 유지, 머리 −4% 측정 → 보정 안 함 확정 (3985429) | [ ] char-dev R |
| turtle_lab_sad (CHR-1.8.5) | [x] | [x] 배율 idle 고정 (16a37d8) | [ ] 재머지 후 |
| turtle_lab_talking (CHR-1.8.5) | [x] | [x] 배율 idle 고정 (16a37d8) | [ ] 재머지 후 |

## 5. 품질 기준 (후처리 시 확인)
- 14장 모두 같은 캐릭터로 보일 것 (얼굴형·색·소품). 어긋나면 해당 장만 재생성 요청
- 투명 배경 (아니면 배경 제거). 발 위치(baseline)·캐릭터 크기 통일되게 크롭·정렬
- 최종: 512×512 PNG(또는 WebP), 장당 ≤150KB 목표. blink 는 idle 과 겹쳐도 어긋나지 않을 것

## 6. 실험복 의상 (R5 · CHR-1.8.1 · D-25) — 4장
> 파일명: `rabbit_lab_idle` · `rabbit_lab_happy` · `turtle_lab_idle` · `turtle_lab_thinking` (→ raw/ 에 .png)
> **순서**: ① 토끼 대화창에 `raw/rabbit_idle.png` 첨부 → `rabbit_lab_idle` 확정 → ② 같은 대화창에 확정한 `rabbit_lab_idle` 첨부 → `rabbit_lab_happy`. 거북이도 같은 방식(새 대화창, `raw/turtle_idle.png` 부터).
> ⚠ 금지(D-25): 특정 작품·인물 오마주(브레이킹 배드 등), 노란 방호복·방독면, 모자·수염 같은 인물 연상 소품, 로고·글자·명찰 문구, 파란 결정/가루.

### 6.1 공통 머리말 (모든 4장 앞에 붙이기)
```
Using the attached image as the exact reference: keep the SAME character — identical face, head shape, proportions, body size, colors, outline thickness, cel-shading style, canvas framing and transparent background. Feet on the same baseline, character the same height on the canvas. The whole character including props must stay fully inside the canvas with a small margin. No background, no ground shadow, no text, no logos, no name tags, no yellow hazmat suit, no gas mask, no hats, no references to any existing TV show, film or real person.
```

### 6.2 rabbit_lab_idle  (첨부: raw/rabbit_idle.png)
```
[공통 머리말]
Outfit change: the rabbit now wears a slightly too-big white lab coat (sleeves a little long, one sleeve rolled up, coat a bit crooked), its purple #6B4EFF scarf still visible at the collar, clear safety goggles with a lavender strap sitting crooked across its forehead and one long ear, a small colorful stain splash on the coat hem. Personality: a mischievous, chaotic little lab assistant who causes cute accidents.
Pose: standing relaxed like the reference, holding a small round glass flask with bubbly mint-green liquid and a little foam fizzing over the rim in one paw, cheeky closed-mouth grin, looking at the viewer.
```

### 6.3 rabbit_lab_happy  (첨부: 확정한 rabbit_lab_idle)
```
[공통 머리말]
Keep the exact lab outfit from the reference (crooked goggles, oversized white lab coat, purple scarf, coat stain).
Change ONLY the pose and expression: excitedly pouring the mint-green flask into a small beaker held in the other paw, the beaker foaming over with a big cheerful pink-and-lavender bubble overflow (bubbles stay close to the beaker, inside the canvas), big open happy smile, sparkling eyes, one foot slightly lifted in excitement.
```

### 6.4 turtle_lab_idle  (첨부: raw/turtle_idle.png)
```
[공통 머리말]
Outfit change: the turtle now wears a neat, perfectly buttoned white lab coat that fits well (the shell visible at the back/side), its purple #6B4EFF bow tie neatly at the collar, its round glasses unchanged, clear safety goggles with a lavender strap resting neatly on top of its head above the glasses, a pen in the coat's chest pocket. Personality: a calm, diligent, model-student researcher.
Pose: standing upright like the reference, holding a clipboard with a blank checklist (lines and checkboxes only, no readable text) against its chest with one arm, gentle confident closed-mouth smile, looking at the viewer.
```

### 6.5 turtle_lab_thinking  (첨부: 확정한 turtle_lab_idle)
```
[공통 머리말]
Keep the exact lab outfit from the reference (neat buttoned white lab coat, bow tie, round glasses, goggles on top of the head, pen in pocket, clipboard).
Change ONLY the pose and expression: holding the clipboard up and reading it carefully, the other hand touching its chin with the pen, eyes looking at the clipboard, slight head tilt, focused and thoughtful. No question marks or symbols.
```

### 6.6 검수 기준 (char-lead)
- 기존 idle 과 얼굴·크기·외곽선 동일, 발 baseline 동일, 투명 배경
- 🐰 "장난꾸러기"(삐뚤어진 고글, 큰 실험복, 거품) / 🐢 "모범생"(단정, 클립보드, 이마 위 고글)이 40dp 축소에서도 구분될 것
- 금지 요소(§6 ⚠) 없음. 실험복 흰색이 앱 배경(연보라·흰 카드) 위에서 외곽선으로 구분될 것

### 6.7 turtle_lab_sad  (CHR-1.8.5 · 첨부: raw/turtle_lab_idle.png · 거북이 대화창)
```
[§6.1 공통 머리말]
Keep the exact lab outfit from the reference (neat buttoned white lab coat, purple bow tie, round glasses, goggles on top of the head, pen in pocket, clipboard).
Change ONLY the pose and expression: a gentle, sympathetic "oops, that didn't work" look — small frown, eyebrows slightly raised in the middle, eyes looking down at the clipboard held lowered at waist height, head slightly lowered, the other hand lightly scratching the back of its head. Calm and kind, NOT crying, no tears, no sweat drops, no symbols.
```

### 6.8 turtle_lab_talking  (CHR-1.8.5 · 첨부: raw/turtle_lab_idle.png · 거북이 대화창)
```
[§6.1 공통 머리말]
Keep the exact lab outfit from the reference (neat buttoned white lab coat, purple bow tie, round glasses, goggles on top of the head, pen in pocket, clipboard).
Change ONLY the pose and expression: explaining something like a friendly teacher — mouth open mid-sentence with a warm smile, holding the clipboard against its chest with one arm, the other hand raised to shoulder height holding the pen up as if pointing out a key point, eyes looking at the viewer. No speech bubble, no text, no symbols.
```

