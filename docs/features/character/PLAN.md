# CHR — Character (토끼·거북이) PLAN

- 세션: **`char-lead` = 캐릭터 팀 PM (코딩 안 함 — 지시·검수·문서·일정·메인 PM 과 소통)**
  - `char-dev` (작업 세션): 위젯·모션·갤러리·테스트 구현 → 태그 `[DEV]`, 로그 `LOG_dev.md`
  - `char-asset` (작업 세션): 이미지 후처리·에셋 배치·pubspec assets 줄 → 태그 `[ASSET]`, 로그 `LOG_asset.md`
  - 두 작업 세션은 같은 worktree 를 쓰되 파일이 겹치지 않음. 작업 세션 프롬프트는 char-lead 가 써서 하도윤이 붙여넣음
  - `[LEAD]` 태스크 = char-lead 본인(검수·문서·승인 요청·PM_SYNC)
- worktree `/Users/hadohadopapi/Desktop/Maru-wt/character` · 브랜치 `feat/character`
- 시뮬레이터 iPhone 16 Plus `50FB788C-2FB3-4D74-8673-5FFFAAD456C8` · 서버 불필요(갤러리는 로그인 없이 단독 실행)
- 목표: 듀오링고처럼 **살아 움직이고 반응하는** 토끼·거북이. AI 이미지(표정별 PNG) + Flutter 코드 모션(방식 B, D-11)
- 동결: **10/1 15:00** (전체 공통). 캐릭터 적용은 10/1 오전
- 🚦 **Go/No-Go 게이트**: Step 1.6.2 갤러리를 하도윤이 보고 승인해야 Step 1.6.4(기능 적용)로 넘어감. 불합격이면 중단하고 이모지 유지

## 일정 (역산 — 동결 10/1 15:00 불변)
| 시각 | 마일스톤 | 담당 |
|---|---|---|
| 09-30 23:00 | char-dev·char-asset 시작 | 하도윤이 프롬프트 붙여넣기 |
| 10-01 01:00 | 플레이스홀더 위젯 + 갤러리 1차 → char-lead 검수 | char-dev |
| 10-01 01:00 | 후처리 파이프라인 준비 완료(이미지 없이) | char-asset |
| **10-01 08:00** | **raw 14장 도착 마감** (늦어도 idle 2장은 먼저) | 하도윤 |
| 10-01 09:00 | 에셋 반영 갤러리 → 🚦 하도윤 승인 요청 | char-asset → char-lead |
| **10-01 10:00** | CHARACTER_API §3 구체화 → PM_SYNC 로 기능 적용 배포 요청 | char-lead |
| 10-01 10:00~14:30 | 기능 FE 세션 적용 (메인 PM 지시) → char-lead 스크린샷 리뷰 | 기능 FE |

**범위 축소안 (위험 시 이 순서로 자른다)**
1. raw 가 08:00 까지 일부만 → 있는 표정만 반영, 없는 표정은 idle 이미지 + 모션(에셋 폴백 §1) 으로 승인 진행
2. idle 조차 없음 → 플레이스홀더 캐릭터로 승인받거나 No-Go(이모지 유지)
3. 적용 범위: 레슨·미션 우선(시연 핵심), 단어장·실험실은 1곳씩, 공통(홈)은 제외
4. 기능 연출: 파티클·typewriter·fidget 은 P1 — 01:00 검수 때 미완이면 잘라내고 P0(숨쉬기·깜빡임·기분 반응·탭)만

## Phase 1 — Step 1.6 캐릭터 (ID: CHR-1.6.x)
### Step 1.6.0 팀 구성 (char-lead)
- [x] CHR-1.6.0.1 [LEAD] P0 캐릭터 디자인 방향·모션 규격 확정(CHARACTER_API v1.0), char-dev·char-asset 첫 프롬프트 작성(`PROMPTS.md`) → 하도윤에게 전달 (09-30 22:55, 문서만)

### Step 1.6.1 기반 (에셋 없이 시작)
- [x] CHR-1.6.1.1 [DEV] P0 `lib/shared/characters/` 에 `MaruCharacter` 구현 (CHARACTER_API §1·§2.1~2.3·§2.5): barrel `maru_character.dart` + `src/`. 숨쉬기·깜빡임·기분별 진입 반응/루프·탭·disableAnimations·에셋 폴백·코드 플레이스홀더(기분별 얼굴이 다르게 보일 것) — 76d454e
- [x] CHR-1.6.1.2 [DEV] P0 갤러리 단독 엔트리 `lib/dev/character_gallery_main.dart` (로그인·서버 불필요, 앱 테마 시드 0xFF6B4EFF). 섹션: ①Stage — 캐릭터별 180dp + 기분 칩 6개 + Replay(reactionKey++) + Reduce motion 토글 + Force placeholder 토글 ②Grid — 2캐릭터 × 6기분(96dp) ③Sizes — 40/72/120/180 ④Bubbles — 거북이 코칭(긴 한·영 혼합 문장 줄바꿈), 토끼 right 대화, typewriter ⑤Scenario — Correct/Wrong/Complete 버튼(레슨 흐름 흉내: happy+settle / sad / cheer) — fc87933
- [x] CHR-1.6.1.3 [DEV] P1 위젯 테스트 `test/shared/characters/` — 에셋 누락 시 플레이스홀더(예외 없음)·기분 전환·reactionKey 재생·disableAnimations(pumpAndSettle 종료)·Bubble 즉시 전체 표시·dispose 후 pending timer 없음 — 0ad33b8
- [x] CHR-1.6.1.4 [DEV] P0 `MaruCharacterBubble` (CHARACTER_API §2.4) — 말풍선·꼬리·등장·typewriter·talking 연동 — 35c1e98
- [x] CHR-1.6.1.5 [DEV] P1 cheer 파티클 + entrance 팝인 + idle fidget (CHARACTER_API §2.2·§2.3) — c5478df (entrance·fidget 은 76d454e 에 포함)
- [x] CHR-1.6.1.6 [ASSET] P0 후처리 파이프라인 `docs/features/character/tools/process_characters.py`(Maru-main 경로, PIL+numpy만) — 배경 제거(알파 없을 때)·kind 별 공통 크롭·baseline/스케일 정렬·blink↔idle 정렬 검사·512px·양자화(≤150KB)·contact sheet 생성. 이미지 없이 합성 테스트 이미지로 동작 확인 — ✅ docs/tools (09-30 23:10)

- [x] CHR-1.6.1.7 [DEV] P0 lead 검수 반영(09-30 23:35): ①갤러리 Sizes 의 180dp 가 가로 스크롤에 잘림 → 스크롤 없이 전부 보이게(40·72·120 한 줄 + 180 다음 줄 등) ②새 PNG 가 들어오면 hot restart 없이도 반영되는지 확인 — 안 되면 갤러리에 "Reload assets" 버튼(매니페스트 캐시 초기화) ③Scenario 에서 Correct 연타 시 매번 반응 재생(reactionKey) 확인 — d21f4fc·7a80ddb
- [x] CHR-1.6.2.3 [LEAD] P1 표정 PNG 도착분마다 갤러리 재확인 — 14/14 (bf572dc), rabbit_blink 눈만 차이 확인

### Step 1.6.2 에셋 반영 + 갤러리 승인 🚦
- [x] CHR-1.6.2.1 [ASSET] P0 `docs/features/character/raw/` 의 이미지 후처리 → `frontend/maru/assets/characters/`, `pubspec.yaml` 의 `flutter:` 아래 `assets:` 에 `- assets/characters/` 1줄(위임 D-12, **파일이 실제로 들어간 뒤에**). ASSETS.md §4 체크리스트 갱신. 일관성 문제는 재생성 요청 목록으로 char-lead 에게. idle 2장이 먼저 오면 먼저 반영 — ✅ 14/14 반영 b91633a·5ff3b0e·7c24cf5·a0cc8ad·5b94eab·bf572dc (10-01 00:07)
- [x] CHR-1.6.2.2 [LEAD] P0 갤러리 직접 실행·스크린샷·짧은 설명을 LOG 에 → **하도윤 승인 요청** (PM_SYNC 에도 기록) — ✅ 10-01 00:10 승인

### Step 1.6.3 적용 설계 (승인 후)
- [x] CHR-1.6.3.1 [LEAD] P0 CHARACTER_API §3 을 화면·이벤트 단위로 구체화 → PM_SYNC 로 메인 PM 에 배포 요청 (기능 세션에 직접 지시 금지) — §3 v1.1, PM_SYNC S-004 (10-01 00:25)

### Step 1.6.4 기능 적용 (메인 PM 이 각 기능 PLAN Step 1.6 으로 배포 — 기능 FE 세션이 수행)
- [x] CHR-1.6.4.1 [LEAD] 메인 PM 이 feat/character 를 main 에 머지·worktree 동기화 → 기능 세션 적용 → char-lead 는 화면별 결과 리뷰(스크린샷) 후 PM_SYNC 로 피드백 — 10-01 01:00 리뷰 완료, 기능 21/21 태스크 합격, PM_SYNC S-005
- [ ] CHR-1.6.4.2 [DEV] P0 (R-004 버그) 캐릭터 첫 표시 시 PNG 디코드 전 그림자만 보이고 몸이 빈칸(~0.5s) → 이미지 첫 프레임 전엔 그림자까지 숨기고 준비되면 페이드인(캐시 HIT 면 즉시), 매니페스트 첫 로드 때 전체 precache(효과 확인 후). 공개 API 변경 없음. 테스트 추가
- [ ] CHR-1.6.4.3 [LEAD] CHR-1.6.4.2 검수 → PM_SYNC 로 재머지 요청
