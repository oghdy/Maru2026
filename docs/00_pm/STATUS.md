# STATUS — 세션 상태판

> 각 세션은 **자기 줄만** 갱신한다 (태스크 시작/완료/막힘 때마다). 시각은 24h.
> 상태: 🟢 진행중 · 🟡 대기/확인 필요 · 🔴 막힘 · ✅ 완료 · ⚪ 미시작

| 세션 | 상태 | 현재 태스크 | 마지막 커밋 | 갱신 | 메모 (짝 세션/PM 에게) |
|---|---|---|---|---|---|
| pm | 🟢 | 머지 3차 완료 → LAB-1.5.3·VOC-1.5.3 후 사용자 확인 → Railway 배포 | - | 09-30 20:10 | 4 worktree main 동기화 완료. lab-fe: LAB-1.5.3 진행. vocab-fe: VOC-1.5.3 확인만(코드 교체 불필요) |
| lesson-be | ✅ | LSN-1.5.1 서버 TTS 완료 | 5bab74c | 09-30 19:56 | 서버 :8081 가동(19:50 재시작, main 동기화+TTS). **lesson-fe → `GET /api/tts?text=` 준비됨** (인증, mp3, 200자, 오류 JSON 4xx/5xx → 폴백). API_CONTRACT 1-4. 목소리 ash — 짧은 낱말 음질은 사람 귀 확인 필요(LOG_be) |
| lesson-fe | 🟢 | TtsHelper 완료 | 75009e9 | 09-30 19:47 | TtsHelper 완료 — TtsHelper.speak(text): /api/tts 서버 음성 → 실패 시 flutter_tts. just_audio 추가. lesson 호출부만 교체(vocab·lab 미수정). 1.5.3 ✅ |
| vocab-be | 🟡 | 대기 (main 동기화 후 재시작) | 288c58d | 09-30 19:41 | 서버 :8082 가동 — 최신 main(859e25a) 기준 19:41 재시작, 전 엔드포인트 200 확인. 추가 작업 없음, 대기 |
| vocab-fe | ✅ | R2: VOC-1.5.1 리디자인·1.5.2 Match 애니메이션 완료 | 3fe6d12 | 09-30 20:00 | iPhone 17 / :8082. 전후 스크린샷 docs/features/vocab/screenshots/r2/ (LOG_fe 참고). 1.5.3(TTS)은 PM 신호 대기. 60fps: debug 97% 프레임 16.7ms 이내, release 는 시뮬레이터 불가로 미확인 |
| mission-be | ✅ | [BE] 전부 완료 (1.2.6·1.3.5 포함) | 326c19b | 09-30 19:43 | 서버 :8083 가동 (09-30 19:43 최신 main 으로 재시작). mission-fe: "null" 문자열 서버 정규화, resultReason "You…" |
| mission-fe | ✅ | [FE] 태스크 전부 완료 (P0·P1) — 대기 | ece6742 | 09-30 22:15 | push 안 함. mission-be: PLAN 에 [BE] MSN-1.2.6("null" 문자열)·1.3.5(resultReason 2인칭) 추가해둠 |
| lab-be | 🟡 | 대기 (BE 태스크 전부 완료) | b1069ea | 09-30 19:41 | 서버 :8084 가동 — 19:41 최신 main(859e25a) 동기화 후 재시작, HIT·400 확인. 추가 작업 대기 |
| lab-fe | ✅ | R2: LAB-1.5.1·1.5.2 완료, 1.5.3(TTS) PM 신호 대기 | 1e3c7f3 | 09-30 19:55 | iPhone 16 Pro. test/features/lab 3/3 |
