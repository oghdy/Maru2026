"""레슨 소스 빌드: lesson*.json + curriculum.csv → 탭 분석 chunks + 조립 문제 → SQL 패치.

14레슨 커리큘럼의 신규 8레슨 (WEB-5.8.4) 과 과거형 Learn + Practice 파일럿 (WEB-5.12.3).

기존 레슨(u1-l1, lesson2, u1-l3, u2-l1~l3)과 그 패치(lsn_003~005)는 다시 만들지 않는다. 단 FIX_PATCHES 는 조립 오답만 고친다.
kiwi-generator 코드는 고치지 않고, 그 표에 없는 항목만 실행 시 추가한다. 출력은 결정적이다.
batch_merger.py --lesson 을 직접 돌리면 이 표 확장이 빠지므로 신규 레슨은 반드시 이 스크립트로 만든다.

사용 (backend/admin-tools/kiwi-generator 에서):
  PYTHONDONTWRITEBYTECODE=1 venv/bin/python ../../lessons/build_curriculum.py
"""
import json
import os
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
})
generate_morphology.CHUNK_OVERRIDE_MAP.update({
    '아니요': 'no',
    '그래요': 'is that so?',
    '했어요': 'did (past)',       # 대화 전용. 조립 문장에는 쓰지 않는다
    '하세요': 'do (polite)',      # u1-l4 '무슨 일 하세요?' 는 요청이 아니라 질문
    '싶어요': 'want to',
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


def _pilot_place_quizzes(base, merger, csv_lesson_id):
    """quiz_slot 자리에 조립 문제를 넣는다. 힌트는 뒤로 갈수록 줄어든다 (소스의 hint)."""
    R[frozenset({'이', '가'})] = NOT_RULE
    quizzes = merger.build_quiz_steps(CSV, csv_lesson_id)
    steps = []
    for step in base['steps']:
        if step['step_type'] != 'quiz_slot':
            steps.append(step)
            continue
        quiz = quizzes[step['quiz'] - 1]
        fix_place_decoys(quiz['contentObj'])
        fix_contracted_decoys(quiz['contentObj'])
        quiz['title'] = step['title']
        quiz['instruction'] += step['hint']
        steps.append(quiz)
    return {'steps': steps}


def _pilot_upsert(lesson_id, order, title, description, minutes):
    return (
        "INSERT INTO lessons (lesson_id, unit_id, unit_title, order_num, title, description,\n"
        "                     difficulty_level, estimated_minutes, is_published, content, created_at, updated_at)\n"
        f"VALUES ('{lesson_id}', {PILOT_UNIT}, {_sql_str(UNIT_TITLES[PILOT_UNIT])}, {order}, {_sql_str(title)},\n"
        f"        {_sql_str(description)}, 1, {minutes}, true, '{{\"steps\": []}}'::jsonb, NOW(), NOW())\n"
        "ON CONFLICT (lesson_id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description,\n"
        "    estimated_minutes = EXCLUDED.estimated_minutes, is_published = EXCLUDED.is_published;\n")


def build_pilot_patch(gen, merger):
    order = dict(PILOT_ORDER)
    learn = _pilot_source(PILOT_LEARN[1], gen)
    practice = _pilot_place_quizzes(_pilot_source(PILOT_PRACTICE[1], gen), merger, PILOT_PRACTICE[2])
    out = [
        "-- WEB-5.12.3: 과거형 Learn u3-l2-learn 추가, Practice u3-l2 다시 쓰기, Unit 3 순서 다시 매김 (멱등). lesson_id 유지라 진도 기록은 그대로.\n",
        "-- 생성: backend/lessons/build_curriculum.py (lesson2_learn.json, lesson2_practice.json, curriculum.csv 의 u3-l2-practice). 직접 고치지 말 것.\n",
        "-- 적용 순서: lsn_008 뒤. concept 위젯이 들어간 앱을 먼저 배포한다. 옛 앱은 'Unknown Step Type: concept' 을 보여 주므로 옛 앱이 쓰는 DB(운영) 금지.\n",
        "-- lsn_006·lsn_007 을 다시 돌리면 순서와 u3-l2 내용이 되돌아가므로, 그 뒤에는 이 패치도 다시 적용한다.\n",
        "-- 되돌리기: DELETE FROM lessons WHERE lesson_id = 'u3-l2-learn'; 후 lsn_007 재적용 (u3-l2 내용과 순서 복원).\n",
        "BEGIN;\n",
    ]
    for lesson_id, _file, _csv, title, description, minutes in (PILOT_LEARN, PILOT_PRACTICE):
        out.append(_pilot_upsert(lesson_id, order[lesson_id], title, description, minutes))
    out.append(to_sql(PILOT_LEARN[0], learn))
    out.append(to_sql(PILOT_PRACTICE[0], practice))
    for lesson_id, num in PILOT_ORDER:
        out.append(f"UPDATE lessons SET order_num = {num} WHERE lesson_id = '{lesson_id}';\n")
    out.append("COMMIT;\n")
    patch_path = os.path.join(PATCH_DIR, PILOT_PATCH)
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


if __name__ == '__main__':
    main()
