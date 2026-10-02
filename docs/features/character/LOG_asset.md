# CHR — char-asset (이미지 후처리·에셋) 세션 로그

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기)
- 현재 태스크: 없음 — CHR-1.8.5 ✅ 실험복 거북이 sad·talking 반영 (에셋 21장: rabbit 8 + turtle 7 + lab 6)
- 다음 할 일: char-lead 검수 대기. raw 가 바뀌면 스크립트(인자 없이) → contact sheet(4줄: rabbit·turtle·rabbit lab·turtle lab + blink 비교) 확인 → 새 png 만 `git add <경로>` + `git commit -- <경로>`. 새 의상 표정은 `LAB_MOODS` 에 추가(자동으로 PROP_MOODS). 머리 크기는 스크립트가 판정하지 않음 → "머리 정합"(scratchpad reg.py 방식, 이동 ±30px 제한 권장 — 넓으면 손이 머리에 닿은 장에서 발산)으로 수동 확인
- 막힌 것: 없음
- 실행 중인 것: -
- 마지막 커밋: 16a37d8 `[CHR-1.8.5] Add turtle lab sad/talking assets`
- char-lead 에게: 없음 — CHR-1.8.5 검수 합격(16a37d8), turtle_lab_thinking −4% 는 보정 안 함으로 확정(char-lead). 대기 중

## 기록 (시간순 추가만)
### 09-30 23:05~23:10 CHR-1.6.1.6 후처리 파이프라인 ✅ (docs/tools)
- `tools/process_characters.py` (PIL 12.2 + numpy 2.3 만 사용). 인자: `--raw --out --sheet --report --kinds --tol 0.03 --bg-tol 28 --max-kb 150 --force-blink --remove-stale --dry-run`. 재실행 가능, 있는 파일만 처리, 없는 표정은 시트에 "missing / fallback" 표시
- 동작:
  1. 테두리가 불투명하면 테두리 지배색(최대 4색 → 그려진 가짜 체커보드도 처리) 기준으로 가장자리부터 flood fill → 1px 가장자리 침식 + 부드러운 알파 + 안쪽 색으로 채움(흰 halo 제거). 본체의 1% 미만인 떨어진 티끌 제거
  2. kind 별로 idle 기준 정규화: 발 baseline·발 중심은 항상 맞추고, 크기(실루엣 면적의 제곱근)가 3% 넘게 다르면 스케일 보정 + 보고 → kind 공통 배율 하나 적용(idle 높이 80%, baseline 하단 6%, 발 중심 = 가로 중앙). cheer 등이 잘리면 kind 전체 배율을 줄이고 보고
  3. blink: 면적으로 스케일 확인 → ±20px 실루엣 XOR 탐색(1/4 해상도 → 원본 해상도). 실루엣 차 ≤2%, 변화 영역 폭 ≤65%·높이 ≤30% 이면 OK → **idle 위에 blink 의 눈 영역만 합성**(움찔 0). 아니면 REGENERATE, assets 에 쓰지 않음(깜빡임 생략 폴백)
  4. 512×512, ≤150KB 면 RGBA 그대로. 넘으면 256색 양자화(외곽 알파 오차 ≤6·색 오차 ≤4 일 때만. 아니면 원본 유지 + 보고)
  5. contact sheet 2×7: 체커보드 배경, baseline 빨간 선, idle 상단 파란 선, 파일명·KB·보정 메모, blink 차이 인셋(마젠타)
- 검증(합성 이미지 10장, scratchpad, assets 에는 아무것도 안 씀): 흰 배경·체커보드 배경·크림 배경·투명 배경 모두 제거됨. 녹색 배경에 합성해 확대 확인 → halo 없음(가장자리 반투명 픽셀 평균 밝기 48 ≈ 외곽선 색). 1.12배 크고 이동된 happy → x0.893 보정·정렬. 발이 들린 cheer → baseline 정렬. 7px 어긋난 blink → shift [-7,5] 검출 후 OK. 6° 기운 blink → REGENERATE(실루엣 차 9.9%), 기록 안 함. 티끌 제거. `--max-kb 20` 으로 양자화 경로 확인(10KB, 외곽 오차 3.8). 14장 처리 ≈ 2초
- 알려진 한계: 닫힌 틈의 배경은 안 지움. 크기를 면적으로 추정하므로 만세 포즈 등은 실제와 ±1% 정도 차이

### 09-30 23:10~23:11 CHR-1.6.2.1 (1차) idle 2장 반영 🔸 b91633a
- raw 도착: rabbit_idle(1254², RGBA, 알파 제공), turtle_idle(RGBA, 알파 제공). 배경 제거 불필요
- 발견·수정: ChatGPT 알파가 몸 전체 254(완전 불투명 아님) → 스크립트에서 ≥250 을 255 로 정리
- 결과: rabbit_idle 118KB(RGBA 그대로), turtle_idle 30KB(원본 RGBA 가 150KB 초과 → 256색 양자화, 외곽 오차 3.7·색 오차 3.2). 보라(#6B4EFF) 배경 3배 확대로 외곽 계단·밴딩 없음 확인. 두 장 모두 높이 80%, baseline 6%, 발 중심 가로 중앙(contact sheet 확인)
- 판정(ASSETS §5): 둘 다 합격. 참고 — 토끼만 흰 스티커 테두리 있음(HANDOFF 참고)
- pubspec `flutter:` 아래 `assets: - assets/characters/` 2줄 추가 → `flutter pub get` 성공, pubspec.lock 변경 없음. 커밋 b91633a (assets 2장 + pubspec 만)
- 미확인: 시뮬레이터 표시(갤러리는 char-dev 담당)

### 09-30 23:37~23:38 CHR-1.6.2.1 (2차) 6장 반영 🔸 5ff3b0e
- raw 도착: rabbit_blink·happy·sad·thinking·talking·cheer, turtle_happy (모두 RGBA 알파 제공, 배경 제거 불필요)
- 결과: rabbit 표정 114~123KB(RGBA 그대로, 150KB 이하), turtle_happy 33KB(256색, 외곽 오차 3.9·색 오차 3.7). 크기 보정 필요한 장 없음(모두 3% 이내). 발 위치 보정: rabbit_sad(+2.3% x, −5.4% y), rabbit_cheer(+13.5% x — 한 발 들기 포즈라 발 중심이 이동, −2.9% y) → baseline 정렬됨. idle 2장은 다시 써졌지만 바이트 동일(git 변경 없음)
- 판정(ASSETS §5, contact sheet 육안): 6장 모두 같은 캐릭터(얼굴형·색·목도리) → 합격. rabbit_blink → REGENERATE(실루엣 차 3.53%, 픽셀 차 8.76%, 변화 영역이 몸 전체 — 웃는 눈으로 다시 그려짐) → assets 에 쓰지 않음, 재생성 요청(HANDOFF)
- 커밋 5ff3b0e: png 6장만(char-dev 의 lib 변경 파일은 건드리지 않음)
- 미확인: 시뮬레이터 표시(char-dev 갤러리 reload 필요)

### 09-30 23:38 CHR-1.6.2.1 (3차) turtle_sad 반영 🔸 7c24cf5
- turtle_sad 29KB(256색, 외곽 오차 3.8·색 오차 2.5), 보정 없음. 안경·나비넥타이·등껍질 일관성 합격(contact sheet 육안). 전체 실행으로 contact sheet 다시 생성

### 09-30 23:50~23:56 CHR-1.6.2.1 (4차) turtle 4장 + blink 로컬 정렬 ✅ a0cc8ad·5b94eab
- raw 14/14 도착(23:45). turtle_thinking 28KB·talking 32KB·cheer 30KB(한 발 포즈, 발 위치 +17.3% x → baseline 정렬). 3장 모두 안경·나비넥타이·등껍질 일관성 합격 → a0cc8ad
- blink 전신 판정: rabbit(실루엣 차 3.53%), turtle(1.04%, 변화 영역이 몸 전체 — 둘 다 ^^ 눈으로 몸 전체를 다시 그림) → REGENERATE
- char-lead 지시로 **로컬 눈 패치** 추가(`local_eye_patch`, 전신 판정 실패 시 자동 시도):
  1. 눈 찾기: idle↔blink 색 차이를 4px 침식 → 외곽선 흔들림(얇은 선)은 사라지고 눈(면)만 남음. 12px 로 이어 붙인 뒤 좌우로 떨어진 가장 큰 덩어리 2개 = 두 눈
  2. 눈 상자(눈 크기의 40% 여유) 주변 40px 고리(얼굴 외곽·안경·눈썹)로 ±20px 로컬 정렬(회색 SAD)
  3. 패치 = 로컬 정렬 후 눈 상자 안에서 실제로 바뀐 픽셀 + 3px 확장 → feather 5회 블러 → idle 위에 합성(실루엣은 절대 안 바꿈). 처음엔 사각형 패치였는데 안경테에 경계가 걸려 이음매 오차 110 → 변경 픽셀 기반 마스크로 바꿔 해결
  4. 판정: feather 경계의 외곽선 픽셀 중 두 그림이 어긋나는 비율 ≤15%, 고리 오차 ≤16, 로컬 이동이 탐색 한계(±20)에 닿지 않을 것
  5. contact sheet 하단에 idle | blink 눈 영역 확대 비교 추가(3배, 폭 제한 시 축소 — 거북이는 2배로 표시돼 별도로 3배 확인)
- 결과: turtle_blink → LOCAL 합격(로컬 이동 [0,−1], 고리 오차 3.3, 이음매 0.3%). 3배 확대로 머리 외곽·안경테·다리·눈썹·코·입 제자리 확인. rabbit_blink → 여전히 REGENERATE(이음매 21%, 머리·눈썹·입 위치까지 다시 그려짐 — 3배 비교에서 확인)
- 추가 수정: idle 과 blink 를 각각 256색 양자화하면 팔레트가 달라 몸 전체 픽셀이 미세하게 달라짐(프레임 교체 시 반짝임 위험) → blink 는 **idle 의 팔레트·인덱스를 그대로 쓰고 바뀐 불투명 픽셀만 재매핑**(`encode_like`). tRNS 알파를 잃는 버그 1회 수정. 결과: 변경 픽셀 6,307개, 전부 얼굴 영역(512 기준 x124~339, y125~243), 알파 차이 최대 2/255(불투명 내부)
- 회귀: 합성 테스트 재실행 → 7px 어긋난 blink OK 유지. 6° 기운 blink 가 로컬 패치로 통과해 버려서(이동이 한계 20px 에 닿음) 한계 도달 시 실패하도록 가드 추가 → REGENERATE 복귀. 실제 turtle_blink 출력은 가드 후에도 바이트 동일(git 변경 없음)
- 커밋 5b94eab (turtle_blink.png 만). 미확인: 시뮬레이터에서 깜빡임 동작(char-dev 갤러리 reload 필요)

### 10-01 00:06~00:07 CHR-1.6.2.1 (5차) rabbit_blink 재생성본 반영 ✅ bf572dc
- raw 교체(00:04, 하도윤 선택 영역 편집). 전신 판정: 실루엣 차 0.79%, 픽셀 차 2.51% — 변화 영역 높이가 97% 라 전신 OK 기준은 미달 → 로컬 눈 패치 자동 적용: 로컬 이동 [0,0], 고리 오차 2.9, 이음매 1.4% → LOCAL 합격
- 확인: 출력 idle↔blink 알파 완전 동일, 변경 픽셀 3,807개 전부 눈 영역(512 기준 x168~308, y227~314). 3배 확대 비교로 머리 외곽·눈썹·코·입·볼·목도리 제자리, 열린 눈 속눈썹 잔상 없음, 감은 눈은 중립 곡선
- 115KB(RGBA 그대로, idle 도 RGBA 라 팔레트 공유 불필요). 커밋 bf572dc (rabbit_blink.png 만). 미확인: 시뮬레이터 깜빡임(char-dev R 필요)

### 10-01 19:18~19:20 CHR-1.7.2 rabbit_magic 반영 ✅ 0310daa
- raw: rabbit_magic(1254², RGBA, 알파 제공, 12:34 도착, char-lead 검수 합격). 알파 bbox x 169~1097(idle 327~983), 마술봉 주변 반투명 글로우·떨어진 반짝이 여러 개
- 스크립트 변경: `MOODS` 에 `magic` 추가 + `PROP_MOODS = {"magic"}` — ①배율 idle 고정(면적 보정이 마술봉에 속지 않게) ②떨어진 반짝이 유지(티끌 제거 생략 — 원래 규칙이면 본체 1% 미만이라 지워짐) ③kind 공통 배율 계산에서 제외(기존 14장 결과 불변 보장) ④대신 캔버스 bbox 를 계산해 밖으로 나가면 CLIP 플래그(멈추고 char-lead 에 질문하는 조건). 변경 전 스크립트 사본은 scratchpad 에 백업
- 머리 크기 판단(귀 제외 얼굴 폭, 마술봉 든 손 제외한 볼 높이 행): idle ≈578px, magic ≈593px(raw) → +2.6%, 3% 이내 → 보정 없음(배율 idle 그대로)
- 결과: 138KB(RGBA 그대로 — 양자화 안 함, 반짝이 품질 유지). 캔버스 bbox x 65~376, 상단 77 → 잘림 없음(여백 좌 65·상 77). 발 baseline 정렬(디딘 발 기준 +8.9% x, −1.1% y)
- 확인: 기존 14장 다시 써졌지만 바이트 동일(git status 에 rabbit_magic 만). contact sheet 2×8(turtle_magic 칸은 missing/idle 폴백 표시) 육안 — 같은 캐릭터·머리 크기 동일. 3배 확대(어두운/흰 배경): 반짝이·얇은 줄·별 외곽선 선명, 계단 없음, 글로우는 그림 일부(배경 halo 아님)
- 커밋 0310daa (rabbit_magic.png 만, char-dev 파일 건드리지 않음). 미확인: 시뮬레이터 표시(char-dev R 필요)

### 10-02 18:00~18:12 CHR-1.8.2 실험복 4장 반영 ✅ 3985429
- raw: rabbit_lab_idle·rabbit_lab_happy·turtle_lab_idle·turtle_lab_thinking (1254², RGBA 알파 제공, 17:48~17:55, char-lead 검수 합격)
- 스크립트 변경: `LAB_MOODS = ["lab_idle","lab_happy","lab_thinking"]` → 파일명 `<kind>_lab_<mood>.png`, `PROP_MOODS` 에 포함(배율 idle 고정·거품 방울 등 떨어진 조각 유지·kind 공통 배율 계산 제외 → 기존 15장 불변). contact sheet 3번째 줄 = lab 6칸(없는 rabbit_lab_thinking·turtle_lab_happy 는 "missing / fallback: <kind>_lab_idle + motion"). 변경 전 사본 scratchpad 백업
- 머리 크기 판정(얼굴 폭 ±3%): 소품(플라스크·손)이 볼을 가리고 고개를 돌린 포즈라 단순 얼굴 폭·눈 간격은 쓸 수 없음(happy 0.93, thinking 0.87 — 가림·회전 때문). 대신 **머리 정합**: idle 의 머리 영역 외곽선(어두운 선)을 각 장에 배율×회전×이동 탐색으로 맞춤(블러 거리장 점수). 결과 rabbit_lab_idle 0.990 · rabbit_lab_happy 0.970 · turtle_lab_idle 0.995 · turtle_lab_thinking 0.960. 같은 방법으로 이미 합격한 기존 장 보정: rabbit_happy 0.980, sad 0.945, thinking 0.985, talking 1.005, cheer 0.980 / turtle happy 1.000, thinking 0.975, talking 1.000, cheer 0.985 → 고개 기울인 장의 측정 오차 ≈ ±4~5%. lab_idle 2장은 idle 외곽선과 배율 1.0 에서 겹쳐 봐도 거의 일치(눈 확인). → 4장 모두 **보정 없음(배율 idle 그대로)**, turtle_lab_thinking 만 경계값으로 char-lead 판단 요청
- 결과: 28KB·30KB·34KB·36KB (256색 양자화, 외곽 오차 4.1~4.8·색 오차 2.4~2.8 — 기준 6/4 이내). baseline·발 중심 정렬(이동 3% 이내, 플래그 없음). 캔버스 bbox 상단 52~71 / 좌우 67~412 → 잘림 없음
- 소품 보존: rabbit_lab_idle 떨어진 방울 4개, turtle_lab_thinking 3개 그대로. rabbit_lab_happy 의 떨어진 1px 조각 3개(알파 35, 거품 외곽선 일부) 유지 — 보이지 않음. 3배 확대(남색·브랜드 보라 배경): 거품·고글 끈·클립보드·주머니 펜·얼룩 외곽 선명, 계단·밴딩·halo 없음 → 용량 기준 완화 불필요
- 금지 요소(ASSETS §6 ⚠) 없음: 클립보드는 선·체크박스만, 로고·글자·명찰·방호복·모자 없음
- 확인: 스크립트 전체 실행 후 기존 15장 바이트 동일(scratchpad dry-run 에서 cmp + git status 에 새 4장만). contact sheet 육안(Read) — lab 줄 4장 baseline·머리 높이가 idle 과 같음
- 커밋 3985429 (lab png 4장만, `git add <4경로>` + `git commit -- <4경로>`; char-dev 파일 안 건드림). 미확인: 시뮬레이터 표시(char-dev R 필요)

### 10-02 19:29~19:31 CHR-1.8.5 실험복 거북이 sad·talking 반영 ✅ 16a37d8
- raw: turtle_lab_sad(19:26)·turtle_lab_talking(19:28), 1254² RGBA 알파 제공, char-lead 검수 합격
- 스크립트: `LAB_MOODS` 에 `lab_sad`·`lab_talking` 추가. contact sheet lab 줄을 kind 별 2줄(각 5칸)로 분리 — 한 줄이면 10칸이라 폭이 늘어남. 변경 전 사본 scratchpad 백업
- 머리 크기(±3%): 머리 정합(idle 머리 외곽선 배율×회전×이동 탐색) talking 1.000. sad 는 이동 ±100px 탐색에선 0.855 로 발산(탐색 경계·단조 증가 — 손이 머리 뒤에 닿은 포즈, 기존 turtle_sad 도 같은 현상) → 눈 위치가 idle 과 거의 같아 이동 ±30px 로 제한: sad 0.965, 같은 조건 기존 합격본 turtle_sad 0.960 → 표정에 따른 측정 편차로 판단, 둘 다 보정 없음(배율 idle 그대로). 원본 나란히 육안으로도 머리 크기 같음
- 결과: turtle_lab_sad 33KB(256색, 외곽 오차 3.7·색 오차 2.8, bbox x 109~425 상단 49), turtle_lab_talking 36KB(외곽 4.1·색 2.8, bbox x 80~415 상단 45) → 잘림 없음, baseline·발 중심 정렬(플래그 없음). 떨어진 조각 없음(둘 다 단일 덩어리)
- 3배 확대(남색·보라 배경): 고글·안경·펜·클립보드(선·체크박스만, 글자 없음)·등껍질 외곽 선명, 계단·halo 없음. 금지 요소 없음
- 확인: scratchpad dry-run 에서 기존 19장 cmp 바이트 동일 → 실제 실행 후 git status 에 새 2장만. contact sheet Read 육안 — turtle lab 줄 5칸(happy 는 missing/폴백) baseline·머리 높이 idle 과 같음
- 커밋 16a37d8 (png 2장만). 미확인: 시뮬레이터 표시

### 10-02 CHR-1.8.5 검수 합격 (char-lead)
- 16a37d8 합격. turtle_lab_thinking −4% → 보정 안 함 확정. 대기
