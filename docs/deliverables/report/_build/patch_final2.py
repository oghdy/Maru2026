s = open('build_report.py', encoding='utf8').read()
def R(old, new, count=1):
    global s
    n = s.count(old); assert n == count, (n, old[:70])
    s = s.replace(old, new)
def B(start, end, new):
    global s
    assert s.count(start) == 1, (s.count(start), start[:70])
    a = s.index(start); b = s.index(end, a); s = s[:a] + new + s[b + len(end):]

# ================= 5장 전체 재구성 =================
B("d.set_para('본 장에서는 MARU 앱의 주요 기능별 구현 결과 화면을 제시한다',", "    CAP('표 5-1. 운영 배포 현황'),\n])",
'''d.set_para('본 장에서는 MARU 앱의 주요 기능별 구현 결과 화면을 제시한다',
    "본 장에서는 MARU 앱의 주요 기능별 구현 결과 화면을 제시한다. 화면은 iOS 시뮬레이터(iPhone 16·17 계열)에서 캡처하였으며, 각 기능의 핵심 흐름을 순서대로 확인할 수 있도록 구성하였다. "
    "5.6절에서는 운영 서버와 실제 iPhone에서의 동작을 정리한다.")
# 1학기 화면(5.1~5.6) 삭제
el = [x for x in body.iter(q('w:p')) if text(x).strip() == '5.1 온보딩 및 소셜 로그인'][0]
p = [x for x in body.iter(q('w:p')) if text(x).strip() == '5.7 구현 결과 종합'][0]
while el is not p:
    nxt = el.getnext(); body.remove(el); el = nxt
d.set_text(p, '5.7 구현 결과 종합')
S = FEAT
SH = OUT_DIR + '/shots'
d.insert_before(p, [
    H(2, '5.1 홈 화면과 학습 통계'),
    P("Google 또는 Apple 계정으로 로그인하면 홈 화면으로 진입한다. 홈에서는 토끼와 거북이가 인사하고, 연속 학습일(스트릭)과 별, 오늘 복습할 단어 수, 네 가지 기능 카드가 표시된다. "
      "Stats 탭은 연속 학습일·별·완료 레슨 수·학습 시간을 보여준다."),
    d.IMGS([(SH + '/01_home.png', None), (S + '/lab/screenshots/r5/after_5_home_lab_subtitle.png', None), (SH + '/02_stats.png', None)]),
    CAP('[그림 5-1] 홈 화면(복습할 단어가 있을 때 / 없을 때 All caught up 카드), 학습 통계 화면', center=True),
    H(2, '5.2 Korean Lesson — 한글 레슨과 형태소 조립'),
    P("레슨은 유닛별로 구성된다. Unit 0은 한글 12레슨, Unit 1은 문법 3레슨이며, 레슨 목록에는 완료 표시·별·진행 중 상태가 나타난다. 한글 레슨은 자모 카드와 발음 듣기, 듣기 퀴즈로 진행한다."),
    d.IMGS([(SH + '/03_units.png', None), (SH + '/04_lesson_list.png', None), (SH + '/05_hangeul_card.png', None)]),
    CAP('[그림 5-2] 유닛 선택, 레슨 목록(완료·별·진행 중 표시), 한글 자모 카드', center=True),
    P("문법 레슨의 조립 문제는 🐰 단계에서 어절 단위로 문장을 조립한 뒤, 🐢 단계에서 그 레슨의 목표 문법만 형태소로 분리해 다시 조립한다. 목표가 아닌 어절은 회색 고정 블록으로 유지되고, "
      "오답이면 거북이가 힌트를 준다. 완료 화면은 학습한 내용을 정리해 보여준다."),
    d.IMGS([(S + '/lesson/screenshots/r3_LSN-1.7.1_after.png', None), (S + '/character/screenshots/apply_lesson_C1.png', None), (S + '/character/screenshots/apply_lesson_C3.png', None)]),
    CAP('[그림 5-3] 🐢 목표 문법 조립(이에요/예요), 오답 시 거북이 힌트(을/를), 레슨 완료', center=True),
    H(2, '5.3 Vocabulary System — FSRS 간격 반복 단어 학습'),
    P("단어장은 14개 주제 덱으로 구성되며, 덱마다 진행률이 표시된다. 단어 카드를 뒤집어 뜻과 예문을 확인한 뒤 Again·Hard·Good·Easy로 평가하면, 버튼 아래에 FSRS가 계산한 다음 복습 간격이 표시된다."),
    d.IMGS([(S + '/vocab/screenshots/r2/after_1_decks.png', None), (S + '/vocab/screenshots/r2/after_4c_card_rating.png', None), (S + '/vocab/screenshots/r2/after_5_card_back.png', None)]),
    CAP('[그림 5-4] 덱 목록, 단어 카드와 평가 버튼(다음 간격 5m·1d·4d·14d), 카드 뒷면', center=True),
    P("짝맞추기 게임은 라운드당 5쌍의 한글 단어와 영어 뜻을 맞춘다. 오늘의 복습은 FSRS 복습 기한이 된 단어만 제시하며, 끝나면 거북이가 요약을 보여준다."),
    d.IMGS([(S + '/vocab/screenshots/r2/after_7_match.png', None), (S + '/character/screenshots/apply_vocab_C2.png', None), (S + '/character/screenshots/apply_vocab_C3_review_done.png', None)]),
    CAP('[그림 5-5] 짝맞추기 게임, Perfect Match 완료, 오늘의 복습 완료 요약', center=True),
    H(2, '5.4 Mission Chat — LLM 역할극 미션 대화'),
    P("미션 설정 화면에서 난이도, 상대와의 관계, 친밀도, 상대 역할을 고르면 토끼가 그 역할로 변신하는 로딩 뒤 대화가 시작된다. 상단 패널에는 미션 제목·난이도·턴 수·목표가 표시된다."),
    d.IMGS([(S + '/mission/screenshots/r4_fe2/1_setup_difficulty.png', None), (S + '/mission/screenshots/r4_fe2/2_setup_role.png', None), (S + '/mission/screenshots/r3_fe2/12_loading_magic.png', None)]),
    CAP('[그림 5-6] 미션 설정(난이도·관계), 역할 입력, 토끼 변신 로딩', center=True),
    P("대화 중 거북이는 작은 실수를 옐로카드로, 대화가 성립하지 않는 큰 실수를 레드카드(해당 문장은 전송되지 않음)로 알려준다. 막히면 Help me Turtle로 힌트 문장을 받을 수 있다."),
    d.IMGS([(S + '/mission/screenshots/r4_fe2/5_chat_easy_short_reply.png', None), (S + '/mission/screenshots/MSN-1.7.6_after_2_chat.png', None), (S + '/mission/screenshots/MSN-1.7.3_red_card.png', None)]),
    CAP('[그림 5-7] Easy 난이도 대화, 옐로카드 교정, 레드카드(Not sent)', center=True),
    P("미션이 끝나면 리포트가 목표 달성 여부와 판정 이유, 잘한 표현·고칠 표현·다음 목표를 보여준다. 달성하지 못하면 재도전을 권한다. 지난 리포트는 목록에서 다시 볼 수 있다."),
    d.IMGS([(S + '/mission/screenshots/r4_fe2/6_report_cleared_easy_badge.png', None), (S + '/mission/screenshots/r3_fe2/8_report_p1_not_cleared.png', None), (S + '/mission/screenshots/r4_fe2/7_list_easy_badge.png', None)]),
    CAP('[그림 5-8] 미션 달성 리포트, 미달성 리포트(Almost there!), 리포트 목록', center=True),
    H(2, '5.5 Language Lab — 한글 조합과 Sentence Lab'),
    P("Language Lab 메뉴에서는 실험복을 입은 토끼(Hangeul Lab)와 거북이(Sentence Lab)가 맞이한다. Hangeul Lab은 초성·중성·종성을 고르면 기기 안에서 바로 글자를 조합하고 발음을 들려준다."),
    d.IMGS([(S + '/lab/screenshots/r5/after_outfit_1_menu.png', None), (S + '/lab/screenshots/r5/after_outfit_2_hangeul_idle.png', None), (S + '/lab/screenshots/r5/after_outfit_3_hangeul_happy.png', None)]),
    CAP('[그림 5-9] Language Lab 메뉴, Hangeul Lab 자모 선택, 조합 결과', center=True),
    P("Sentence Lab은 문장을 입력하고 Explore(한 규칙으로 변형 3개) 또는 Combine(여러 규칙을 한 문장에 조합)을 고른다. 거북이가 실험하는 로딩 뒤 원문과 변형 결과, 설명이 한 화면에 표시된다."),
    d.IMGS([(S + '/lab/screenshots/r5/after_outfit_4_sentence_idle.png', None), (S + '/lab/screenshots/r5/after_outfit_6_sentence_loading_thinking.png', None), (S + '/lab/screenshots/r5/after_outfit_7_sentence_result_talking_fallback.png', None)]),
    CAP('[그림 5-10] Sentence Lab 입력(Explore/Combine), 거북이 실험 로딩, Combine 결과', center=True),
    H(2, '5.6 운영 배포와 실기기 동작'),
    P("백엔드와 데이터베이스는 Railway에 배포되어 있으며(6.5절), 앱은 빌드 시 서버 주소를 지정한다. 운영 빌드를 설치한 실제 iPhone에서 Google 로그인에 성공하였고, "
      "운영 서버를 통해 레슨·단어장·미션·실험실 기능을 사용할 수 있다."),
    TABLE(['항목', '내용'], [
        ['운영 서버', 'https://maru2026-production.up.railway.app (GitHub main push 시 자동 배포, 약 2분)'],
        ['운영 데이터', '레슨 15개(한글 12·문법 3), 덱 14개, 단어 5,561개, AI 캐시, TTS 캐시'],
        ['실기기', 'iPhone(iOS) 운영 서버 연결 release 빌드, Google 로그인 확인'],
        ['스모크 테스트', '유닛별 레슨 수, 인증이 필요한 API의 403, 잘못된 Google 토큰의 401, 덱 목록 200, 미션 생성 API의 기본 난이도(easy)·최소 턴 응답 확인'],
    ], [1800, 7560]),
    CAP('표 5-1. 운영 배포 현황'),
])''')
R("하나의 일관된 학습 경험으로 통합되었다. 2학기에는 이 기능들이 개발 환경을 넘어 운영 서버와 실제 iPhone에서 동작함을 확인하였다.",
  "하나의 일관된 학습 경험으로 통합되었다. 또한 이 기능들이 개발 환경을 넘어 운영 서버와 실제 iPhone에서 동작함을 확인하였다.")

# ================= 6장 =================
B("    H(1, '6. 2학기 개발 과정과 검증'),", "    H(2, '6.2 병렬 세션 개발 방법론'),\n",
'''    H(1, '6. 개발 과정과 검증'),
    P("본 장에서는 MARU를 어떤 방법으로 개발하고 어떻게 검증하였는지를 기술한다. 1인 팀이 네 기능과 캐릭터, 배포를 함께 완성해야 했으므로, "
      "작업을 나누고 충돌 없이 합치는 방법 자체가 중요한 설계 대상이었다."),
    H(2, '6.1 병렬 세션 개발 방법론'),
''')
R('    P("2학기 개발은 AI 코딩 에이전트(Claude Code) 세션 여러 개를', '    P("마무리 개발 단계는 AI 코딩 에이전트(Claude Code) 세션 여러 개를')
R("CAP('표 6-2. 병렬 세션 개발을 위한 장치'),", "CAP('표 6-1. 병렬 세션 개발을 위한 장치'),")
B('    P("이 방식으로 사흘(2026-09-30 ~ 10-02) 동안', "    H(2, '6.3 사용자 피드백 4라운드'),\n",
'''    P("이 방식으로 짧은 기간에 네 기능의 완성도 작업, 캐릭터 시스템, 네 차례의 사용자 피드백 반영, 운영 배포를 병행할 수 있었다. 반면 세션이 많아질수록 "
      "같은 worktree를 쓰는 짝 세션이 git 인덱스를 공유하는 문제, 시뮬레이터 ID를 명시하지 않으면 다른 세션의 기기를 잡는 문제처럼 조율 비용이 생겼고, 이는 규칙 문서에 교훈으로 기록하여 반복을 막았다."),
    H(2, '6.2 검증 원칙 — 주장과 동작의 일치'),
    P("보고서와 발표에 쓰는 모든 문장은 실제 코드와 측정값으로 확인할 수 있어야 한다는 원칙을 두었다. 이를 위해 코드 전체를 대상으로 주장 문장마다 근거(파일 위치, 로그, 테스트)를 대조하는 "
      "점검을 수행하고, 확인된 표현만 모은 단일 목록에서 제출물의 문장을 가져왔다. 성능 수치는 서버에 측정 로그를 넣어 얻은 값만 사용한다."),
    TABLE(['주장', '근거'], [
        ['FSRS-4.5 표준 공식으로 복습일 산출', 'FsrsAlgorithm 단위 테스트, 기본 파라미터에서의 손계산 검증'],
        ['미션 한 턴 약 1.5~2초, 순차 대비 30~50% 단축', '서버 턴 처리 시간 로그(실측 1.4~2.2초, 순차 추정 2.6~4.1초)'],
        ['캐시 HIT 1~2ms / MISS 3~5초', '실험실 서비스의 HIT/MISS 소요 시간 로그'],
        ['레슨 목표 문법만 형태소로 분해', '레슨 3개의 생성 데이터와 앱 화면 확인(표 4-1)'],
        ['미션은 최대 minTurns+3 턴 안에 종료', '3-Zone 규칙 단위 테스트'],
        ['리포트는 학습자가 실제 보낸 문장만 인용', '인용 검증 단위 테스트'],
    ], [4200, 5160]),
    CAP('표 6-2. 주요 주장과 근거'),
    H(2, '6.3 사용자 피드백 반영'),
''')
R("정리하는 피드백 라운드를 네 차례(R2~R5) 진행하였다. 그 이전의 코드 실사와 기능별 완주 점검(6.1절)은 피드백 라운드와 구분한다.",
  "정리하는 피드백 라운드를 네 차례 진행하였다.")
R("['R2', '09-30',", "['1차', '09-30',"); R("['R3', '10-01',", "['2차', '10-01',"); R("['R4', '10-02',", "['3차', '10-02',"); R("['R5', '10-02',", "['4차', '10-02',")
R("'실험실이 실험실처럼 보이지 않음, \"AI Grammar Lab\" 이름이 기능 컨셉과 맞지 않음'", "'실험실이 실험실처럼 보이지 않음, 문장 실험 기능의 이름이 컨셉과 맞지 않음'")
R("미션이 초급자에게 너무 어렵고 토끼 말이 김, 문법 실험실 입력 화면에서", "미션이 초급자에게 너무 어렵고 토끼 말이 김, 문장 실험실 입력 화면에서")
R("CAP('표 6-3. 사용자 피드백 라운드(R2~R5)와 반영 결과'),", "CAP('표 6-3. 사용자 피드백 라운드와 반영 결과'),")
B('    P("1학기 말에는 서버 테스트 일부가', '캐릭터 위젯 등)."),',
  '    P("핵심 로직은 자동 테스트로 검증한다. 서버는 FSRS 공식, 3-Zone 규칙, 난이도 규칙, 리포트 인용 검증, 입력 검증, 오류 응답을, 앱은 캐릭터 위젯과 주요 화면 위젯을 테스트한다. "'
  '기능 브랜치를 통합할 때마다 서버 테스트·정적 분석·앱 테스트를 모두 실행하였다."),')
R("TABLE(['구분', '결과 (2026-10-02 최종 통합·운영 재배포 기준)'], [", "TABLE(['구분', '결과 (최종 통합·운영 배포 기준)'], [")
B('    P("배포 전 Railway 데이터베이스를 확인한 결과', '짧은 첫 대사를 반환하는 것을 확인하였다."),',
  '    P("운영 환경은 Railway의 Spring Boot 서비스와 PostgreSQL로 구성된다. GitHub main 브랜치에 반영하면 자동으로 배포되며, 스키마는 서버 기동 시 갱신된다. 콘텐츠는 개발 DB에서 검증한 뒤 '
  '콘텐츠 테이블 5개(lessons 15행, word_categories 14행, words 5,561행, ai_cache, tts_cache)만 단일 트랜잭션으로 이관하였다. 개발용 계정·진행 기록·수료증·FSRS 기록은 옮기지 않았다. '
  '이관 후 행 수가 개발 DB와 일치하는지, 시퀀스가 정상인지 확인하고 스모크 테스트를 수행하였다."),\n'
  '    P("배포 절차는 운영 DB 백업 → 필요한 SQL 패치 적용 → main 브랜치 배포 → 스모크 테스트 순서로 고정하였다. 스키마 변경은 추가만 허용하므로, 새 버전 배포 중에도 이전 버전 앱이 그대로 동작한다."),')

# ================= 7장 =================
R('"2학기에 Railway 운영 서버에 배포하였다. 개발 초기에', '"Railway 운영 서버에 배포하였다. 개발 초기에')
R("old = d.table_after('2학기에 Railway 운영 서버에 배포하였다')", "old = d.table_after('Railway 운영 서버에 배포하였다. 개발 초기에')")
R("['캐릭터 (2학기)',", "['캐릭터',")
B('    "네 가지 목표 모두 실제 동작하는 기능으로 구현되었으며, 2학기에는', '서비스의 기반을 갖추었다.")',
  '    "네 가지 목표 모두 실제 동작하는 기능으로 구현되었으며, 형태소 분석·간격 반복 알고리즘·대형 언어 모델·유니코드 처리가 토끼·거북이 캐릭터와 함께 하나의 학습 경험으로 통합되었다. '
  '특히 kiwi-generator 파이프라인은 레슨의 CSV 행과 목표 품사만으로 조립 문제를 생성하고 SQL 패치로 반영하므로, 기존 문제 유형 안에서는 앱·서버 코드를 고치지 않고 콘텐츠를 늘릴 수 있다. '
  '또한 서버 135개·앱 83개의 자동 테스트와 운영 배포를 통해 개발 환경을 넘어 실제 기기에서 동작하는 서비스의 기반을 갖추었다.")')
R('"2학기에 1학기 한계점 일부(캐릭터 시각화, UI/UX, 미션 판정)는 해소하였으나, 다음과 같은 한계가 남아 있음을 인식하고 있다."',
  '"구현과 배포를 완료하였으나, 다음과 같은 한계가 남아 있음을 인식하고 있다."')
R('d.insert_after(p, [P("2학기에 기호·이름 표시 오류는 정리하였으나, 뜻풀이가 정적 규칙표에 의존하는 구조는 그대로이다.")])',
  'd.set_text(p, text(p).replace("이는 초기 구현의 단순화를 위한 결정이었으나, 서비스 품질 측면에서 개선이 필요한 지점이다.", "문맥을 반영한 설명 생성은 향후 과제이다."))')
B("p = d.find('둘째, 학습자가 시나리오에서 완전히 벗어난')", '아직 구현하지 않았다.")])',
'''p = d.find('LLM 기반 역할극 미션은 시나리오 다양성과')
d.set_text(p, "LLM 기반 역할극 미션은 시나리오 다양성과 자연스러운 대화 흐름 면에서 강점을 가지나, 다음과 같은 한계가 있다.")
p = d.find('첫째, 현재는 미션 시나리오 자체의 난이도가 고정되어')
d.set_text(p, "첫째, 난이도는 Easy·Normal·Hard 3단계를 학습자가 직접 고르는 방식이다. 학습자의 응답 수준을 실시간으로 감지하여 AI의 언어 복잡도를 자동으로 조절하는 적응형 난이도 제어는 구현하지 않았다.")
p = d.find('둘째, 학습자가 시나리오에서 완전히 벗어난')
d.set_text(p, "둘째, 거북이의 교정과 목표 달성 판정의 정확도는 프롬프트에 의존한다. 서버가 3-Zone 규칙·최대 턴·인용 문장 검증으로 형식적 오류는 막지만, 교정 내용이 얼마나 정확한지를 측정할 평가 데이터셋은 아직 없다.")''')
B('    "2학기에 네 차례의 피드백 라운드(R2~R5)로', '아직 충분히 다루지 못하였다.")',
  '    "네 차례의 피드백 라운드로 주요 화면의 디자인과 로딩·오류 상태, 작은 화면 레이아웃을 다듬었다. 그러나 화면 전환 애니메이션의 일관성, '
  'Android 실기기 검증, 다크모드·접근성은 아직 충분히 다루지 못하였다.")')
R('"1학기의 한계였던 캐릭터 시각화는 2학기에 해소하였다(4.5절). 대신 학습 효과에 대한 검증이 가장 큰 한계로 남는다. 현재', '"학습 효과에 대한 검증이 가장 큰 한계로 남는다. 현재')
B('d.insert_after(p, [P("2학기에 가장 크게 배운 것은', '확인하였다.")])',
  'd.insert_after(p, [P("이 프로젝트에서 가장 크게 배운 것은 \\"동작한다\\"와 \\"설명한 대로 동작한다\\"는 다르다는 점이다. 보고서의 문장 하나하나를 코드와 측정값에 대조하는 과정에서, '
  '화려한 수치보다 검증할 수 있는 사실이 프로젝트를 더 단단하게 만든다는 것을 확인하였다.")])')

# ================= 부록 삭제 =================
B("d.insert_after(last_ref, [\n    H(1, '부록 A.", "    ], [3100, 4900, 1360]),\n])", "")

# ================= 용어 교체 패스 단순화 =================
B("first_lab = True", "    d.set_text(el, new)\n",
'''for el in list(body.iter(q('w:p'))):
    t = text(el)
    if not any(k in t for k in ('AI Grammar Lab', 'Grammar Lab', 'AI 문법 실험실', '그래머랩')):
        continue
    new = t.replace('AI Grammar Lab(AI 문법 실험실)', 'Sentence Lab(문장 실험실)').replace('AI 문법 실험실', '문장 실험실')
    new = new.replace('AI Grammar Lab', 'Sentence Lab').replace('Grammar Lab', 'Sentence Lab').replace('그래머랩', 'Sentence Lab')
    d.set_text(el, new)
''')
R("out = OUT_DIR + '/MARU_최종보고서_2학기.docx'", "out = OUT_DIR + '/MARU_최종보고서.docx'")
open('build_report.py', 'w', encoding='utf8').write(s)
print('part2 ok')
