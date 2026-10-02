# STATUS — 세션 상태판

> 각 세션은 **자기 줄만** 갱신한다 (태스크 시작/완료/막힘 때마다). 시각은 24h.
> 상태: 🟢 진행중 · 🟡 대기/확인 필요 · 🔴 막힘 · ✅ 완료 · ⚪ 미시작

| 세션 | 상태 | 현재 태스크 | 마지막 커밋 | 갱신 | 메모 (짝 세션/PM 에게) |
|---|---|---|---|---|---|
| pm | 🟢 | R3 피드백 배포 (Step 1.7) | - | 10-01 12:40 | lesson-fe·mission-be(새)·mission-fe·mission-fe2(새)·char-lead 투입 |
| lesson-be | ✅ | LSN-1.5.1 서버 TTS 완료 | 5bab74c | 09-30 19:56 | 서버 :8081 가동(19:50 재시작, main 동기화+TTS). **lesson-fe → `GET /api/tts?text=` 준비됨** (인증, mp3, 200자, 오류 JSON 4xx/5xx → 폴백). API_CONTRACT 1-4. 목소리 ash — 짧은 낱말 음질은 사람 귀 확인 필요(LOG_be) |
| lesson-fe | ✅ | Step 1.8 PM-1.8.1 홈 카드 완료 | fd583ea | 10-02 17:02 | PM-1.8.1 ✅ 홈 4개 카드 파스텔(명도·채도 통일)+설명 한 줄+높이 축소. 스크린샷 docs/features/lesson/screenshots/r4_PM-1.8.1_before/after.png. 앱·시뮬레이터·서버 :8081 종료함 |
| vocab-be | 🟡 | 대기 (main 동기화 후 재시작) | 288c58d | 09-30 20:06 | 서버 :8082 가동 — HEAD 53ab930 기준. 19:41 기동 후 외부 SIGTERM 으로 종료돼 20:06 재기동, 200 확인. 추가 작업 없음, 대기 |
| vocab-fe | ✅ | Step 1.6 캐릭터 C1·C2(P0)·C3(P1) 완료 | ec29f38 | 10-01 00:32 | C1 05059bc / C2 da48b2c / C3 ec29f38. 스크린샷 character/screenshots/apply_vocab_*. 캐릭터 코드 이슈 없음. PM 홈 참고: 오늘의 복습을 뒤로가기로 나가면 배너 카운트 미갱신(0인데 "1 word") |
| mission-be | ✅ | MSN-1.8.1~1.8.3 완료 (난이도 easy/normal/hard, 기본 easy) | 6d7cd6d | 10-02 17:05 | **서버 :8083 반영·켜 둠(17:02 재시작)**. mission-fe2: API_CONTRACT §1-8 — /setup 에 difficulty 전송, 응답 setup.difficulty 보존해 /chat·/suggestion·/clearance 로 전달, /clearance 응답 difficulty. 난이도별 실제 예시 LOG_be |
| mission-fe | ✅ | R3 채팅 화면 1.7.2~1.7.6 전부 완료 | 1516ebe | 10-01 13:25 | push 안 함. 전후 스크린샷 docs/features/mission/screenshots/MSN-1.7.*. mission-fe2: 디자인 토큰은 LOG_fe HANDOFF '짝 세션에게' 참고 |
| lab-be | 🟡 | 대기 (BE 태스크 전부 완료) | b1069ea | 09-30 20:08 | 서버 :8084 가동 — 20:06 다른 세션이 재시작(main 53ab930 기준, lab worktree), 400 응답 확인. 추가 작업 대기 |
| lab-fe | ✅ | LAB-1.8.1 그래머랩 입력 재설계 + 1.8.2 거북이 실험 로딩 완료 (Step 1.8 전부 완료) | 61873e8 | 10-02 17:06 | screenshots/r4/ before·after. 서버·시뮬레이터 종료 |
| char-lead | ✅ | R3 미션 적용 리뷰 합격(S-009) — 캐릭터 팀 버그 대기 | 3c31c5c | 10-01 20:10 | 필수 수정 0. 선택: 옛 C5 스크린샷(우는 토끼) 교체, 역할 입력 상태 로딩 캡처 |
| char-dev | 🟡 | CHR-1.7.3 ✅·1.7.5 ✅ → **char-lead 검수 요청** | 3c31c5c | 10-01 19:32 | **MaruMood.magic 사용 가능**(a594fb9, rabbit_magic PNG 반영 확인) — 재머지 후 mission-fe2 C7. 말풍선 자모 ▯ 없음. 테스트 32 통과. 갤러리 실행 중(토글 꺼짐) |
| char-asset | 🟢 | CHR-1.7.2 ✅ rabbit_magic 반영 (에셋 15장) | 0310daa | 10-01 19:20 | rabbit_magic 0310daa — char-dev R 필요 |
| mission-fe2 | ✅ | R4 MSN-1.8.4·1.8.5 완료 + Easy 실기 확인 | c4b4266 | 10-02 17:25 | 토끼 답 1문장("물컵 필요하세요?")·힌트 짧음, 배지 채팅·리포트·목록 확인, /chat·/suggestion 에 difficulty 전달(로그). 추가 수정 없음. 스크린샷 screenshots/r4_fe2/1~7. push 안 함 |
| dlv-design | 🟡 | DLV-4.1.2·4.2.2 ✅ → 4.2.3 대기(QR URL·최종 스크린샷) | - (커밋 안 함) | 10-01 22:35 | 책자 7장·포스터(시안 B) pptx+PDF+PNG, 안내 `deliverables/book/README.md`. **PM 확인**: 테스트 수치 123·67 사용(CLAIMS 는 107·11). PowerPoint 를 dlv-talk 와 같이 씀 — 내 변환 스크립트는 파일 이름으로만 문서 지정 |
| dlv-talk | ✅ | DLV-4.3.1 발표 슬라이드 완료 (talk/OUTLINE·MARU_발표.pptx·NOTES·preview) | - (커밋 금지) | 10-01 22:45 | 16장·슬라이드 3분38초 + 시연 5~6분 자리(12장 DEMO). PM: CLAIMS 테스트 수치 107·11 → 123·67 갱신 요청. 지도교수 한경수 교수 표지 반영 |
| dlv-report | ✅ | DLV-4.4.1 보고서 개정판 완료 → PM 검수 대기 | - (커밋 안 함) | 10-01 22:48 | report/MARU_최종보고서_2학기.docx·.pdf(77쪽), OUTLINE.md. 확인 필요 4건(OUTLINE 하단: 과목명·통계 출처·피드백 1차 정의·테스트 수치). 5.7 그림은 features/*/screenshots 사용 — 촬영본 오면 교체 |
