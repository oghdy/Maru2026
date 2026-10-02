"""MARU 최종보고서 2학기 개정판 빌드 (1학기 docx 복사본 편집).
사용: python build_report.py [toc_pages.json]
"""
import os, re, sys, json, shutil, subprocess, zipfile
sys.path.insert(0, os.path.dirname(__file__))
from lib import *

SCR = os.path.dirname(os.path.abspath(__file__))
REPO = '/Users/hadohadopapi/Desktop/Maru-main'
FEAT = REPO + '/docs/features'
OUT_DIR = REPO + '/docs/deliverables/report'
SRC = SCR + '/orig.docx'           # 1학기 원본의 복사본
WORK = SCR + '/work'
SK = '/Users/hadohadopapi/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/02529a56-510d-4c6a-bf54-524fca498efd/6f0e104e-fc27-4a1f-91f0-3bd2794caebd/skills/docx'

shutil.rmtree(WORK, ignore_errors=True)
os.makedirs(WORK)
with zipfile.ZipFile(SRC) as z:
    z.extractall(WORK)
subprocess.run(['python3', SK + '/scripts/merge_runs.py', WORK + '/'], check=True, capture_output=True)
d = Doc(WORK)
body = d.body

# =====================================================================
# 0. 목차(수동) 제거 → 나중에 재생성
# =====================================================================
toc_title = d.find('목  차')
first_h1 = [p for p in body.iter(q('w:p')) if text(p).strip() == '1. 서론'][0]
el = toc_title.getnext()
toc_templates = {}
while el is not first_h1:
    nxt = el.getnext()
    t = text(el)
    m = re.match(r'^(\d+(?:\.\d+)*)\.?\s', t)
    if m:
        lvl = m.group(1).count('.') + 1
        toc_templates.setdefault(lvl, copy.deepcopy(el))
    body.remove(el)
    el = nxt

# 빈 단락 정리 (1장 이후): 페이지 넘김용으로 쌓아둔 빈 제목 단락 제거
started = False
for el in list(body):
    if el is first_h1:
        started = True
    if not started or el.tag != q('w:p'):
        continue
    if text(el).strip():
        continue
    if el.find('.//' + q('w:drawing')) is not None or el.find('.//' + q('w:sectPr')) is not None:
        continue
    if el.find('.//' + q('w:br')) is not None:
        continue
    st = el.find(q('w:pPr') + '/' + q('w:pStyle'))
    if st is None or st.get(q('w:val')) not in ('1', '2', '3'):
        continue   # 일반 빈 단락은 문단 간격용이므로 유지
    body.remove(el)

# =====================================================================
# 표지
# =====================================================================
d.replace('2026년 6 월 17 일', '2026년 10월 2일')
d.replace('전공종합설계 최종보고서', '전공종합설계 최종보고서 (2학기 개정판)')

# =====================================================================
# 1장 서론
# =====================================================================
d.set_para('2000년대 이후 한국 대중문화는',
    "2000년대 이후 한국 대중문화는 전 세계 시장에서 전례 없는 파급력을 발휘하고 있다. K-pop, K-드라마, 한국 영화 등 이른바 K-콘텐츠의 확산은 "
    "한국어에 대한 직접적인 학습 수요로 이어졌고, 이는 수치로도 명확히 확인된다. 글로벌 한국어 학습 시장은 2024년 기준 약 72억 달러 규모에서 "
    "2034년 약 670억 달러 규모로 성장할 것으로 전망된다(Research and Markets, 2024). 관광 측면에서도 2024년 한국을 방문한 외국인이 1,510만 명으로 "
    "전년 대비 51.1% 증가하였으며, 교육 분야에서는 해외 한국어 수업 운영 학교 수가 2021년 1,806개에서 2025년 2,777개로 54% 늘었다(대한민국 교육부, MOE). "
    "이처럼 한국어 학습에 대한 전 세계적 관심은 더 이상 일시적 현상이 아니며, 효과적인 한국어 학습 도구에 대한 필요성 또한 그에 비례하여 확대되고 있다.")
d.set_para('그러나 한국어는 외국인 학습자에게',
    "그러나 한국어는 외국인 학습자에게 구조적으로 높은 장벽을 가지는 언어이다. 미국 외교관 연수기관(FSI)은 영어 화자 기준 학습 난이도에 따라 "
    "언어를 네 범주(Category I~IV)로 분류하는데, 한국어는 가장 어려운 범주인 Category IV로 분류되어 있다. 이는 단순히 어휘량의 문제가 아니라, "
    "한국어가 가진 언어 유형적 특성에서 기인한다.")
d.replace('반면 한국어는  로,', '반면 한국어는 교착어로,')
d.replace('FSRS 망각곡선 알고리즘 기반 개인 맞춤형', 'FSRS-4.5 망각곡선 알고리즘 기반 개인 맞춤형')
d.replace('형태소 분석기를 학습 깊이 제어에', '형태소 분석기를 목표 문법 분해에')
p = d.find('이 두 모드는 모든 핵심 기능에 일관되게 적용된다')
d.insert_after(p, [P("1학기에는 이 철학이 🐰/🐢 이모지와 텍스트로만 표현되었으나, 2학기에는 토끼와 거북이를 실제 캐릭터로 구현하였다. "
                     "토끼는 체험과 연기(정답 반응, 미션 속 역할 연기)를, 거북이는 분석과 코칭(오답 힌트, 문법 교정)을 맡아 학습 이벤트에 실시간으로 반응한다(4.5절).")])

h = d.find('1.4 보고서 구성')
d.insert_before(h, [
    H(2, '1.4 2학기 개발 개요'),
    P("1학기에는 네 가지 핵심 기능의 동작하는 시제품을 완성하였다. 2학기에는 이를 실제 사용자가 쓸 수 있는 수준으로 끌어올리는 것을 목표로 하였으며, "
      "출발점은 \"발표와 보고서에서 주장한 내용이 실제 코드와 일치하는가\"라는 질문이었다. 2026년 9월 코드 전체를 대상으로 실사를 수행한 결과, "
      "FSRS 계산식이 표준 공식이 아닌 고정 배수였던 점, 미션 수료증이 목표 달성과 무관하게 발급되던 점, 레슨 점수가 100점으로 고정되어 있던 점, "
      "서버 주소가 개발 PC로 고정되어 실기기에서 동작하지 않던 점 등이 확인되었다. 2학기 작업은 이러한 차이를 \"코드를 주장에 맞게 고치거나, 주장을 사실대로 바꾸는\" 방향으로 해소하는 데 집중하였다."),
    P("2학기의 주요 변경 사항은 다음과 같다. 각 항목의 상세 내용은 괄호 안의 절에서 다루며, 1학기 대비 전체 변경 목록은 부록 A에 정리하였다."),
    TABLE(['영역', '2학기 변경 내용', '절'], [
        ['캐릭터 시스템', '토끼·거북이 캐릭터(표정 이미지 + 코드 모션)를 4개 기능 21개 화면 지점과 홈에 적용', '4.5'],
        ['서버 TTS', 'OpenAI TTS로 자연스러운 한국어 음성 생성, DB 캐시, 실패 시 기기 TTS로 대체', '4.1.7'],
        ['FSRS-4.5', '고정 배수 계산식을 FSRS-4.5 표준 공식·기본 파라미터로 교체, 평가 버튼에 다음 간격 미리보기', '4.2.3'],
        ['형태소 파이프라인', 'Kiwi 조립 문제 생성기 재작성: 목표 문법만 분해, 비문 오답 제거, SQL 패치 출력, 을/를 레슨 추가', '4.1.2~4.1.3'],
        ['미션 판정·리포트', '3-Zone 서버 강제, AI 코치의 실제 목표 달성 판정, 리포트에 사용자 문장만 인용', '4.3.5'],
        ['오류 처리·보안', '모든 API 오류를 상태 코드 + 사용자용 문장으로, 인증 없는 디버그 API 삭제, 키·토큰 노출 제거', '3.6'],
        ['배포', 'Railway 운영 서버 배포 및 콘텐츠 데이터 이관, iPhone 실기기에서 Google 로그인·전 기능 동작', '5.8, 6.5'],
        ['개발·검증 방법', '기능별 병렬 세션 개발, 사용자 피드백 3라운드, 자동 테스트(서버 123개·앱 67개 통과)', '6장'],
    ], [2200, 6000, 1160]),
    CAP('표 1-1. 2학기 주요 변경 사항'),
])
d.replace('1.4 보고서 구성', '1.5 보고서 구성')
old = d.table_after('1.5 보고서 구성')
new = TABLE(['장', '제목', '내용'], [
    ['1장', '서론', '개발 배경, 연구 목적, 학습 설계 철학, 2학기 개발 개요'],
    ['2장', '관련 연구 및 기술 검토', '기존 언어 학습 앱 분석, 형태소 분석·간격 반복·LLM 활용 관련 기술 검토'],
    ['3장', '시스템 설계', '전체 아키텍처, 기술 스택, 데이터베이스 스키마, 인증, API, 오류 처리와 보안'],
    ['4장', '핵심 기능 구현', 'Korean Lesson·Vocabulary System·Mission Chat·Language Lab·캐릭터 시스템의 설계와 구현 상세'],
    ['5장', '결과 및 시연', '1학기 구현 화면, 2학기 개선 화면, 운영 배포와 실기기 동작'],
    ['6장', '2학기 개발 과정과 검증', '실사 기반 정직화, 병렬 세션 개발 방법론, 사용자 피드백 3라운드, 자동 테스트, 배포·데이터 이관'],
    ['7장', '결론 및 향후 계획', '개발 성과 정리, 남은 한계점, 확장 방향'],
    ['부록', '변경 요약', '1학기 → 2학기 변경 요약표, 1학기 문장 정정 목록'],
], [1000, 2600, 5760])
old.addprevious(new)
body.remove(old)

# =====================================================================
# 2장
# =====================================================================
d.replace('구현한 알고리즘을 개발하였다', '구현한 SM-2 알고리즘을 개발하였다')
d.replace('ACM SIGKDD 2022에서 알고리즘을 제안하였다', 'ACM SIGKDD 2022에서 FSRS(Free Spaced Repetition Scheduler)의 기반이 되는 알고리즘을 제안하였다')
d.set_para('MARU는 FSRS를 어휘 학습 시스템',
    "MARU는 FSRS를 어휘 학습 시스템(Vocabulary System)의 스케줄링 엔진으로 채택하였다. 1학기 구현은 FSRS의 상태 모델만 차용하고 안정성을 "
    "고정 배수(×1.2/×2/×3)로 늘리는 단순화된 식이었으나, 2학기에 공개된 FSRS-4.5 표준 공식과 기본 파라미터(w0~w16)로 교체하였다. "
    "FsrsAlgorithm.java는 단어별 안정성(stability)·난이도(difficulty)와 경과일에 따른 인출 가능성(retrievability)을 계산하고, "
    "목표 기억률 0.9에 도달하는 시점을 다음 복습일(next_review_date)로 정한다(4.2.3절).")
d.set_para('MARU는 kiwi-generator 파이프라인에서',
    "MARU는 kiwi-generator 파이프라인에서 kiwipiepy를 핵심 엔진으로 사용한다. 이 파이프라인은 서비스 안에서 실시간으로 동작하는 것이 아니라 "
    "개발자가 실행하는 오프라인 콘텐츠 생성 도구이다. curriculum.csv에 정의된 문장과 학습 목표 품사(Target_POS)를 입력받아, Kiwi가 형태소를 분석하고 "
    "목표 문법 형태소만 분리한 2단계 조립 문제 데이터를 생성하며, 결과는 재실행 가능한 SQL 패치로 데이터베이스에 반영된다. "
    "Tap-to-Translate 기능을 위한 형태소 청크 주입에도 동일하게 적용된다.")
d.replace('GPT-4o를 와 의 두 역할로', 'GPT-4o를 토끼(연기자)와 거북이(채점자)의 두 역할로')
d.replace('정렬된 수식어 키를 사용하여', '입력 문장을 정규화(앞뒤·연속 공백 정리)하고 정렬된 수식어 키를 사용하여')
d.replace('FSRS 알고리즘 채택으로', 'FSRS-4.5 표준 공식 채택으로')
d.replace('POS_MAP +', '목표 문법 형태소만 분리하는 조립 문제 생성 +')

# =====================================================================
# 3장
# =====================================================================
d.set_para('MARU는 프론트엔드(Flutter), 백엔드(Spring Boot)',
    "MARU는 프론트엔드(Flutter), 백엔드(Spring Boot), 데이터베이스(PostgreSQL)의 3-tier 구조로 설계되었다. 백엔드와 데이터베이스는 Railway 클라우드 "
    "플랫폼에 배포되어 운영 주소(https://maru2026-production.up.railway.app)에서 동작하며, GitHub main 브랜치에 반영하면 자동으로 재배포된다. "
    "AI 기능은 외부 API(OpenAI GPT-4o 대화·gpt-4o-mini-tts 음성, Google Gemini 2.5 Flash 문법 변형)를 호출하고, 같은 요청의 결과는 DB 캐시(ai_cache, tts_cache)로 재사용한다. "
    "프론트엔드는 iOS와 Android를 동시에 지원하는 Flutter 단일 코드베이스이며, 서버 주소는 빌드 시 지정(--dart-define)한다.")
old = d.table_after('MARU는 프론트엔드(Flutter), 백엔드(Spring Boot)')
old.addprevious(CODE('''
[ Flutter App (iOS / Android) ]
  · Riverpod 3 상태 관리 · Dio (JWT 자동 주입) · just_audio (TTS 재생)
  · 토끼·거북이 캐릭터 (표정 PNG + 코드 모션)
        │  HTTPS / REST API (JSON, mp3)
        ▼
[ Spring Boot 3.5 — Railway 운영 배포 (main push 시 자동 배포) ]
  · JWT Auth Filter → Controller → Service → Repository
  · 전역 예외 처리: 4xx/5xx + 사용자용 영어 메시지
  · 외부 API ─┬─ OpenAI GPT-4o ........ 미션 대화·교정·판정
              ├─ OpenAI gpt-4o-mini-tts  한국어 음성 (TTS)
              └─ Google Gemini 2.5 Flash 문법 변형 (AI Grammar Lab)
        │  JPA / JDBC
        ▼
[ PostgreSQL — Railway Managed DB ]
  · JSONB 레슨 · FSRS 진행 · ai_cache · tts_cache

[ 오프라인 도구 ] Kiwi 조립 문제 생성기 · 단어 파이프라인 → 멱등 SQL 패치'''))
body.remove(old)
d.replace('그림 3-1. MARU 전체 시스템 아키텍처', '그림 3-1. MARU 전체 시스템 아키텍처 (2학기 운영 구성)')

old = d.table_after('3.2 기술 스택')
old.addprevious(TABLE(['영역', '기술', '선택 이유'], [
    ['프론트엔드', 'Flutter 3.x (Dart)', 'iOS·Android 단일 코드베이스. 드래그앤드롭·카드 플립·캐릭터 모션 등 애니메이션을 네이티브 수준으로 구현'],
    ['상태 관리', 'flutter_riverpod ^3.2.1', '선언형 의존성 주입·상태 관리. 실패한 요청의 자동 재시도는 끄고 화면별 오류 UI로 처리'],
    ['HTTP 클라이언트', 'Dio ^5.9.2', 'Interceptor로 모든 요청에 JWT Bearer 토큰 자동 주입. 서버 주소는 --dart-define 으로 지정'],
    ['음성(TTS)', '서버: OpenAI gpt-4o-mini-tts\n앱: just_audio ^0.10.6\n폴백: flutter_tts ^4.2.5', '자연스러운 한국어 음성을 서버에서 생성·캐시. 앱은 공통 TtsHelper 한 곳에서 재생, 실패 시 기기 TTS'],
    ['백엔드 프레임워크', 'Spring Boot 3.5.11 (Java 17)', 'RESTful API 설계. Spring Security로 JWT 필터 체인 구성'],
    ['ORM', 'Spring Data JPA + Hibernate 6', 'JSONB 컬럼 자동 직렬화(@JdbcTypeCode). 엔티티-테이블 매핑'],
    ['데이터베이스', 'PostgreSQL (Railway)', 'JSONB 타입 + GIN 인덱스. 레슨 콘텐츠의 이종 구조를 단일 컬럼에 저장'],
    ['AI (대화)', 'OpenAI GPT-4o', 'Mission Chat의 토끼(연기)·거북이(채점) 역할과 목표 달성 판정. JSON 구조 응답'],
    ['AI (번역·문법)', 'Google Gemini 2.5 Flash', 'Vocabulary 데이터 배치 번역(오프라인) 및 AI Grammar Lab 문장 변형'],
    ['인증', 'JWT (jjwt 0.12.5) + Google·Apple OAuth', '네이티브 OAuth SDK로 idToken 발급 → 서버에서 서명 검증 → 내부 JWT 발급'],
    ['형태소 분석', 'Kiwi (kiwipiepy 0.17)', '오프라인 콘텐츠 도구. 어절 경계 계산·품사 태그로 조립 문제와 탭 분석 데이터 생성'],
    ['캐릭터', 'AI 생성 표정 PNG + Flutter 애니메이션', '그림(표정)과 몸짓(코드 모션)을 분리해 새 패키지 없이 구현'],
    ['배포', 'Railway', 'Spring Boot JAR + PostgreSQL Managed DB. GitHub main push 시 자동 배포'],
], [1700, 2700, 4960]))
body.remove(old)
d.replace('3.2 기술 스택', '3.2 기술 스택')

d.set_para('국립국어원 XLS에서 AI 파이프라인을 통해 구축된',
    "국립국어원 학습용 어휘 XLS(5,965개 항목)를 AI 파이프라인으로 번역·분류하여 최종 적재한 5,561개의 단어를 저장한다. category_id로 word_categories와 "
    "N:1 관계를 맺는다. 복합 유니크 제약 UNIQUE(korean_word, part_of_speech)으로 파이프라인 재실행 시 중복 적재를 방지한다. 동음이의어는 품사(part_of_speech)로 구분된다.")
cap = d.find('mission_clearances 테이블')
d.insert_after(cap, [P("2학기에는 미션의 실제 판정 결과를 저장하기 위해 nullable 컬럼 세 개(cleared BOOLEAN, result_reason TEXT, goal_condition TEXT)를 추가하였다. "
                       "기존 기록은 값이 비어 있으며, 앱은 이를 판정 도입 전 기록(\"Completed\")으로 표시한다. 스키마는 JPA ddl-auto(update)로 관리하므로 "
                       "2학기의 모든 스키마 변경은 컬럼·테이블 추가만 허용하고 이름 변경·삭제는 하지 않았다.")])
erd = d.find('3.3.6 전체 ERD 요약')
d.set_text(erd, '3.3.7 전체 ERD 요약')
d.insert_before(erd, [
    H(3, '3.3.6 TTS 캐시 도메인 (tts_cache) — 2학기 추가'),
    P("서버 TTS(4.1.7절)가 생성한 mp3 음성을 저장하는 테이블이다. 캐시 키는 모델·목소리·지시문 버전·정규화된 문장을 이어 붙인 문자열의 SHA-256 해시이며, "
      "같은 문장을 다시 요청하면 OpenAI를 호출하지 않고 저장된 음성을 바로 반환한다. 목소리나 모델을 바꾸면 키가 달라지므로 예전 음성이 섞이지 않는다."),
    CODE('''
CREATE TABLE tts_cache (
  id            BIGSERIAL PRIMARY KEY,
  cache_key     VARCHAR(64) NOT NULL UNIQUE,  -- sha256(model|voice|지시문버전|text)
  input_text    TEXT NOT NULL,
  model         VARCHAR(50),                   -- gpt-4o-mini-tts
  voice         VARCHAR(30),                   -- ash
  content_type  VARCHAR(50),                   -- audio/mpeg
  audio         BYTEA NOT NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);'''),
    CAP('표 3-10. tts_cache 테이블'),
])
old = d.table_after('3.3.7 전체 ERD 요약')
old.addprevious(TABLE(['테이블', 'PK', '주요 FK / 제약', '비고'], [
    ['users', 'id (BIGSERIAL)', 'UNIQUE(oauth_provider, oauth_id)', '소셜 로그인 전용'],
    ['user_stats', 'id', 'user_id → users (1:1)', '스트릭·별·학습 시간'],
    ['user_progress', 'id', 'user_id → users\nUNIQUE(user_id, lesson_id)', '레슨 진행·점수·별·이어하기 단계'],
    ['lessons', 'id', 'UNIQUE(lesson_id)', 'JSONB content, GIN 인덱스, 15개 레슨'],
    ['word_categories', 'id', '-', '덱 14개 (레벨·순서)'],
    ['words', 'id', 'category_id → word_categories\nUNIQUE(korean_word, pos)', '5,561개 단어'],
    ['fsrs_progress', 'id', 'word_id → words\nUNIQUE(user_id, word_id)', 'FSRS 상태·안정성·난이도, next_review_date 인덱스'],
    ['mission_clearances', 'id', 'user_id → users', '미션 리포트, 판정(cleared) 추가'],
    ['ai_cache', 'id', 'UNIQUE(input_text, transformation_type)', 'Gemini 응답 캐시'],
    ['tts_cache', 'id', 'UNIQUE(cache_key)', 'TTS 음성 캐시 (2학기 추가)'],
], [1900, 1500, 3200, 2760]))
body.remove(old)
d.insert_after(d.table_after('3.3.7 전체 ERD 요약'), [
    P("레슨·단어 등 콘텐츠 데이터의 변경은 모두 재실행해도 결과가 같은(멱등) SQL 패치 파일(backend/db/patches/*.sql)로 남겼다. 2학기에 작성한 패치는 "
      "레슨 4개(lsn_001~004), 미션 1개(msn_001), 실험실 1개(lab_001)이며, 개발 DB에서 검증한 패치를 운영 DB에도 그대로 적용하였다."),
])

p = d.find('JWT는 JJWT(io.jsonwebtoken)')
d.insert_after(p, [P("1학기에는 Google idToken 검증에 실패하면 서버가 HTTP 200과 빈 데이터를 돌려주어 앱이 로딩 상태에서 멈추는 문제가 있었다. 2학기에는 검증 실패 시 401과 "
                     "영어 안내 문장을 반환하고, 앱은 로그인 화면에 오류를 표시하도록 수정하였다. iOS에서는 Google 로그인용 서버 클라이언트 ID를 빌드 시 주입하여 "
                     "실제 iPhone에서 Google 로그인이 동작함을 확인하였다. 개발 중에는 여러 세션이 동시에 테스트할 수 있도록 디버그 빌드에서만 동작하는 개발용 토큰(DEV_JWT) 로그인을 사용하였다.")])

d.replace('총 17개의 API 엔드포인트(API)를', '총 22개의 API 엔드포인트를')
old = d.table_after('총 22개의 API 엔드포인트를')
old.addprevious(TABLE(['도메인', '메서드', '엔드포인트', '설명'], [
    ['인증', 'POST', '/api/auth/google', 'Google idToken 검증 → 내부 JWT 발급 (실패 401)'],
    ['인증', 'POST', '/api/auth/apple', 'Apple idToken 검증 → 내부 JWT 발급'],
    ['사용자', 'GET', '/api/me', '현재 인증 사용자 정보 조회'],
    ['사용자', 'PUT', '/api/me/profile', '닉네임 등 프로필 설정'],
    ['사용자', 'GET', '/api/me/stats', '학습 통계(스트릭·별·학습 시간·완료 레슨) 조회'],
    ['레슨', 'GET', '/api/units/{unitId}/lessons', '유닛의 공개 레슨 목록 + JSONB content'],
    ['레슨 진행', 'POST', '/api/progress/lessons/{lessonId}', '진행·완료 저장 (점수 기반 별, 최고 기록 유지)'],
    ['레슨 진행', 'GET', '/api/progress/lessons?unitId=', '내 레슨별 진행 기록 조회 (2학기 추가)'],
    ['음성', 'GET', '/api/tts?text=', '한국어 mp3 음성, DB 캐시 (2학기 추가)'],
    ['단어장', 'GET', '/api/v1/vocabulary/decks', '덱 목록 + 단어 수'],
    ['단어장', 'GET', '/api/v1/vocabulary/decks/{deckId}/lessons', '덱의 30단어 레슨 목록 + 학습 진행'],
    ['단어장', 'GET', '/api/v1/vocabulary/due', '레슨 단어 카드 + 평가별 다음 간격'],
    ['단어장', 'GET', '/api/v1/vocabulary/daily-review', 'FSRS 복습 기한이 된 단어 조회'],
    ['단어장', 'GET', '/api/v1/vocabulary/game/{deckId}', '짝맞추기용 단어 (라운드당 5쌍)'],
    ['단어장', 'POST', '/api/v1/vocabulary/review', 'FSRS 평가(Again/Hard/Good/Easy) 제출'],
    ['미션챗', 'POST', '/api/v1/mission-chat/setup', 'LLM #1: 페르소나·미션 생성'],
    ['미션챗', 'POST', '/api/v1/mission-chat/chat', 'LLM #2: 한 턴 (토끼+거북이 병렬), 3-Zone 판정'],
    ['미션챗', 'POST', '/api/v1/mission-chat/suggestion', 'LLM #4: 거북이 표현 힌트'],
    ['미션챗', 'POST', '/api/v1/mission-chat/clearance', 'LLM #3: 목표 달성 판정 + 리포트 저장'],
    ['미션챗', 'GET', '/api/v1/mission-chat/clearances', '내 미션 리포트 목록'],
    ['랩', 'POST', '/api/lab/explore', 'Gemini: 한 범주로 3가지 문장 변형'],
    ['랩', 'POST', '/api/lab/combine', 'Gemini: 여러 변형자 결합 → 한 문장'],
], [1300, 1000, 3600, 3460]))
body.remove(old)
last35 = d.find('공통 응답 형식인 ApiResponse는')
d.insert_after(last35, [
    H(2, '3.6 오류 처리와 보안 (2학기 추가)'),
    P("1학기 시제품은 외부 API 오류나 잘못된 입력이 들어오면 HTTP 500 또는 200과 빈 데이터를 반환하는 경우가 많았고, 앱은 예외 원문(DioException 등)을 화면에 "
      "그대로 노출하거나 무한 로딩에 빠졌다. 2학기에는 모든 기능에 같은 오류 규칙을 적용하였다."),
    TABLE(['HTTP', '상황', '응답 message 예시'], [
        ['400', '입력 누락·형식 오류·범위 밖 값', 'Please enter a sentence in Korean. / rating must be 1 (Again) to 4 (Easy).'],
        ['401 / 403', '로그인 검증 실패 / 토큰 없음', '(로그인 화면에 영어 안내 표시)'],
        ['404', '없는 레슨·단어·사용자', 'Lesson not found: … / Word not found.'],
        ['502', 'AI 오류 응답, AI가 JSON 형식을 깨뜨림', 'The AI gave an unexpected answer. Please try again.'],
        ['503', 'AI 서비스 사용 불가(키 없음·쿼터)', 'The AI service is unavailable right now. Please try again in a moment.'],
        ['504', 'AI 응답 시간 초과', 'The AI took too long to respond. Please try again.'],
    ], [1300, 3300, 4760]),
    CAP('표 3-11. 공통 오류 응답 규칙 ({status, message, data:null})'),
    P("message는 학습자에게 그대로 보여줄 수 있는 영어 문장으로 작성하였고, 앱은 각 화면에서 이 문장과 함께 재시도(Retry) 버튼을 제공한다. 실패한 AI 결과는 캐시에 저장하지 않으므로 "
      "재시도하면 다시 외부 API를 호출한다. 보안 측면에서는 실사에서 확인된 다음 문제를 제거하였다."),
    BUL("인증 없이 여러 테이블을 수정·삭제할 수 있던 임시 디버그 API(DebugController)와 해당 permitAll 설정 삭제"),
    BUL("요청마다 JWT 원문을 INFO 로그로 남기던 코드 제거"),
    BUL("Gemini API 키를 URL 쿼리스트링 대신 x-goog-api-key 헤더로 전달, 오류 로그에 URL·키가 남지 않도록 처리"),
    BUL("앱의 서버 주소 하드코딩(localhost) 제거 → 빌드 시 --dart-define 으로 지정, API 키·토큰·.env 는 저장소에 커밋하지 않음"),
])

# =====================================================================
# 4장 — 4.1 Korean Lesson
# =====================================================================
d.replace('🐰 토끼: 저는 / 사라입니다', '🐰 토끼: 저는 / Sarah입니다')
d.replace('🐢 거북이: 저 / 는 / 사라 / 입니다 (핵심 조사', '🐢 거북이: 저 / 는 / Sarah입니다 (핵심 조사')
d.replace('4.1.2 타깃 어절 한정(Target-Eojeol Scoping) 알고리즘', '4.1.2 목표 문법 형태소 분리 알고리즘 (2학기 재작성)')
d.set_para('MARU의 형태소 분석은 오픈소스 한국어 형태소 분석기 Kiwi',
    "MARU의 형태소 분석은 오픈소스 한국어 형태소 분석기 Kiwi를 사용하되, Kiwi의 원시 분석 결과(Raw Token)를 그대로 노출하지 않고 가공하여 사용한다. "
    "1학기 엔진은 목표 품사가 포함된 어절을 Kiwi 형태소 전부로 분해하였기 때문에 목표와 무관한 형태소까지 쪼개졌고, 마침표가 별도 블록으로 들어가거나 "
    "'이예요' 같은 비표준 표기가 정답에 섞였다. 2학기에는 core_engine.py를 다시 작성하여 어절 안에서 목표 문법에 해당하는 조각만 떼어 내고 나머지는 "
    "한 덩어리로 유지하도록 하였다. 문장부호·기호는 조립 블록에서 제외하고, 서술격 조사와 어미(이에요·예요·입니다)는 원문 표기 그대로 한 조각으로 묶는다.")
old = d.table_after('MARU의 형태소 분석은 오픈소스 한국어 형태소 분석기 Kiwi')
old.addprevious(CODE('''
# core_engine.py : process_sentence() — 어절별로 목표 조각만 분리
for u in units:                       # 어절 안의 표면형 조각 (문장부호 제외)
    if self._is_target(u, targets):   # CSV Target_POS 에 해당하는 조각
        flush(buffer)                 # 앞부분은 한 덩어리로
        pieces.append(piece(u))       # 목표 형태소만 별도 블록
        target_pieces.append((piece(u), u.category))
    else:
        buffer.extend(u)              # 목표가 아니면 이어 붙임
if not target_pieces:                 # 목표 문법이 없는 어절은 통째로
    pieces = [core]
    explanation = "Keep '저는' as one block — it is not this lesson's focus."

# 🐰 오답: 목표 형태만 이형태로 바꾼 어절 (저는 → 저은, 학생이에요 → 학생예요)
# 🐢 오답: 이형태 1순위(은↔는, 을↔를, 이에요↔예요) + 같은 범주 2순위(도, 만 …)'''))
body.remove(old)
d.replace('그림 4-2. 타깃 어절만 선택적으로 분해하는 핵심 로직', '그림 4-2. 목표 문법 형태소만 분리하는 핵심 로직')
d.set_para('또한 단순 분할에 그치지 않고, 학습자가 정답 외에',
    "오답 보기(Decoy)도 새로 설계하였다. 1학기 엔진은 어절 끝 글자를 '고'로 바꾸는 규칙 때문에 \"Sarah입니다고\", \"저고\" 같은 비문을 만들었다. "
    "2학기 엔진은 학습자가 실제로 헷갈리는 선택만 내도록, 받침 유무에 따라 갈리는 이형태(은/는, 이/가, 을/를, 이에요/예요)를 1순위로, 같은 문법 범주의 다른 형태(도·만 등)를 2순위로 사용한다.")
d.set_para('KiwiEngine클래스 내부의 디코이 풀',
    "또한 선택지마다 고유 ID를 부여하여, 같은 형태소가 한 문장에 두 번 필요한 경우(예: '는'×2)에도 풀 수 있게 하였다. 오답 시 보여주는 거북이 설명"
    "(turtle_explanation)도 한국어 품사 태그 대신 영어 문장(\"After a vowel use 를, after a consonant use 을.\")으로 생성한다. 실제 레슨 데이터의 분해 결과는 다음과 같다.")
p = d.find('또한 선택지마다 고유 ID를 부여하여')
d.insert_after(p, [
    TABLE(['레슨 (목표 문법)', '문장', '🐰 토끼 정답', '🐢 거북이 정답'], [
        ['u1-l1 (은/는, JX)', '제 이름은 유미예요.', '제 / 이름은 / 유미예요', '제 / 이름 + 은 / 유미예요'],
        ['lesson2 (이에요/예요)', '저는 학생이에요.', '저는 / 학생이에요', '저는 / 학생 + 이에요'],
        ['u1-l3 (을/를, JKO)', '저는 커피를 좋아해요.', '저는 / 커피를 / 좋아해요', '저는 / 커피 + 를 / 좋아해요'],
    ], [2200, 2300, 2300, 2560]),
    CAP('표 4-1. 레슨별 목표 문법 분해 결과 (목표가 아닌 "저는"·"좋아해요"는 통째로 유지)'),
    P("분해 여부는 학습자 개인의 학습 이력이 아니라 문장마다 지정한 목표 문법(Target_POS)으로 결정된다. 예를 들어 을/를 레슨에서 \"저는\"이 분해되지 않는 이유는 "
      "학습자가 이미 배웠기 때문이 아니라, 그 레슨의 목표 문법이 아니기 때문이다. 학습자별 습득 기록에 따라 분해 깊이를 바꾸는 기능은 향후 과제로 남겼다(7.3절)."),
])
d.set_para('새로운 문법을 가르칠 때마다 코드를 수정해야 한다면',
    "새로운 문법을 가르칠 때마다 코드를 수정해야 한다면 콘텐츠 확장성이 떨어진다. MARU는 데이터와 코드를 격리하는 데이터 주도 설계(Data-Driven Design)를 채택하여, "
    "레슨 행이 있는 경우 curriculum.csv에 문장·번역·목표 품사 한 줄을 추가하고 파이프라인을 실행하면 해당 레슨의 조립 문제가 생성된다. 1학기 스크립트는 대상 레슨과 DB 주소가 "
    "코드에 고정되어 있어 레슨마다 코드를 고쳐야 했으나, 2학기에 명령행 인자로 바꾸고 결과를 SQL 패치로 출력하도록 재작성하였다. 핵심 파이프라인은 kiwi-generator 디렉터리 안의 모듈로 구성된다.")
d.replace('pandas로 CSV를 로드하고 core_engine을 호출. 생성된', '명령행 인자(--lesson, --csv, --sql-out, --dry-run 등)로 대상 레슨을 받아 core_engine을 호출. 생성된')
old = d.table_after('명령행 인자(--lesson')
old.addprevious(CODE('''
# 레슨 하나의 조립 문제를 다시 만들고 SQL 패치로 저장 (DB 직접 수정 대신)
$ python batch_merger.py --lesson u1-l3 --csv curriculum.csv \\
      --base-json lessons/unit1/u1-l3.json --chunks \\
      --sql-out ../../db/patches/lsn_004_add_u1_l3_object_particle.sql

# batch_merger.py : merge_content() — 기존 조립 단계만 교체
steps = [s for s in base['steps'] if step_type(s) != 'agglutinative_quiz']
idx   = completion_index(steps)              # completion 단계 바로 앞
steps = steps[:idx] + quiz_steps + steps[idx:]
# → UPDATE lessons SET content = '...'::jsonb WHERE lesson_id = 'u1-l3';'''))
body.remove(old)
d.replace('그림 4-3. 드래그앤드롭 퀴즈 병합·적재 흐름', '그림 4-3. 조립 문제 생성·SQL 패치 출력 흐름')
p = d.find('이 파이프라인의 가장 중요한 설계 원칙은')
d.set_text(p, "이 파이프라인의 가장 중요한 설계 원칙은 '멱등성(Idempotency)을 보장하는 것'이다. 기존 agglutinative_quiz 단계만 제거한 뒤 새로 생성된 문제를 completion 단계 앞에 "
              "삽입하므로, 여러 번 실행해도 소개·연습 등 다른 단계에는 영향이 없고 중복 데이터가 쌓이지 않는다. 2학기에는 결과를 DB에 바로 쓰는 대신 SQL 패치 파일로 남겨, "
              "개발 DB에서 검증한 것과 같은 내용을 운영 DB에 그대로 적용할 수 있게 하였다. 현재 이 파이프라인으로 문법 레슨 3개(u1-l1 은/는, lesson2 이에요/예요, u1-l3 을/를)의 "
              "조립 문제 7개를 생성하였다. 새 레슨을 만들 때 소개·연습 단계의 JSON은 여전히 사람이 작성한다.")
p = d.find('그림 4-5.')
d.insert_after(p, [P("2학기에는 탭 분석 데이터도 정리하였다. 1학기 데이터에는 \"Sarah\", \":\", \"=\" 같은 기호와 이름이 \"word\"로 표시되고, 같은 이름이 레슨마다 다른 뜻(Proper Noun/Noun)으로 "
                     "나오는 문제가 있었다. 기호는 탭 대상에서 제외하고, 이름은 \"Sarah (name)\", 화자 표시는 \"Minsu (speaker)\"처럼 일관되게 표시하며, 서술격은 원문 표기(예요/이에요/입니다)를 따르도록 수정하였다. "
                     "뜻풀이가 정적 규칙표에 의존한다는 한계는 7.2.1절에 남겨 두었다.")])
p = d.find('그림 4-7. JSONB 자동 매핑')
d.insert_after(p, [
    H(3, '4.1.6 점수·별·이어하기 (2학기 추가)'),
    P("1학기에는 앱이 레슨 점수를 항상 100점으로 보내 첫 완료 시 무조건 별 3개를 받았다. 2학기에는 문제별 첫 시도 정답률을 점수로 전송하고, 서버가 점수에 따라 "
      "별을 계산한다(80점 이상 3개, 60점 이상 2개, 그 외 1개). 다시 풀어도 최고 기록이 유지되며, 늘어난 별만 사용자 통계에 더해진다. 레슨 도중 나가면 현재 단계가 저장되어 "
      "다음에 이어서 학습할 수 있고, 레슨 목록에는 완료 표시와 별이 나타난다. 이를 위해 내 진행 기록을 조회하는 API(GET /api/progress/lessons)를 추가하였다."),
    P("한글 레슨(Unit 0, 12개)에서도 모든 카드에 같은 설명이 나오던 고정 문구, 항목 수와 무관하게 5문제로 고정된 듣기 퀴즈, \"Basic Vowels Mastered!\"로 고정된 완료 화면을 "
      "모두 데이터 기반으로 바꾸었다. 듣기 퀴즈는 항목 수만큼 중복 없이 출제하고 실제 점수를 표시한다."),
    H(3, '4.1.7 서버 TTS — 자연스러운 한국어 음성 (2학기 추가)'),
    P("1학기에는 기기 내장 TTS(flutter_tts)를 사용하여 기기마다 음질이 다르고 시뮬레이터에서는 부자연스러웠다. 사용자 피드백(6.3절)에 따라 2학기에는 서버가 OpenAI "
      "gpt-4o-mini-tts(목소리 ash, \"표준 서울말, 학습자용으로 약간 천천히\" 지시)로 mp3를 생성하고 tts_cache 테이블에 저장한다. 같은 문장은 OpenAI를 다시 호출하지 않고 "
      "캐시에서 바로 반환하며, 응답 헤더 X-TTS-Cache로 HIT/MISS를 확인할 수 있다."),
    CODE('''
GET /api/tts?text=저는 커피를 좋아해요   (인증 필요, 1~200자)
 ├─ text 정규화(앞뒤·연속 공백) → 자모 한 글자는 표준 읽기로 변환 (ㄱ → 기역, ㅏ → 아)
 ├─ cache_key = sha256(model | voice | 지시문버전 | text)
 ├─ tts_cache HIT  → audio/mpeg 즉시 반환 (수 ms)
 └─ tts_cache MISS → OpenAI TTS 호출(약 1초) → 저장 → 반환
앱: TtsHelper.speak(text) 한 곳에서 just_audio 재생
     실패(4xx/5xx·타임아웃) 시 기기 TTS(flutter_tts)로 폴백'''),
    CAP('그림 4-8. 서버 TTS 처리 흐름'),
    P("앱은 레슨·단어장·실험실이 모두 같은 TtsHelper.speak()를 호출하도록 통일하여, 기능마다 따로 있던 TTS 코드를 한 곳으로 모았다."),
])

# ---- 4.2 Vocabulary
d.replace('를 활용한 3단계 자동 파이프라인()으로 구축하였다', 'Gemini를 활용한 3단계 자동 파이프라인(vocab-pipeline)으로 구축하였다. 최종 적재된 단어는 14개 주제 덱의 5,561개이며, 번역·예문은 AI가 생성한 것이다')
p = d.find('복습 스케줄링의 핵심은 FSRS')
d.set_text(p, "복습 스케줄링의 핵심은 FSRS(Free Spaced Repetition Scheduler) 알고리즘이다. 1학기 구현은 FSRS의 상태 모델(New·Learning·Review·Relearning)을 차용했지만, "
              "안정성을 평가별 고정 배수로 늘리고 경과 시간과 인출 가능성을 반영하지 않는 단순화된 식이었다. 2학기에는 공개된 FSRS-4.5 표준 공식과 기본 파라미터 17개(w0~w16)로 "
              "FsrsAlgorithm을 다시 구현하였다. 각 단어 카드에 대해 안정성(S, 기억이 유지되는 기간), 난이도(D, 1~10), 인출 가능성(R, 지금 기억하고 있을 확률)을 계산하고, "
              "R이 목표 기억률 0.9로 떨어지는 시점을 다음 복습일로 정한다. 구현체는 DB·JPA에 의존하지 않는 순수 자바 객체로 분리하여 단위 테스트로 검증하였다.")
p = d.find('사용자의 4단계 응답(ReviewRating)에 따라')
d.set_text(p, "사용자의 4단계 응답(G: Again=1, Hard=2, Good=3, Easy=4)에 따라 새 카드는 초기 안정성 S0 = w[G−1]과 초기 난이도 D0 = w4 − (G−3)·w5로 시작한다. 복습 카드는 "
              "경과일 t로 R(t,S)를 구한 뒤, 기억에 성공하면 R이 낮을수록(잊기 직전에 떠올릴수록) 안정성이 크게 늘고, 실패(Again)하면 망각 공식으로 안정성이 줄며 5분 뒤 다시 출제된다.")
old = d.table_after('사용자의 4단계 응답(G: Again=1')
old.addprevious(CODE('''
// FsrsAlgorithm.java — FSRS-4.5 표준 공식 (기본 파라미터 w0~w16)
R(t,S)   = (1 + FACTOR·t/S)^DECAY             // DECAY = -0.5, FACTOR = 19/81
I(S)     = S/FACTOR · (0.9^(1/DECAY) − 1)      // 목표 기억률 0.9 → 간격 = S일
D'       = w7·D0(Good) + (1−w7)·(D − w6·(G−3)) // 평균 회귀, 1~10
S'recall = S·(1 + e^w8·(11−D)·S^−w9·(e^(w10·(1−R)) − 1)·hardPenalty·easyBonus)
S'forget = w11·D^−w12·((S+1)^w13 − 1)·e^(w14·(1−R))

double nextRecallStability(double d, double s, double r, ReviewRating g) {
    double hardPenalty = g == ReviewRating.HARD ? W[15] : 1;
    double easyBonus   = g == ReviewRating.EASY ? W[16] : 1;
    return s * (1 + Math.exp(W[8]) * (11 - d) * Math.pow(s, -W[9])
            * (Math.exp((1 - r) * W[10]) - 1) * hardPenalty * easyBonus);
}'''))
body.remove(old)
d.replace('그림 4-11. FSRS 상태 전이 핵심 로직', '그림 4-11. FSRS-4.5 핵심 공식과 구현')
old = d.table_after('그림 4-11. FSRS-4.5 핵심 공식과 구현')
old.addprevious(TABLE(['응답 등급', '새 카드 (S, D)', '다음 복습', '복습 카드에서'], [
    ['Again', 'S=0.49, D=7.62', '5분 뒤 (Learning)', 'Relearning, 망각 공식으로 S 감소, 5분 뒤'],
    ['Hard', 'S=1.40, D=6.39', '1일 뒤', 'S 소폭 증가 (hardPenalty)'],
    ['Good', 'S=3.71, D=5.16', '4일 뒤', '예: 4일 뒤 Good → S 3.71 → 14.81, 15일 뒤'],
    ['Easy', 'S=13.82, D=3.93', '14일 뒤', 'S 크게 증가 (easyBonus), 간격 Hard ≤ Good < Easy 보장'],
], [1400, 2400, 2000, 3560]))
body.remove(old)
d.insert_after(d.table_after('그림 4-11. FSRS-4.5 핵심 공식과 구현'),
    [CAP('표 4-2. FSRS-4.5 기본 파라미터에서의 평가별 결과 (서버 실측·손계산 검증)'),
     P("계산 결과는 손계산으로 검증하였으며, 공식 구현체(py-fsrs)와의 교차 검증과 사용자 데이터로 파라미터를 최적화하는 기능은 아직 적용하지 않았다(7.2.5절).")])
d.set_para('FSRS가 계산한 복습 기한이 된 단어만을 선별하여',
    "FSRS가 계산한 복습 기한이 된 단어만을 선별하여 \"오늘의 복습(Daily Review)\"으로 제공한다. 요청 시 FsrsProgressRepository가 @Query(JPQL) 조건으로 복습 도래 카드를 "
    "조회하며, state 정렬로 재학습 카드를 우선 노출한다. 복습 결과는 다시 4단계 평가를 거쳐 FSRS로 재연산된다. 홈 화면에는 복습할 단어 수가 항상 표시되며, 0개이면 "
    "\"All caught up!\" 카드로 안내한다. 덱 안의 Word Study는 레슨(30단어)의 단어를 순서대로 학습하는 모드로, FSRS 추천은 오늘의 복습에 한정된다.")
d.set_para('암기를 게임으로 강화하기 위해 단어 매칭 게임을 제공한다',
    "암기를 게임으로 강화하기 위해 단어 짝맞추기 게임(Match Madness)을 제공한다. 백엔드가 레슨(30단어)의 단어를 내려주고, 앱은 라운드당 5쌍(한글 ↔ 영어 뜻 2열)씩 "
    "나누어 출제한다. 라운드 수와 진행 표시는 실제 단어 수로 계산한다. 2학기에는 타일 순차 등장, 선택 시 확대, 정답 짝 팝·페이드, 부드러운 오답 흔들림, 라운드 전환, "
    "완료 축하 연출을 추가하고, 토끼 캐릭터가 정답·오답에 반응하도록 하였다.")
p = d.find('2학기에는 타일 순차 등장')
d.insert_after(p, [
    H(3, '4.2.5 평가 무결성과 다음 간격 미리보기 (2학기 추가)'),
    P("실사 과정에서 카드를 스와이프로 넘긴 뒤 평가하면 화면의 단어가 아닌 다른 단어로 평가가 저장되는 버그가 발견되었다. 이는 FSRS 데이터를 오염시키는 문제였으므로 "
      "카드 화면의 인덱스와 상태 관리의 인덱스를 동기화하고, 평가 시 해당 카드의 단어 ID로 제출하도록 수정하였다. 서버는 범위 밖 평가(1~4 외)나 없는 단어를 400/404로 거절한다."),
    P("Word Study에서 이미 학습한 단어를 복습일 전에 다시 평가하면 간격이 흐트러지므로, 이 경우는 저장하지 않는다(Spacing Integrity Guard, 응답 applied:false). 단, 복습일이 지난 "
      "단어의 평가는 정식 복습으로 반영한다. 또한 서버가 네 평가 각각의 결과를 미리 계산(nextIntervals)해 내려주어, 평가 버튼에 \"Again 5m · Hard 1d · Good 4d · Easy 14d\"처럼 "
      "다음 복습 간격을 표시한다. 학습자는 자신의 선택이 복습 일정에 어떤 영향을 주는지 바로 알 수 있다."),
])

# ---- 4.3 Mission
d.replace('세 가지 문제에 직면한다. (상황·목적·상대가 없음), (종료 기준 부재), (피드백 부재).',
          '세 가지 문제에 직면한다. 목적 부재(상황·목적·상대가 없음), 끝없는 대화(종료 기준 부재), 피드백 부재이다.')
d.replace('미션 종료 시 피드백 + 클리어증 발급·저장', '미션 종료 시 목표 달성 판정 + 피드백 리포트 저장')
d.replace('그 결과 응답 시간을 1.5초대로 단축하여 실시간 UX를 확보하였다.',
          '서버 로그로 측정한 결과 한 턴의 응답은 약 1.5~2초(실측 1.4~2.2초)로, 두 호출을 순차 처리할 때의 추정치(2.6~4.1초)보다 30~50% 짧았다.')
d.replace('이로써 대화가 늘어지거나 흐지부지 끝나지 않고, 목표 달성 시점에 명확히 종료된다.',
          '다만 LLM의 판단만으로는 규칙이 항상 지켜진다고 보장할 수 없으므로, 2학기에는 서버가 LLM의 판정 위에 3-Zone 규칙을 강제하도록 바꾸었다(표 4-3). 그 결과 모든 미션은 최대 minTurns+3 턴 안에 반드시 끝난다.')
p = d.find('다만 LLM의 판단만으로는 규칙이 항상')
d.insert_after(p, [
    TABLE(['Zone', '조건 (t = 사용자 턴)', '서버 규칙'], [
        ['A (초반)', 't < minTurns − 1', 'LLM이 cleared/failed를 주어도 무시하고 진행(in_progress)'],
        ['B (판정 구간)', 'minTurns − 1 ≤ t ≤ minTurns + 1', '목표 달성이면 cleared, 아니면 계속 진행'],
        ['C (연장)', 't ≥ minTurns + 2', 'cleared 또는 failed. t ≥ maxTurns(= minTurns + 3)인데 진행 중이면 서버가 failed로 종료'],
    ], [1700, 3000, 4660]),
    CAP('표 4-3. 서버가 강제하는 3-Zone 규칙 (ChatTurnService.applyZoneRules)'),
])
d.set_para('미션 종료 시(호출 #3) 거북이는',
    "미션이 cleared 또는 failed로 끝나면 앱은 입력을 막고 호출 #3을 요청한다. 1학기에는 사용자 턴이 minTurns+2에 도달하면 목표 달성과 무관하게 발급을 요청하고, 프롬프트도 "
    "결과를 \"클리어\"로 고정하여 사실상 항상 수료증이 발급되었다. 2학기에는 이를 실제 판정으로 바꾸었다(4.3.5절). 막연한 AI 잡담이 아니라, 정해진 턴 안에 끝나는 목적 지향형 학습 대화로 완성되는 것이다.")
p = d.find('4.3.4 사용 프롬프트')
d.insert_after(p, [P("아래 프롬프트 이미지는 1학기 버전이다. 2학기에는 clearance_system.txt에 목표 달성 판정(cleared·result_reason)과 \"후보로 주어진 사용자 문장만 원문 그대로 인용\" 규칙을 추가하고, "
                     "판정 이유와 총평을 학습자에게 직접 말하는 2인칭(You …)으로 바꾸었다. 사용하지 않던 chat_turn_system.txt는 삭제하였다.")])
d.replace('사용자가 잘 사용한 우수 표현(good_expressions) 2~4개를', '사용자가 실제로 보낸 문장 중에서만 우수 표현(good_expressions) 0~4개를')
d.replace('오류나 어색했던 표현(incorrect_expressions) 1~3개를', '오류나 어색했던 표현(incorrect_expressions) 0~3개(틀린 것이 없으면 빈 목록)를')
p = d.find('출력 포맷 (JSON)**: certificate') if False else d.find('certificate (미션 정보')
d.insert_after(p, [
    H(3, '4.3.5 목표 달성 판정과 리포트 정직화 (2학기 추가)'),
    P("2학기에는 미션 종료 시 거북이 코치(호출 #3)가 대화 전체를 보고 미션 목표(goalCondition)와 언어 조건 달성 여부를 판정한다. 달성하면 \"Mission Cleared\", 미달성이면 "
      "\"Almost there!\"와 함께 판정 이유(resultReason)와 재도전 조언을 보여준다. 어떤 경우든 잘한 표현·고칠 표현·다음 목표 피드백은 항상 제공한다. "
      "대화가 minTurns−1 턴보다 짧게 끝나면 서버가 AI 판정과 무관하게 미달성으로 처리한다."),
    P("사용자 피드백 3차에서는 리포트의 \"Great Expressions\"에 사용자가 보내지 않은 문장(거북이 힌트로 제안만 된 문장)이 나오는 문제가 발견되었다. 원인은 AI가 후보 밖의 문장을 "
      "인용한 것이었으므로, 서버가 대화 기록에서 사용자 발화만 뽑아 번호 목록으로 프롬프트에 넣고, AI 응답의 각 인용 문장이 실제 사용자 문장에 포함되는지 정규화(유니코드 NFC·공백·문장부호) "
      "후 검사하여 아니면 제거하도록 하였다. 이제 리포트에는 학습자가 실제로 말한 문장만 남는다."),
    CODE('''
// MissionClearanceService.java — AI 가 인용한 문장이 실제 사용자 발화인지 검증
List<String> userSentences = userSentences(conversationHistory);  // role=user 만
promptVars.put("student_messages", numberedList(userSentences));  // 후보로 제공
...
if (!isQuotedFromUser(item.path("expression").asText(""), userSentences)) {
    continue;                                   // 후보 밖 인용은 버림
}
static boolean isQuotedFromUser(String quote, List<String> userSentences) {
    String q = normalizeForMatch(quote);        // NFC · 공백 · 문장부호 정규화
    return userSentences.stream().anyMatch(u -> normalizeForMatch(u).contains(q));
}'''),
    CAP('그림 4-14. 리포트 인용 문장 검증'),
    H(3, '4.3.6 레드카드·옐로카드와 토끼 변신 로딩 (2학기 추가)'),
    P("거북이의 실시간 교정은 심각도에 따라 두 가지 카드로 표시한다. 존댓말 수준이 틀리거나 대화가 성립하지 않는 치명적 오류(immediate)는 레드카드로 표시하고 해당 문장을 전송하지 않으며"
      "(\"Not sent\"), 대화는 이어갈 수 있는 사소한 실수(side)는 옐로카드로 표시한다. 카드에는 \"Politeness level\", \"Grammar\" 같은 사람이 읽는 라벨을 붙였다. "
      "미션 설명 패널은 기본으로 접혀 제목·턴 수(Turn n/max)·목표 한 줄만 보이고, 탭하면 펼쳐진다."),
    P("미션 생성에는 수 초가 걸리므로, 로딩 화면을 \"장난꾸러기 토끼가 사용자가 고른 역할로 변신하는 중\"이라는 컨셉으로 만들었다. 사용자가 입력한 역할이 문구에 들어가고"
      "(예: Tokki is transforming into a café barista…), 마술봉을 든 토끼(magic 표정)가 회전·반짝임 모션으로 변신한다. 또한 GPT가 낱자 모음을 조합형 자모로 출력하여 iOS에서 "
      "글자가 깨지던(▯) 문제를 찾아 표준 자모로 변환하도록 수정하였다."),
])

# ---- 4.4 Lab
d.replace('ai_caches 테이블을 활용한', 'ai_cache 테이블을 활용한')
d.replace('캐시 적중(Cache Hit) 시 0.1초대로 즉시 반환하고', '캐시 적중(Cache Hit) 시 1~2ms 만에 반환하고')
d.replace('Gemini를 호출한 뒤 결과를 검증·저장한다.', 'Gemini를 호출(3~5초)한 뒤 결과를 검증·저장한다. 이 수치는 2학기에 추가한 HIT/MISS 소요 시간 로그로 측정한 값이다.')
d.replace('Cache HIT ───→ 0.1초 즉시 반환', 'Cache HIT ───→ 1~2ms 반환')
d.replace('적중률이 극대화된다.', '같은 캐시를 재사용한다.')
p = d.find('이상으로 MARU의 네 가지 핵심 기능을 살펴보았다')
d.insert_before(p, [
    H(3, '4.4.4 입력 검증과 결과 화면 (2학기 추가)'),
    P("Gemini 호출 전에 서버가 입력을 검증한다. 빈 문장, 200자 초과, 한글이 없는 문장, 목록에 없는 범주·변형자, 같은 그룹의 변형자 중복(예: 과거+미래)은 400과 영어 안내로 거절한다. "
      "Explore 결과는 항상 정확히 3개를 보장하고, AI 응답이 깨지거나 개수가 모자라면 502, 40초 안에 응답이 없으면 504를 반환한다. 앱은 첫 요청(캐시 MISS)의 대기 시간 동안 "
      "거북이가 생각하는 로딩 화면을 보여주고 중복 요청을 막는다."),
    P("사용자 피드백에 따라 결과 화면도 바꾸었다. 그래머랩은 생성 후 입력부를 한 줄 요약으로 접고 원문과 변형 결과를 한 화면에서 비교하도록 하였으며, 결과 문장은 음절이 아닌 "
      "어절 단위로 줄바꿈하고 복사·발음 듣기를 제공한다. 한글랩은 조합 후 큰 주 버튼이 \"Try another\"(초기화)로 바뀌고, 결과 글자를 서버 TTS로 읽어준다. "
      "한국어 키보드가 없는 학습자를 위해 입력창 아래에 탭으로 넣을 수 있는 예문 칩도 추가하였다."),
    H(2, '4.5 캐릭터 시스템 — 토끼와 거북이 (2학기 추가)'),
    P("1학기 보고서는 한계점으로 \"토끼·거북이 컨셉이 이모지와 텍스트로만 표현된다\"는 점을 들었다. 2학기에는 이 학습 철학을 실제로 움직이는 캐릭터로 구현하였다. "
      "목표는 듀오링고처럼 학습 이벤트에 살아 반응하는 캐릭터였으며, 전문 애니메이터 없이 이틀 안에 완성해야 했으므로 \"그림은 AI 이미지, 움직임은 코드\"로 역할을 나누었다."),
    TABLE(['구성', '내용'], [
        ['표정 (그림)', '토끼·거북이 각 7종(idle·blink·happy·sad·thinking·talking·cheer) + 토끼 magic = PNG 15장. AI로 생성 후 배경 제거·공통 크롭·기준선 정렬·512px 후처리'],
        ['몸짓 (코드)', 'Flutter 애니메이션: 숨쉬기·깜빡임·등장 팝인·정답 점프·오답 찌그러짐·cheer 파티클·magic 회전과 반짝임. 접근성 설정(동작 줄이기) 시 정지'],
        ['공개 API', 'MaruCharacter(kind, mood, size, reactionKey) · MaruCharacterBubble(말풍선·타자 효과). 기분(mood)만 바꾸면 표정과 몸짓이 함께 바뀜'],
        ['폴백', '표정 이미지가 없으면 idle 이미지 + 해당 모션, 이미지 자체가 없으면 코드로 그린 플레이스홀더 → 그림 교체 시 기능 코드 수정 0줄'],
        ['적용 범위', '4개 기능 21개 화면 지점 + 홈 인사 (아래 표)'],
    ], [1700, 7660]),
    CAP('표 4-4. 캐릭터 시스템 구성'),
    TABLE(['기능', '토끼 🐰 (체험·연기)', '거북이 🐢 (분석·코칭)'], [
        ['Korean Lesson', '정답 happy, 듣기 퀴즈 반응, 완료 화면 cheer 점프', '조립 문제 오답 시 thinking + 힌트 말풍선'],
        ['Vocabulary', '짝맞추기 정답·오답 반응, Perfect Match cheer', '오늘의 복습 요약, 복습할 단어 없음 안내'],
        ['Mission Chat', '대화 상대 아바타, 입력 중 thinking, 역할 변신 로딩(magic)', '레드·옐로카드 교정, 리포트 판정 이유·Tutor\'s Note'],
        ['Language Lab', '한글 조합 성공 happy', 'AI 생성 중 thinking, 결과 설명 talking, 오류 sad'],
        ['홈', '인사(idle)', '인사(idle), All caught up 카드'],
    ], [1800, 3780, 3780]),
    CAP('표 4-5. 기능별 캐릭터 반응'),
    d.IMGS([(FEAT + '/character/screenshots/lead_approval_2_grid.png', (40, 640, 1250, 2260))], height_in=3.6),
    CAP('그림 4-17. 캐릭터 갤러리 — 토끼·거북이 표정 그리드 (개발용 단독 실행 화면)', center=True),
    P("캐릭터 코드는 기능 코드와 분리된 공유 모듈(lib/shared/characters)로 두고, 각 기능 화면은 정해진 명세(어떤 이벤트에 어떤 기분·크기)를 따라 한두 줄로 적용하였다. "
      "사용자 피드백에 따라 미션 미달성 리포트에서는 토끼가 우는(sad) 대신 생각하는 표정과 응원 문구를 쓰도록 바꾸었다."),
])
d.replace('이상으로 MARU의 네 가지 핵심 기능을 살펴보았다.', '이상으로 MARU의 네 가지 핵심 기능과 이를 하나로 묶는 캐릭터 시스템을 살펴보았다.')

# =====================================================================
# 5장
# =====================================================================
d.set_para('본 장에서는 MARU 앱의 주요 기능별 구현 결과 화면을 제시한다',
    "본 장에서는 MARU 앱의 주요 기능별 구현 결과 화면을 제시한다. 5.1~5.6절은 1학기에 캡처한 화면이며, 2학기에 디자인과 동작이 바뀐 화면은 5.7절에 따로 제시한다. "
    "2학기 화면은 iOS 시뮬레이터(iPhone 16/17 계열)에서 캡처하였고, 5.8절에서 운영 서버와 실제 iPhone에서의 동작을 정리한다.")
p = [x for x in body.iter(q('w:p')) if text(x).strip() == '5.7 구현 결과 종합'][0]
d.set_text(p, '5.9 구현 결과 종합')
S = FEAT
d.insert_before(p, [
    H(2, '5.7 2학기 개선 화면'),
    P("Korean Lesson은 🐢 단계에서 정답 덩어리를 그대로 보여주던 라벨을 없애고 회색 고정 블록과 빈칸 묶음으로만 구분하며, 오답 시 거북이가 힌트를 준다. 완료 화면은 실제 학습 내용과 점수를 보여준다."),
    d.IMGS([(S + '/lesson/screenshots/r3_LSN-1.7.1_after.png', None), (S + '/character/screenshots/apply_lesson_C1.png', None), (S + '/character/screenshots/apply_lesson_C3.png', None)]),
    CAP('[그림 5-19] Korean Lesson — 🐢 목표 문법 조립(이에요/예요), 오답 시 거북이 힌트(을/를), 레슨 완료', center=True),
    P("Vocabulary는 주제별 아이콘·색과 진행률을 가진 덱 카드로 다시 디자인하였고, 단어 카드의 평가 버튼에 FSRS가 계산한 다음 복습 간격이 표시된다."),
    d.IMGS([(S + '/vocab/screenshots/r2/after_1_decks.png', None), (S + '/vocab/screenshots/r2/after_4c_card_rating.png', None), (S + '/character/screenshots/apply_vocab_C2.png', None)]),
    CAP('[그림 5-20] Vocabulary — 덱 목록, 평가 버튼의 다음 간격(5m·1d·4d·14d), 짝맞추기 완료', center=True),
    P("Mission Chat은 설정 화면, 역할로 변신하는 토끼 로딩, 접히는 미션 패널과 새 말풍선 디자인을 적용하였다. 거북이 교정은 레드카드(전송 안 됨)와 옐로카드로 구분되고, "
      "목표를 달성하지 못하면 리포트가 판정 이유와 함께 재도전을 권한다."),
    d.IMGS([(S + '/mission/screenshots/r3_fe2/1_setup_top.png', None), (S + '/mission/screenshots/r3_fe2/12_loading_magic.png', None), (S + '/mission/screenshots/MSN-1.7.6_after_2_chat.png', None)]),
    CAP('[그림 5-21] Mission Chat — 시나리오 설정, 토끼 변신 로딩, 대화와 옐로카드', center=True),
    d.IMGS([(S + '/mission/screenshots/MSN-1.7.3_red_card.png', None), (S + '/mission/screenshots/r3_fe2/8_report_p1_not_cleared.png', None), (S + '/mission/screenshots/r3_fe2/9_report_p2.png', None)]),
    CAP('[그림 5-22] Mission Chat — 레드카드(Not sent), 미달성 리포트(Almost there!), 리포트 상세', center=True),
    P("Language Lab은 한글 조합 결과를 토끼가 축하하고, 그래머랩은 생성 중 거북이 로딩과 원문·결과를 한 화면에 보여주는 결과 화면을 갖추었다. 홈에는 캐릭터 인사와 오늘의 복습 카드가 항상 표시된다."),
    d.IMGS([(S + '/character/screenshots/apply_lab_C1.png', None), (S + '/character/screenshots/apply_lab_C3.png', None), (S + '/lesson/screenshots/r3_PM-1.7.2_home.png', None)]),
    CAP('[그림 5-23] Language Lab 한글랩·그래머랩 결과, 홈 화면(캐릭터 인사·All caught up 카드)', center=True),
    H(2, '5.8 운영 배포와 실기기 동작'),
    P("1학기에는 앱의 서버 주소가 개발 PC(localhost)로 고정되어 에뮬레이터·시뮬레이터에서만 동작하였다. 2학기에는 서버 주소를 빌드 시 지정하도록 바꾸고, 백엔드와 데이터베이스를 "
      "Railway에 배포하였다(6.5절). 운영 빌드를 설치한 실제 iPhone에서 Google 로그인에 성공하였고, 운영 서버를 통해 레슨·단어장·미션·실험실 기능을 사용할 수 있다."),
    TABLE(['항목', '내용'], [
        ['운영 서버', 'https://maru2026-production.up.railway.app (GitHub main push 시 자동 배포, 약 2분)'],
        ['운영 데이터', '레슨 15개(한글 12·문법 3), 덱 14개, 단어 5,561개, AI 캐시, TTS 캐시 — 사용자·학습 기록은 이관하지 않음'],
        ['실기기', 'iPhone(iOS) 운영 서버 연결 release 빌드, Google 로그인 확인 (2026-10-01)'],
        ['스모크 테스트', '유닛별 레슨 수, 인증이 필요한 API의 403, 잘못된 Google 토큰의 401, 덱 목록 200 확인'],
    ], [1800, 7560]),
    CAP('표 5-1. 운영 배포 현황'),
])
d.set_para('위 시연 화면들을 통해 MARU의 네 가지 핵심 기능',
    "위 시연 화면들을 통해 MARU의 네 가지 핵심 기능(Korean Lesson, Vocabulary System, Mission Chat, Language Lab)이 실제 동작하는 것을 확인하였다. 각 기능은 교착어로서의 "
    "한국어 구조를 학습 설계에 직접 반영하였으며, 형태소 분석(Kiwi), 간격 반복(FSRS-4.5), 대형 언어 모델(GPT-4o, Gemini), 서버 TTS, 유니코드 한글 조합 규칙이 토끼·거북이 캐릭터와 함께 "
    "하나의 일관된 학습 경험으로 통합되었다. 2학기에는 이 기능들이 개발 환경을 넘어 운영 서버와 실제 iPhone에서 동작함을 확인하였다.")

# =====================================================================
# 6장 (신규) — 2학기 개발 과정과 검증
# =====================================================================
h7 = [x for x in body.iter(q('w:p')) if text(x).strip() == '6. 결론 및 향후 계획'][0]
d.insert_before(h7, [
    H(1, '6. 2학기 개발 과정과 검증'),
    P("본 장에서는 2학기 개발을 어떤 방법으로 진행하고 어떻게 검증하였는지를 기술한다. 1인 팀이 짧은 기간에 네 기능과 캐릭터, 배포를 동시에 다듬어야 했으므로, "
      "작업을 나누고 충돌 없이 합치는 방법 자체가 중요한 설계 대상이었다."),
    H(2, '6.1 실사 기반 정직화'),
    P("2학기 작업은 2026년 9월에 수행한 코드 실사에서 출발하였다. 실사는 발표·보고서·신청서의 주장 문장마다 실제 코드 위치(파일:라인)와 로컬 DB 기록을 근거로 \"사실 / 부분적으로 사실 / 근거 없음\"을 "
      "판정하고, 쓰면 안 되는 주장과 대신 쓸 문장을 정리한 문서이다. 이후 모든 수정은 \"코드를 주장에 맞게 고치거나, 주장을 사실대로 바꾼다\"는 원칙을 따랐고, 제출물에 쓰는 문장은 "
      "세션들이 코드와 실측으로 확인한 표현만 모은 단일 목록에서 가져왔다."),
    TABLE(['1학기 주장', '실사 결과', '2학기 조치'], [
        ['FSRS 알고리즘 기반 복습', '고정 배수 계산식, FSRS 파라미터 미사용', '코드 수정: FSRS-4.5 표준 공식'],
        ['미션을 성공해야 수료증', '턴 수 도달 시 무조건 발급, 결과 "클리어" 고정', '코드 수정: AI 판정 + 서버 3-Zone 강제'],
        ['레슨 점수·별로 성취도 평가', '점수 100 고정, 첫 완료 시 별 3개', '코드 수정: 정답률 점수, 점수 기반 별'],
        ['배포하여 서비스', '서버 주소 localhost 고정, 배포 URL 없음', '코드 수정: 주소 설정화, Railway 배포'],
        ['이미 배운 부분은 분해하지 않음', '학습 이력 없음, 문장별 태그로 결정', '문구 수정: "레슨 목표 문법만 분해"'],
        ['병렬 호출 1.5초대', '측정 근거 없음', '측정 로그 추가 → "1.5~2초, 30~50% 단축"'],
        ['캐시 HIT 0.1초, 비용 90% 절감', '측정 근거 없음', '측정 로그 추가 → "HIT 1~2ms / MISS 3~5s", 비용 수치 삭제'],
        ['4x4 매칭 게임 / 8쌍', '실제 라운드당 5쌍', '앱 문구·보고서 수정'],
    ], [2600, 3300, 3460]),
    CAP('표 6-1. 실사로 확인한 주요 차이와 2학기 조치 (전체 목록은 부록 B)'),
    H(2, '6.2 병렬 세션 개발 방법론'),
    P("2학기 개발은 AI 코딩 에이전트(Claude Code) 세션 여러 개를 기능별로 병렬 운영하는 방식으로 진행하였다. 개발자(하도윤)는 PM 세션과 함께 계획·결정·통합을 맡고, 각 기능 세션은 "
      "정해진 범위 안에서 구현·테스트·기록을 수행하였다. 핵심은 세션들이 서로의 작업을 망가뜨리지 않도록 작업 공간과 소유권을 완전히 분리하는 것이었다."),
    TABLE(['장치', '내용'], [
        ['역할 분리', 'PM(계획·머지·배포) + 기능 4개 × 서버/앱 세션 + 캐릭터 팀(팀 PM·위젯 개발·에셋) + 제출물 세션'],
        ['작업 공간 격리', '기능마다 git worktree·브랜치(feat/lesson 등), 서버 포트(8081~8084), DB 복제본(maru_<기능>), iOS 시뮬레이터를 고정 배정'],
        ['파일 소유권', '기능별 소유 파일 목록을 명시하고 공유 파일(보안·설정·홈·pubspec 등)은 PM 전용으로 잠금 → 수정이 필요하면 요청 문서로'],
        ['계약 우선', '서버가 API 응답을 바꾸면 API_CONTRACT 문서를 먼저 갱신하고 앱 세션에 알림. 가능하면 필드 추가로 호환 유지'],
        ['데이터 변경', 'DB 수정은 멱등 SQL 패치로만, 스키마는 추가만 → 개발 DB 검증 후 운영 DB에 같은 패치 적용'],
        ['문서 체계', 'Phase > Step > Task 계획과 태스크 ID([LSN-1.2.3] 등), 세션별 작업 로그와 인수인계(HANDOFF), 상태판, 결정 기록 — 컨텍스트가 요약돼도 이어서 작업'],
        ['통합', 'PM이 기능 브랜치를 main에 머지할 때마다 서버 테스트·정적 분석·앱 테스트를 실행. 12차례 머지에서 충돌 0건'],
    ], [1900, 7460]),
    CAP('표 6-2. 병렬 세션 개발을 위한 장치'),
    P("이 방식으로 이틀(2026-09-30 ~ 10-01) 동안 네 기능의 버그 수정·사실화, 캐릭터 시스템 신설, 두 차례의 사용자 피드백 반영, 운영 배포까지 진행할 수 있었다. 반면 세션이 많아질수록 "
      "같은 worktree를 쓰는 짝 세션이 git 인덱스를 공유하는 문제, 시뮬레이터 ID를 명시하지 않으면 다른 세션의 기기를 잡는 문제처럼 조율 비용이 생겼고, 이는 규칙 문서에 교훈으로 기록하여 반복을 막았다."),
    H(2, '6.3 사용자 피드백 3라운드'),
    P("기능 수정과 별도로, 개발자가 학습자 입장에서 앱을 직접 끝까지 사용하며 불편한 점을 스크린샷과 함께 정리하는 피드백 라운드를 세 차례 진행하였다. 피드백은 각 기능 계획에 태스크로 "
      "등록되어 처리되었다. 다만 이는 개발자 본인의 사용 피드백이며, 외부 학습자를 대상으로 한 사용성 평가는 아직 수행하지 못하였다(7.2.5절)."),
    TABLE(['라운드', '시점', '주요 피드백', '반영 결과'], [
        ['1차', '09-15 ~ 09-30', '코드 실사와 기능별 완주 점검: 고정 문구·가짜 점수·무한 로딩·평가 오저장 등', '4개 기능 P0·P1 버그 수정, 오류 처리 통일'],
        ['2차', '09-30', '기기 TTS 음질, 한글 카드 네비게이션 중복, 단어장이 너무 단순함, 짝맞추기 애니메이션, 실험실 결과를 보려면 스크롤 필요', '서버 TTS, 네비게이션 통합, 단어장 리디자인, Match 애니메이션, 결과 한 화면'],
        ['3차', '10-01', '🐢 단계 라벨이 정답을 노출, 미션 로딩 컨셉, 교정 카드 색 구분, 미션 패널 접기, 채팅방 미감, 우는 토끼, 리포트에 내가 안 쓴 문장, 홈 복습 카드', '라벨 제거, 토끼 변신 로딩, 레드/옐로카드, 채팅·설정·리포트 리디자인, 사용자 문장 검증, 복습 카드 상시 표시'],
    ], [900, 1400, 3800, 3260]),
    CAP('표 6-3. 사용자 피드백 라운드와 반영 결과'),
    d.IMGS([(S + '/lesson/screenshots/r3_LSN-1.7.1_before.png', None), (S + '/lesson/screenshots/r3_LSN-1.7.1_after.png', None),
            (S + '/vocab/screenshots/r2/before_4_card_front.png', None), (S + '/vocab/screenshots/r2/after_4_card_front.png', None)], height_in=3.3),
    CAP('[그림 6-1] 피드백 반영 전후 — 🐢 단계 정답 라벨 제거(왼쪽 두 장), 단어 카드 리디자인(오른쪽 두 장)', center=True),
    H(2, '6.4 자동 테스트와 통합'),
    P("1학기 말에는 서버 테스트 일부가 컴파일되지 않아 전체 테스트를 실행할 수 없었고, 앱 테스트는 기본 템플릿뿐이었다. 2학기에는 먼저 깨진 테스트를 복구하고 테스트용 설정을 분리한 뒤, "
      "기능을 고칠 때마다 관련 테스트를 추가하였다(FSRS 공식, 3-Zone 규칙, 리포트 인용 검증, 입력 검증, 캐릭터 위젯 등)."),
    TABLE(['구분', '결과 (2026-10-01 최종 머지 기준)'], [
        ['서버 (JUnit, ./gradlew test)', '123개 전부 통과'],
        ['앱 정적 분석 (flutter analyze)', '경고 0건'],
        ['앱 테스트 (flutter test)', '67개 통과 (2개 skip)'],
        ['수동 검증', '기능별 시뮬레이터 완주, 서버 curl 확인, 운영 스모크, 실기기 로그인'],
    ], [3200, 6160]),
    CAP('표 6-4. 자동 테스트 결과'),
    H(2, '6.5 배포와 데이터 이관'),
    P("배포 전 Railway 데이터베이스를 확인한 결과, 스키마만 있고 데이터가 0건이었다. 즉 1학기의 \"배포\"는 서버만 올라가 있고 콘텐츠가 없는 상태였다. 2학기에는 운영 DB를 백업한 뒤 "
      "main 브랜치를 배포하고, 로컬 원본 DB에서 콘텐츠 테이블 5개(lessons 15행, word_categories 14행, words 5,561행, ai_cache, tts_cache)만 단일 트랜잭션으로 이관하였다. "
      "사용자 계정·진행 기록·수료증·FSRS 기록은 개발용 데이터이므로 옮기지 않았다. 이관 후 행 수가 로컬과 일치하는지, 시퀀스가 정상인지 확인하고 스모크 테스트를 수행하였다."),
])
d.set_text(h7, '7. 결론 및 향후 계획')
for old_, new_ in [('6.1 개발 성과 요약', '7.1 개발 성과 요약'), ('6.2 현재 한계점', '7.2 현재 한계점'),
                   ('6.2.1 Tap-to-Translate 하드코딩 문제', '7.2.1 Tap-to-Translate 정적 규칙 문제'),
                   ('6.2.2 Mission Chat의 엣지케이스 및 난이도 제어 한계', '7.2.2 Mission Chat의 난이도 제어와 교정 정확도'),
                   ('6.2.3 Korean Lesson 콘텐츠 품질', '7.2.3 Korean Lesson 콘텐츠 규모'),
                   ('6.2.4 UI/UX 완성도', '7.2.4 UI/UX 완성도'),
                   ('6.2.5 토끼·거북이 캐릭터 시각화 미흡', '7.2.5 학습 효과 검증과 알고리즘 개인화'),
                   ('6.3 향후 개발 계획', '7.3 향후 개발 계획'), ('6.4 맺음말', '7.4 맺음말')]:
    hp = [x for x in body.iter(q('w:p')) if text(x).strip() == old_]
    d.set_text(hp[0], new_)

d.set_para('본 프로젝트는 교착어로서의 한국어 구조를 학습 설계에',
    "본 프로젝트는 교착어로서의 한국어 구조를 학습 설계에 직접 반영한 모바일 앱 MARU를 Flutter(iOS/Android) + Spring Boot 3.5 + PostgreSQL 기반으로 설계·구현하고, "
    "2학기에 Railway 운영 서버에 배포하였다. 개발 초기에 설정한 네 가지 목표(M-A-R-U)의 달성 여부를 다음과 같이 정리한다.")
old = d.table_after('2학기에 Railway 운영 서버에 배포하였다')
old.addprevious(TABLE(['목표', '구현 내용', '핵심 기술'], [
    ['M — Morpheme-based Learning', 'Kiwi 기반 조립 문제 생성 도구로 레슨 목표 문법만 분해하는 2단계(🐰 어절 / 🐢 목표 형태소) 조립 문제 생성. 한글 12레슨 + 문법 3레슨(은/는, 이에요/예요, 을/를), 정답률 점수·별·이어하기, 서버 TTS', 'kiwipiepy, kiwi-generator, 멱등 SQL 패치, JSONB 레슨 데이터, OpenAI TTS'],
    ['A — Adaptive Vocabulary', 'FSRS-4.5 표준 공식·기본 파라미터로 단어별 안정성·난이도·인출 가능성을 계산해 다음 복습일 산출. 오늘의 복습, 다음 간격 미리보기, 5,561단어·14덱, 짝맞추기', 'FsrsAlgorithm.java, FsrsProgress, Gemini 배치 번역'],
    ['R — Roleplay Mission', 'GPT-4o 토끼(연기)·거북이(채점) 병렬 호출로 한 턴 1.5~2초. 서버 강제 3-Zone, AI 목표 달성 판정, 사용자 문장만 인용하는 리포트, 레드/옐로카드', 'ChatTurnService, MissionClearanceService, 프롬프트 템플릿'],
    ['U — Upgrade Your Expression', '기기 내 유니코드 한글 조합(Hangeul Lab)과 Gemini 문법 변형(AI Grammar Lab). 정렬 캐시 키, HIT 1~2ms / MISS 3~5s, 입력 검증', 'hangeul_combiner.dart, AiLabService, ai_cache'],
    ['캐릭터 (2학기)', '토끼·거북이 표정 15장 + 코드 모션, 4개 기능 21개 지점 + 홈', 'MaruCharacter, MaruCharacterBubble'],
], [2100, 4560, 2700]))
body.remove(old)
d.set_para('네 가지 목표 모두 실제 동작하는 기능으로 구현되었으며',
    "네 가지 목표 모두 실제 동작하는 기능으로 구현되었으며, 2학기에는 발표에서 주장한 내용과 실제 동작의 차이를 찾아 코드를 고치거나 문장을 바로잡았다. 특히 kiwi-generator 파이프라인은 "
    "레슨의 CSV 행과 목표 품사만으로 조립 문제를 생성하고 SQL 패치로 반영하므로, 기존 문제 유형 안에서는 앱·서버 코드를 고치지 않고 콘텐츠를 늘릴 수 있다. "
    "또한 서버 123개·앱 67개의 자동 테스트와 운영 배포를 통해 개발 환경을 넘어 실제 기기에서 동작하는 서비스의 기반을 갖추었다.")
d.set_para('구현을 완료하였으나, 개발 과정에서 시간 및 범위의',
    "2학기에 1학기 한계점 일부(캐릭터 시각화, UI/UX, 미션 판정)는 해소하였으나, 다음과 같은 한계가 남아 있음을 인식하고 있다.")
p = d.find('현재 Tap-to-Translate 기능에서 어절을 탭할 때')
d.insert_after(p, [P("2학기에 기호·이름 표시 오류는 정리하였으나, 뜻풀이가 정적 규칙표에 의존하는 구조는 그대로이다.")])
p = d.find('둘째, 학습자가 시나리오에서 완전히 벗어난')
d.insert_after(p, [P("2학기에는 서버가 3-Zone 규칙과 최대 턴을 강제하고 AI 오류·형식 깨짐을 명확한 오류로 처리하여 대화가 멈추거나 끝나지 않는 문제는 해소하였다. 그러나 거북이 교정과 "
                     "목표 달성 판정의 정확도는 여전히 프롬프트에 의존하며, 이를 측정할 평가 데이터셋은 없다.")])
d.set_para('kiwi-generator 파이프라인은 curriculum.csv에 정의된',
    "kiwi-generator 파이프라인은 curriculum.csv에 정의된 문장과 Target_POS를 기반으로 퀴즈를 생성하므로, 최종 학습 콘텐츠의 품질은 CSV 데이터의 품질에 직결된다. 현재 문법 레슨은 "
    "3개(조립 문제 7개)이고 Unit 2·3은 \"Coming soon\" 상태로, 서비스 수준의 커리큘럼으로는 충분하지 않다. 소개·연습 단계 JSON은 사람이 작성해야 하며, 문장의 자연스러움·난이도 배열·"
    "목표 문법의 다양성 측면에서 교육 전문가와의 협력이 필요하다. 또한 단어 데이터의 번역·예문은 AI가 생성한 것으로 전수 검수가 이루어지지 않았다.")
d.set_para('전체적인 UI/UX는 기능 구현 중심으로 설계되어 있어',
    "2학기에 세 차례의 피드백 라운드로 단어장·미션·실험실 화면을 다시 디자인하고, 로딩·오류 상태와 작은 화면 레이아웃을 정리하였다. 그러나 화면 전환 애니메이션의 일관성, "
    "Android 실기기 검증, 다크모드·접근성은 아직 충분히 다루지 못하였다.")
d.set_para('MARU의 핵심 학습 철학인 토끼(유창성)',
    "1학기의 한계였던 캐릭터 시각화는 2학기에 해소하였다(4.5절). 대신 학습 효과에 대한 검증이 가장 큰 한계로 남는다. 현재 사용자는 개발 계정뿐이며, 외부 학습자를 대상으로 한 사용성 평가나 "
    "기억 유지율 측정은 수행하지 않았다. FSRS-4.5는 기본 파라미터를 사용하므로 개인의 복습 기록으로 파라미터를 최적화하지 않으며, 공식 구현체(py-fsrs)와의 교차 검증도 하지 못하였다. "
    "덱의 Word Study는 FSRS 추천 순서가 아닌 등급·ID 순 30단어 묶음이고, 조립 문제의 분해 깊이도 학습자 개인의 습득 기록이 아닌 문장별 목표 문법으로 정해진다.")
old = d.table_after('7.3 향후 개발 계획')
old.addprevious(TABLE(['구분', '개발 항목', '내용'], [
    ['단기 (~11월)', '웹 체험판·랜딩 페이지', '졸업전시(11/6) 관람객이 설치 없이 체험할 수 있는 Flutter Web 체험판(게스트 로그인·비용 제한)과 소개 페이지'],
    ['단기 (~6개월)', '사용성 평가', '외부 학습자 대상 사용성 테스트와 설문, 피드백 라운드 정례화'],
    ['단기 (~6개월)', 'Tap-to-Translate 동적 설명', 'LLM 기반 문맥 인식 형태소 설명 생성으로 정적 규칙표 대체, ai_cache 연동으로 비용 최소화'],
    ['중기 (~12개월)', 'Korean Lesson 콘텐츠 확장', '교육 전문가 협력 커리큘럼(Unit 2·3 포함), 학습한 문법을 새 어휘에 적용하는 전이 학습 단계, 학습자별 습득 기록에 따른 분해 깊이 조절'],
    ['중기 (~12개월)', 'FSRS 개인화', '복습 기록이 쌓이면 사용자별 파라미터 최적화, py-fsrs 교차 검증, Word Study에 FSRS 큐 적용'],
    ['중기 (~12개월)', '발음 평가 (STT)', '음성 인식 기반 발음 피드백, Mission Chat 음성 대화 모드'],
    ['장기 (~24개월)', '다국어 지원 · 학습 분석', '일본어·중국어·스페인어 UI 현지화, FSRS·미션·레슨 데이터를 시각화한 학습 분석 대시보드, 학습 효과 측정 연구'],
], [1600, 2400, 5360]))
body.remove(old)
d.replace("그것이 바로 이 프로젝트가 '졸업 작품의 완성'이 아니라 임을 의미한다고 생각한다.",
          "그것이 바로 이 프로젝트가 '졸업 작품의 완성'이 아니라 '서비스의 시작'임을 의미한다고 생각한다.")
d.replace('콘텐츠의 양과 질, UI/UX의 완성도, 엣지케이스 처리, 캐릭터 시각화 모두', '콘텐츠의 양과 질, 학습 효과 검증, 알고리즘 개인화 모두')
p = d.find("'서비스의 시작'임을")
d.insert_after(p, [P("2학기에 가장 크게 배운 것은 \"동작한다\"와 \"주장한 대로 동작한다\"는 다르다는 점이다. 발표 문장 하나하나를 코드와 대조하며 고치는 과정에서, 화려한 수치보다 "
                     "검증할 수 있는 사실이 프로젝트를 더 단단하게 만든다는 것을 확인하였다.")])

# =====================================================================
# 참고문헌 + 부록
# =====================================================================
d.set_text([x for x in body.iter(q('w:p')) if text(x).strip() == '7. 참고 문헌'][0], '8. 참고 문헌')
last_ref = d.find('Spring Boot 3.5 Reference Documentation')
REFS = [
    "[21] open-spaced-repetition. (2024). The Algorithm — FSRS-4.5 (fsrs4anki Wiki) [Software documentation]. GitHub. https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm",
    "[22] open-spaced-repetition. (2024). py-fsrs: Python package for FSRS [Software]. GitHub. https://github.com/open-spaced-repetition/py-fsrs",
    "[23] OpenAI. (2025). Text to speech — Audio API Guide. https://platform.openai.com/docs/guides/text-to-speech",
    "[24] Railway. (2025). Railway Documentation. https://docs.railway.com",
]
ref_els = []
for r_ in REFS:
    e_ = copy.deepcopy(last_ref)
    d.set_text(e_, r_)
    ref_els.append(e_)
anchor_ = last_ref
for e_ in ref_els:
    anchor_.addnext(e_); anchor_ = e_
last_ref = anchor_
d.insert_after(last_ref, [
    H(1, '부록 A. 1학기 → 2학기 변경 요약', page_break=True),
    TABLE(['영역', '1학기 (2026-06)', '2학기 (2026-10)'], [
        ['배포', '서버 주소 localhost 고정, 에뮬레이터·시뮬레이터에서만 동작', 'Railway 운영 서버 + 콘텐츠 이관, 실제 iPhone에서 Google 로그인·전 기능 동작'],
        ['형태소 조립', '목표 품사가 있는 어절을 형태소 전부로 분해, 구두점 블록·"이예요"·"~고" 비문 오답, 조립 문제 4개(2개 수작업)', '목표 문법 형태소만 분리, 이형태 오답, 선택지 고유 ID, 파이프라인 인자화·SQL 패치, 문법 레슨 3개·조립 문제 7개'],
        ['레슨', '점수 100 고정, 첫 완료 시 별 3개, 고정 설명 문구, 듣기 퀴즈 5문제 고정', '정답률 점수·점수 기반 별·최고 기록, 이어하기, 데이터 기반 문구, 항목 수 기반 퀴즈, 을/를 레슨 추가'],
        ['TTS', '기기 TTS(flutter_tts)', 'OpenAI gpt-4o-mini-tts 서버 TTS + DB 캐시, 기기 TTS 폴백'],
        ['FSRS', '고정 배수(×1.2/×2/×3), 경과일·인출 가능성 미반영', 'FSRS-4.5 표준 공식·기본 파라미터, 다음 간격 미리보기, 평가 오저장 버그 수정'],
        ['짝맞추기', '"4x4 게임"·"8쌍" 표기, 라운드·진행 수 고정', '라운드당 5쌍(실제 동작대로), 실제 단어 수 기반 라운드, 애니메이션'],
        ['미션 판정', 'minTurns+2 도달 시 무조건 발급, 결과 "클리어" 고정', 'AI 목표 달성 판정(cleared/not cleared), 서버 강제 3-Zone·maxTurns, 판정 이유'],
        ['미션 리포트', '사용자가 보내지 않은 문장이 인용될 수 있음', '사용자 문장만 후보로 제공 + 서버 검증'],
        ['미션 UI', '분홍 교정 카드, 이모지 아바타', '레드/옐로카드, 접히는 패널, 토끼 변신 로딩, 채팅·설정·리포트 리디자인'],
        ['실험실', '예외 원문 노출, 키를 URL에 포함, "HIT 0.1초" 근거 없음', '오류 코드·영어 안내, 키 헤더 전달, 입력 검증, HIT 1~2ms/MISS 3~5s 실측, 결과 화면'],
        ['캐릭터', '이모지(🐰/🐢)와 텍스트', '표정 PNG 15장 + 코드 모션, 21개 지점 + 홈'],
        ['오류·보안', '200+null, 무한 로딩, 인증 없는 디버그 API, JWT 원문 로그', '공통 오류 규칙(4xx/5xx+문장), 디버그 API 삭제, 로그 정리'],
        ['홈·통계', 'Stats·Settings "Coming Soon", 복습 배너는 1개 이상일 때만', 'Stats·Settings 화면, 로그아웃 확인, 복습 카드 항상 표시'],
        ['테스트', '서버 테스트 일부 컴파일 불가, 앱 테스트 템플릿뿐', '서버 123개·앱 67개 통과, 정적 분석 경고 0'],
        ['API', '17개', '22개 (진행 조회·TTS 등 추가)'],
    ], [1500, 3900, 3960]),
    H(1, '부록 B. 1학기 문장 정정 목록'),
    P("아래는 1학기 보고서·발표에서 실제 동작과 달랐던 표현과 이 개정판에서 바꾼 표현이다. 왼쪽 표현은 이후 제출물에서 사용하지 않는다."),
    TABLE(['1학기 표현', '정정한 표현', '위치'], [
        ['학습자가 이미 배운 부분은 분해하지 않는다', '레슨의 목표 문법만 형태소로 분해한다 (분해 여부는 문장별 목표 문법으로 결정)', '4.1.2'],
        ['FSRS 알고리즘(안정성 × 고정 배수)', 'FSRS-4.5 표준 공식과 기본 파라미터로 다음 복습일 산출', '2.2.3, 4.2.3'],
        ['병렬 호출로 응답 1.5초대', '한 턴 약 1.5~2초, 순차 대비 30~50% 단축 (실측)', '4.3.2'],
        ['캐시 적중 시 0.1초대', '캐시 HIT 1~2ms, MISS(Gemini 호출) 3~5초 (실측)', '4.4.3'],
        ['미션 종료 시 클리어증 발급', 'AI 코치가 목표 달성 여부를 판정, 달성 시 클리어·미달 시 재도전 권유, 피드백은 항상 제공', '4.3.3, 4.3.5'],
        ['매칭 게임 8쌍 추출', '라운드당 5쌍', '4.2.4'],
        ['5,965개의 단어를 저장', '원천 5,965개 → 최종 5,561개 단어', '3.3.3'],
        ['CSV 한 줄 추가만으로 새 퀴즈 자동 생성', '레슨 행이 있으면 CSV 행 추가 + 파이프라인 실행으로 조립 문제 생성(소개·연습 단계는 수작업)', '4.1.3'],
        ['Kiwi가 연동된 파이프라인', 'Kiwi 기반 오프라인 콘텐츠 생성 도구', '2.3.2'],
        ['FSI 1~5단계 중 최고 난이도', 'FSI Category IV (네 범주 중 가장 어려움)', '1.1.2'],
        ['ai_caches 테이블', 'ai_cache 테이블', '4.4.3'],
    ], [3100, 4900, 1360]),
])

# =====================================================================
# 장 제목 페이지 나눔, 캡션 번호 재부여
# =====================================================================
chap = None
counters = {}
cap_re = re.compile(r'(\[?)(그림|표) ([0-9A-Z]+)-(\d+)(\]?)')
for el in body:
    if el.tag != q('w:p'):
        continue
    ppr = el.find(q('w:pPr'))
    st = ppr.find(q('w:pStyle')) if ppr is not None else None
    t = text(el).strip()
    if st is not None and st.get(q('w:val')) == '1' and t:
        m = re.match(r'^(\d+)\.|^부록 ([A-Z])\.', t)
        if m:
            chap = m.group(1) or m.group(2)
            if ppr.find(q('w:pageBreakBefore')) is None:
                ppr.insert(1, etree.Element(q('w:pageBreakBefore')))
        continue
    if chap and cap_re.match(t) and len(t) < 160 and ('그림' in t[:4] or t.startswith('표') or t.startswith('[')):
        def sub(m):
            kind = m.group(2)
            counters[(chap, kind)] = counters.get((chap, kind), 0) + 1
            return f'{m.group(1)}{kind} {chap}-{counters[(chap, kind)]}{m.group(5)}'
        new = cap_re.sub(sub, t)
        if new != t:
            d.set_text(el, new)

for el in body:
    if el.tag != q('w:p'):
        continue
    ppr = el.find(q('w:pPr'))
    st = ppr.find(q('w:pStyle')) if ppr is not None else None
    if st is not None and st.get(q('w:val')) in ('1', '2', '3') and ppr.find(q('w:keepNext')) is None:
        ppr.insert(1, etree.Element(q('w:keepNext')))

for el in body:
    n_ = el.getnext()
    if el.tag == q('w:p') and n_ is not None and n_.tag == q('w:p') and n_.find('.//' + q('w:drawing')) is not None \
            and el.find('.//' + q('w:drawing')) is None and 0 < len(text(el)) < 200:
        ppr = el.find(q('w:pPr'))
        if ppr is None:
            ppr = etree.Element(q('w:pPr')); el.insert(0, ppr)
        if ppr.find(q('w:keepNext')) is None:
            st = ppr.find(q('w:pStyle'))
            ppr.insert(1 if st is not None else 0, etree.Element(q('w:keepNext')))

# =====================================================================
# 목차 재생성
# =====================================================================
pages = json.load(open(sys.argv[1])) if len(sys.argv) > 1 and os.path.exists(sys.argv[1]) else {}
heads = []
for el in body:
    if el.tag != q('w:p'):
        continue
    ppr = el.find(q('w:pPr'))
    st = ppr.find(q('w:pStyle')) if ppr is not None else None
    t = text(el).strip()
    if st is None or not t:
        continue
    lv = st.get(q('w:val'))
    if lv in ('1', '2', '3'):
        m = re.match(r'^(\d+(?:\.\d+)*)\.?\s', t)
        if t == '개발 배경':
            t = '1.1 개발 배경'
            pass
        if (m and m.group(1).count('.') + 1 == int(lv)) or t.startswith('부록') or t == '1.1 개발 배경':
            heads.append((int(lv), t))
anchor = toc_title
for lv, t in heads:
    tpl = copy.deepcopy(toc_templates[min(lv, 3)])
    runs = tpl.findall(q('w:r'))
    # 템플릿: [제목 run(+tab)] [tab run?] [번호 run]
    tr = [r for r in runs if r.find(q('w:t')) is not None]
    title_r, num_r = tr[0], tr[-1]
    label = re.sub(r'^(\d+(?:\.\d+)*\.?)\s+', lambda m: m.group(1) + '  ', t)
    label = label.replace(' (2학기 추가)', '').replace(' (2학기 재작성)', '').replace(' — 2학기 추가', '')
    title_r.find(q('w:t')).text = label
    title_r.find(q('w:t')).set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
    num_r.find(q('w:t')).text = str(pages.get(t, '00'))
    anchor.addnext(tpl)
    anchor = tpl
json.dump([t for _, t in heads], open(SCR + '/heads.json', 'w'), ensure_ascii=False)

d.save()
out = OUT_DIR + '/MARU_최종보고서_2학기.docx'
if os.path.exists(out):
    os.remove(out)
subprocess.run(f'cd "{WORK}" && zip -qXr "{out}" .', shell=True, check=True)
print('built', out, os.path.getsize(out) // 1024, 'KB', len(heads), 'headings')
