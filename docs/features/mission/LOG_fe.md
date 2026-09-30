# MSN — Mission Chat — FE 세션 로그 (`mission-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음. **Step 1.6 캐릭터 적용 C1~C8 전부 완료** (P0 12:34, P1 12:40). 마지막 ad0cbcb
- 다음 할 일: 대기. char-lead 리뷰 피드백·PM 통합 요청 오면 처리
- 막힌 것 / 기다리는 것: 없음. REQUESTS 없음(캐릭터 코드 문제 발견 안 됨)
- 실행 중인 것: BE :8083 (이 세션이 scripts/run_backend.sh mission 으로 띄움 — mission-be 가 없어서), 테스트 프록시 :8093(플래그 전부 제거 = 그대로 통과), 앱 `flutter run -d FE45C935-… --dart-define=API_PORT=8093`
- 시뮬레이터 팁: 제안 시트는 로딩 중 짧아서 그때 카드 위치를 탭하면 바깥(배리어)이라 닫힘 → 시트 결과가 뜬 걸 확인하고 탭. simctl 스크린샷(`xcrun simctl io <UDID> screenshot`)은 지연 없음
- 마지막 커밋: ad0cbcb
- 짝 세션에게: 없음

## 기록 (시간순 추가만, 수정 금지)

### 09-30 19:40 · MSN-1.1.2 코드 점검 (시뮬레이터 확인 전)
- 흐름 코드 읽기: 설정 → 대화 → 수료증 → 목록. 새 문제 5건 → PLAN 1.1.4~1.1.8 추가.
- 1.1.4(history 중복)는 API_CONTRACT 1-2 확인 결과 BE MSN-1.2.5 담당 → FE 는 계약대로 유지(처음엔 FE 에서 제외했다가 되돌림). 1.2.2/1.2.3/1.1.5 구현: provider 에서 `error` 상태 제거(오류는 errorMessage+failedAction 로), 전송 실패 메시지에 Retry, 수료증 발급 실패 배너+Retry, 설정 실패 스낵바+Retry, `failed` → "Mission not completed" 배너(See Feedback / New Mission), 사용자 문구는 예외 원문 대신 영어 안내문(`missionErrorMessage`).
- `flutter analyze lib/features/mission_chat`: 새 경고 없음(기존 3건: list_screen state 대입 2 → 1.1.8, clearance_screen withOpacity 1 → 1.3.3 때 정리).
- 시뮬레이터: **미확인** (도구 접근 권한 대기).

### 09-30 21:25 · MSN-1.1.2 / 1.1.5 / 1.2.2 / 1.2.3 완료 — fd58a75
- 시뮬레이터(iPhone Air, 프록시 :8093 경유)에서 확인:
  - 설정 → 대화: 정상 (미션 생성 ~7s, 턴 ~3s, 힌트 시트 정상)
  - 설정 실패(프록시 끔): 처음엔 스낵바+Retry 였으나 4초 후 사라져 Retry 를 못 누름 → 폼 안 **고정 오류 카드 + Retry** 로 변경. Retry → 미션 생성 성공 확인
  - 전송 실패: 내 문장 흐리게 + "Couldn't send · Retry" + 상단 오류 배너(닫기). Retry → 정상 답변, 배너 사라짐
  - `failed`(프록시로 missionStatus 강제): "Mission not completed" 배너, 입력·힌트 비활성, New Mission / See Feedback
  - 수료증 발급 실패(프록시 500): "Couldn't create your feedback report…" + Retry, 대화 유지. Retry → 수료증 화면
  - 수료증 목록: 방금 발급한 수료증 바로 보임(invalidate 동작)
  - 즉시교정(프록시로 severity=immediate): 문장 흐리게 + "🐢 Not sent — try saying it again", 다음 요청 history 에서 제외됨(flutter 로그의 요청 본문으로 확인)
- 확인된 남은 문제: 수료증 화면이 failed 여도 "Mission Cleared! 🎉 / Cleared" (→1.3.3), 즉시교정 배너 코드값 노출·종료 후 전송 아이콘 색(→1.4.1에 추가)
- analyze: 새 경고 없음 (기존 3건 유지: list_screen 2 → 1.1.8, clearance_screen withOpacity 1)

### 09-30 21:50 · MSN-1.3.2(FE) / 1.3.3 / 1.1.6 / 1.1.8 / 1.4.2 — fac4381, 82c39d4
- API_CONTRACT §1-7(BE 구현 완료) 기준으로 구현. /chat 새 필드(userTurn·maxTurns·zone), /clearance 새 필드(cleared·resultReason·goalCondition) 사용.
- 시뮬레이터 확인(프록시로 상태 강제, 판정은 실제 BE):
  - failed 턴 → 입력 잠김, "Mission not completed. Preparing your feedback..." → 결과 화면 "Mission Result / MISSION REPORT / Not cleared yet — try again" + 실제 BE 판정 이유·목표, 빈 교정 목록 문구, 'Try This Mission Again' → 같은 미션 Turn 0/10 으로 재시작
  - cleared(+force_cleared=true) → "Mission Cleared! 🎉 / CERTIFICATE OF COMPLETION", 금색 테두리
  - 미션 카드 "Turn n/max" 표시 (setup 직후 0/10, 한 턴 후 1/10)
  - 목록: Not cleared/Cleared/Completed 배지, 항목 → 결과 화면 → 뒤로 = 목록으로 복귀(전엔 홈으로)
  - 목록 오류(force_500 /clearances): 처음엔 Riverpod 3 자동 재시도로 ~10회 스피너 → retry 끔(82c39d4) → 즉시 오류+Retry, Retry 로 복구. 오류 문구는 계약 §1-6 대로 서버 message 사용
- 미확인: 목록 당겨서 새로고침 제스처 자체(오류 테스트 중 스피너만 봄), 목록 빈 상태(이 계정은 수료증 있음), 실제 LLM 이 cleared 를 주는 긴 대화(비용상 프록시로 대체)
- analyze: No issues found

### 09-30 22:15 · MSN-1.2.4 / 1.1.7 / 1.4.1 — f4e66c8, 0f3ece2, ece6742
- 1.2.4: 응답 대기 중 🐰 ••• 버블(프록시 delay 로 확인), 설정 로딩 "Creating your mission..." + 설명문 (확인)
- 1.1.7: 힌트 시트를 한 개로(로딩/오류+Retry/결과). 로딩 중 바깥 탭으로 닫고 응답 도착 → 채팅 화면 유지 확인(예전엔 pop 됨). 시트 오류(force_500 /suggestion) → Retry → 제안 표시, 제안 탭 → 입력칸 채움+시트만 닫힘 확인. 중간에 `setState(() => _future = …)` 가 Future 반환 assertion → 블록으로 수정
- 1.4.1: teal/grey → colorScheme (설정 버튼·말풍선·미션카드 보라 계열 확인), 즉시교정 배너 "(Politeness level)", 대화 종료 시 전송 아이콘 회색, 배너 생길 때 마지막 메시지가 가려지던 문제 → 상태 변화 시 자동 스크롤(확인)
- 발견: BE 가 correction 필드를 문자열 "null" 로 보내는 경우 있음 → 화면에 "null" 노출됐음. FE 방어(_text) 추가 + PLAN MSN-1.2.6 [BE] 추가. resultReason 3인칭 → MSN-1.3.5 [BE] 추가
- analyze: No issues found
- 미확인(전 기간): 실제 LLM 이 cleared 를 주는 긴 대화(프록시로 대체), 목록 빈 상태, 다크모드

### 10-01 12:45 · MSN-1.6.1~1.6.8 캐릭터 적용 — 763a5ca, 8a94d90, b93560a, 58b7f1d, c3b7d4b, ad0cbcb
- 명세 CHARACTER_API §3.0·§3.3 그대로. import 는 barrel 하나, 캐릭터 코드 수정 없음, 로직·상태 변경 없음(기존 상태에 mood 만 연결)
- pub get + 앱 완전 재실행 후 확인. 서버가 꺼져 있어 scripts/run_backend.sh mission 으로 직접 기동
- 이벤트를 프록시(:8093)로 강제해 시뮬레이터에서 직접 발생 → 스크린샷 docs/features/character/screenshots/apply_mission_C1~C8.png (+ C4_real_correction, C5_not_cleared, C6_tutor_note)
  - C1 상대 아바타 rabbit idle 40 / C2 입력 중 rabbit thinking 40 (지연 8s 중 캡처) / C3 side 교정 turtle idle 40
  - C4 즉시 교정 turtle thinking 48, reactionKey = 교정 객체(새 응답마다 새 객체). 실제 AI 교정(반말 지적)으로도 확인
  - C5 not cleared = 실제 BE 판정으로 sad rabbit + idle turtle / cleared = 프록시 강제로 cheer rabbit + happy turtle(entrance). 위 여백 28 + 아래 16, 고정 높이·Clip 없음
  - C6 판정 이유·Tutor's Note turtle idle 40 / C7 설정 로딩 rabbit thinking 120 (위 여백 30) / C8 실패 배너 turtle sad 40, 'Help me Turtle' 버튼·'🐢 Not sent' 이모지는 명세대로 유지
- analyze: No issues found
- 참고: BE 가 resultReason 을 이제 2인칭("You …")으로 줌(1.3.5 반영된 듯)
- 미확인: 애니메이션 자체(정지 스크린샷만), 접근성 reduce-motion

