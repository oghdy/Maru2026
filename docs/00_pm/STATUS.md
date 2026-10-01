# STATUS — 세션 상태판

> 각 세션은 **자기 줄만** 갱신한다 (태스크 시작/완료/막힘 때마다). 시각은 24h.
> 상태: 🟢 진행중 · 🟡 대기/확인 필요 · 🔴 막힘 · ✅ 완료 · ⚪ 미시작

| 세션 | 상태 | 현재 태스크 | 마지막 커밋 | 갱신 | 메모 (짝 세션/PM 에게) |
|---|---|---|---|---|---|
| pm | 🟢 | R3 피드백 배포 (Step 1.7) | - | 10-01 12:40 | lesson-fe·mission-be(새)·mission-fe·mission-fe2(새)·char-lead 투입 |
| lesson-be | ✅ | LSN-1.5.1 서버 TTS 완료 | 5bab74c | 09-30 19:56 | 서버 :8081 가동(19:50 재시작, main 동기화+TTS). **lesson-fe → `GET /api/tts?text=` 준비됨** (인증, mp3, 200자, 오류 JSON 4xx/5xx → 폴백). API_CONTRACT 1-4. 목소리 ash — 짧은 낱말 음질은 사람 귀 확인 필요(LOG_be) |
| lesson-fe | ✅ | Step 1.7 피드백 R3 완료 | d2938f0 | 10-01 12:40 | LSN-1.7.1 ✅ 조립 라벨 정답 노출 제거 · PM-1.7.2 ✅ 홈 All caught up! 카드. 스크린샷 docs/features/lesson/screenshots/r3_* |
| vocab-be | 🟡 | 대기 (main 동기화 후 재시작) | 288c58d | 09-30 20:06 | 서버 :8082 가동 — HEAD 53ab930 기준. 19:41 기동 후 외부 SIGTERM 으로 종료돼 20:06 재기동, 200 확인. 추가 작업 없음, 대기 |
| vocab-fe | ✅ | Step 1.6 캐릭터 C1·C2(P0)·C3(P1) 완료 | ec29f38 | 10-01 00:32 | C1 05059bc / C2 da48b2c / C3 ec29f38. 스크린샷 character/screenshots/apply_vocab_*. 캐릭터 코드 이슈 없음. PM 홈 참고: 오늘의 복습을 뒤로가기로 나가면 배너 카운트 미갱신(0인데 "1 word") |
| mission-be | ✅ | MSN-1.7.1 완료 (수료증 인용 = 사용자 문장만, 서버 검증) | a186f8c | 10-01 12:35 | 서버 :8083 재시작(12:34). API 모양 변경 없음. 제안 문장 history 제외는 FE 1.7.2 |
| mission-fe | ✅ | R3 채팅 화면 1.7.2~1.7.6 전부 완료 | 1516ebe | 10-01 13:25 | push 안 함. 전후 스크린샷 docs/features/mission/screenshots/MSN-1.7.*. mission-fe2: 디자인 토큰은 LOG_fe HANDOFF '짝 세션에게' 참고 |
| lab-be | 🟡 | 대기 (BE 태스크 전부 완료) | b1069ea | 09-30 20:08 | 서버 :8084 가동 — 20:06 다른 세션이 재시작(main 53ab930 기준, lab worktree), 400 응답 확인. 추가 작업 대기 |
| lab-fe | ✅ | LAB-1.6.5 어절 줄바꿈 완료 (Step 1.6 전부 완료) | bbda55c | 10-01 13:10 | apply_lab_wrap.png. 복사·TTS 원문 확인 |
| char-lead | ✅ | R3 미션 적용 리뷰 합격(S-009) — 캐릭터 팀 버그 대기 | 3c31c5c | 10-01 20:10 | 필수 수정 0. 선택: 옛 C5 스크린샷(우는 토끼) 교체, 역할 입력 상태 로딩 캡처 |
| char-dev | 🟡 | CHR-1.7.3 ✅·1.7.5 ✅ → **char-lead 검수 요청** | 3c31c5c | 10-01 19:32 | **MaruMood.magic 사용 가능**(a594fb9, rabbit_magic PNG 반영 확인) — 재머지 후 mission-fe2 C7. 말풍선 자모 ▯ 없음. 테스트 32 통과. 갤러리 실행 중(토글 꺼짐) |
| char-asset | 🟢 | CHR-1.7.2 ✅ rabbit_magic 반영 (에셋 15장) | 0310daa | 10-01 19:20 | rabbit_magic 0310daa — char-dev R 필요 |
| mission-fe2 | ✅ | 1.7.7·1.7.8·1.7.9 전부 완료 — 채팅 토큰과 **일치**(차이 3곳 맞춤) | 491dc4b | 10-01 20:12 | 배경 alphaBlend·카드 surface r22·stadium 칩으로 맞춤, 제목 w800 은 원래 일치. 스크린샷 r3_fe2/14~16. push 안 함. 참고: 확인 끝난 뒤 iPhone 16 시뮬레이터가 꺼짐(Shutdown) → flutter run 종료, 추가 작업 없음 |
| dlv-design | ⚪ | - | - | - | 책자+포스터 · Maru-main docs/deliverables |
| dlv-talk | ⚪ | - | - | - | 발표자료+시연 대본 |
| dlv-report | ⚪ | - | - | - | 최종보고서 개정 |
