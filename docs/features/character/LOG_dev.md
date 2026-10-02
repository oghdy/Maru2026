# CHR — char-dev (위젯·모션·갤러리) 세션 로그

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기)
- 현재 태스크: 없음 — CHR-1.8.3 ✅ fbd4010·c783d97 → **char-lead 검수 요청 (10-02 18:06)**
- 다음 할 일: 검수 피드백 반영 (실제 lab PNG 3985429 반영 확인 완료 18:12)
- 새 에셋 반영 절차: 앱 실행 중이면 `R`(hot restart) — 또는 `r` 후 갤러리 "Reload assets" 버튼
- 모션 확인: `FILMSTRIP_OUT=<dir> [FILMSTRIP_REAL=1] flutter test test/shared/characters/filmstrip_test.dart`
- 막힌 것: 없음
- 실행 중인 것: 없음 — 갤러리 flutter run 은 백그라운드 시간 제한으로 종료됨. 필요하면 `cd frontend/maru && flutter run -d 50FB788C-2FB3-4D74-8673-5FFFAAD456C8 -t lib/dev/character_gallery_main.dart` 로 다시 실행
- 마지막 커밋: c783d97 [CHR-1.8.3]
- 테스트: `flutter test test/shared/characters` → 41 통과 + 필름스트립 2 skip
- char-lead 에게: 공개 API 변경 = `MaruOutfit` + `outfit:` 추가뿐. **문서와 다르게 한 것 1가지**: 깜빡임은 "화면에 실제로 그려진 idle 이미지의 짝"(`<x>_idle` → `<x>_blink`)을 씀. lab_idle 이 보이면 lab_blink 만(없으면 생략 — 기본 blink 를 lab 위에 덮지 않음, 테스트 고정). 단 lab PNG 가 하나도 없어 **기본 의상 rabbit_idle 로 폴백된 경우엔 기본 blink 가 그대로 동작**(그려진 그림이 기본 의상이라 짝이 맞음). §1 문구 "깜빡임은 lab_blink 있을 때만"에 "(기본 의상으로 폴백된 경우 제외)" 보충 부탁

## 기록 (시간순 추가만)

### 09-30 23:03~23:18 · CHR-1.6.1.1 MaruCharacter ✅ 76d454e
- 구조: `maru_character.dart`(barrel, 공개: MaruCharacterKind·MaruMood·MaruBubbleSide·MaruCharacter) + `src/` — `character_types` / `character_pose`(Pose·키프레임 트랙) / `character_motion`(§2.2·2.3 수치 전부, 🐰/🐢 두 세트) / `character_assets`(AssetManifest 조회·폴백·precache) / `placeholder_painter` / `maru_character_widget`
- 동작 방식: 캐릭터당 Ticker 1개가 시계를 돌림(**Timer 없음** → dispose 후 pending timer 0). 포즈 = 기분 루프(숨쉬기·흔들림·주기 점프) + 반응 트랙. 새 반응/새 기분은 "현재 포즈 − 새 루프" 에서 시작해 0 으로 가므로 반응 중 교체돼도 튐 없음. 매 프레임 setState 없음: ChangeNotifier → AnimatedBuilder(Transform)·그림자 CustomPaint 만 갱신, 표정이 바뀔 때만 setState. 캐릭터마다 RepaintBoundary, 숨쉬기 위상 랜덤(여러 마리가 동시에 숨쉬지 않게)
- 에셋 폴백: `AssetManifest.loadFromAssetBundle` 로 존재하는 파일만 사용 → `<kind>_<mood>` → `<kind>_idle` → 플레이스홀더, blink 없으면 깜빡임 생략. 예외·콘솔 에러 없음. 로드 전 1프레임은 그림자만. errorBuilder 도 플레이스홀더로 이중 안전장치. 갤러리용 `CharacterAssets.forcePlaceholder`(src 전용)
- disableAnimations: 정자세, 깜빡임·잔동작 없음, 크로스페이드 0ms, 표정 전환은 유지(탭 900ms happy·settleToIdle 도 동작 — 그 동안만 Ticker 가동 후 정지 → pumpAndSettle 종료)
- **§2 수치에서 바꾼 것**:
  - thinking 루프: 기울기 +6°/+4° 를 기준으로 ±(4°/3°)**의 절반** 왕복(기준을 넘어 반대로 넘어가지 않게, 계속 "갸웃" 상태 유지)
  - 주기 점프(happy 🐰 1.6s, cheer 🐰 2.2s/🐢 3.0s): 첫 점프는 진입 반응 끝나고 0.6주기 뒤(착지 직후 바로 또 뛰면 경련처럼 보여서)
  - 🐢 정착 곡선: elasticOut 대신 `ElasticOutCurve(0.55)`(출렁임 적고 부드럽게 — 성격 차이)
  - 🐰 happy 점프마다 ±3° 좌우 번갈아 기울기 추가(생동감). 🐢 cheer 웅크림 120→150ms
  - entrance: elasticOut 은 1.25 까지 튀어서 0→1.08(330ms easeOutCubic)→1.0(220ms) 키프레임으로 구현
  - talking 진입 들썩: 올라감 60ms + 내려옴 90ms
  - 이미지 cacheWidth: size×dpr < 256px 일 때만 적용(큰 크기는 원본 512 디코드 → `MaruCharacter.precache` 와 캐시 공유)
  - 프레임 간 dt 는 최대 0.1s 로 제한(끊겼다 돌아올 때 반응이 건너뛰지 않게)
- 플레이스홀더: 100×100 단위 좌표 CustomPainter. 🐰 흰 몸·긴 귀(sad 축 처짐, thinking 한쪽 접힘, cheer 벌어짐)·보라 목도리 / 🐢 초록 몸·육각 등껍질·배딱지·안경·보라 나비넥타이. 기분별 눈(idle 점·blink 곡선·happy ^^·sad 처진 눈썹·thinking 위 곁눈+한쪽 눈썹·cheer 굵은 ^^)·입·팔 포즈 다름. 외곽선 = primary 와 검정 62% 혼합, 소품 = primary, 몸 색은 캐릭터 고유색 상수(파티클 보조색처럼 예외)
- 확인:
  - `flutter analyze lib/shared/characters lib/dev test/shared/characters` → No issues
  - `flutter test test/shared/characters` → 통과(필름스트립은 skip). 위젯 테스트 본편은 1.6.1.3
  - 필름스트립(`screenshots/dev_CHR-1.6.1.1_filmstrip_{rabbit,turtle}.png`): 🐰 happy 2회 점프·cheer 큰 점프+회전·sad 가라앉음+귀 처짐·thinking 기울기·talking 들썩·탭 점프 후 900ms 뒤 idle 표정 복귀. 🐢 같은 기분에서 점프 높이 절반·느림·회전 없음 → 성격 차이 확인
  - 시뮬레이터(iPhone 16 Plus): 갤러리 Stage 에서 char-asset 이 넣은 rabbit_idle·turtle_idle PNG 가 **자동으로** 사용됨, 모든 기분 = idle 이미지 + 모션(폴백), Force placeholder 토글 시 플레이스홀더. 슬로모션 ×5 로 cheer 연속 캡처(`dev_CHR-1.6.1.1_rabbit_cheer_sim_slowmo.png`): 웅크림 → 늘어나며 점프·기울기 → 그림자 작아지고 옅어짐 확인
  - 미확인: 12개 동시 성능·reduce motion 시뮬레이터 확인 → 1.6.1.2 갤러리 Grid 에서

### 09-30 23:18~23:21 · CHR-1.6.1.4 MaruCharacterBubble ✅ 35c1e98
- `[캐릭터][말풍선]`(side=right 면 반대), surfaceContainerHighest·라운드 16·꼬리(캐릭터 입 높이 ≈ size×0.5 를 가리킴), Flexible 로 최대 폭 = 가용 폭 − 캐릭터
- 등장: 꼬리 쪽 기준 scale .85→1 + 페이드 220ms easeOutBack. message 바뀌면 재등장+재타이핑
- typewriter 40자/초(Ticker, Timer 없음), 타이핑 중 캐릭터 talking → 끝나면 mood. 타이핑 중 말풍선 탭 = 즉시 전체. 레이아웃은 처음부터 전체 텍스트(안 나온 글자 투명) → 흔들림 없음. onTypingDone 은 항상 프레임 뒤 호출(콜백에서 setState 안전). disableAnimations 면 즉시 전체
- **추가**: 한국어가 음절 단위로 줄바꿈되는 문제("학 / 생이에요") → 단어 안 한글 음절 사이에 WORD JOINER(U+2060) → 띄어쓰기에서만 줄바꿈(keep-all). 타이핑 글자 수는 원문 기준
- 확인: analyze 0, 시뮬레이터에서 타이핑 중/완료 비교(`screenshots/dev_CHR-1.6.1.4_bubble_typing_vs_done.png`) — 말풍선 크기 고정, 거북이 talking, 완료 후 "done ✓"(onTypingDone), 토끼 right 배치·꼬리 방향, 40dp compact

### 09-30 23:19~23:23 · CHR-1.6.1.2 갤러리 ✅ fc87933
- `lib/dev/character_gallery_main.dart` 단독 엔트리(main.dart·core import 없음), 테마 fromSeed(0xFF6B4EFF).copyWith(primary, onPrimary white)
- 상단 토글: Reduce motion(MediaQuery disableAnimations 주입) / Force placeholder / Slow motion ×5(timeDilation)
- ①Stage 🐰🐢 180dp + 기분 칩 6 + Replay ②Grid 2×6 96dp(12개 동시) + Replay all ③Sizes 40(compact)/72/120/180 + Pop in(entrance) ④Bubbles 거북이 긴 한·영 혼합 코칭 / 토끼 right 대화 / 40dp typewriter 없음 + Replay typing ⑤Scenario 토끼 120 + 거북이 말풍선, Correct(happy, settleToIdleAfter 1600ms)/Wrong(sad + 거북이 thinking 힌트)/Complete(cheer)
- 확인(시뮬레이터 iPhone 16 Plus, 스크린샷 `dev_CHR-1.6.1.2_*`): Grid·Sizes 표시, Scenario Wrong → 토끼 sad·거북이 힌트 재타이핑, Reduce motion + cheer → 표정만 바뀌고 정자세(점프·회전 없음), 실행 로그 exception 0. analyze 0 / test 통과(필름스트립 skip)
- 미확인: entrance 육안, 12개 동시 프레임 시간 수치(육안상 부드러움)

### 09-30 23:37~23:42 · CHR-1.6.1.7 lead 검수 반영 ✅ d21f4fc·7a80ddb
1. Sizes: 크기별로 묶음 [🐰40 🐰72 🐢40 🐢72] / [🐰120 🐢120] / [🐰180 🐢180] → 8개가 스크롤 없이 한 화면(`screenshots/dev_CHR-1.6.1.7_sizes_one_screen.png`). 라벨 폭을 캐릭터 폭(최소 56)으로 제한 — 첫 커밋 후 위젯 테스트가 좁은 폰트에서 70px overflow 를 잡아서 7a80ddb 로 수정. 같은 이유로 Bubbles 의 "Turtle: typing… + Replay typing" Row → Wrap
2. 에셋 캐시: `_available` static 은 hot reload 에서 유지됨 → 새 PNG 를 못 잡는 게 맞음. `CharacterAssets.reload()` 추가(rootBundle.clear — AssetManifest.bin 캐시 제거, imageCache 비움, 매니페스트 재조회, 끝나면 모든 캐릭터에 알림 — 로드 중엔 이전 목록 유지라 깜빡임 없음). 갤러리 상단에 "PNGs (n/14): …" 목록 + Reload assets 버튼. 확인: 실행 중에 char-asset 이 추가한 7장(5ff3b0e·7c24cf5)이 `R` 후 9/14 로 표시되고 rabbit happy PNG 표정으로 바뀜. Reload 버튼 실행 시 예외 0. **미확인: `r` + 버튼 조합으로 실행 중 새 파일을 잡는 경우**(확인 당시 새로 들어온 파일이 없었음) → 확실한 절차는 `R`
3. Correct 연타: `test/shared/characters/gallery_test.dart` 가 실제 갤러리에서 Correct 3회(각각 settle→idle 후) 누르고 토끼 최대 높이 측정 → 3회 모두 점프(>10px, 규격 14.4px). reactionKey 재생 정상, 코드 수정 불필요
4. 기본값: 같은 테스트에서 Reduce motion·Force placeholder·Slow motion 칩이 시작 시 모두 꺼짐, forcePlaceholder=false 확인
- 추가 확인: entrance(Pop in) 시뮬레이터 연속 캡처 — 작음 → 1.08 과장 → 1.0(`dev_CHR-1.6.1.7_entrance_frames.png`). 지난 검수의 미확인 해소
- analyze 0, `flutter test test/shared/characters` 통과(+2, 필름스트립 2 skip)

### 09-30 23:42~23:46 · CHR-1.6.1.5 cheer 파티클 ✅ c5478df
- `src/particles.dart`: 10~14개, 별/원 반반, 색 primary·#FFC83D·#4CD4B0·#FF8FB1, 위쪽 부채꼴(−170°~−10°) 방사 + 중력 2.4·size/s² + 페이드(1−u²), 900ms, 처음 120ms 팝인. 캐릭터 Ticker 로 그림(추가 Ticker 없음), 몸을 따라가지 않고 화면 공간에서 날아감
- 발생: cheer 트랙의 TrackEvent.burst(🐰 360ms / 🐢 450ms = 점프 정점). 원점 = 발 피벗에서 0.8·size 위 + 현재 기울기 반영(처음엔 기울기 무시해서 🐰 공중회전 시 옆으로 치우쳤음 → 수정). compact(≤56)·reduce motion 에선 생략
- 확인: 필름스트립 cheer 행(`dev_CHR-1.6.1.5_cheer_particles_filmstrip.png`), 시뮬레이터 슬로모션 실제 rabbit_cheer PNG 로 연속 캡처(`dev_CHR-1.6.1.5_cheer_particles_sim_slowmo.png`) — 머리 위 중앙에서 퍼지고 떨어지며 사라짐. analyze 0, test 통과
- entrance·fidget 은 1.6.1.1(76d454e)에 이미 구현, entrance 는 1.6.1.7 에서 시뮬레이터 확인

### 09-30 23:46~23:48 · CHR-1.6.1.3 위젯 테스트 ✅ 0ad33b8
- `test/shared/characters/maru_character_test.dart` 16개 + `gallery_test.dart` 2개(1.6.1.7) = 18 통과
  - 에셋 3케이스(debugSetAvailable): 없음 → 전 기분 플레이스홀더·예외 0 / 전부 → 정확한 기분 이미지 + idle 에서만 blink 레이어 / 일부(rabbit idle·happy) → happy 는 happy, sad 는 idle 이미지, blink 없음, 거북이는 플레이스홀더. + Force placeholder
  - 모션: 기분 전환 시 표정 교체 + 점프(>8px), 같은 mood + reactionKey 변경 → 재반응, settleToIdleAfter → 표정 idle, 탭 → 900ms happy 후 복귀 + onTap, interactive:false 무시, cheer 파티클 120dp 생성·40dp(compact) 없음·900ms 후 정리
  - reduce motion: lift 0, entrance 없음, pumpAndSettle 종료, 표정 전환·settle·탭 표정은 유지
  - 말풍선: 약 40자/초 + 타이핑 중 talking → 끝나면 mood + onTypingDone 1회, 탭 → 즉시 전체, typewriter:false·reduce motion → 즉시 전체, 첫 프레임부터 전체 텍스트 크기(흔들림 없음)
  - dispose: cheer·탭 반응·타이핑 중 제거 → pending timer·활성 ticker 없음(flutter_test 검사)
- 테스트가 실제로 잡는지 확인: reactionKey 재생 조건 제거 / reduce motion 에서 ticker 항상 가동으로 바꾸면 각각 실패함(확인 후 원복, diff 없음)
- analyze 0

### 09-30 23:53~23:55 · 에셋 반영 절차 확인 (코드 변경 없음)
- `r` + Reload assets: a0cc8ad(turtle thinking·talking·cheer) 반영 전 9/14 → `r` → 버튼 → **12/14**, Grid 에 새 거북이 PNG(턱 괴기·만세) 즉시 표시(`screenshots/dev_assets_12of14_after_r_reload.png`). **지난번 미확인 해소 — 두 방법 모두 동작**
- 이어서 `R`: **13/14**(그 사이 turtle_blink 추가됨) 표시, 토글 전부 꺼짐, 로그 exception 0(`dev_assets_13of14_after_R.png`)
- 남은 에셋: rabbit_blink 1장

### 10-01 00:07~00:10 · 에셋 14/14 반영 확인 (코드 변경 없음)
- bf572dc(rabbit_blink) 커밋 감지 → 갤러리 `R` → **PNGs (14/14)**, 토글 전부 꺼짐, 로그 exception 0(`screenshots/dev_assets_14of14_after_R.png`)
- 실제 blink PNG 동작: idle 토끼를 simctl 로 40장 연속 캡처 → 눈 영역 어두운 픽셀 수로 감은 프레임 3장 검출(b03·b04 연속 = 2회 깜빡임 추정, b31). 뜬 눈/감은 눈 비교 시 눈 외 윤곽·귀·목도리 어긋남 없음(`dev_rabbit_blink_open_vs_closed_sim.png`). turtle_blink 는 육안 미확인(같은 경로, 파일 존재·목록 표시만 확인)

### 10-01 01:02~01:18 · CHR-1.6.4.2 (R-004) 첫 표시 빈칸 수정 ✅ add2fbb
- 재현(수정 전 코드, 콜드 실행 + 계측): 첫 캐릭터의 PNG 첫 프레임이 위젯 생성 후 **약 510~640ms**(디버그 빌드) 뒤에 옴 → 그동안 그림자만 보였음. simctl 200ms 간격 캡처로는 안 잡혀서 계측 로그(임시, 커밋 안 함)로 측정
- 수정 1: `_reveal` AnimationController — 몸(FadeTransition)과 그림자(알파 곱) 모두 0 에서 시작. 얼굴이 처음 그려질 때(Image.frameBuilder 의 frame != null) 공개: `wasSynchronouslyLoaded`(캐시 HIT)면 즉시 1, 새 디코드면 120ms 페이드인. 플레이스홀더·errorBuilder 는 즉시. reduce motion 은 즉시. 매니페스트 로딩 중(얼굴 없음)도 숨김. entrance 팝인은 공개 시점부터 시작(보이기 전에 팝인이 끝나버리지 않게)
- 수정 2 판단(warm-up precache) — **넣음**. 근거(임시 측정 앱: 토끼만 먼저 → 몇 초 뒤 거북이 말풍선 + 토끼 cheer, 콜드 실행 각 1회):
  | | 거북이 말풍선 talking | 거북이 idle(타이핑 끝) | 토끼 cheer 전환 |
  |---|---|---|---|
  | warm-up 없음 | 새 디코드(106ms 빈칸) | 새 디코드 | 새 디코드(크로스페이드가 빈칸으로) |
  | warm-up 있음 | 캐시 HIT(1ms, 즉시) | 캐시 HIT | 캐시 HIT |
  - 전제: cacheWidth(ResizeImage) 를 쓰면 72dp(216px) 말풍선은 캐시 키가 달라 precache 가 무효 → **cacheWidth 제거**, 모든 크기가 512px 원본 한 벌을 공유. 비용: 디코드 메모리 약 1MB × 16장 ≈ 16MB(ImageCache 기본 한도 100MB), 첫 캐릭터 표시 직후 백그라운드 디코드. `MaruCharacter.precache` 도 같은 원본 키로 통일
  - warm-up 은 앱 실행당 1회(Reload assets 시 다시). 첫 캐릭터 자체는 여전히 디코드 시간이 필요 → 수정 1(숨김+페이드)로 처리
- 갤러리: `--dart-define=GALLERY_SLOWMO=true` 로 슬로모션 상태로 시작(기본값은 그대로 꺼짐) — 콜드 첫 표시를 느리게 보기 위해
- 확인:
  - 콜드 실행(simctl terminate → launch) + 슬로모션 ×5 연속 캡처(`screenshots/dev_CHR-1.6.4.2_cold_start_slowmo_fadein.png`): 앱 전체 페이드 → 몸·그림자가 **함께** 반투명으로 나타남 → 완전 표시. 그림자만 있는 프레임 없음
  - 테스트 `first_show_test.dart` 5개(실제 rabbit_idle.png 디코드): 디코드 전 `paintsNothing`(그림자 포함) / 디코드 후 페이드 중간값 → 1 + 그림자·이미지 그림 / precache 후 첫 프레임부터 1 / entrance 는 이미지 준비 전 scale 0, 준비 후 1 로 / 플레이스홀더 즉시. 그림자 숨김을 빼면 첫 테스트가 실패함을 확인(원복)
  - 기존 18 + 새 5 = 23 통과, analyze 0
  - 계측 코드·임시 앱(`lib/dev/_measure_main.dart`)은 삭제, 위젯 파일이 계측 전과 동일함을 diff 로 확인

### 10-01 19:18~19:29 · CHR-1.7.3 MaruMood.magic ✅ a594fb9
- 공개 API: `MaruMood` 끝에 `magic` 추가만(기존 값·순서 유지 — 테스트로 고정). 내부 switch 전부(모션 루프/진입, 플레이스홀더 귀·팔·눈·입) magic 케이스 추가. warm-up·precache 목록은 `MaruMood.values` 기반이라 rabbit_magic 자동 포함(테스트 확인)
- 회전: 발 피벗 기울기와 별개인 **스핀 채널**(몸 중심 = 발 위 0.46·size 기준 360°, easeInOutCubic). 2π 는 0 과 같은 모습이라 끝날 때 튐 없음. 다른 반응으로 끊겨도 스핀은 끝까지 돌고 끝남
- 진입(🐰/🐢): 웅크림 sY .90·sX 1.06(120/160ms) → 점프 h .10/.06 + 스핀(520/800ms) → 착지 squash(80/100ms) → 스케일 펄스 1→1.12→1(300/400ms) + 착지 순간 **펑 연기**(라벤더·흰 원 4개가 부풀며 450ms 페이드, 살짝 위로) + **반짝이**(별 8~10개, primary·금·흰, 흰/금 별은 primary 얇은 테두리로 밝은 배경에서도 보임). 🐰 총 1020ms / 🐢 1520ms
- 루프: 흔들림 🐰 ±4°·1.6s / 🐢 ±3°·2.2s + 상하 h .02, 마술봉 반짝이 3~4개 🐰 1.8~2.6s / 🐢 2.4~3.4s 마다, **미니 변신**(스핀 🐰 450ms / 🐢 700ms + 작은 펑·반짝이 5개) 🐰 3.2s / 🐢 4.0s 마다 — 첫 미니 변신은 진입 끝나고 0.6주기 뒤(다른 반복 점프와 같은 규칙)
- 이펙트 위치: 반짝이 원점 = 🐰 실제 rabbit_magic.png 마술봉 별 위치 측정값 (0.21w, 0.41h) — 문서의 (0.3w, 0.15h) 로 하면 귀 위에서 나와 어색해서 바꿈 / 🐢 는 마술봉 이미지가 없어 머리 위 (0.5, 0.12). 이펙트는 현재 기울기·높이를 반영한 몸 위 지점에서 생겨서 화면 공간으로 퍼짐(몸을 따라가지 않음)
- compact(≤56): 진입 = 점프 없이 idle 진입(400ms easeOut), 흔들림만(진폭 ½), 스핀·연기·반짝이 없음. reduce motion: 정자세 + magic 표정만, pumpAndSettle 종료
- 파티클 구조: `ParticleBurst` 를 여러 개 동시에(리스트) — cheer 색종이(기존 그대로)·`.sparkle`·`.smoke`. 끝난 것은 매 프레임 정리
- 플레이스홀더 magic: 윙크(왼눈 ^, 오른눈 뜸) + 작은 벌린 미소 + 왼손 들고 금색 별 마술봉(별 끝 = 반짝이 원점과 같은 (21,40)), 🐰 귀 (-16°, 22°). 🐢 도 같은 얼굴·마술봉
- 갤러리: 기분 칩·Grid 자동 7개(2×7), "Scenario — mission loading"(rabbit magic 120 + entrance + "Tokki is transforming into a café barista…", Mission loading / Stop 버튼). PNG 수 표시를 "n PNGs" 로(turtle_magic 은 원래 없으니 /14 표기 제거)
- 필름스트립: `FILMSTRIP_REAL=1` 옵션(실제 PNG 디코드 후 촬영), "magic loop" 행(첫 미니 변신 직전부터)
- 확인:
  - 테스트 `magic_test.dart` 8개: enum 순서 / 진입 360° + 착지 연기·반짝이 + magic 얼굴 + 끝나면 똑바로 / 🐢 스핀이 🐰 보다 늦게 끝남 / 루프 3.4s 안에 미니 변신 360° + 반짝이 / compact 는 흔들림만(각도 < 2.4°, 파티클 0) / reduce motion 정자세·파티클 0·pumpAndSettle / 에셋: rabbit_magic 있으면 그것 → 없으면 rabbit_idle → 🐢 는 turtle_idle → 없으면 플레이스홀더 / warm-up 목록에 rabbit_magic. 스핀을 끄면 실패함 확인(원복)
  - 기존 23 + 8 = 31 통과, analyze 0
  - 필름스트립(실제 PNG): `screenshots/dev_CHR-1.7.3_rabbit_magic_entry_filmstrip.png`(웅크림→몸 중심 360°→착지→펄스+연기+마술봉 별에서 반짝이), `_loop_minitransform_filmstrip.png`(흔들림·반짝이 → 미니 변신), `_turtle_magic_entry_filmstrip.png`(idle 이미지 폴백, 더 느림), 플레이스홀더 `dev_CHR-1.7.3_placeholder_rabbit_magic_entry.png`
  - 시뮬레이터 iPhone 16 Plus: 실제 rabbit_magic PNG 반영(15 PNGs), 슬로모션 진입 연속 캡처 `dev_CHR-1.7.3_rabbit_magic_sim_slowmo.png`, Mission loading 미리보기 연속 캡처 `dev_CHR-1.7.3_mission_loading_preview_sim.png`(팝인→변신→루프→미니 변신), 로그 exception 0

### 10-01 19:29~19:32 · CHR-1.7.5 말풍선 WORD JOINER 점검 ✅ 3c31c5c (코드 변경 없음)
- 갤러리 Bubbles 에 자모·따옴표 혼합 문장 추가: `'ㅛ' 를 'ㅕ' 와 헷갈리지 마세요. ㅋㅋㅋ 괜찮아요! Say "요" not "여".` — 자모 사이(ㅋ⁠ㅋ⁠ㅋ)에도 joiner 가 들어가는 경우 포함
- 시뮬레이터(iPhone 16 Plus) 확대 확인: **▯ 없음**, 자모·따옴표 정상 표시, 띄어쓰기에서만 줄바꿈(`screenshots/dev_CHR-1.7.5_jamo_quotes_bubble_sim.png`) → PLAN 조건("깨지면 축소")에 따라 **범위(AC00–D7A3 + 3130–318F) 유지**. ㅋㅋㅋ 같은 자모 묶음이 한 단어로 유지되는 것도 keep-all 취지에 맞음
- 테스트 추가(maru_character_test): joiner 제거 시 원문과 동일 / 모든 joiner 는 한글 두 글자 사이 / 따옴표·공백 옆엔 없음. 32 통과, analyze 0
- 참고: 미션 MSN-1.7.4 의 ▯ 는 캐릭터 코드와 무관(PLAN 메모대로) — 말풍선 쪽은 재현 안 됨

### 10-02 18:00~18:06 · CHR-1.8.3 실험복 의상 API ✅ fbd4010·c783d97
- 공개 API(추가만): `enum MaruOutfit { normal, lab }`(character_types, barrel export), `MaruCharacter(outfit:)`·`MaruCharacterBubble(outfit:)` 기본 normal — 기존 호출 무변경(테스트로 고정). 말풍선은 outfit 을 캐릭터에 그대로 전달(타이핑 중 talking → lab_talking 없으니 lab_idle)
- 에셋: `CharacterAssets.face(kind, mood, outfit:)` 폴백 = `<kind>_lab_<mood>` → `<kind>_lab_idle` → `<kind>_<mood>` → `<kind>_idle` → 플레이스홀더. normal 은 lab 파일을 절대 안 씀. 깜빡임 `blinkFor(facePath)` = 그려진 idle 이미지의 짝(`_idle`→`_blink`) — lab 위에 기본 blink 안 덮음(HANDOFF 참고). `existingFor` 가 모든 의상을 포함 → warm-up·`MaruCharacter.precache` 에 있는 lab PNG 자동 포함
- outfit 전환: 이미지 경로가 바뀌면 기존 AnimatedSwitcher 키가 바뀌어 표정 전환과 같은 150ms 크로스페이드. 모션·연출은 의상과 무관(코드 경로 동일)
- 플레이스홀더 lab: 이마에 올린 고글(하늘색 렌즈 2 + 끈) + 실험복 옷깃 2장. 옷깃은 처음 흰색 → 흰 토끼 위에서 선만 보여 어색 → 연회색(#E6EBF2)으로(c783d97)
- 갤러리: 상단 "Outfit: normal / lab"(SegmentedButton, Stage·Grid 적용), "Lab menu (lab outfit)" 섹션(토끼 lab happy 96 + 거북이 lab thinking 96). Grid 제목 "12 at once" → "14 at once"(magic 추가 후 실제 14개)
- 테스트 `outfit_test.dart` 9개: enum 순서·기본값 normal(캐릭터·말풍선) / 폴백 4단계 + 플레이스홀더(outfit=lab) / lab 4장만 있는 실제 상황(lab happy·lab idle 폴백·turtle lab thinking·lab cheer→lab idle, normal 은 lab 파일 안 씀) / lab idle 에서 기본 blink 미사용·lab_blink 있으면 사용 / normal blink 유지 / outfit 변경 시 크로스페이드 중 두 이미지 → 끝나면 lab 이미지, 다시 normal 로 복귀 / 플레이스홀더 outfit 반영 / 말풍선 전달 / precache 목록. + gallery_test: Outfit 기본 normal, lab 탭 시 Stage 가 lab
- 첫 실행 때 gallery_test 가 Lab menu 라벨 overflow(테스트 폰트 폭) 잡음 → 라벨 폭 120 + FittedBox, Outfit 줄 Wrap 으로 수정
- 확인: analyze 0, `flutter test test/shared/characters` 41 통과(기존 32 + 9, 필름스트립 2 skip). 시뮬레이터 iPhone 16 Plus: lab 선택 시 lab PNG 없음 → 기본 의상 PNG 로 폴백 표시(`screenshots/dev_CHR-1.8.3_lab_menu_fallback_no_lab_png.png`), Force placeholder + lab → 고글·옷깃(`dev_CHR-1.8.3_placeholder_lab_stage.png`, Stage·Grid 둘 다 lab), 실행 로그 exception 0
- **미확인**: 실제 lab PNG 4장(CHR-1.8.2 미도착) — 도착 후 R 로 확인 예정. 크로스페이드는 테스트로만 확인(육안 미확인)

### 10-02 18:12 · 실제 lab PNG 반영 확인 (코드 변경 없음)
- char-asset 3985429 [CHR-1.8.2] 감지 → 갤러리 `R` → **19 PNGs**(lab 4장 포함). Outfit lab: Stage 토끼 = rabbit_lab_idle(고글·실험복·비커), Lab menu = rabbit_lab_happy + turtle_lab_thinking(클립보드) 실제 PNG, 발 baseline·크기 기본 의상과 일치(`screenshots/dev_CHR-1.8.3_lab_real_png_stage.png`, `_lab_real_png_menu.png`). normal → lab 전환 후 이미지 교체 확인(크로스페이드 중간 프레임은 스크린샷으로 못 잡음 — 테스트로만 확인). 로그 exception 0
- 이전 LOG 의 "미확인: 실제 lab PNG" 해소

