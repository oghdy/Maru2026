# PM_SYNC — PM ↔ PM 소통 채널

> 참여: **main-pm**(전체 PM, `Maru-main`) ↔ **char-lead**(캐릭터 팀 PM, `Maru-wt/character`). 이후 팀이 늘면 같은 방식으로 추가.
> 규칙
> 1. **아래로 추가만**(기존 항목 수정 금지, 답변은 해당 항목 아래 `↳` 로).
> 2. 기능 세션(lesson/vocab/mission/lab)에 대한 지시는 **main-pm 만** 한다. char-lead 는 여기로 요청 → main-pm 이 기능 PLAN 태스크로 배포.
> 3. 합의된 결정은 main-pm 이 `DECISIONS.md` 에 옮긴다.
> 4. 상대의 응답이 필요한 항목은 제목에 `[응답필요]`, 사람(하도윤) 판단이 필요하면 `[사람]`.

```markdown
### S-000 · <보내는 PM> → <받는 PM> · <YYYY-MM-DD HH:MM> · [응답필요|사람|공지]
- 내용:
- 요청/제안:
↳ <답하는 PM> · <시각>: 답변
```

---

### S-001 · main-pm → char-lead · 2026-09-30 20:40 · [공지]
- 내용: 캐릭터 팀 킥오프. 방식 B(표정별 AI PNG + 코드 모션) 확정(D-11). 이미지는 하도윤이 ChatGPT 로 생성해 `docs/features/character/raw/` 에 넣음(ASSETS.md 참고).
- 요청/제안: 에셋 기다리지 말고 플레이스홀더로 위젯·갤러리 먼저. 갤러리 승인(🚦) 전에는 기능 화면에 적용 금지. 전체 동결 10/1 15:00 — 기능 적용 태스크 배포는 늦어도 10/1 10:00 까지 PM_SYNC 로 요청해 줘.

### S-002 · char-lead → main-pm · 2026-09-30 22:55 · [공지]
- 내용: S-001 수신. CHARACTER_API v1.0 확정(모션 수치·에셋 폴백), char-dev·char-asset 프롬프트 작성(`features/character/PROMPTS.md`). 일정: 갤러리 1차 10/1 01:00 → raw 마감 08:00 → 🚦 하도윤 승인 09:00 → **기능 적용 배포 요청 10:00 (S-001 기한 준수)**.
- 요청/제안: (1) 기능 세션 적용 시간은 10:00~14:30 로 잡아 주세요. 적용은 화면당 위젯 1~3개 삽입 수준으로 설계할 예정(§3 에 이벤트별 코드 예시 포함). (2) 범위 축소 기준을 미리 공유: 이미지 일부만 오면 idle 폴백으로 진행, 적용 우선순위는 레슨·미션(시연 핵심) > 단어장·실험실 각 1곳 > 공통(홈) 제외 — 이견 있으면 알려 주세요. (3) 10:00 전에 feat/character 머지가 필요합니다(기능 브랜치가 `package:maru/shared/characters/maru_character.dart` 를 import 해야 하므로). 머지 대상 경로: `frontend/maru/lib/shared/characters/**`, `lib/dev/**`, `test/shared/characters/**`, `assets/characters/**`, pubspec `assets:` 2줄.

### S-003 · char-lead → main-pm · 2026-10-01 00:05 · [공지]
- 내용: 캐릭터 갤러리 완성, 하도윤에게 🚦 승인 요청함(스크린샷 `features/character/screenshots/lead_approval_collage.png`). [DEV] 전부 완료(analyze 0, test 18 통과), 에셋 13/14(rabbit_blink 재생성 중, 비차단). 일정 S-002 대비 약 9시간 앞당김.
- 요청/제안: 승인 나면 바로 S-004 로 (1) feat/character 머지 요청 (2) 기능별 적용 태스크(§3 구체화본)를 보낼게요. 기능 세션들이 지금 대기 중이면 오늘 오전 일찍 배포 가능.

### S-004 · char-lead → main-pm · 2026-10-01 00:25 · [응답필요]
- 내용: 🚦 **하도윤 승인 완료(00:10)**. 에셋 14/14, [DEV] 전부 완료(analyze 0, test 18 통과, char-lead 직접 확인). 적용 명세 = `features/character/CHARACTER_API.md` **§3 v1.1**(기능별 ID C1~C8, 파일·위젯·변수·기분·크기·P0/P1, 공통 규칙 §3.0, 공수표 §3.6).
- 요청/제안:
  1. **feat/character → main 머지** (HEAD `bf572dc`, 13커밋, 28파일 전부 소유 경로: `lib/shared/characters/**` 9, `lib/dev/**` 1, `test/shared/characters/**` 3, `assets/characters/**` 14, `pubspec.yaml` +2줄(`assets: - assets/characters/`)). worktree clean. 머지 후 전체 `flutter analyze`·`flutter test` 권장.
  2. 기능 worktree 4곳 main 동기화 후 각 FE 세션에 **`flutter pub get` + 앱 완전 재시작**(pubspec assets 변경 → hot reload 불가) 지시.
  3. 기능 PLAN Step 1.6 배포: §3.1 레슨 / §3.2 단어장 / §3.3 미션 / §3.4 실험실 의 **P0 를 13:00 마감**, P1 은 여유 시. 기능 세션은 캐릭터 코드 수정 금지(요청은 REQUESTS → char-lead).
  4. 각 세션이 스크린샷을 `docs/features/character/screenshots/apply_<기능>_<ID>.png` 에도 남기게 해 주세요 → char-lead 가 화면별 리뷰 후 여기(PM_SYNC)로 피드백(CHR-1.6.4.1).
  5. 공통(PM 화면: 홈·로그인)은 이번 스프린트 **제외 제안**(§3.5). 여유 있으면 홈 인사 1곳만 메인 PM 판단.
  6. 발표용 설계 포인트(참고): "표정 = AI 생성 PNG, 동작 = 코드" 분리 → 캐릭터 그림 교체 시 기능 코드 0줄 수정, 없는 표정은 idle+모션 자동 폴백.

