s = open('build_report.py', encoding='utf8').read()
def R(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, (n, old[:80])
    s = s.replace(old, new)

# ---- 수치·라운드
R('서버 123개·앱 67개', '서버 135개·앱 83개', 3)
R("'123개 전부 통과'", "'135개 전부 통과'")
R("'67개 통과 (2개 skip)'", "'83개 통과 (2개 skip)'")
R("결과 (2026-10-01 최종 머지 기준)", "결과 (2026-10-02 최종 통합·운영 재배포 기준)")
R('사용자 피드백 3라운드', '사용자 피드백 4라운드', 3)
R("12차례 머지에서 충돌 0건", "총 16차례 머지마다 같은 검증을 반복")
R("이 방식으로 이틀(2026-09-30 ~ 10-01) 동안 네 기능의 버그 수정·사실화, 캐릭터 시스템 신설, 두 차례의 사용자 피드백 반영, 운영 배포까지",
  "이 방식으로 사흘(2026-09-30 ~ 10-02) 동안 네 기능의 버그 수정·사실화, 캐릭터 시스템 신설, 네 차례의 사용자 피드백 반영, 운영 배포와 재배포까지")
R("2학기에 세 차례의 피드백 라운드로 단어장·미션·실험실 화면을", "2학기에 네 차례의 피드백 라운드(R2~R5)로 단어장·미션·실험실·홈 화면을")
R("정리하는 피드백 라운드를 세 차례 진행하였다.", "정리하는 피드백 라운드를 네 차례(R2~R5) 진행하였다. 그 이전의 코드 실사와 기능별 완주 점검(6.1절)은 피드백 라운드와 구분한다.")
a = s.index("        ['1차', '09-15 ~ 09-30'"); b = s.index("    ], [900, 1400, 3800, 3260]),")
s = s[:a] + """        ['R2', '09-30', '기기 TTS 음질, 한글 카드 네비게이션 중복, 단어장이 너무 단순함, 짝맞추기 애니메이션, 실험실 결과를 보려면 스크롤 필요', '서버 TTS, 네비게이션 통합, 단어장 리디자인, Match 애니메이션, 결과 한 화면'],
        ['R3', '10-01', '🐢 단계 라벨이 정답을 노출, 미션 로딩 컨셉, 교정 카드 색 구분, 미션 패널 접기, 채팅방 미감, 우는 토끼, 리포트에 내가 안 쓴 문장, 홈 복습 카드', '라벨 제거, 토끼 변신 로딩, 레드/옐로카드, 채팅·설정·리포트 리디자인, 사용자 문장 검증, 복습 카드 상시 표시'],
        ['R4', '10-02', '미션이 초급자에게 너무 어렵고 토끼 말이 김, 문법 실험실 입력 화면에서 두 기능이 구분되지 않음, "AI가 만드는 중" 로딩 문구, 홈 카드 4개가 흰색이라 밋밋함', '미션 난이도 Easy/Normal/Hard(기본 Easy·토끼 답 길이 상한), Explore/Combine 모드 카드 재설계, "거북이 실험 중" 로딩, 홈 파스텔 카드'],
        ['R5', '10-02', '실험실이 실험실처럼 보이지 않음, "AI Grammar Lab" 이름이 기능 컨셉과 맞지 않음', '화면 이름 Sentence Lab(문장 실험실), 실험 노트 무드 메뉴, 실험복 토끼·거북이(이미지 6장 추가)'],
""" + s[b:]
R("CAP('표 6-3. 사용자 피드백 라운드와 반영 결과'),", "CAP('표 6-3. 사용자 피드백 라운드(R2~R5)와 반영 결과'),")

# ---- 1.4 표
R("'토끼·거북이 캐릭터(표정 이미지 + 코드 모션)를 4개 기능 21개 화면 지점과 홈에 적용'", "'토끼·거북이 캐릭터(표정 이미지 21장 + 코드 모션)를 4개 기능 21개 화면 지점과 홈에 적용, 실험실 전용 실험복'")
R("'3-Zone 서버 강제, AI 코치의 실제 목표 달성 판정, 리포트에 사용자 문장만 인용'", "'난이도 3단계(Easy·Normal·Hard), 3-Zone 서버 강제, AI 코치의 실제 목표 달성 판정, 리포트에 사용자 문장만 인용'")
R("['미션 판정·리포트',", "['미션 난이도·판정',")
R("'4.3.5'],", "'4.3.5, 4.3.7'],")
R("        ['배포', 'Railway 운영 서버 배포 및 콘텐츠 데이터 이관, iPhone 실기기에서 Google 로그인·전 기능 동작', '5.8, 6.5'],",
  "        ['Sentence Lab', 'AI Grammar Lab을 Sentence Lab(문장 실험실)으로 개편: Explore/Combine 모드 구분, 거북이 실험 로딩', '4.4.4'],\n        ['배포', 'Railway 운영 서버 배포·콘텐츠 이관, R4·R5 반영 재배포(10-02), iPhone 실기기에서 Google 로그인·전 기능 동작', '5.8, 6.5'],")

# ---- 3장
R("'AI 생성 표정 PNG + Flutter 애니메이션', '그림(표정)과 몸짓(코드 모션)을 분리해 새 패키지 없이 구현'",
  "'AI 생성 표정 PNG 21장 + Flutter 애니메이션', '그림(표정·의상)과 몸짓(코드 모션)을 분리해 새 패키지 없이 구현'")
R("nullable 컬럼 세 개(cleared BOOLEAN, result_reason TEXT, goal_condition TEXT)를 추가하였다. ",
  "nullable 컬럼 세 개(cleared BOOLEAN, result_reason TEXT, goal_condition TEXT)를, 난이도 도입 후에는 difficulty VARCHAR 컬럼을 추가하였다(패치 msn_001·msn_002). ")
R("'미션 리포트, 판정(cleared) 추가'", "'미션 리포트, 판정(cleared)·난이도 추가'")
R("미션 1개(msn_001)", "미션 2개(msn_001~002)")
R("'LLM #1: 페르소나·미션 생성'", "'LLM #1: 페르소나·미션 생성 (난이도 easy/normal/hard)'")

# ---- 4.3.7 난이도
R("""      "글자가 깨지던(▯) 문제를 찾아 표준 자모로 변환하도록 수정하였다."),
])""", """      "글자가 깨지던(▯) 문제를 찾아 표준 자모로 변환하도록 수정하였다."),
    H(3, '4.3.7 난이도 설계 — Easy·Normal·Hard (2학기 추가)'),
    P("사용자 피드백 4차(R4)에서 \\"초급 학습자에게 미션이 너무 어렵고 토끼의 말이 길다\\"는 문제가 확인되었다. 1학기 설계는 하나의 프롬프트로 모든 학습자를 상대했기 때문에, "
      "초급자는 토끼의 긴 문장을 읽느라 대화를 이어가기 어려웠다. 2학기에는 미션 설정 화면에서 난이도를 Easy·Normal·Hard 중에서 고르게 하고(기본값 Easy), "
      "선택한 난이도를 프롬프트와 서버 규칙 양쪽에 적용하였다. 난이도는 /setup 요청의 선택 필드(difficulty)로 전달되며, 값이 없거나 알 수 없으면 easy로 처리하므로 이전 앱도 그대로 동작한다."),
    TABLE(['항목', 'Easy (기본)', 'Normal', 'Hard'], [
        ['어휘·문법', 'TOPIK 1, 현재형·-요 위주', 'TOPIK 2, 기본 연결어미', '자연스러운 구어'],
        ['미션 목표', '1개, 단순', '1~2단계', '기존 수준'],
        ['최소 턴 (minTurns, 서버가 범위로 고정)', '3~4', '4~6', '5~10'],
        ['토끼 답 길이 상한', '1문장, 공백 빼고 약 25자', '1~2문장, 약 50자', '최대 2문장, 약 80자'],
        ['거북이 교정 강도', '뜻이 안 통하는 큰 실수만. 존댓말 실수도 옐로카드(막지 않음)', '분명한 문법·어휘·존댓말', '화용(드시다·계시다 등)까지'],
        ['힌트 문장', '아주 짧고 쉬운 -요 문장', '짧은 문장', '자연스러운 문장'],
        ['수료 판정', '목표만 달성하면 통과(실수에 관대), 고칠 표현 2개 이하', '보통', '기존 수준'],
    ], [2300, 2600, 2100, 2360]),
    CAP('표 4-4. 미션 난이도별 서버 규칙 (API_CONTRACT §1-8)'),
    P("토끼 답이 상한의 1.4배를 넘으면 서버가 토끼 호출을 한 번 더 요청하여 더 짧은 답을 받는다. 답을 잘라내지는 않으므로 문장이 어색해지지 않는 대신, 그 턴만 응답이 약 1초 늦어질 수 있다. "
      "최대 턴 규칙(maxTurns = minTurns + 3)과 3-Zone 판정은 모든 난이도에서 같다. 리포트(수료증)와 목록에는 그 미션의 난이도 배지가 표시되고, 난이도는 mission_clearances.difficulty 컬럼에 저장된다. "
      "다만 난이도는 학습자가 직접 고르는 방식이며, 학습자의 실력을 자동으로 측정해 조절하는 기능은 아니다(7.2.2절)."),
    d.IMGS([(S + '/mission/screenshots/r4_fe2/1_setup_difficulty.png', None), (S + '/mission/screenshots/r4_fe2/5_chat_easy_short_reply.png', None), (S + '/mission/screenshots/r4_fe2/6_report_cleared_easy_badge.png', None)]),
    CAP('그림 4-15. 난이도 선택(Easy·Normal·Hard), Easy 미션의 짧은 토끼 답, Easy 배지가 붙은 수료증', center=True),
])""")

# ---- 4.4 Sentence Lab
R("""    P("사용자 피드백에 따라 결과 화면도 바꾸었다. 그래머랩은""", """    H(3, '4.4.5 Sentence Lab 개편 — 모드 구분과 거북이 실험 컨셉 (2학기 추가)'),
    P("사용자 피드백 4·5차(R4·R5)에서 문법 실험실의 입력 화면은 예문 칩, Explore 칩, 접혀 있는 Combine 영역이 위아래로 나열되어 \\"기능이 두 개\\"라는 것이 한눈에 보이지 않는다는 지적을 받았다. "
      "또한 \\"AI Grammar Lab\\"이라는 이름과 \\"AI가 만드는 중\\" 로딩 문구가 MARU의 캐릭터 컨셉과 어울리지 않았다. 이에 화면 이름을 Sentence Lab(문장 실험실)으로 바꾸고 입력 화면을 다시 설계하였다. "
      "코드 식별자(AiLabService, /api/lab 등)는 그대로 두고 화면 문구만 바꾸었으며, 변형은 여전히 AI(Gemini)가 생성하므로 메뉴 카드에 \\"AI-powered\\"를 작게 표기하였다."),
    TABLE(['구성', '내용'], [
        ['공통 입력 카드', '문장 입력창(200자) + 탭으로 넣는 예문 칩. 두 모드가 같은 입력을 공유'],
        ['모드 카드 2개', 'Explore — 한 규칙으로 변형 3개 (시제·높임·부정·감정 중 하나 선택) / Combine — 여러 규칙을 한 문장에 조합 (그룹마다 하나씩)'],
        ['실행 버튼', '하단 고정 1개, 모드별 라벨(예: Combine 2 rules)'],
        ['로딩', '\"Turtle is experimenting with your sentence…\" + 단계 문구(Mixing grammar… 등), 실험복 거북이 thinking과 플라스크 장식'],
        ['Language Lab 메뉴', '실험 노트(모눈종이) 무드, 코드로 그린 비커·플라스크, 카드 거품 애니메이션(동작 줄이기 설정 존중). 한글랩 = 장난꾸러기 토끼, Sentence Lab = 모범생 거북이'],
    ], [2000, 7360]),
    CAP('표 4-5. Sentence Lab 입력 화면과 실험실 메뉴 재설계'),
    d.IMGS([(S + '/lab/screenshots/r5/after_outfit_1_menu.png', None), (S + '/lab/screenshots/r5/after_outfit_4_sentence_idle.png', None), (S + '/lab/screenshots/r5/after_outfit_6_sentence_loading_thinking.png', None)]),
    CAP('그림 4-21. Language Lab 실험실 메뉴(실험복 캐릭터), Sentence Lab 입력, 거북이 실험 로딩', center=True),
    P("사용자 피드백에 따라 결과 화면도 바꾸었다. Sentence Lab은""")

# ---- 4.5 캐릭터
R("'토끼·거북이 각 7종(idle·blink·happy·sad·thinking·talking·cheer) + 토끼 magic = PNG 15장. AI로 생성 후 배경 제거·공통 크롭·기준선 정렬·512px 후처리'",
  "'기본: 토끼·거북이 각 7종(idle·blink·happy·sad·thinking·talking·cheer) + 토끼 magic = 15장. 실험복: 토끼 idle·happy, 거북이 idle·thinking·talking·sad = 6장. 총 PNG 21장. AI로 생성 후 배경 제거·공통 크롭·기준선 정렬·512px 후처리'")
R("        ['적용 범위', '4개 기능 21개 화면 지점 + 홈 인사 (아래 표)'],",
  "        ['의상 (2학기 R5)', 'MaruOutfit { normal, lab } — 실험실 화면만 outfit: lab. 실험복 이미지가 없는 표정은 기본 의상으로 자동 폴백(예: 실험복 토끼 sad → 기본 토끼 sad)'],\n        ['적용 범위', '4개 기능 21개 화면 지점 + 홈 인사 (아래 표)'],")
R("'MaruCharacter(kind, mood, size, reactionKey) · MaruCharacterBubble(말풍선·타자 효과). 기분(mood)만 바꾸면 표정과 몸짓이 함께 바뀜'",
  "'MaruCharacter(kind, mood, size, reactionKey, outfit) · MaruCharacterBubble(말풍선·타자 효과). 기분(mood)만 바꾸면 표정과 몸짓이 함께 바뀜'")
R("['Language Lab', '한글 조합 성공 happy', 'AI 생성 중 thinking, 결과 설명 talking, 오류 sad'],",
  "['Language Lab (실험복)', '한글랩 담당(장난꾸러기 실험), 조합 성공 happy', 'Sentence Lab 담당(모범생 실험), 실험 중 thinking, 결과 설명 talking, 오류 sad'],")
R("""      "사용자 피드백에 따라 미션 미달성 리포트에서는 토끼가 우는(sad) 대신 생각하는 표정과 응원 문구를 쓰도록 바꾸었다."),""",
  """      "사용자 피드백에 따라 미션 미달성 리포트에서는 토끼가 우는(sad) 대신 생각하는 표정과 응원 문구를 쓰도록 바꾸었다."),
    P("R5 피드백에서는 실험실 화면에만 실험복을 입힌 의상(outfit) 개념을 추가하였다. 공개 API에 outfit 파라미터를 추가만 하고 기본값을 normal로 두었으므로 기존 21개 화면 지점의 코드는 바뀌지 않았다. "
      "실험복 이미지는 6장만 만들고, 없는 표정은 기본 의상 이미지로 자동 대체되도록 폴백 순서를 정하였다. 특정 작품의 인물·로고·의상을 연상시키는 디자인은 저작권·초상권 위험이 있어 의도적으로 피하였다."),
    d.IMGS([(REPO + '/frontend/maru/assets/characters/rabbit_lab_idle.png', None), (REPO + '/frontend/maru/assets/characters/rabbit_lab_happy.png', None),
            (REPO + '/frontend/maru/assets/characters/turtle_lab_idle.png', None), (REPO + '/frontend/maru/assets/characters/turtle_lab_thinking.png', None)], height_in=1.6),
    CAP('그림 4-22. 실험복 캐릭터 (토끼 idle·happy, 거북이 idle·thinking)', center=True),""")

# ---- 5.7
R("""    P("Language Lab은 한글 조합 결과를 토끼가 축하하고, 그래머랩은 생성 중 거북이 로딩과 원문·결과를 한 화면에 보여주는 결과 화면을 갖추었다. 홈에는 캐릭터 인사와 오늘의 복습 카드가 항상 표시된다."),
    d.IMGS([(S + '/character/screenshots/apply_lab_C1.png', None), (S + '/character/screenshots/apply_lab_C3.png', None), (S + '/lesson/screenshots/r3_PM-1.7.2_home.png', None)]),
    CAP('[그림 5-23] Language Lab 한글랩·그래머랩 결과, 홈 화면(캐릭터 인사·All caught up 카드)', center=True),""",
  """    d.IMGS([(S + '/mission/screenshots/r4_fe2/1_setup_difficulty.png', None), (S + '/mission/screenshots/r4_fe2/3_chat_start_badge.png', None), (S + '/mission/screenshots/r4_fe2/7_list_easy_badge.png', None)]),
    CAP('[그림 5-23] Mission Chat — 난이도 선택, Easy 배지가 붙은 대화 시작, 수료증 목록', center=True),
    P("Language Lab은 실험 노트 무드의 메뉴에서 실험복 토끼(한글랩)와 거북이(Sentence Lab)가 맞이한다. 한글랩은 조합 결과를 토끼가 축하하고, Sentence Lab은 거북이가 실험하는 로딩 뒤 원문과 결과를 한 화면에 보여준다. "
      "홈에는 캐릭터 인사, 오늘의 복습 카드, 기능별 파스텔 색 카드 4개가 표시된다."),
    d.IMGS([(S + '/lab/screenshots/r5/after_outfit_3_hangeul_happy.png', None), (S + '/lab/screenshots/r5/after_outfit_7_sentence_result_talking_fallback.png', None), (S + '/lab/screenshots/r5/after_5_home_lab_subtitle.png', None)]),
    CAP('[그림 5-24] Language Lab 한글랩·Sentence Lab 결과(실험복 캐릭터), 홈 화면(파스텔 카드·All caught up)', center=True),""")
R("        ['실기기', 'iPhone(iOS) 운영 서버 연결 release 빌드, Google 로그인 확인 (2026-10-01)'],",
  "        ['재배포', '2026-10-02 R4·R5 반영: 운영 DB 백업 → 패치 msn_002 적용 → main push 자동 배포, 운영 /setup 이 difficulty=easy·minTurns 3 반환 확인'],\n        ['실기기', 'iPhone(iOS) 운영 서버 연결 release 빌드, Google 로그인 확인 (2026-10-01)'],")
R("""사용자 계정·진행 기록·수료증·FSRS 기록은 개발용 데이터이므로 옮기지 않았다. 이관 후 행 수가 로컬과 일치하는지, 시퀀스가 정상인지 확인하고 스모크 테스트를 수행하였다."),""",
  """사용자 계정·진행 기록·수료증·FSRS 기록은 개발용 데이터이므로 옮기지 않았다. 이관 후 행 수가 로컬과 일치하는지, 시퀀스가 정상인지 확인하고 스모크 테스트를 수행하였다."),
    P("10월 2일에는 R4·R5 피드백 반영분을 다시 배포하였다. 난이도 컬럼을 추가하는 패치(msn_002)를 운영 DB 백업 후 먼저 적용하고 main 브랜치를 배포하였으며, 운영 서버의 미션 생성 API가 "
      "기본 난이도 easy와 최소 턴 3, 짧은 첫 대사를 반환하는 것을 확인하였다."),""")

# ---- 7장
R("'GPT-4o 토끼(연기)·거북이(채점) 병렬 호출로 한 턴 1.5~2초. 서버 강제 3-Zone, AI 목표 달성 판정, 사용자 문장만 인용하는 리포트, 레드/옐로카드'",
  "'GPT-4o 토끼(연기)·거북이(채점) 병렬 호출로 한 턴 1.5~2초. 난이도 3단계(Easy 기본), 서버 강제 3-Zone, AI 목표 달성 판정, 사용자 문장만 인용하는 리포트, 레드/옐로카드'")
R("'기기 내 유니코드 한글 조합(Hangeul Lab)과 Gemini 문법 변형(AI Grammar Lab). 정렬 캐시 키, HIT 1~2ms / MISS 3~5s, 입력 검증'",
  "'기기 내 유니코드 한글 조합(Hangeul Lab)과 AI(Gemini) 기반 문장 변형 Sentence Lab(Explore/Combine). 정렬 캐시 키, HIT 1~2ms / MISS 3~5s, 입력 검증'")
R("'토끼·거북이 표정 15장 + 코드 모션, 4개 기능 21개 지점 + 홈'", "'토끼·거북이 이미지 21장(기본 15 + 실험복 6) + 코드 모션, 4개 기능 21개 지점 + 홈'")
R("""      "목표 달성 판정의 정확도는 여전히 프롬프트에 의존하며, 이를 측정할 평가 데이터셋은 없다.")])""",
  """      "목표 달성 판정의 정확도는 여전히 프롬프트에 의존하며, 이를 측정할 평가 데이터셋은 없다. 난이도는 Easy·Normal·Hard 3단계를 도입했지만 학습자가 직접 고르는 방식이며, "
                     "학습자의 응답 수준을 감지해 자동으로 조절하는 적응형 난이도는 아직 구현하지 않았다.")])""")

# ---- 부록 A
R("'레드/옐로카드, 접히는 패널, 토끼 변신 로딩, 채팅·설정·리포트 리디자인'", "'레드/옐로카드, 접히는 패널, 토끼 변신 로딩, 채팅·설정·리포트 리디자인, 난이도 Easy/Normal/Hard(기본 Easy, 토끼 답 길이 상한)'")
R("'오류 코드·영어 안내, 키 헤더 전달, 입력 검증, HIT 1~2ms/MISS 3~5s 실측, 결과 화면'",
  "'Sentence Lab으로 개편(Explore/Combine 모드 카드, 거북이 실험 로딩, 실험실 무드 메뉴), 오류 코드·영어 안내, 키 헤더 전달, 입력 검증, HIT 1~2ms/MISS 3~5s 실측'")
R("['실험실', '예외 원문 노출", "['실험실', 'AI Grammar Lab: 예외 원문 노출")
R("'표정 PNG 15장 + 코드 모션, 21개 지점 + 홈'", "'이미지 21장(기본 15 + 실험복 6) + 코드 모션, 21개 지점 + 홈'")
R("'Stats·Settings 화면, 로그아웃 확인, 복습 카드 항상 표시'", "'Stats·Settings 화면, 로그아웃 확인, 복습 카드 항상 표시, 기능별 파스텔 카드'")
R("        ['API', '17개', '22개 (진행 조회·TTS 등 추가)'],", "        ['API', '17개', '22개 (진행 조회·TTS 등 추가)'],\n        ['배포', '-', '10-01 첫 운영 배포, 10-02 R4·R5 재배포'],")
R("        ['ai_caches 테이블', 'ai_cache 테이블', '4.4.3'],", "        ['ai_caches 테이블', 'ai_cache 테이블', '4.4.3'],\n        ['화면 이름 \\'AI Grammar Lab\\'', 'Sentence Lab(문장 실험실) — AI(Gemini) 기반임은 명시', '4.4.5'],")

# ---- 전역 이름 교체 패스 (장 번호 재부여 직전)
R("""# =====================================================================
# 장 제목 페이지 나눔, 캡션 번호 재부여""", """# =====================================================================
# 용어 교체: 화면 이름 AI Grammar Lab → Sentence Lab (D-24)
# =====================================================================
first_lab = True
for el in list(body.iter(q('w:p'))):
    t = text(el)
    if "화면 이름 'AI Grammar Lab'" in t or 'Sentence Lab(문장 실험실)으로' in t or '"AI Grammar Lab"이라는' in t \\
            or 'AI Grammar Lab을 Sentence Lab' in t or t.startswith('AI Grammar Lab: '):
        continue
    if not any(k in t for k in ('AI Grammar Lab', 'Grammar Lab', 'AI 문법 실험실')):
        continue
    if t.startswith('[그림') and 'AI Grammar Lab' in t:
        new = t.replace('AI Grammar Lab', 'Sentence Lab(1학기 화면, 구 AI Grammar Lab)')
    else:
        new = t.replace('AI Grammar Lab(AI 문법 실험실)', 'AI Grammar Lab').replace('AI 문법 실험실', '문장 실험실')
        if first_lab and 'AI Grammar Lab' in new:
            new = new.replace('AI Grammar Lab', 'Sentence Lab(문장 실험실, 구 AI Grammar Lab)', 1)
            first_lab = False
        new = new.replace('AI Grammar Lab', 'Sentence Lab').replace('Grammar Lab', 'Sentence Lab')
    d.set_text(el, new)

# =====================================================================
# 장 제목 페이지 나눔, 캡션 번호 재부여""")
open('build_report.py', 'w', encoding='utf8').write(s)
print('patched')
