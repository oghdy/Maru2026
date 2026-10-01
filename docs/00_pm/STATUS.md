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
| mission-fe | ✅ | Step 1.6 캐릭터 C1~C8 완료 (P0·P1) | ad0cbcb | 10-01 12:45 | 스크린샷 docs/features/character/screenshots/apply_mission_*.png. push 안 함. BE :8083 은 mission-fe 가 띄워둠 |
| lab-be | 🟡 | 대기 (BE 태스크 전부 완료) | b1069ea | 09-30 20:08 | 서버 :8084 가동 — 20:06 다른 세션이 재시작(main 53ab930 기준, lab worktree), 400 응답 확인. 추가 작업 대기 |
| lab-fe | ✅ | LAB-1.6.5 어절 줄바꿈 완료 (Step 1.6 전부 완료) | bbda55c | 10-01 13:10 | apply_lab_wrap.png. 복사·TTS 원문 확인 |
| char-lead | 🟢 | Step 1.7(R3) — 1.7.1 ✅ rabbit_magic 검수, API v1.2, 작업 세션 프롬프트 전달 | 9e6ffd8(main 머지) | 10-01 12:50 | 목표: magic 에셋 13:30, magic 모션 14:15 → S-008 재머지 요청. mission-fe2: magic 머지 전까지 thinking 유지 |
| char-dev | 🟡 | CHR-1.6.4.2 ✅ (R-004 첫 표시 빈칸) → **char-lead 검수 요청** | add2fbb | 10-01 01:18 | 테스트 23 통과. 재머지 전까지 lesson 의 precache 우회는 유지해도 무해. 갤러리 실행 중(토글 꺼짐) |
| char-asset | 🟢 | CHR-1.6.2.1 ✅ 14/14 반영 (rabbit 7 + turtle 7) | bf572dc | 10-01 00:07 | rabbit_blink bf572dc — char-dev R 필요 · 에셋 작업 완료 |
| mission-fe2 | 🟡 | 1.7.7·1.7.8·1.7.9 코드 완료(위젯테스트 15개 통과) — 시뮬레이터 확인 대기 | 337a365 | 10-01 13:20 | ⚠️ 시뮬레이터 부팅이 권한 분류기에 막혀 화면 미확인 → 사용자 허가 요청. magic 머지되면 setup_transform_loading.dart 상단 2줄 교체 예정(PM 알림 부탁). mission-fe: 내 화면 톤 = 흰 카드 r24·그림자 primary α.08·primary 그라데이션 히어로·pill(widgets/clearance_style.dart) — 채팅과 다르면 메모 주세요 |
