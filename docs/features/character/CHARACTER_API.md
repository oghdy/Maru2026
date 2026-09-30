# CHR — CHARACTER API (캐릭터 팀 ↔ 기능 FE 세션 약속)

> char-lead 가 관리. 기능 FE 세션은 **이 문서의 공개 API 만** 쓴다(내부 파일 import 금지).
> 변경 시 char-lead 가 §4 이력에 기록하고 PM_SYNC 로 메인 PM 에 알린다.

## 1. 공개 API (초안 — char-lead 가 구현하며 확정)
```dart
import 'package:maru/shared/characters/maru_character.dart';

enum MaruCharacterKind { rabbit, turtle }
enum MaruMood { idle, happy, sad, thinking, talking, cheer }

// 기본 위젯: 표정 전환 + 자동 모션(숨쉬기·깜빡임) + 반응 모션
MaruCharacter(
  kind: MaruCharacterKind.turtle,
  mood: MaruMood.happy,     // 바뀌면 크로스페이드 + 반응 모션 1회
  size: 120,                // 정사각 한 변(dp)
  onTap: null,              // null 이면 기본 탭 반응(찌그러졌다 튀기)
)

// 말풍선 버전: 캐릭터 + 메시지 (코칭·안내용)
MaruCharacterBubble(kind:, mood:, message: 'Nice! 는 marks the topic.', size: 72)
```

## 2. 동작 규격
| 상태/이벤트 | 모션 |
|---|---|
| 항상 | 숨쉬기(세로 scale 1.00↔1.03, ~2.4s), 3~6초 랜덤 깜빡임(`*_blink` 150ms) |
| → happy | 작은 점프(hop) 1회 |
| → sad | 아래로 살짝 가라앉기 + 느린 흔들림 |
| → thinking | 좌우 기울기 흔들림(반복) |
| → talking | 4Hz 정도 작은 들썩임(반복) — 말하는 동안 유지 |
| → cheer | 큰 점프 + 착지 squash & stretch |
| 탭 | squash → 튕김, 잠깐 happy |
| 접근성 | `MediaQuery.disableAnimationsOf(context)` 가 true 면 모션 끄고 표정만 |

- 에셋이 오기 전에는 **플레이스홀더**(코드로 그린 단순 실루엣 또는 원+이모지)로 같은 API 동작 → 이미지 도착 시 파일 교체만
- 이미지 precache, 한 화면 여러 개여도 60fps

## 3. 기능별 적용 제안 (갤러리 승인 후 메인 PM 이 각 기능 PLAN 태스크로 배포)
| 기능 | 위치 · 이벤트 → 캐릭터/기분 |
|---|---|
| 레슨 | 조립 🐰 단계 = 토끼, 🐢 단계 = 거북이 코칭 말풍선. 정답 happy / 오답 sad(+힌트) / 완료 cheer |
| 단어장 | 덱 헤더 인사, Match 중 토끼 응원(정답 happy, 오답 sad), 완료 cheer. 평가 후 거북이 "4일 뒤 다시 만나요" |
| 미션 | 🐰 대화 상대 아바타(응답 대기 thinking, 말할 때 talking), 🐢 교정 배너 아바타. 수료증 cleared=cheer / not=sad |
| 실험실 | 한글랩 조합 성공 토끼 happy, 그래머랩 결과 설명 거북이 talking, 로딩 thinking |
| 공통(PM) | 홈 인사, 빈 상태·오류 화면, 스플래시/로그인 |

## 4. 변경 이력
| 시각 | 변경 | 영향 |
|---|---|---|
