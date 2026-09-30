# STATUS — 세션 상태판

> 각 세션은 **자기 줄만** 갱신한다 (태스크 시작/완료/막힘 때마다). 시각은 24h.
> 상태: 🟢 진행중 · 🟡 대기/확인 필요 · 🔴 막힘 · ✅ 완료 · ⚪ 미시작

| 세션 | 상태 | 현재 태스크 | 마지막 커밋 | 갱신 | 메모 (짝 세션/PM 에게) |
|---|---|---|---|---|---|
| pm | 🟢 | PM-2.1 머지 1차 완료 → mission-fe·lab-fe 완료 대기 | ba17273 | 09-30 22:15 | 4개 브랜치 main 머지(충돌 0), BE 107/107·FE analyze 0·test 11/11. mission-fe·lab-fe: 끝나면 STATUS ✅ 로 알려주면 2차 머지 |
| lesson-be | ✅ | PM 위임 Step 1.P [BE] 4개 완료 | e67ea48 | 09-30 21:22 | 서버 :8081 가동(21:20 재시작). 전체 test: feat/lesson 에선 VOC/MSN 테스트 컴파일 오류(머지 후 해소), 제외 시 vocab 3개만 실패(LOG_be). lesson-fe: 로그인 실패는 이제 HTTP 401/400/500 (PM-1.P.1f) |
| lesson-fe | 🟢 | PM 위임 Step 1.P [FE] 전부 ✅ | 0f8c579 | 09-30 18:31 | LSN [FE] + PM 위임 FE(1.P.11·1f·2·4·3·6·9) 전부 완료. PM 확인: iOS 구글 serverClientId, 슬로건 문구, 전역 재시도 끔(LOG_fe) |
| vocab-be | ✅ | [BE] 태스크 전부 완료 (1.1~1.4) | 288c58d | 09-30 17:48 | 서버 :8082 가동(17:45 재시작, 최종). vocab 테스트 29/29. 스키마·데이터 변경 없음. vocab-fe: API_CONTRACT §1 최신(isCompleted·studiedWords·totalWords·nextIntervals·review 결과). PM: R-002, 발표 문구 메모는 LOG_be HANDOFF |
| vocab-fe | ✅ | [FE] 태스크 전부 완료 (1.1~1.4) | c477e51 | 09-30 18:03 | iPhone 17 / :8082. P0: 1.2.1·1.2.2·1.2.4·1.2.12(평가가 다른 단어로 저장되던 버그) 포함 전부 ✅, analyze 0건. push 안 함. PM: R-003 확인 부탁. 커밋 태그 오타 22fdf6d [VOC-1.210]=1.2.10 |
| mission-be | ✅ | [BE] 태스크 전부 완료 (1.3.2 FE 부분 대기) | e92129f | 09-30 17:45 | 서버 :8083 가동 (17:45 재시작). mission-fe: API_CONTRACT §1-6 오류, §1-7 판정·종료 반영됨. PM: 패치 msn_001, 발표 "1.5초대" → 실측 1.5~2.2s(LOG_be) |
| mission-fe | 🟢 | FE P0 전부 ✅ → P1 1.2.4 시작 | 82c39d4 | 09-30 21:50 | 1.3.2/1.3.3 §1-7 반영 완료. mission-be: resultReason 3인칭("The student…") → 2인칭 부탁 (LOG_fe HANDOFF) |
| lab-be | ✅ | [BE] 태스크 전부 완료 (1.1.1·1.2.1~3·1.3.4), 1.4.2 QA 지시 대기 | b1069ea | 09-30 18:33 | 서버 :8084 가동 (18:31 재시작, 최종). lab 테스트 20/20. lab-fe: API_CONTRACT §1-5 오류표. PM: 패치 lab_001, 발표 수치(HIT 1~2ms/MISS 3~5s) LOG_be HANDOFF |
| lab-fe | 🟢 | P0 완료(1.1.2·1.2.4·1.2.5) → Step 1.3 P1 진행 | b6bf419 | 09-30 18:30 | iPhone 16 Pro. 서버 400/502/503/504 message 그대로 표시 |
