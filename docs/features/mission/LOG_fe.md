# MSN — Mission Chat — FE 세션 로그 (`mission-fe`)

## ▶ HANDOFF (항상 최신 상태로 덮어쓰기 — 컨텍스트 요약 후 여기부터 읽는다)
- 현재 태스크: MSN-1.1.2 완주 점검 + MSN-1.2.2/1.2.3/1.1.4/1.1.5 구현 완료(미커밋, analyze 통과) → 시뮬레이터 확인 대기
- 다음 할 일: 시뮬레이터에서 설정→대화→오류(서버 끊고 재전송)→수료증→목록 확인 후 커밋. 이후 1.1.6, 1.2.4, 1.1.7, 1.3.x
- 막힌 것 / 기다리는 것: iOS Simulator 도구의 iPhone Air 접근 권한(사용자 승인 필요)
- 실행 중인 것: BE :8083 (mission-be 가 띄움), `flutter run -d FE45C935-… --dart-define=API_PORT=8083 --dart-define=DEV_JWT=…` (로그: 세션 scratchpad/flutter_run.log, 재시작은 flutter 프로세스에 `kill -USR2`)
- 마지막 커밋: -
- 짝 세션에게: history 는 계약(1-2)대로 이번 userMessage 포함 전송 유지 — 중복은 BE MSN-1.2.5 에서 처리해줘. 단, immediate 교정으로 막힌 문장·전송 실패 문장은 이제 history 에서 **제외**됨(턴 수에도 안 셈).

## 기록 (시간순 추가만, 수정 금지)

### 09-30 19:40 · MSN-1.1.2 코드 점검 (시뮬레이터 확인 전)
- 흐름 코드 읽기: 설정 → 대화 → 수료증 → 목록. 새 문제 5건 → PLAN 1.1.4~1.1.8 추가.
- 1.1.4(history 중복)는 API_CONTRACT 1-2 확인 결과 BE MSN-1.2.5 담당 → FE 는 계약대로 유지(처음엔 FE 에서 제외했다가 되돌림). 1.2.2/1.2.3/1.1.5 구현: provider 에서 `error` 상태 제거(오류는 errorMessage+failedAction 로), 전송 실패 메시지에 Retry, 수료증 발급 실패 배너+Retry, 설정 실패 스낵바+Retry, `failed` → "Mission not completed" 배너(See Feedback / New Mission), 사용자 문구는 예외 원문 대신 영어 안내문(`missionErrorMessage`).
- `flutter analyze lib/features/mission_chat`: 새 경고 없음(기존 3건: list_screen state 대입 2 → 1.1.8, clearance_screen withOpacity 1 → 1.3.3 때 정리).
- 시뮬레이터: **미확인** (도구 접근 권한 대기).

