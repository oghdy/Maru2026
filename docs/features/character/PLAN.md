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

## Phase 1 — Step 1.6 캐릭터 (ID: CHR-1.6.x)
### Step 1.6.0 팀 구성 (char-lead)
- [ ] CHR-1.6.0.1 [LEAD] P0 캐릭터 디자인 방향·모션 규격 확정(CHARACTER_API 보완), char-dev·char-asset 첫 프롬프트 작성 → 하도윤에게 전달

### Step 1.6.1 기반 (에셋 없이 시작)
- [ ] CHR-1.6.1.1 [DEV] P0 `lib/shared/characters/` 에 `MaruCharacter`·`MaruCharacterBubble` 구현 (CHARACTER_API §1·§2), 에셋 없을 때 플레이스홀더
- [ ] CHR-1.6.1.2 [DEV] P0 갤러리 단독 실행 엔트리 `lib/dev/character_gallery_main.dart` — 2캐릭터 × 6기분 그리드 + 기분 전환 버튼 + 탭 반응 + 크기 비교. `flutter run -t lib/dev/character_gallery_main.dart` (로그인·서버 불필요)
- [ ] CHR-1.6.1.3 [DEV] P1 위젯 테스트(기분 전환·disableAnimations·에셋 누락 시 플레이스홀더)

### Step 1.6.2 에셋 반영 + 갤러리 승인 🚦
- [ ] CHR-1.6.2.1 [ASSET] P0 `docs/features/character/raw/` 의 이미지 후처리(배경 제거·baseline 정렬·512px·용량) → `assets/characters/`, `pubspec.yaml` 의 `assets:` 에 폴더 1줄 추가(위임 허용 D-12). ASSETS.md §4 체크리스트 갱신. 일관성 문제는 재생성 요청 목록으로 하도윤에게
- [ ] CHR-1.6.2.2 [LEAD] P0 갤러리 스크린샷·짧은 설명을 LOG 에 → **하도윤 승인 요청** (PM_SYNC 에도 기록)

### Step 1.6.3 적용 설계 (승인 후)
- [ ] CHR-1.6.3.1 [LEAD] P0 CHARACTER_API §3 을 화면·이벤트 단위로 구체화 → PM_SYNC 로 메인 PM 에 배포 요청 (기능 세션에 직접 지시 금지)

### Step 1.6.4 기능 적용 (메인 PM 이 각 기능 PLAN Step 1.6 으로 배포 — 기능 FE 세션이 수행)
- [ ] CHR-1.6.4.1 [LEAD] 메인 PM 이 feat/character 를 main 에 머지·worktree 동기화 → 기능 세션 적용 → char-lead 는 화면별 결과 리뷰(스크린샷) 후 PM_SYNC 로 피드백
