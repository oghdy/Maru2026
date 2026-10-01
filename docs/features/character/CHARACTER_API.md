# CHR — CHARACTER API (캐릭터 팀 ↔ 기능 FE 세션 약속)

> char-lead 가 관리. 기능 FE 세션은 **이 문서의 공개 API 만** 쓴다(`lib/shared/characters/src/**` 직접 import 금지).
> 변경 시 char-lead 가 §5 이력에 기록하고 PM_SYNC 로 메인 PM 에 알린다.
> **v1.0 확정 (2026-09-30 22:50, char-lead)** — §1·§2 는 char-dev 구현 기준. §3 은 🚦 갤러리 승인 후 화면·이벤트 단위로 구체화.

## 0. 연출 원칙 (듀오링고 기준 "살아 있다"의 정의)
1. **가만히 있어도 살아 있다** — 숨쉬기·깜빡임·가끔 하는 잔동작(fidget)이 절대 멈추지 않는다(접근성 모드 제외).
2. **모든 반응은 예비동작 → 본동작 → 여운** — 점프 전에 살짝 웅크리고(anticipation), 착지 때 찌그러지고(squash), 탄성 있게 제자리로(settle). 딱딱한 선형 이동 금지.
3. **성격은 타이밍으로** — 🐰 토끼는 빠르고 크고 통통 튄다(연기자·체험). 🐢 거북이는 느리고 작고 부드럽다(코치·분석). 같은 기분이라도 두 캐릭터의 진폭·속도·횟수가 다르다(§2.3 표).
4. **땅에 붙어 있다** — 코드로 그린 바닥 그림자가 점프 높이에 따라 작아지고 옅어진다.
5. **이미지는 표정, 코드는 몸짓** — PNG 7장(표정)만 바꾸고 나머지 생동감은 전부 Transform 으로. 새 패키지 없음.

## 1. 공개 API
```dart
import 'package:maru/shared/characters/maru_character.dart'; // 이 파일 하나만 import (barrel)

enum MaruCharacterKind { rabbit, turtle }
enum MaruMood { idle, happy, sad, thinking, talking, cheer, magic } // magic 은 v1.2 에서 끝에 추가(기존 값·순서 유지)

MaruCharacter(
  kind: MaruCharacterKind.turtle,
  mood: MaruMood.happy,        // 바뀌면: 표정 크로스페이드 + 해당 기분의 진입 반응 1회 + 기분 루프
  size: 120,                   // 레이아웃이 차지하는 정사각 한 변(dp). 권장 40 / 72 / 120 / 180
  reactionKey: _attempt,       // (선택) 값이 바뀌면 mood 가 같아도 진입 반응을 다시 재생 (연속 정답 등)
  settleToIdleAfter: const Duration(milliseconds: 1600), // (선택) 반응 후 표정을 idle 로 되돌림. null = mood 유지
  entrance: false,             // (선택) true 면 처음 나타날 때 팝인(0 → 1.08 → 1.0)
  interactive: true,           // (선택) false 면 탭 반응 없음 (작은 아바타·리스트용)
  onTap: null,                 // (선택) 탭 시 추가 콜백. 기본 탭 반응은 interactive 가 true 면 항상 실행
  semanticLabel: null,         // (선택) null 이면 장식용(스크린리더 제외). 의미 있으면 'Turtle coach' 등
)

// 말풍선 버전: 캐릭터 + 메시지 (코칭·안내·대화용)
MaruCharacterBubble(
  kind: MaruCharacterKind.turtle,
  mood: MaruMood.idle,         // 타이핑이 끝난 뒤의 기분
  message: 'Nice! 는 marks the topic.',
  size: 72,
  side: MaruBubbleSide.left,   // 캐릭터 위치 left | right (말풍선 꼬리가 캐릭터를 향함)
  typewriter: true,            // 글자가 ~40자/초로 나타나는 동안 캐릭터는 talking, 끝나면 mood 로
  onTypingDone: null,          // (선택) 타이핑 완료 콜백
)

// (선택) 화면 진입 전 이미지 미리 로드 — 첫 표정 전환 깜빡임 방지
await MaruCharacter.precache(context, MaruCharacterKind.rabbit);
```
- **precache 권장**: 캐릭터가 화면 진입 즉시 보이는 곳(말풍선·완료 화면)은 화면 `didChangeDependencies`(또는 단계 진입 시)에 `MaruCharacter.precache(context, kind)` 호출 — 첫 표시 0.5초 빈칸 방지(R-004). CHR-1.6.4.2 반영 후엔 선택
- 에셋 경로 규칙: `assets/characters/<kind>_<mood>.png`, 깜빡임 `assets/characters/<kind>_blink.png` (512×512, 투명, 발 baseline 통일)
- **에셋 폴백(범위 축소 장치)**: `<kind>_<mood>.png` 없음 → `<kind>_idle.png` + 모션만으로 기분 표현 → idle 도 없음 → 코드로 그린 플레이스홀더. `<kind>_blink.png` 없음 → 깜빡임만 생략. **어떤 경우에도 예외·빨간 화면 없음.**
- `size` 박스 밖으로 점프·파티클이 그려질 수 있다(Clip 없음). 부모가 잘라내는 곳(리스트 타일 등)에선 `size ≤ 56` 을 쓰면 자동으로 **compact 모드**(진폭 ½, 파티클 없음).

## 2. 모션 규격 (char-dev 구현 기준)
### 2.1 레이어 구조 (아래 → 위)
1. **바닥 그림자** — 타원, 폭 0.55·size, 높이 0.07·size, `colorScheme.onSurface` alpha 0.10. 캐릭터가 올라간 높이 h 에 따라 scale `1 - 0.5·h/maxH`, alpha 같이 감소
2. **몸 Transform** — translate(y) → rotate → scale(x,y). **피벗은 발 중앙(Alignment.bottomCenter)** — 찌그러짐·기울기가 발에서 일어나야 자연스럽다
3. **표정 이미지** — 기분 전환 시 크로스페이드 150ms (`gaplessPlayback: true`, 두 장을 겹쳐 페이드). 깜빡임은 idle 위에 blink 를 즉시 교체(페이드 없음)
4. **이펙트** — cheer 파티클(CustomPainter)

### 2.2 공통 루프
| 항목 | 규격 |
|---|---|
| 숨쉬기 | scaleY 1.00↔1+A, scaleX 1.00↔1−A/2 (부피 보존), easeInOutSine, 피벗 발. 🐰 A=0.025·주기 1.8s / 🐢 A=0.020·주기 3.0s |
| 깜빡임 | **mood == idle 일 때만**(다른 표정에 idle 눈 덮어쓰기 금지). 간격 랜덤 🐰 2.0~4.5s / 🐢 3.5~6.5s, 감은 시간 120ms. 🐰 25% 확률로 연속 2회 |
| 잔동작(fidget) | idle 에서만, 랜덤 간격. 🐰 5~9s 마다 제자리 콩(h .04, 280ms) 또는 좌우 기울기 ±5° 1회 / 🐢 8~12s 마다 천천히 기울기 ±3°(900ms) 1회 |
| 전환 | 모든 반응은 현재 Transform 값에서 이어서 시작(튀는 스냅 금지). 반응 중 새 mood 가 오면 즉시 새 반응으로 교체 |

### 2.3 기분별 연출 (진입 반응 1회 → 기분 루프) · h = size 대비 높이 비율, 시간은 🐰 / 🐢
| 기분 | 진입 반응 | 기분 루프 (해당 mood 유지 중) |
|---|---|---|
| idle | (없음) 이전 변형에서 400ms easeOut 으로 제자리 | 숨쉬기 + 깜빡임 + 잔동작 |
| happy | 웅크림 squash(sY .92, sX 1.06, 80ms) → 점프 🐰 h .12 ×**2회**(각 320ms) / 🐢 h .06 ×1회(420ms) → 착지 squash(sY .94) → elasticOut 정착 | 🐰 1.6s 마다 작은 바운스(h .03) / 🐢 숨쉬기만(주기 ×0.8, 기분 좋은 빠른 숨) |
| sad | 450ms / 700ms 동안 아래로 가라앉기(y +0.03·size) + sY .96 (easeOutCubic) | 느린 좌우 흔들림 rotate ±2° 🐰 2.4s / 🐢 3.2s, 숨쉬기 주기 ×1.4. 깜빡임 없음 |
| thinking | 한쪽으로 기울기 rotate +6° / +4° (300ms / 500ms, easeOutBack) | 기울기 ±(4°/3°) 왕복 🐰 1.4s / 🐢 2.2s + 아주 작은 상하 이동(h .01) |
| talking | 짧은 들썩 1회(h .02, 120ms) | 말 들썩임: translateY h .015 + sY 1.00↔1.03, 🐰 5Hz / 🐢 3.5Hz, **주기에 ±20% 랜덤 지터**(기계적 반복 방지). Bubble 타이핑 중 자동 |
| cheer | 깊은 웅크림(sY .85, sX 1.10, 120ms) → 큰 점프 🐰 h .25(올라갈 때 stretch sY 1.08·sX .94, 480ms) + 공중 회전 ±8° / 🐢 h .12(600ms, 회전 없음) → 착지 squash(sY .88·sX 1.10) → elasticOut 정착(500ms). 점프 정점에서 **파티클 버스트** | 🐰 2.2s 마다 중간 점프(h .08) / 🐢 3.0s 마다 작은 점프(h .04) |
| magic (v1.2 · 🐰 전용 에셋, 🐢 는 idle 이미지 폴백) | "변신 마술": 웅크림(sY .90·sX 1.06, 120ms) → 작은 점프(h .10) 하며 **몸 중심 기준 360° 회전**(🐰 520ms / 🐢 800ms, easeInOutCubic) → 착지 squash → **스케일 펄스** 1.0→1.12→1.0(300ms) + **펑 연기**(라벤더·흰색 원 3~4개가 퍼지며 사라짐, 450ms) + **반짝이 버스트**(별 8~10개, 보라·금·흰, 마술봉 끝 = 실제 PNG 별 위치 약 (0.21w, 0.41h)에서) | 느린 흔들림 ±4°(1.6s) + 상하 h .02, 1.8~2.6s 마다 마술봉 끝 반짝이 3~4개, **미니 변신 🐰 3.2s / 🐢 4.0s 마다**(360° 회전 450ms + 작은 펑 + 반짝이). 🐢 흔들림 ±3°·2.2s, 반짝이 간격 2.4~3.4s — 로딩 화면이 몇 초 이어져도 "변신 중"으로 보이게 |
| 탭 | squash(sY .90·sX 1.08, 90ms) → elasticOut 복귀(450ms) + **900ms 동안 happy 표정** 후 원래 mood 로. 🐰 +작은 점프(h .06) / 🐢 +기울기 4° 1회. 연타 시 매번 재시작(쌓이지 않음) | - |
| entrance | scale 0 → 1.08 → 1.0 (elasticOut 550ms) + 그림자 페이드인 | - |

- magic 의 회전은 발이 아니라 **몸 중심** 피벗(발 피벗이면 굴러가는 것처럼 보임). compact(≤56)는 회전·파티클·연기 없이 흔들림만, reduce motion 은 정자세 + magic 표정만
- **파티클(cheer)**: 10~14개, `colorScheme.primary`·노랑 #FFC83D·민트 #4CD4B0·핑크 #FF8FB1, 별/원 혼합, 머리 위에서 방사형으로 퍼지며 중력 낙하 + 페이드, 900ms. compact·접근성 모드에선 생략
- `settleToIdleAfter` 가 있으면: 진입 반응이 끝나고 해당 시간 뒤 **표정만** idle 로 크로스페이드, 루프도 idle 로. 부모의 mood 값은 그대로 두고, 다음 `reactionKey` 변경 때 다시 반응

### 2.4 말풍선 (MaruCharacterBubble)
- 레이아웃: `[캐릭터] [말풍선]` (side=right 면 반대). 말풍선 = `colorScheme.surfaceContainerHighest` 배경, 라운드 16, 꼬리가 캐릭터 입 높이를 가리킴, 최대 폭 = 가용 폭 − 캐릭터, 텍스트 줄바꿈(넘침 금지)
- 등장: 꼬리 쪽 기준 scale .85 → 1.0 + 페이드 (220ms, easeOutBack). `message` 가 바뀌면 재등장 + 타이핑 재시작
- typewriter: 약 40자/초(글자 단위). 타이핑 중 캐릭터 = talking, 끝나면 `mood`. 타이핑 중 말풍선 탭 → 즉시 전체 표시
- 레이아웃 흔들림 방지: 말풍선 크기는 **처음부터 전체 텍스트 기준**으로 잡고 글자만 드러냄(아직 안 나온 글자는 투명)

### 2.5 접근성·성능
- `MediaQuery.disableAnimationsOf(context) == true` → 모든 Transform 정지(정자세), 깜빡임·잔동작·파티클 없음, 크로스페이드 0ms, typewriter 즉시 전체 표시. **표정 전환은 유지**
- `semanticLabel == null` 이면 `ExcludeSemantics`(장식). 있으면 `Semantics(label: …, image: true)`
- 한 화면 12개 동시 실행해도 끊김 없을 것: 캐릭터당 `RepaintBoundary`, 애니메이션은 `AnimatedBuilder`+`Transform` 만(매 프레임 setState·레이아웃 금지), 이미지는 크기와 무관하게 **512px 원본 한 벌을 공유**(캐시 키 통일, 디코드 메모리 약 16MB — 기본 한도 100MB). 첫 캐릭터가 뜰 때 전체 PNG 를 백그라운드 precache(warm-up). 이미지 첫 프레임 전엔 몸·그림자 모두 숨기고 준비되면 120ms 페이드인(캐시 HIT 면 즉시), entrance 는 이미지 준비 후 시작 — CHR-1.6.4.2
- 타이머·컨트롤러는 dispose 에서 전부 정리(위젯 테스트에서 pending timer 0)
- 첫 build 때 해당 kind 의 7장+blink precache 시도(없는 파일은 조용히 무시)

## 3. 기능별 적용 명세 (v1.1 — 🚦 10-01 00:10 하도윤 승인 후 확정. 메인 PM 이 각 기능 PLAN Step 1.6 태스크로 배포)
> 파일:라인은 main `87aa61a` 기준(조사 10-01 00:15). 줄은 달라졌을 수 있으니 **표시한 위젯/변수 이름으로 찾을 것**.
> 경로 기준 `frontend/maru/lib/features/`.

### 3.0 모든 기능 공통 규칙
1. import 는 `package:maru/shared/characters/maru_character.dart` **하나만**. `src/` 직접 import 금지. 캐릭터 코드(`lib/shared/characters/**`) 수정 금지 → 필요하면 REQUESTS 로(char-lead 가 처리).
2. **로직·상태·API 는 건드리지 않는다.** 이미 있는 변수(정답 여부·로딩·결과)에 캐릭터의 `mood` 만 연결한다.
3. 같은 기분이 연속으로 나와야 하면(연속 정답·연속 오답) `reactionKey` 에 시도 횟수 등 **바뀌는 값**을 넣는다. 정답 반응 후 원래대로 돌아가야 하면 `settleToIdleAfter: const Duration(milliseconds: 1600)`.
4. 크기: 채팅·리스트·배너 아이콘 = **40**(compact, 자동으로 진폭 ½·파티클 없음) / 피드백 옆 = **64~72** / 결과·완료·로딩 주인공 = **120**. `size > 56` 이면 점프가 위로 튀어나오므로 **위쪽에 0.25×size 여백**을 두고 `ClipRect`·고정 높이 박스 안에 넣지 말 것.
5. 텍스트 피드백은 **지우지 않는다**(접근성·명확성). 캐릭터는 옆에 붙이거나, 말풍선(`MaruCharacterBubble`)으로 같은 문장을 감싼다. 이모지 🐰🐢 를 캐릭터로 바꾸는 곳은 아래 표에 명시한 곳만.
6. 완료 기준: `flutter analyze lib/features/<자기폴더>` 새 경고 0 + 시뮬레이터에서 해당 이벤트를 **직접 발생시켜** 스크린샷(`docs/features/character/screenshots/apply_<기능>_<ID>.png` 에도 복사 — char-lead 리뷰용).
7. main 동기화 후 `flutter pub get` + **앱 완전 재시작**(pubspec `assets:` 가 바뀌어 hot reload 로는 PNG 가 안 잡힘).
9. **위젯 테스트 팁**(R-004): ① 말풍선은 한글 음절 사이에 U+2060(WORD JOINER)을 넣어 단어 단위 줄바꿈 → 텍스트 검색 시 `text.replaceAll('\u2060', '')` 후 비교 ② 캐릭터는 무한 루프 애니메이션이라 `pumpAndSettle` 이 타임아웃 → 테스트 트리를 `MediaQuery(data: MediaQueryData(disableAnimations: true), …)` 로 감쌀 것. 참고 `test/features/lesson/agglutinative_step_widget_test.dart` `_bubbleText`
8. 우선순위: **P0 = 10/1 13:00 까지 필수**, P1 = 시간 남으면, P2 = 하지 않음(참고용). 동결 15:00.

### 3.1 레슨 (LSN) — 🐰 먼저 덩어리로 / 🐢 쪼개서 분석
| ID | P | 위치 (파일 · 위젯/변수) | 넣을 것 |
|---|---|---|---|
| C1 | P0 | `lesson/widgets/agglutinative_step_widget.dart` — Check 버튼 위 인라인 피드백 박스(`_feedback`, `_feedbackIsError`, 약 :330-355) | 박스를 `MaruCharacterBubble(size: 64, typewriter: true, message: _feedback)` 로 교체. kind = `isTurtleMode ? turtle : rabbit`. 정답 → `mood: happy`, 오답 → **거북이** `mood: thinking`(힌트 코칭 — `_turtleHint()` 문장). 🤔/✅ 접두어는 제거. 오답 연속 시 말풍선이 다시 타이핑되도록 `message` 가 같으면 시도 횟수를 key 로(`ValueKey`) |
| C2 | P0 | 같은 파일 — 🐰 단계에서 정답 후 🐢 단계로 전환(`_phaseTransitionController`, `isTurtleMode=true`, 약 :131-146) | C1 말풍선이 토끼(happy "Great! Now split…") → 거북이로 바뀌는 것 확인만(추가 코드 없음 예상) |
| C3 | P0 | `lesson/widgets/completion_step_widget.dart` — 초록 `Icons.check_circle`(size 112, 약 :44-70) | 아이콘 자리에 `Row[ MaruCharacter(rabbit, cheer, 110, entrance: true), MaruCharacter(turtle, happy, 110, entrance: true) ]`. "Score: n%" 텍스트 유지 |
| C4 | P1 | `lesson/widgets/practice_step_widget.dart` — listen_match(`answeredCorrectly`, 약 :371-381)·fill_blank(약 :492) 피드백 문장 | 문장 왼쪽에 `MaruCharacter(rabbit, size: 40, mood: 정답? happy : sad, reactionKey: 시도 횟수)` |
| — | P2 | agglutinative 단계 칩의 🐰/🐢 이모지(약 :236, :246) | 이모지 유지(칩이 작아 캐릭터가 오히려 안 보임) |

### 3.2 단어장 (VOC) — 🐰 게임 응원 / 🐢 복습 코칭
| ID | P | 위치 | 넣을 것 |
|---|---|---|---|
| C1 | P0 | `vocabulary/screens/vocabulary_game_screen.dart` — Match 보드 위 `'Round n/m'` 라벨 줄(약 :67) · 상태는 `vocabulary_game_provider.dart` `_checkMatch()`(`totalMatches`, `mistakes`) | 라벨 옆에 `MaruCharacter(rabbit, size: 72)`. 마지막 판정이 정답이면 `happy`, 오답이면 `sad`, `reactionKey: totalMatches + mistakes`, `settleToIdleAfter: 1200ms`. 기존 타일 흔들림·팝 애니메이션 유지 |
| C2 | P0 | 같은 파일 `_GameOverView`(약 :382, "Perfect Match!/Amazing Match!") | 제목 위에 `MaruCharacter(rabbit, mistakes == 0 ? cheer : happy, 120, entrance: true)`. 기존 confetti 유지 |
| C3 | P1 | `vocabulary/widgets/session_summary_view.dart` 아이콘 자리 (daily_review "All Caught Up!"/"Nothing to review right now", learning "Lesson Completed!") | 복습 완료 → `turtle happy 120`, 복습할 것 없음 → `turtle idle 120`, 레슨 완료 → `rabbit cheer 120` (모두 entrance) |
| — | P2 | FSRS 평가 바 "How well did you know it?"·다음 간격 미리보기 | 하지 않음 (평가 흐름을 늦추지 않게) |

### 3.3 미션 (MSN) — 🐰 대화 상대(연기자) / 🐢 교정 코치 · **이모지 → 캐릭터 교체가 가장 많은 곳**
| ID | P | 위치 | 넣을 것 |
|---|---|---|---|
| C1 | P0 | `mission_chat/widgets/chat_bubble_widget.dart` — 상대 메시지 `'🐰'` 아바타(약 :35) | `MaruCharacter(rabbit, idle, 40, interactive: false)` |
| C2 | P0 | `mission_chat/widgets/typing_bubble_widget.dart` — `'🐰'`(약 :33), `isAwaitingReply` 동안 표시 | `MaruCharacter(rabbit, thinking, 40, interactive: false)` |
| C3 | P0 | `mission_chat/widgets/chat_bubble_widget.dart` — side 교정 박스 `'🐢'`(tertiaryContainer, 약 :155-175) | `MaruCharacter(turtle, idle, 40, interactive: false)` |
| C4 | P0 | `mission_chat/screens/mission_chat_screen.dart` — 즉시 교정 배너 `'Wait a second!'` 의 `'🐢'`(size 32, 약 :363-391) | `MaruCharacter(turtle, thinking, 48, reactionKey: immediateCorrection)` (새 교정마다 반응) |
| C5 | P0 | `mission_chat/screens/mission_clearance_screen.dart` — `_buildPage1Summary` 상단(`clearance.cleared`, 약 :138-170) | 제목 위에 cleared == true → `Row[rabbit cheer 110, turtle happy 110]`(entrance), false → `Row[rabbit thinking 110, turtle happy 110]` + 응원 톤 문구("Almost there!" 류) — **v1.2: 미달성에 토끼 sad(우는 표정) 쓰지 않음**(하도윤 R3 피드백, MSN-1.7.8), null → 캐릭터 없음 |
| C6 | P1 | 같은 파일 `resultReason` 박스 `'🐢'`(약 :182), Tutor's Note `'🐢'`(약 :281) | `MaruCharacter(turtle, idle, 40, interactive: false)` |
| C7 | P1 | `mission_chat/screens/mission_setup_screen.dart` — `settingUp` 로딩 `'🐰'`(약 :67) + 스피너(:71) | `MaruCharacter(rabbit, thinking, 120)` + 기존 문구·스피너 유지. **v1.2 → `MaruMood.magic` 120 + "Tokki is transforming into <역할>…" (MSN-1.7.7, `setup_transform_loading.dart`)** — 변신 연출(회전·펑·반짝이)은 캐릭터가 하므로 화면에서 따로 만들지 말 것 |
| C8 | P1 | `mission_chat_screen.dart` 실패 배너 `'🐢'`(약 :121), 전송 실패 `'🐢 Not sent'`(chat_bubble :129), "Help me Turtle" 버튼 `'🐢'`(약 :416) | 배너 = `turtle sad 40`, 나머지 두 곳은 **이모지 유지**(버튼·짧은 문구 안이라) |
| — | P2 | `suggestion_sheet.dart:32` 제목, setup 버튼 `'Start Mission 🐰'` | 이모지 유지 |

### 3.4 실험실 (LAB) — 🐰 한글 조합 놀이 / 🐢 문법 설명
| ID | P | 위치 | 넣을 것 |
|---|---|---|---|
| C1 | P0 | `lab/screens/hangeul_lab_screen.dart` — `hasResult`(약 :36) 로 `_ResultCard` ↔ 안내 placeholder(약 :138-165) | 카드 위에 `MaruCharacter(rabbit, size: 72, mood: hasResult ? happy : idle, reactionKey: state.combinedResult)` |
| C2 | P0 | `lab/screens/lab_screen.dart` — `_buildLoading()`(약 :642, 스피너 + `'$_loadingLabel...'` 단계 문구) | 스피너 자리에 `MaruCharacter(turtle, thinking, 120)`, 단계 문구 유지 |
| C3 | P0 | 같은 파일 `_buildResultsArea()` Combine 결과 카드 "Explanation"(약 :713-766) | 카드 머리에 `MaruCharacter(turtle, talking, 64, settleToIdleAfter: 2000ms, reactionKey: _combineResult)` |
| C4 | P1 | 같은 파일 오류 뷰(약 :686-710) · `_buildEmptyState`(약 :824) | 오류 = `turtle sad 96`(기존 아이콘 대체, Retry 유지), 빈 상태 = `turtle idle 96` |

### 3.5 공통 (PM 소유 화면) — **이번 스프린트 제외** (범위 축소안 3). 필요 시 메인 PM 판단으로 홈 인사 1곳(`rabbit`+`turtle` idle 72)만.

### 3.6 예상 공수 (기능 FE 세션 1명 기준)
| 기능 | P0 | P1 | 비고 |
|---|---|---|---|
| 레슨 | C1~C3 ≈ 60분 | C4 ≈ 20분 | C1 이 핵심(시연 하이라이트) |
| 단어장 | C1·C2 ≈ 45분 | C3 ≈ 20분 | |
| 미션 | C1~C5 ≈ 60분 | C6~C8 ≈ 25분 | 교체 위주라 단순 |
| 실험실 | C1~C3 ≈ 40분 | C4 ≈ 15분 | |

## 4. 갤러리
`flutter run -t lib/dev/character_gallery_main.dart` (로그인·서버 불필요). 검수·승인용 단독 앱. 섹션 구성은 PLAN CHR-1.6.1.2. 승인 스크린샷은 `docs/features/character/screenshots/`.

## 5. 변경 이력
| 시각 | 변경 | 영향 |
|---|---|---|
| 09-30 22:50 | v1.0 확정: 원칙(§0), `reactionKey`·`settleToIdleAfter`·`entrance`·`interactive`·`semanticLabel`·`precache`·Bubble `side`/`typewriter`/`onTypingDone` 추가, 기분별·캐릭터별 모션 수치, 에셋 폴백, compact 모드, 파티클 | char-dev 구현 기준. 기능 세션 영향 없음(아직 미배포) |
| 09-30 23:35 | char-dev 구현 중 조정 승인: thinking 루프 폭 ½(기울어진 채 갸웃), 반복 점프는 진입 후 0.6주기 뒤 시작, 🐢 정착 곡선 ElasticOut(0.55), 🐰 happy 점프마다 ±3° 교대 기울기, entrance = 0→1.08(330ms)→1.0(220ms), Bubble 한글 단어 단위 줄바꿈(keep-all) | 공개 API 변경 없음 |
| 10-01 00:20 | §3 v1.1: 🚦 승인 후 기능별 적용 명세 확정(화면·파일·변수·기분·크기·우선순위), 공통 규칙 8개, PM 화면 제외 | 메인 PM 이 기능 PLAN Step 1.6 으로 배포 |
| 10-01 01:00 | §1 precache 권장, §3.0-9 테스트 팁(R-004). 첫 표시 빈칸 수정은 CHR-1.6.4.2(코드, 공개 API 변경 없음) | 기능 세션 코드 변경 불필요 |
| 10-01 01:25 | §2.5: cacheWidth 축소 디코드 폐지 → 512px 원본 공유 + 자동 warm-up precache + 첫 프레임 전 숨김·페이드인(R-004 수정, add2fbb). §1 의 precache 권장은 이제 선택 | 공개 API·기능 코드 변경 없음 |
| 10-01 12:50 | v1.2: `MaruMood.magic` 추가(enum 끝, 기존 값 유지 — 기능 코드에 MaruMood switch 없음 확인), §2.3 magic 연출(회전·펑 연기·반짝이·미니 변신 루프), 에셋 `rabbit_magic.png`(🐢 는 idle 폴백). §3.3 C5 미달성 = rabbit thinking + turtle happy(sad 금지), C7 → magic | 미션만 사용(MSN-1.7.7·1.7.8). 다른 기능 영향 없음 |
| 10-01 19:50 | magic 구현 반영(a594fb9): 반짝이 시작점 (0.3w,0.15h)→실제 마술봉 별 (0.21w,0.41h), 🐢 수치(미니 변신 4.0s, 흔들림 ±3°/2.2s, 반짝이 2.4~3.4s). 말풍선 WORD JOINER 범위(음절+자모) 유지 — 자모·따옴표 혼합 시뮬레이터 ▯ 없음(CHR-1.7.5, 3c31c5c) | 공개 API 는 magic 추가뿐 |
