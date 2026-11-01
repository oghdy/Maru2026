"""레슨 소스 빌드: lesson*.json + curriculum.csv → 탭 분석 chunks + 조립 문제 → SQL 패치.

14레슨 커리큘럼의 신규 8레슨 (WEB-5.8.4), 과거형 Learn + Practice 파일럿 (WEB-5.12.3), 문법별 Learn + Practice 전체 적용 (WEB-5.13, WEB-5.15), u1-l1 다양화 (WEB-5.16).

기존 레슨(u1-l1, lesson2, u1-l3, u2-l1~l3)과 그 패치(lsn_003~005)는 다시 만들지 않는다. 단 FIX_PATCHES 는 조립 오답만 고친다.
kiwi-generator 코드는 고치지 않고, 그 표에 없는 항목만 실행 시 추가한다. 출력은 결정적이다.
batch_merger.py --lesson 을 직접 돌리면 이 표 확장이 빠지므로 신규 레슨은 반드시 이 스크립트로 만든다.

사용 (backend/admin-tools/kiwi-generator 에서):
  PYTHONDONTWRITEBYTECODE=1 venv/bin/python ../../lessons/build_curriculum.py
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GENERATOR = os.path.join(HERE, '..', 'admin-tools', 'kiwi-generator')
sys.path.insert(0, GENERATOR)

import core_engine  # noqa: E402
import generate_morphology  # noqa: E402
from batch_merger import ContentMerger, to_sql  # noqa: E402
from inject_morphology import inject_chunks  # noqa: E402

CSV = os.path.join(GENERATOR, 'curriculum.csv')
PATCH_DIR = os.path.join(HERE, '..', 'db', 'patches')

UNIT_TITLES = {1: 'Introduce Yourself', 2: 'Daily Life', 3: 'Say More'}

# (패치 파일, 머리말, 레슨들). 레슨 = (lesson_id, unit, order, 파일, 제목, 설명)
PATCHES = [
    ('lsn_006_add_u1_review_u2_place_review.sql',
     "WEB-5.8.4 묶음 1: u1-l4 Unit 1 Review, u2-l4 에서, u2-l5 Unit 2 Review 추가 (멱등).",
     [
         ('u1-l4', 1, 4, 'unit1/lesson4.json', 'Unit 1 Review',
          'Review 은/는, 이에요/예요 and 을/를 together.'),
         ('u2-l4', 2, 4, 'unit2/lesson4.json', 'Where do you study?',
          'Say where you do something using the place particle 에서.'),
         ('u2-l5', 2, 5, 'unit2/lesson5.json', 'Unit 2 Review',
          'Review 이/가, 에, 에서 and 안 together.'),
     ]),
    ('lsn_007_add_unit3_say_more.sql',
     "WEB-5.8.4 묶음 2: Unit 3 \"Say More\" 레슨 5개 추가 (멱등): 이/가 아니에요, 았/었어요, 고 싶어요, (으)세요, Unit 3 Review.",
     [
         ('u3-l1', 3, 1, 'unit3/lesson1.json', "I'm not a doctor",
          'Say what someone or something is not using 이/가 아니에요.'),
         ('u3-l2', 3, 2, 'unit3/lesson2.json', 'What did you do?',
          'Say what you did using 았/었어요.'),
         ('u3-l3', 3, 3, 'unit3/lesson3.json', 'What do you want to do?',
          'Say what you want to do using 고 싶어요.'),
         ('u3-l4', 3, 4, 'unit3/lesson4.json', 'Please sit here',
          'Ask someone politely to do something using (으)세요.'),
         ('u3-l5', 3, 5, 'unit3/lesson5.json', 'Unit 3 Review',
          'Review 이/가 아니에요, 았/었어요, 고 싶어요 and (으)세요 together.'),
     ]),
]

# 기존 레슨의 조립 오답만 다시 만드는 패치 (WEB-5.10.1). 소개·연습·완료 단계와 탭 뜻은 소스 그대로 둔다 (inject_chunks 안 함).
FIX_PATCHES = [
    ('lsn_008_fix_unit1_quiz_decoys.sql',
     "WEB-5.10.1: u1-l1 조립 오답 도, lesson2 조립 오답 입니다 제거 (저도 ..., 학생입니다 는 맞는 문장). 조립 단계 외 변경 없음 (멱등).",
     [('u1-l1', 'unit1/lesson1.json'), ('lesson2', 'unit1/lesson2.json')]),
]

# 과거형 파일럿 (WEB-5.12.3). u3-l2 를 lsn_007 과 별도 소스로 다시 쓴다: lesson2.json 과 CSV 의 u3-l2 는 lsn_007 용으로 그대로 둔다.
PILOT_PATCH = 'lsn_009_pilot_past_tense.sql'
PILOT_UNIT = 3
# (lesson_id, 파일, 조립 문제의 CSV LessonID, 제목, 설명, 예상 분)
PILOT_LEARN = ('u3-l2-learn', 'unit3/lesson2_learn.json', None, 'Learn: Past tense',
               'Slowly learn how 았/었 makes the past. Only three small checks, with no score.', 5)
PILOT_PRACTICE = ('u3-l2', 'unit3/lesson2_practice.json', 'u3-l2-practice', 'What did you do?',
                  'Practice saying what you did using 았/었어요.', 10)
# 끼워 넣은 뒤 Unit 3 순서. 목록 화면이 order_num 을 숫자로 보여 주므로 빈 번호 없이 맞춘다.
PILOT_ORDER = [('u3-l1', 1), ('u3-l2-learn', 2), ('u3-l2', 3), ('u3-l3', 4), ('u3-l4', 5), ('u3-l5', 6)]

# 문법별 Learn + Practice (WEB-5.13, LESSON_DESIGN.md 6절 P0). 파일럿과 같은 방식: 기존 소스·CSV 행·패치는 그대로 두고 새 소스·새 패치로 쓴다.
# lessons = (lesson_id, 파일, 조립 문제의 CSV LessonID, 제목, 설명, 예상 분)
LEARN_NOTE = "Only three small checks, with no score."
REWRITE_PATCHES = [
    {
        'patch': 'lsn_010_unit1_learn_practice.sql',
        'header': "WEB-5.13.1 묶음 1: 입문 u1-intro, 을/를 Learn u1-l3-learn 추가, Practice u1-l3 다시 쓰기, Unit 1 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.",
        'unit': 1,
        'lessons': [
            ('u1-intro', 'unit1/intro_learn.json', None, 'Learn: How Korean sentences work',
             f'See how blocks on words and verbs build a Korean sentence. {LEARN_NOTE}', 5),
            ('u1-l3-learn', 'unit1/lesson3_learn.json', None, 'Learn: 을/를',
             f'Slowly learn how 을/를 marks the thing you act on. {LEARN_NOTE}', 5),
            ('u1-l3', 'unit1/lesson3_practice.json', 'u1-l3-practice', 'What do you like?',
             'Practice saying what you eat, drink and like using 을/를.', 10),
        ],
        # u1-l4 🐢 오답 은 을 빵 칸에 넣으면 '저는 빵은 먹어요' 라는 맞는 문장이 된다 (대조의 은). 이 는 어느 칸에 넣어도 틀린다.
        'decoy_fixes': [('u1-l4', 'lsn_006_add_u1_review_u2_place_review.sql', 6, '은', '이')],
        'order': [('u1-intro', 1), ('u1-l1', 2), ('lesson2', 3), ('u1-l3-learn', 4), ('u1-l3', 5), ('u1-l4', 6)],
    },
    {
        'patch': 'lsn_011_unit2_learn_practice.sql',
        'header': "WEB-5.13.2 묶음 2: 이/가·에·에서 Learn 추가, Practice u2-l1·u2-l2·u2-l4 다시 쓰기, u2-l5·u2-l3 의 뜻만 달라지는 오답 교체, Unit 2 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.",
        'unit': 2,
        'lessons': [
            ('u2-l1-learn', 'unit2/lesson1_learn.json', None, 'Learn: 이/가',
             f'Slowly learn how 이/가 works with 있어요 and 없어요. {LEARN_NOTE}', 5),
            ('u2-l1', 'unit2/lesson1_practice.json', 'u2-l1-practice', 'Do you have time?',
             "Practice saying what you have and don't have using 이/가.", 10),
            ('u2-l2-learn', 'unit2/lesson2_learn.json', None, 'Learn: 에',
             f'Slowly learn how 에 marks where you go or where you are. {LEARN_NOTE}', 5),
            ('u2-l2', 'unit2/lesson2_practice.json', 'u2-l2-practice', 'Where are you going?',
             'Practice saying where you go and where you are using 에.', 10),
            ('u2-l4-learn', 'unit2/lesson4_learn.json', None, 'Learn: 에서',
             f'Slowly learn how 에서 marks where you do something. {LEARN_NOTE}', 5),
            ('u2-l4', 'unit2/lesson4_practice.json', 'u2-l4-practice', 'Where do you study?',
             'Practice saying where you do something using 에서.', 10),
        ],
        # 복습은 제목·설명 그대로, 내용만 새 소스로 (조립 문장은 기존 CSV 행, 오답만 후처리)
        'reviews': [('u2-l5', 'unit2/lesson5_review.json', 'u2-l5')],
        # 재작성하지 않는 레슨의 오답만 고친다: (레슨, 내용의 원본 패치, 0부터 센 단계, 문항, 새 선택지)
        'option_fixes': [('u2-l3', 'lsn_005_add_unit2_daily_life.sql', 3, 4, ['안 마셔요', '마셔요 안'])],
        'order': [('u2-l1-learn', 1), ('u2-l1', 2), ('u2-l2-learn', 3), ('u2-l2', 4), ('u2-l3', 5),
                  ('u2-l4-learn', 6), ('u2-l4', 7), ('u2-l5', 8)],
    },
    {
        'patch': 'lsn_012_unit3_learn_practice.sql',
        'header': "WEB-5.13.3 묶음 3: (으)세요 Learn u3-l4-learn 추가, Practice u3-l4 다시 쓰기, Unit 3 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.",
        'unit': 3,
        'lessons': [
            ('u3-l4-learn', 'unit3/lesson4_learn.json', None, 'Learn: (으)세요',
             f'Slowly learn how (으)세요 asks someone politely. {LEARN_NOTE}', 5),
            ('u3-l4', 'unit3/lesson4_practice.json', 'u3-l4-practice', 'Please sit here',
             'Practice asking someone politely using (으)세요.', 10),
        ],
        'order': [('u3-l1', 1), ('u3-l2-learn', 2), ('u3-l2', 3), ('u3-l3', 4), ('u3-l4-learn', 5), ('u3-l4', 6), ('u3-l5', 7)],
    },
    {
        'patch': 'lsn_013_unit1_learn_practice.sql',
        'header': "WEB-5.15.2 묶음 1: 은/는·이에요/예요 Learn 추가, Practice u1-l1·lesson2 다시 쓰기, Unit 1 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.",
        'unit': 1,
        'lessons': [
            ('u1-l1-learn', 'unit1/lesson1_learn.json', None, 'Learn: 은/는',
             f'Slowly learn how 은/는 marks who or what you are talking about. {LEARN_NOTE}', 5),
            ('u1-l1', 'unit1/lesson1_practice.json', 'u1-l1-practice', 'My Name is...',
             'Practice saying your name and who you are using 은/는.', 10),
            ('lesson2-learn', 'unit1/lesson2_learn.json', None, 'Learn: 이에요/예요',
             f'Slowly learn how 이에요/예요 means am, is or are. {LEARN_NOTE}', 5),
            ('lesson2', 'unit1/lesson2_practice.json', 'lesson2-practice', 'What do you do?',
             'Practice saying what you do using 이에요/예요.', 10),
        ],
        'order': [('u1-intro', 1), ('u1-l1-learn', 2), ('u1-l1', 3), ('lesson2-learn', 4), ('lesson2', 5),
                  ('u1-l3-learn', 6), ('u1-l3', 7), ('u1-l4', 8)],
    },
    {
        'patch': 'lsn_014_unit2_learn_practice.sql',
        'header': "WEB-5.15.3 묶음 2: 안 Learn 추가, Practice u2-l3 다시 쓰기, u2-l1-learn·u2-l4-learn 의 나중 약속 문구 완화 (WEB-5.15.1), Unit 2 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.",
        'unit': 2,
        'lessons': [
            ('u2-l3-learn', 'unit2/lesson3_learn.json', None, 'Learn: 안',
             f'Slowly learn where 안 goes to say what you do not do. {LEARN_NOTE}', 5),
            ('u2-l3', 'unit2/lesson3_practice.json', 'u2-l3-practice', "I don't drink coffee",
             "Practice saying what you don't do using 안, and review 을/를.", 10),
        ],
        'revisions': [
            ('u2-l1-learn', 'lsn_011_unit2_learn_practice.sql', [
                ('set', 9, ('title',), 'A note for later', 'A small note'),
                ('set', 9, ('content', 'explanation'),
                 "이/가 does more than this. You'll see it later, so this lesson uses it before 있어요 and 없어요.",
                 '이/가 does more than this. For now, just use it before 있어요 and 없어요.'),
            ]),
            ('u2-l4-learn', 'lsn_011_unit2_learn_practice.sql', [
                ('set', 9, ('title',), 'A note for later', 'A small note'),
                ('set', 9, ('content', 'explanation'),
                 "에서 can also mean from, like from school. You'll see that later, so this lesson uses it for doing things.",
                 '에서 can also mean from, like from school. For now, just use it for doing things.'),
            ]),
        ],
        'order': [('u2-l1-learn', 1), ('u2-l1', 2), ('u2-l2-learn', 3), ('u2-l2', 4), ('u2-l3-learn', 5), ('u2-l3', 6),
                  ('u2-l4-learn', 7), ('u2-l4', 8), ('u2-l5', 9)],
    },
    {
        'patch': 'lsn_015_unit3_learn_practice.sql',
        'header': "WEB-5.15.4 묶음 3: 이/가 아니에요·고 싶어요 Learn 추가, Practice u3-l1·u3-l3 다시 쓰기, u3-l2-learn 첫 확인 문제 교체와 나중 약속 문구 완화 (WEB-5.15.1), Unit 3 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.",
        'unit': 3,
        'lessons': [
            ('u3-l1-learn', 'unit3/lesson1_learn.json', None, 'Learn: 이/가 아니에요',
             f'Slowly learn how 이/가 아니에요 says what something is not. {LEARN_NOTE}', 5),
            ('u3-l1', 'unit3/lesson1_practice.json', 'u3-l1-practice', "I'm not a doctor",
             'Practice saying what someone or something is not using 이/가 아니에요.', 10),
            ('u3-l3-learn', 'unit3/lesson3_learn.json', None, 'Learn: 고 싶어요',
             f'Slowly learn how 고 싶어요 says what you want to do. {LEARN_NOTE}', 5),
            ('u3-l3', 'unit3/lesson3_practice.json', 'u3-l3-practice', 'What do you want to do?',
             'Practice saying what you want to do using 고 싶어요.', 10),
        ],
        'revisions': [
            # 3단계의 먹어요/먹었어요 는 둘 다 맞는 문장이었다. 어제 를 넣어 하나로 갈리게 하고, 어제 소개 카드를 문제 앞으로 옮긴다.
            ('u3-l2-learn', 'lsn_009_pilot_past_tense.sql', [
                ('swap', 2, 3),
                ('set', 3, ('content', 'exercises', 0, 'instruction'), 'I ate bread.', 'I ate bread yesterday.'),
                ('set', 3, ('content', 'exercises', 0, 'sentence'), '저는 빵을 [ ? ].', '저는 어제 빵을 [ ? ].'),
                ('set', 3, ('content', 'exercises', 0, 'feedback', 'correct'), 'Yes! 었 makes it past.', 'Yes! 어제 means yesterday, and 었 makes it past.'),
                ('set', 3, ('content', 'exercises', 0, 'feedback', 'incorrect'), 'Look for the 었 block. 먹어요 is now. 먹었어요 is past.',
                 '어제 means yesterday. 먹어요 is now, so look for the 었 block.'),
                ('set', 9, ('title',), 'A note for later', 'A small note'),
                ('set', 9, ('content', 'explanation'),
                 "Verbs ending in a vowel, like 가요, change shape in the past. You'll see them later, so this lesson uses verbs like 먹.",
                 'Verbs ending in a vowel, like 가요, change shape in the past. For now, just use verbs like 먹.'),
            ]),
            ('u3-l2', 'lsn_009_pilot_past_tense.sql', [
                ('set', 11, ('content', 'text'),
                 "You've practiced the past with 았/었어요.\nLast vowel ㅏ or ㅗ → 았 (찾았어요). Other vowels → 었 (먹었어요).\nVerbs like 가요 change shape in the past. You will see them later.",
                 "You've practiced the past with 았/었어요.\nLast vowel ㅏ or ㅗ → 았 (찾았어요). Other vowels → 었 (먹었어요).\nVerbs like 가요 change shape in the past, so we skip them for now."),
            ]),
            ('u3-l4-learn', 'lsn_012_unit3_learn_practice.sql', [
                ('set', 9, ('title',), 'A note for later', 'A small note'),
                ('set', 9, ('content', 'explanation'),
                 "(으)세요 has other uses too. You'll see them later, so this lesson only uses it to ask politely.",
                 '(으)세요 has other uses too. For now, just use it to ask politely.'),
            ]),
        ],
        'order': [('u3-l1-learn', 1), ('u3-l1', 2), ('u3-l2-learn', 3), ('u3-l2', 4), ('u3-l3-learn', 5), ('u3-l3', 6),
                  ('u3-l4-learn', 7), ('u3-l4', 8), ('u3-l5', 9)],
    },
    {
        # lsn_013 은 그대로 둔다: 소스 lesson1_learn.json·lesson1_practice.json, CSV u1-l1-practice 를 고치면 lsn_013 이 다시 만들어진다.
        'patch': 'lsn_016_u1_l1_variety.sql',
        'header': "WEB-5.16.1: u1-l1-learn·u1-l1 문장 다양화. 빵을 먹어요 반복과 어색한 문장을 빼고 맛있어요·좋아요·커요, 대조, 은/는요? 되묻기를 넣음. Unit 1 순서는 lsn_013 과 같음 (멱등). lesson_id 유지라 진도 기록은 그대로.",
        'unit': 1,
        'lessons': [
            ('u1-l1-learn', 'unit1/lesson1_learn_v2.json', None, 'Learn: 은/는',
             f'Slowly learn how 은/는 marks who or what you are talking about. {LEARN_NOTE}', 5),
            ('u1-l1', 'unit1/lesson1_practice_v2.json', 'u1-l1-v2', 'My Name is...',
             'Practice saying who you are, comparing and asking back using 은/는.', 10),
        ],
        'order': [('u1-intro', 1), ('u1-l1-learn', 2), ('u1-l1', 3), ('lesson2-learn', 4), ('lesson2', 5),
                  ('u1-l3-learn', 6), ('u1-l3', 7), ('u1-l4', 8)],
    },
]

# 조립 문제별 안내 문구에 덧붙일 말 (문제 순서대로). 앱 고정 문구 "Now split the part this lesson teaches" 를 보완한다.
QUIZ_INSTRUCTION_SUFFIX = {
    'u1-l4': [" Split 은/는 and 이에요/예요.", " Split 은/는 and 이에요/예요.", " Split 은/는 and 을/를."],
    'u2-l5': [" Split 에 and 이/가.", " Split 에. 안 stays whole.", " Split 에서 and 을/를. 안 stays whole."],
    'u3-l5': [" Split 이/가.", " Split the verb, 았/었 and the ending.", " Split 고. 싶어요 stays whole.",
              " Split the verb and (으)세요."],
    'u3-l1': [" Split 이/가. 아니에요 stays whole."] * 3,
    'u3-l2': [" Split the verb, 았/었 and the ending."] * 3,
    'u3-l3': [" Split 고. 싶어요 stays whole."] * 3,
    'u3-l4': [" Split the verb and (으)세요."] * 3,
}

# ---------- 오답·힌트 표 (CURRICULUM.md 5.1) ----------
A, P, R = core_engine.ALLOMORPHS, core_engine.CATEGORY_POOL, core_engine.ALLOMORPH_RULES
P['JX'] = []                       # 안 배운 도·만 을 새 레슨 오답으로 내지 않는다
P['COPULA'] = ['이에요', '예요']   # '학생입니다' 는 맞는 문장이므로 입니다 를 오답으로 내지 않는다
A['에'] = ['가']
A['에서'] = ['에']
P['JKB'] = ['에', '에서']
A['았'] = ['었']
A['었'] = ['았']
P['EP'] = ['았', '었']             # 기본 풀의 겠 제거
A['고'] = ['어요']
P['EC'] = []
A['으세요'] = ['세요']
A['세요'] = ['으세요']
P['EF'] = ['세요', '으세요']
R[frozenset({'에'})] = "marks a place: where you go or where something is. It is the same after a consonant or a vowel."
R[frozenset({'에서'})] = "marks the place where an action happens. It is the same after a consonant or a vowel."
R[frozenset({'안'})] = "means 'not'. It goes right before the verb."
R[frozenset({'았', '었'})] = "marks the past. After ㅏ or ㅗ use 았, otherwise use 었."
R[frozenset({'고'})] = "links the verb to 싶어요. The verb stays the same."
R[frozenset({'으세요', '세요'})] = "asks someone politely to do it. After a consonant use 으세요, after a vowel use 세요."
SUBJECT_RULE = R[frozenset({'이', '가'})]
# 아니에요 앞의 이/가 는 문장의 주어가 아니므로 Unit 3 에서는 힌트를 따로 쓴다
NOT_RULE = "comes before 아니에요. After a vowel use 가, after a consonant use 이."

# ---------- 탭 분석 표 ----------
generate_morphology.TOKEN_SPECIFIC_MAP.update({
    '있': 'there is / have / be at', '없': "there isn't / don't have",
    '에': 'place marker', '안': 'not',
    '네': 'yes', '오늘': 'today', '지금': 'now', '어디': 'where',
    '시간': 'time', '친구': 'friend', '돈': 'money', '우유': 'milk', '가방': 'bag',
    '학교': 'school', '집': 'home', '회사': 'company', '카페': 'café', '도서관': 'library',
    '에서': 'action place marker', '어제': 'yesterday', '찾': 'look for / find', '앉': 'sit', '받': 'receive',
    '여기': 'here', '공부': 'study', '식당': 'restaurant', '밥': 'rice / meal',
    '고': 'and (link)', '싶': 'want', '아니': 'not be', '에요': 'polite ending',
    '었': 'past', '았': 'past', '으세요': 'please (polite)', '세요': 'please (polite)',
    '요': 'and ...? (asks back)',  # u1-l1 대화 이름은요?, 유미 씨는요?
})
generate_morphology.CHUNK_OVERRIDE_MAP.update({
    '아니요': 'no',
    '그래요': 'is that so?',
    '했어요': 'did (past)',       # 대화 전용. 조립 문장에는 쓰지 않는다
    '하세요': 'do (polite)',      # u1-l4 '무슨 일 하세요?' 는 요청이 아니라 질문
    '싶어요': 'want to',
    '반가워요': 'nice to meet you',  # ㅂ불규칙이라 통째 한 토큰 (u1-l1 대화·낱말 전용)
})


class CurriculumMorphology(generate_morphology.MorphologyGenerator):
    def get_meaning(self, text, tag):
        if text == '가' and tag == 'VV':  # 조사 '가' 와 글자가 같아 품사로 구분
            return 'go'
        if text in ('이', '가') and tag == 'JKC':  # 기본값 complement marker 는 학습자에게 어렵다
            return 'marker before 아니에요'
        return super().get_meaning(text, tag)


def _ends_with_consonant(word):
    return (ord(word[-1]) - 0xAC00) % 28 != 0


def fix_place_decoys(body):
    """에 문제의 🐰 오답을 받침에 맞는 이/가 로 쓴다 (집가 → 집이). 정답과 같아지면 바꾸지 않는다."""
    if not any('에' in e['correct_turtle'] for e in body['elements']):
        return
    correct = {t for e in body['elements'] for t in e['correct_rabbit']}
    for o in body['options']:
        text = o['text']
        if o['mode'] == 'rabbit' and text not in correct and text.endswith('가') and _ends_with_consonant(text[:-1]):
            candidate = text[:-1] + '이'
            if candidate not in correct:
                o['text'] = candidate


def fix_contracted_decoys(body):
    """고 문제의 🐰 오답은 학습자가 실제로 헷갈리는 형태로 (가어요 → 가요, 마시어요 → 마셔요)."""
    swap = {'가어요': '가요', '마시어요': '마셔요'}
    for o in body['options']:
        if o['mode'] == 'rabbit' and o['text'] in swap:
            o['text'] = swap[o['text']]


def _add_turtle_decoy(body, text):
    """정답·기존 오답과 겹치지 않으면 🐢 오답을 하나 넣는다. 자리는 문장에 따라 정해져 빌드마다 같다."""
    options = body['options']
    if any(o['mode'] == 'turtle' and o['text'] == text for o in options):
        return
    used = {int(o['id'][1:]) for o in options}
    new_id = next(i for i in range(1, len(options) + 2) if i not in used)
    at = sum(ord(c) for c in body['sentence']) % (len(options) + 1)
    options.insert(at, {'id': f'o{new_id}', 'text': text, 'mode': 'turtle'})


def fix_meaning_decoys(body):
    """오답을 넣어도 맞는 문장이 되면 안 된다 (D-35). 에 문제에서 다음을 뺀다.
    - 🐢 에서: 학교에서 가요·회사에서 안 가요·학교에서 친구가 있어요 는 뜻만 달라진다.
    - 있어요/없어요 바로 앞 장소의 이/가: 집이 있어요 는 집을 가졌다는 맞는 문장이다. 을/를 로 바꾼다 (집을 있어요 는 틀린 문장).
    가요 앞에는 을/를 을 쓰지 않는다 (학교를 가요 는 구어에서 맞다)."""
    elements = body['elements']
    if not any('에' in e['correct_turtle'] for e in elements):
        return
    correct_t = {t for e in elements for t in e['correct_turtle']}
    correct_r = {t for e in elements for t in e['correct_rabbit']}
    body['options'] = [o for o in body['options'] if not (o['mode'] == 'turtle' and o['text'] == '에서' and '에서' not in correct_t)]
    last = elements[-1]['correct_rabbit'][0]
    exists = last in ('있어요', '없어요')
    before_verb = elements[-2]['correct_turtle'] if len(elements) > 1 else []
    place = before_verb[0] if exists and before_verb[1:] == ['에'] else None
    if place:
        block = '을' if _ends_with_consonant(place) else '를'
        valid = '이' if _ends_with_consonant(place) else '가'
        body['options'] = [o for o in body['options'] if not (o['mode'] == 'turtle' and o['text'] == valid and valid not in correct_t)]
        for o in body['options']:
            if o['mode'] == 'rabbit' and o['text'] == place + valid and o['text'] not in correct_r:
                o['text'] = place + block
        _add_turtle_decoy(body, block)
    # 칸이 하나뿐이면 너무 쉬우니 오답을 둘로 맞춘다
    decoys = [o['text'] for o in body['options'] if o['mode'] == 'turtle' and o['text'] not in correct_t]
    if len(decoys) < 2:
        for extra in (('를', '을') if exists else ('이', '가')):
            if extra not in correct_t and extra not in decoys:
                _add_turtle_decoy(body, extra)
                break


def fix_vocabulary_chunks(content):
    """낱말 카드는 활용형을 쪼개지 않고 한 토큰으로 ('마셔요' 를 문장 없이 분석하면 마+시+어요 로 잘못 나뉜다)."""
    for step in content['steps']:
        if step['title'].startswith('Vocabulary'):
            for s in step['content']['sentences']:
                s['chunks'] = [{'display': s['korean'], 'tokens': [{'text': s['korean'], 'meaning': s['english'].lower()}]}]


def _sql_str(text):
    return "'" + text.replace("'", "''") + "'"


def build_fix_patches(merger):
    for patch_name, header, lessons in FIX_PATCHES:
        out = [
            f"-- {header}\n",
            "-- 생성: backend/lessons/build_curriculum.py (lesson*.json + curriculum.csv). 직접 고치지 말 것.\n",
            "BEGIN;\n",
        ]
        for lesson_id, filename in lessons:
            with open(os.path.join(HERE, filename), encoding='utf-8') as f:
                base = json.load(f)
            out.append(to_sql(lesson_id, merger.merge_content(base, merger.build_quiz_steps(CSV, lesson_id))))
        out.append("COMMIT;\n")
        patch_path = os.path.join(PATCH_DIR, patch_name)
        with open(patch_path, 'w', encoding='utf-8') as f:
            f.writelines(out)
        print("wrote", os.path.normpath(patch_path))


def _pilot_source(filename, gen):
    """소개 단계에 탭 분석을 넣어 소스 파일에 다시 쓴다 (다른 레슨 소스와 같은 방식)."""
    path = os.path.join(HERE, filename)
    with open(path, encoding='utf-8') as f:
        base = json.load(f)
    inject_chunks(base, gen)
    fix_vocabulary_chunks(base)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(base, f, ensure_ascii=False, indent=2)
        f.write('\n')
    return base


def _place_quizzes(base, merger, csv_lesson_id, fix_decoys=None):
    """quiz_slot 자리에 조립 문제를 넣는다. 힌트는 뒤로 갈수록 줄어든다 (소스의 hint)."""
    quizzes = merger.build_quiz_steps(CSV, csv_lesson_id)
    steps = []
    for step in base['steps']:
        if step['step_type'] != 'quiz_slot':
            steps.append(step)
            continue
        quiz = quizzes[step['quiz'] - 1]
        fix_place_decoys(quiz['contentObj'])
        fix_contracted_decoys(quiz['contentObj'])
        if fix_decoys:
            fix_decoys(quiz['contentObj'])
        quiz['title'] = step['title']
        quiz['instruction'] += step['hint']
        steps.append(quiz)
    return {'steps': steps}


def _lesson_upsert(lesson_id, unit, order, title, description, minutes):
    return (
        "INSERT INTO lessons (lesson_id, unit_id, unit_title, order_num, title, description,\n"
        "                     difficulty_level, estimated_minutes, is_published, content, created_at, updated_at)\n"
        f"VALUES ('{lesson_id}', {unit}, {_sql_str(UNIT_TITLES[unit])}, {order}, {_sql_str(title)},\n"
        f"        {_sql_str(description)}, 1, {minutes}, true, '{{\"steps\": []}}'::jsonb, NOW(), NOW())\n"
        "ON CONFLICT (lesson_id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description,\n"
        "    estimated_minutes = EXCLUDED.estimated_minutes, is_published = EXCLUDED.is_published;\n")


def build_pilot_patch(gen, merger):
    order = dict(PILOT_ORDER)
    R[frozenset({'이', '가'})] = NOT_RULE
    learn = _pilot_source(PILOT_LEARN[1], gen)
    practice = _place_quizzes(_pilot_source(PILOT_PRACTICE[1], gen), merger, PILOT_PRACTICE[2])
    out = [
        "-- WEB-5.12.3: 과거형 Learn u3-l2-learn 추가, Practice u3-l2 다시 쓰기, Unit 3 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.\n",
        "-- 생성: backend/lessons/build_curriculum.py (lesson2_learn.json, lesson2_practice.json, curriculum.csv 의 u3-l2-practice). 직접 고치지 말 것.\n",
        "-- 적용 순서: lsn_008 뒤. concept 위젯이 들어간 앱을 먼저 배포한다. 옛 앱은 'Unknown Step Type: concept' 을 보여 주므로 옛 앱이 쓰는 DB(운영) 금지.\n",
        "-- lsn_006·lsn_007 을 다시 돌리면 순서와 u3-l2 내용이 되돌아가므로, 그 뒤에는 이 패치도 다시 적용한다.\n",
        "-- 되돌리기: DELETE FROM lessons WHERE lesson_id = 'u3-l2-learn'; 후 lsn_007 재적용 (u3-l2 내용과 순서 복원).\n",
        "BEGIN;\n",
    ]
    for lesson_id, _file, _csv, title, description, minutes in (PILOT_LEARN, PILOT_PRACTICE):
        out.append(_lesson_upsert(lesson_id, PILOT_UNIT, order[lesson_id], title, description, minutes))
    out.append(to_sql(PILOT_LEARN[0], learn))
    out.append(to_sql(PILOT_PRACTICE[0], practice))
    for lesson_id, num in PILOT_ORDER:
        out.append(f"UPDATE lessons SET order_num = {num} WHERE lesson_id = '{lesson_id}';\n")
    out.append("COMMIT;\n")
    patch_path = os.path.join(PATCH_DIR, PILOT_PATCH)
    with open(patch_path, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print("wrote", os.path.normpath(patch_path))


def _content_from_patch(patch_name, lesson_id):
    with open(os.path.join(PATCH_DIR, patch_name), encoding='utf-8') as f:
        text = f.read()
    found = dict((lesson, body) for body, lesson in
                 re.findall(r"UPDATE lessons SET content = \$lsn\$(.*?)\$lsn\$::jsonb\nWHERE lesson_id = '([^']+)';", text, re.S))
    return json.loads(found[lesson_id])


def _apply_revision(content, ops):
    """이미 승인된 레슨의 몇 군데만 고친다. 기대한 옛 값이 아니면 빌드를 멈춘다."""
    steps = content['steps']
    for op in ops:
        if op[0] == 'swap':
            _, i, j = op
            steps[i], steps[j] = steps[j], steps[i]
            continue
        _, step, path, old, new = op
        target = steps[step]
        for key in path[:-1]:
            target = target[key]
        assert target[path[-1]] == old, (step, path, target[path[-1]])
        target[path[-1]] = new
    return content


def build_rewrite_patches(gen, merger):
    for spec in REWRITE_PATCHES:
        R[frozenset({'이', '가'})] = NOT_RULE if spec['unit'] == 3 else SUBJECT_RULE
        order = dict(spec['order'])
        out = [
            f"-- {spec['header']}\n",
            "-- 생성: backend/lessons/build_curriculum.py (소스 *_learn.json, *_practice.json, curriculum.csv). 직접 고치지 말 것.\n",
            "-- 적용 순서: lsn_009 뒤, 번호 순서대로. concept 위젯이 들어간 앱을 먼저 배포한다. 옛 앱은 'Unknown Step Type: concept' 을 보여 주므로 옛 앱이 쓰는 DB(운영) 금지.\n",
            "-- lsn_005·006·007·009 를 다시 돌리면 순서와 내용이 되돌아가므로, 그 뒤에는 이 패치도 다시 적용한다.\n",
            "BEGIN;\n",
        ]
        contents = []
        for lesson_id, filename, csv_id, title, description, minutes in spec['lessons']:
            out.append(_lesson_upsert(lesson_id, spec['unit'], order[lesson_id], title, description, minutes))
            base = _pilot_source(filename, gen)
            contents.append((lesson_id, _place_quizzes(base, merger, csv_id, fix_meaning_decoys) if csv_id else base))
        for lesson_id, filename, csv_id in spec.get('reviews', []):
            base = _pilot_source(filename, gen)
            quizzes = merger.build_quiz_steps(CSV, csv_id)
            for quiz, suffix in zip(quizzes, QUIZ_INSTRUCTION_SUFFIX[lesson_id], strict=True):
                fix_place_decoys(quiz['contentObj'])
                fix_meaning_decoys(quiz['contentObj'])
                quiz['instruction'] += suffix
            contents.append((lesson_id, merger.merge_content(base, quizzes)))
        for lesson_id, patch_name, ops in spec.get('revisions', []):
            contents.append((lesson_id, _apply_revision(_content_from_patch(patch_name, lesson_id), ops)))
        for lesson_id, patch_name, step, exercise, options in spec.get('option_fixes', []):
            content = _content_from_patch(patch_name, lesson_id)
            target = content['steps'][step]['content']['exercises'][exercise]
            assert target['answer'] in options
            target['options'] = options
            contents.append((lesson_id, content))
        for lesson_id, patch_name, step, old, new in spec.get('decoy_fixes', []):
            content = _content_from_patch(patch_name, lesson_id)
            body = content['steps'][step]['contentObj']
            found = [o for o in body['options'] if o['mode'] == 'turtle' and o['text'] == old]
            assert len(found) == 1 and all(new not in e['correct_turtle'] for e in body['elements'])
            found[0]['text'] = new
            contents.append((lesson_id, content))
        out.extend(to_sql(lesson_id, content) for lesson_id, content in contents)
        out.extend(f"UPDATE lessons SET order_num = {num} WHERE lesson_id = '{lesson_id}';\n" for lesson_id, num in spec['order'])
        out.append("COMMIT;\n")
        patch_path = os.path.join(PATCH_DIR, spec['patch'])
        with open(patch_path, 'w', encoding='utf-8') as f:
            f.writelines(out)
        print("wrote", os.path.normpath(patch_path))


def main():
    gen = CurriculumMorphology()
    merger = ContentMerger()
    build_fix_patches(merger)
    for patch_name, header, lessons in PATCHES:
        out = [
            f"-- {header}\n",
            "-- 생성: backend/lessons/build_curriculum.py (lesson*.json + curriculum.csv). 직접 고치지 말 것.\n",
            "-- lsn_001~005 이후 번호 순서로 적용. 다시 적용하면 메타데이터·content 가 이 파일 내용으로 맞춰진다.\n",
            "BEGIN;\n\n",
        ]
        for lesson_id, unit, order, filename, title, description in lessons:
            path = os.path.join(HERE, filename)
            with open(path, encoding='utf-8') as f:
                base = json.load(f)
            inject_chunks(base, gen)
            fix_vocabulary_chunks(base)
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(base, f, ensure_ascii=False, indent=2)
                f.write('\n')

            R[frozenset({'이', '가'})] = NOT_RULE if unit == 3 else SUBJECT_RULE
            quiz_steps = merger.build_quiz_steps(CSV, lesson_id)
            suffixes = QUIZ_INSTRUCTION_SUFFIX.get(lesson_id, [''] * len(quiz_steps))
            assert len(suffixes) == len(quiz_steps), lesson_id
            for step, suffix in zip(quiz_steps, suffixes):
                fix_place_decoys(step['contentObj'])
                fix_contracted_decoys(step['contentObj'])
                step['instruction'] += suffix
            content = merger.merge_content(base, quiz_steps)

            out.append(
                "INSERT INTO lessons (lesson_id, unit_id, unit_title, order_num, title, description,\n"
                "                     difficulty_level, estimated_minutes, is_published, content, created_at, updated_at)\n"
                f"VALUES ('{lesson_id}', {unit}, {_sql_str(UNIT_TITLES[unit])}, {order}, {_sql_str(title)},\n"
                f"        {_sql_str(description)}, 1, 15, true, '{{\"steps\": []}}'::jsonb, NOW(), NOW())\n"
                "ON CONFLICT (lesson_id) DO UPDATE SET unit_id = EXCLUDED.unit_id, unit_title = EXCLUDED.unit_title,\n"
                "    order_num = EXCLUDED.order_num, title = EXCLUDED.title, description = EXCLUDED.description,\n"
                "    difficulty_level = EXCLUDED.difficulty_level, estimated_minutes = EXCLUDED.estimated_minutes,\n"
                "    is_published = EXCLUDED.is_published;\n\n")
            out.append(to_sql(lesson_id, content))
            out.append("\n")
        out.append("COMMIT;\n")
        patch_path = os.path.join(PATCH_DIR, patch_name)
        with open(patch_path, 'w', encoding='utf-8') as f:
            f.writelines(out)
        print("wrote", os.path.normpath(patch_path))
    build_pilot_patch(gen, merger)
    build_rewrite_patches(gen, merger)


if __name__ == '__main__':
    main()
