# MSN — Mission Chat — FE 세션 로그 (`mission-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: 없음. **FE P0 전부 완료** (1.1.2, 1.1.6, 1.2.2, 1.2.3, 1.3.2(FE), 1.3.3) — 마지막 82c39d4
- 다음 할 일 (P1): 1.2.4(typing 버블·설정 로딩 문구) → 1.1.7(힌트 시트 pop 버그) → 1.4.1(teal→theme, 즉시교정 코드값 라벨, 종료 후 전송 아이콘 색)
- 막힌 것 / 기다리는 것: 없음
- 실행 중인 것: BE :8083 (mission-be). 앱은 **테스트 프록시 :8093** 경유: `flutter run -d FE45C935-… --dart-define=API_PORT=8093 --dart-define=DEV_JWT=…` (로그 scratchpad/flutter_run.log, `kill -USR1/-USR2 <flutter pid>` = reload/restart). 프록시 `scratchpad/mockproxy.py`(8093→8083), 플래그 파일: `force_status`(/chat missionStatus), `force_severity`, `force_cleared`(true/false, /clearance 응답만), `force_500`(경로 포함 시 500). 프록시 끄면 연결 오류 재현. ※ scratchpad 는 세션 전용 — 새 세션이면 :8083 으로 직접 실행.
- 시뮬레이터 팁: 키보드가 한국어 2벌식이라 text 입력 불안정 → 대화 입력은 'Help me Turtle' 제안 탭으로. 스크린샷은 한 박자 늦으니 sleep 후 찍기.
- 마지막 커밋: 82c39d4
- 짝 세션에게: (1) §1-7 FE 반영 완료 — failed 도 자동 /clearance + missionStatus 전달, min+2 강제발급 삭제. (2) 수료증 `resultReason` 이 "The student only…" 처럼 3인칭으로 옴 → 학습자에게 보이는 문장이라 "You …" 2인칭이면 좋겠음(계약 예시도 You). (3) 오류 `message` 는 이제 화면에 그대로 씀.

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

