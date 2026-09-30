# LSN — Korean Lesson PLAN

- 세션: `lesson-be`, `lesson-fe` · worktree `/Users/hadohadopapi/Desktop/Maru-wt/lesson` · 브랜치 `feat/lesson`
- 서버 :8081 · DB `maru_lesson` · 시뮬레이터 iPhone 17 Pro
- 범위: Unit 0(한글 12레슨) · Unit 1(문법 2레슨, 형태소 조립) · 진행/완료 저장 · Kiwi 콘텐츠 파이프라인
- 발표 주장(맞춰야 할 것): "🐰 의미 덩어리 → 🐢 해당 레슨의 핵심 조사만 분해", "CSV 한 줄로 새 퀴즈", "Tap-to-Translate 형태소 분석"
- 동결: 10/1 15:00 · 우선순위 P0 > P1 > P2

## Phase 1 — 기능 수정

### Step 1.1 현황 점검
- [ ] LSN-1.1.1 [BE] P0 서버 기동, `GET /api/units/{0,1,2,3}/lessons`·`POST /api/progress/lessons/{id}` 실제 응답 확인 → `API_CONTRACT.md` 에 **현재** 레슨 JSON 구조(step_type 별 content 필드) 기록. `LessonControllerTest` 기존 실패 원인 파악
- [ ] LSN-1.1.2 [FE] P0 Unit 0 레슨 2개 + Unit 1 두 레슨 완주하며 화면 점검. 실사에 없는 문제는 이 PLAN 에 태스크 추가

### Step 1.2 P0 하드코딩·버그 (앱)
- [ ] LSN-1.2.1 [FE] P0 완료 화면 "Basic Vowels Mastered!" 고정 → content 의 `text`/`highlights` 사용 (실사 §8-P0#1, `completion_step_widget.dart:41,67`)
- [ ] LSN-1.2.2 [FE] P0 단계 `title`/`instruction` 화면 표시 (실사 §8-P0#4, `StepModel`)
- [ ] LSN-1.2.3 [FE] P0 한글 소개 카드 고정 설명("Open your mouth wide", "basic vowel") 제거 → 데이터 필드 사용, 없으면 자음/모음/음절 유형별 문구 (실사 §8-P0#7, `introduction_step_widget.dart:75-81,183-196`). 데이터 필드 추가가 필요하면 LSN-1.2.12 로 BE 에 요청
- [ ] LSN-1.2.4 [FE] P0 듣기 퀴즈: 문제 수 = 항목 수 기반, 중복 없이 출제, 점수 실제 계산·표시("Score: 0/6" 고정 제거), 자음 레슨에서 "vowel" 문구 제거, 오답 시 피드백 (실사 §3-A, §8-P0#8, `practice_step_widget.dart:79-89,211,221,238,342`)
- [ ] LSN-1.2.5 [FE] P0 조립 문제: 토끼→거북이 전환 스낵바가 Check 버튼 가림 → 인라인 안내로, 선택지 많을 때 오버플로 없게 스크롤 (실사 §8-P0#6, `agglutinative_step_widget.dart:104-115`)
- [ ] LSN-1.2.6 [FE] P1 레슨 점수 100 고정 제거 → 실제 정답률로 전송 (실사 §3-D, `lesson_screen.dart:39`)
- [ ] LSN-1.2.7 [FE] P1 `user_input` 빈 입력으로 Next 불가 + 최소 검사 (실사 §2-A, `practice_step_widget.dart:457-489`)
- [ ] LSN-1.2.8 [FE] P1 Unit 2·3: 레슨이 없으면 "Coming soon" 잠금 카드로 (실사 §8-P1#12, `unit_selection_screen.dart:36-50`). 유닛 제목·부제 DB 와 일치
- [ ] LSN-1.2.9 [FE] P1 한국어 오류 문구 → 영어 + Retry (`lesson_list_screen.dart:33-39`), 색상 `0xFF6B4EFF`/`Colors.blue` 하드코딩 → theme
- [ ] LSN-1.2.10 [BE] P1 `Lesson.isPublished` 조회 필터 적용 (NULL 처리 방침 포함, lesson2 는 패치로 true) (실사 §2-B)
- [ ] LSN-1.2.11 [BE] P1 별 개수 = 실제 점수 기반(80↑3, 60↑2, 그 외 1), 학습 시간 초 단위 누적 (실사 §3-D, `UserProgressService.java:65-67,97`)
- [ ] LSN-1.2.12 [BE] P1 레슨 데이터 정리 패치: Unit 0 레슨 제목 괄호 숫자·unit_title 혼재 정리, Unit 0 에 completion 단계 추가 여부 결정, (FE 요청 시) 한글 카드 설명 필드 추가 → `lsn_001_*.sql`
- [ ] LSN-1.2.13 [FE] P2 레슨 중간 진행 저장 (`user_progress_provider.dart:28` currentStep 999)

### Step 1.3 조립 문제 데이터 품질 (발표 주장 "핵심 조사만" 사실화)
- [ ] LSN-1.3.1 [BE] P0 `core_engine.py` 후처리: 구두점("."), 기호 칸 제외 / 서술격 병합 '이예요' → 표준형(예요·이에요) / 어절 끝 "고" 치환 오답 규칙 제거 → 문법 범주 오답 풀만 / 선택지에 고유 ID 부여(같은 형태소 2회 필요한 문장 해결) (실사 §3-B, §5, `core_engine.py:15-21,96-123,105`)
- [ ] LSN-1.3.2 [BE] P0 Target_POS 에 해당하는 어절만 분해되는지 확인하고 `curriculum.csv` 정리: u1-l1 = JX(은/는) 중심, lesson2 = 이에요/예요 중심. **lesson2 조립 문제도 파이프라인으로 재생성**(현재 수작업, "저는" 재분해 문제)
- [ ] LSN-1.3.3 [BE] P1 `batch_merger.py`·`inject_morphology.py` 인자화 (DB 이름·lesson_id·경로), `update_lesson.py` 와 실행 순서 충돌 제거 (실사 §5-A, §5-D)
- [ ] LSN-1.3.4 [BE] P0 탭 분석 `chunks` 뜻풀이 수정: "Sarah → word", ":", "=" 등 기호 → 제거/고유명사, '민수' 표기 일관, '이예요' 제거 (실사 §8-P0#5)
- [ ] LSN-1.3.5 [BE] P0 결과를 `backend/db/patches/lsn_00N_*.sql` 로 생성 → `maru_lesson` 적용 → FE 에 알림. 변경된 JSON 모양은 API_CONTRACT 갱신
- [ ] LSN-1.3.6 [FE] P0 조립 위젯이 선택지 ID 기준으로 동작(같은 텍스트 선택지 2개 허용) + 새 데이터로 u1-l1·lesson2 완주 확인

### Step 1.4 확장 (P2, 1.2·1.3 끝난 뒤)
- [ ] LSN-1.4.1 [BE] P2 을/를(JKO) 레슨 `u1-l3` 생성: 소개·연습·조립(파이프라인, "저는"은 통째 유지)·완료 → 패치. 발표의 "레슨 목표 조사만 분해" 시연용
- [ ] LSN-1.4.2 [FE] P2 u1-l3 완주 확인
