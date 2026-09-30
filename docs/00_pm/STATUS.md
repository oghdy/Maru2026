# STATUS — 세션 상태판

> 각 세션은 **자기 줄만** 갱신한다 (태스크 시작/완료/막힘 때마다). 시각은 24h.
> 상태: 🟢 진행중 · 🟡 대기/확인 필요 · 🔴 막힘 · ✅ 완료 · ⚪ 미시작

| 세션 | 상태 | 현재 태스크 | 마지막 커밋 | 갱신 | 메모 (짝 세션/PM 에게) |
|---|---|---|---|---|---|
| pm | 🟢 | 머지 4차 완료 · 캐릭터 팀 킥오프(Step 1.6) | 49af250 | 09-30 20:45 | 기능 세션 전원 대기. PM_HANDOFF·PM_SYNC 신설 |
| lesson-be | ✅ | LSN-1.5.1 서버 TTS 완료 | 5bab74c | 09-30 19:56 | 서버 :8081 가동(19:50 재시작, main 동기화+TTS). **lesson-fe → `GET /api/tts?text=` 준비됨** (인증, mp3, 200자, 오류 JSON 4xx/5xx → 폴백). API_CONTRACT 1-4. 목소리 ash — 짧은 낱말 음질은 사람 귀 확인 필요(LOG_be) |
| lesson-fe | 🟢 | TtsHelper 완료 | 75009e9 | 09-30 19:47 | TtsHelper 완료 — TtsHelper.speak(text): /api/tts 서버 음성 → 실패 시 flutter_tts. just_audio 추가. lesson 호출부만 교체(vocab·lab 미수정). 1.5.3 ✅ |
| vocab-be | 🟡 | 대기 (main 동기화 후 재시작) | 288c58d | 09-30 20:06 | 서버 :8082 가동 — HEAD 53ab930 기준. 19:41 기동 후 외부 SIGTERM 으로 종료돼 20:06 재기동, 200 확인. 추가 작업 없음, 대기 |
| vocab-fe | ✅ | R2 전부 완료 (1.5.1·1.5.2·1.5.3) | 3fe6d12 | 09-30 20:09 | 1.5.3: 코드 변경 없음, 서버 TTS 확인 — 오늘의 복습(용)·단어 카드(모자) 탭 → maru_vocab tts_cache 행 생성, 기기 폴백 0건. pub get 이 macos GeneratedPluginRegistrant.swift 수정(PM 소유, 미커밋) |
| mission-be | ✅ | [BE] 전부 완료 (1.2.6·1.3.5 포함) | 326c19b | 09-30 19:43 | 서버 :8083 가동 (09-30 19:43 최신 main 으로 재시작). mission-fe: "null" 문자열 서버 정규화, resultReason "You…" |
| mission-fe | ✅ | [FE] 태스크 전부 완료 (P0·P1) — 대기 | ece6742 | 09-30 22:15 | push 안 함. mission-be: PLAN 에 [BE] MSN-1.2.6("null" 문자열)·1.3.5(resultReason 2인칭) 추가해둠 |
| lab-be | 🟡 | 대기 (BE 태스크 전부 완료) | b1069ea | 09-30 20:08 | 서버 :8084 가동 — 20:06 다른 세션이 재시작(main 53ab930 기준, lab worktree), 400 응답 확인. 추가 작업 대기 |
| lab-fe | ✅ | R2: LAB-1.5.1·1.5.2·1.5.3 완료 | fbae653 | 09-30 20:12 | :8084 lab-fe 가 재시작(/api/tts 포함). tts_cache 행 생성 확인(하, 강아지가 안 뛰어요.) |
| char-lead | ⚪ | - | - | - | worktree Maru-wt/character · iPhone 16 Plus · 서버 불필요 |
| char-dev | ⚪ | - | - | - | char-lead 지시로 시작 · iPhone 16 Plus |
| char-asset | ⚪ | - | - | - | char-lead 지시로 시작 |
