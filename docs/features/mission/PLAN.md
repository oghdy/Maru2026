# MSN — Mission Chat PLAN

- 세션: `mission-be`, `mission-fe` · worktree `/Users/hadohadopapi/Desktop/Maru-wt/mission` · 브랜치 `feat/mission`
- 서버 :8083 · DB `maru_mission` · 시뮬레이터 iPhone Air
- 범위: 미션 설정 → 대화(토끼 연기 🐰 / 거북이 채점 🐢, 병렬 호출) → 힌트 → 수료증 발급·목록 · OpenAI(gpt-4o) · prompts
- 발표 주장(맞춰야 할 것): "제한된 대화·명확한 목표", "3-Zone 판정", "잘한 것·틀린 것·다음 목표 피드백 + 클리어증", "병렬 비동기 1.5초대"
- 참고: 홈의 Mission Chat 진입 버튼·트로피 아이콘은 PM 소유.
- 동결: 10/1 15:00 · 우선순위 P0 > P1 > P2 · OpenAI 호출 비용 주의(테스트는 짧게)

## Phase 1 — 기능 수정

### Step 1.1 현황 점검
- [ ] MSN-1.1.1 [BE] P0 서버 기동, `/api/v1/mission-chat/{setup,chat,suggestion,clearance,clearances}` 실제 호출 → `API_CONTRACT.md` 에 현재 요청/응답 기록 (특히 turn 응답의 zone/상태 값 목록). `MissionChatControllerTest`·`MissionChatDtoTest` 결과 기록
- [ ] MSN-1.1.2 [FE] P0 설정 → 대화 → 수료증 → 목록 완주 점검, 새 문제는 태스크 추가

### Step 1.2 오류·상태 처리 (P0)
- [ ] MSN-1.2.1 [BE] P0 OpenAI 오류·타임아웃·JSON 파싱 실패 시 적절한 HTTP 오류 + 사용자용 메시지 (200+null 금지)
- [ ] MSN-1.2.2 [FE] P0 대화 중 오류 → 채팅에 오류 표시 + 재전송 버튼 (실사 §2-C, `mission_chat_provider.dart:139-144`, `mission_chat_screen.dart`)
- [ ] MSN-1.2.3 [FE] P0 `failed` 상태 처리 분기 추가 (실사 §2-A)
- [ ] MSN-1.2.4 [FE] P1 응답 대기 중 상대 "typing…" 버블, 설정 로딩 문구 "Getting ready to transform..." → 기능에 맞게 (실사 §8-P1#14,16, `mission_setup_screen.dart:79`, `mission_chat_screen.dart:363-370`)

### Step 1.3 판정·수료증 정직화 (발표 "명확한 목표" 사실화)
- [ ] MSN-1.3.1 [BE] P0 수료증 결과를 실제 판정으로: `clearance_system.txt` 의 `"result": "클리어"` 고정 제거 → 목표 달성 여부에 따라 cleared / not cleared(재도전 권유), 피드백(잘한 표현·고칠 표현·다음 목표)은 항상 제공 (실사 §3-C, §8-P1#17)
- [ ] MSN-1.3.2 [BE+FE 조율] P0 발급 트리거: FE 가 `minTurns + 2` 도달 시 무조건 발급 요청하는 로직(`mission_chat_provider.dart:127-137`) → 거북이 판정(목표 달성 zone) 기반 종료 + 최대 턴 도달 시 종료. 규칙을 API_CONTRACT 에 먼저 합의 후 구현
- [ ] MSN-1.3.3 [FE] P0 수료증 화면·목록이 cleared/not cleared 를 구분해 표시
- [ ] MSN-1.3.4 [BE] P2 미사용 `prompts/chat_turn_system.txt` 정리

### Step 1.4 UX 정리 (P1)
- [ ] MSN-1.4.1 [FE] P1 `teal` 하드코딩 → theme 색, 한국어/영어 문구 혼용 정리
- [ ] MSN-1.4.2 [FE] P1 수료증 목록 빈 상태·오류 상태
- [ ] MSN-1.4.3 [BE] P2 병렬 호출 응답시간 측정 로그(발표 "1.5초대" 근거) — 요청당 소요 ms 를 INFO 로 (내용·키 제외)
