# INTEGRATION LOG — 머지·배포 기록 (PM)

| 시각 | 작업 | 대상 | 결과 | 비고 |
|---|---|---|---|---|
| 09-30 | 베이스라인 | main | - | P0 공통 기반 + 작업 체계 |
| 09-30 22:10 | 머지 1차 | feat/lesson(+PM 위임), feat/vocab, feat/mission(중간), feat/lab(중간) → main | ✅ 충돌 0 | 로컬 maru 백업 후 패치 6개 적용. BE test 107/107, flutter analyze 0, flutter test 11/11 |
| 09-30 23:00 | 머지 2차 | feat/mission, feat/lab (FE 완료분) → main | ✅ 충돌 0 | BE 107/107, analyze 0, FE test 12/12 |
| 09-30 23:05 | Railway 점검 | Postgres 백업(pg_dump) + 읽기전용 조회 | ⚠ | 스키마만 있고 데이터 0건 → Phase 3 를 데이터 이관으로 변경 |
| 09-30 ~20:10 | 머지 3차 (R2) | feat/lesson(TTS API·TtsHelper·카드 네비), feat/vocab(리디자인·매치), feat/mission(1.2.6·1.3.5), feat/lab(1.5.1·1.5.2) → main, 4개 worktree 동기화 | ✅ 충돌 0 | BE 120/120, analyze 0, flutter test 전부 통과. ⚠ 이전 행의 22:10/23:00 은 오기(실제 ~19:00대) |
| 10-01 00:18 | 머지 5차 | feat/character(bf572dc, 28파일) → main, 5개 worktree 동기화 | ✅ 충돌 0 | flutter analyze 0, flutter test 31(+2 skip) |
| 10-01 01:04 | 머지 6차 | feat/lesson·vocab·mission·lab (캐릭터 적용 Step 1.6 + 홈 인사) → main, 5 worktree 동기화 | ✅ 충돌 0 | analyze 0, flutter test 31(+2 skip). char-lead 리뷰 21/21 |
| 10-01 11:57 | 머지 7차 | feat/lab (LAB-1.6.5 어절 줄바꿈) → main | ✅ | analyze 0, flutter test 33(+2 skip). 캐릭터 R-004(add2fbb)는 char-lead 검수 대기 |
| 10-01 12:02 | 머지 8차 | feat/character (R-004 첫 표시 빈칸 수정 add2fbb) → main | ✅ | Phase 1 기능 작업 전부 main 반영 완료 |
| 10-01 12:43 | 머지 9차 | feat/lesson (R3: LSN-1.7.1 정답 라벨 제거, PM-1.7.2 홈 복습 카드) → main | ✅ | analyze 0, flutter test 38(+2 skip). mission 은 fe/fe2 완료 후 일괄 |
| 10-01 19:52 | 머지 10차 | feat/character (MaruMood.magic·rabbit_magic) → main, mission·character 동기화 | ✅ | analyze 0, flutter test 47(+2 skip) |
| 10-01 20:07 | 머지 11차 | feat/mission (R3 전체: be 1.7.1 · fe 1.7.2~6 · fe2 1.7.7~9) → main, 5 worktree 동기화 | ✅ 충돌 0 | BE 123/123, analyze 0, flutter test 67(+2 skip). **R3 전부 main 반영** |
| 10-01 20:12 | 머지 12차 | feat/mission (fe2 디자인 토큰 정렬 491dc4b) → main | ✅ | char-lead S-009 리뷰 합격. 하도윤 최종 점검 단계 |
| 10-01 20:37 | **배포** | main(675c8fb) → GitHub → Railway Maru2026 | ✅ | 새 버전 ~130s. Railway DB 백업 후 콘텐츠 5테이블 이관(카운트 로컬과 일치), 시퀀스 OK, 스모크 OK |
