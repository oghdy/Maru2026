"""Unit 2 "Daily Life" 빌드: lesson*.json + curriculum.csv → 탭 분석 chunks + 조립 문제 → SQL 패치.

kiwi-generator 코드는 고치지 않는다. 그 표에 없는 Unit 2 항목(에·안 설명과 오답, 새 단어 뜻)만
여기서 실행 시 추가하므로 Unit 0·1 생성 결과에는 영향이 없다. 출력은 결정적이다.

사용 (backend/admin-tools/kiwi-generator 에서):
  PYTHONDONTWRITEBYTECODE=1 venv/bin/python ../../lessons/unit2/build_unit2.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GENERATOR = os.path.join(HERE, '..', '..', 'admin-tools', 'kiwi-generator')
sys.path.insert(0, GENERATOR)

import core_engine  # noqa: E402
import generate_morphology  # noqa: E402
from batch_merger import ContentMerger, to_sql  # noqa: E402
from inject_morphology import inject_chunks  # noqa: E402

CSV = os.path.join(GENERATOR, 'curriculum.csv')
PATCH = os.path.join(HERE, '..', '..', 'db', 'patches', 'lsn_005_add_unit2_daily_life.sql')

UNIT_TITLE = 'Daily Life'
LESSONS = [
    ('u2-l1', 1, 'lesson1.json', 'Do you have time?',
     "Say what you have and don't have using 있어요/없어요 and the subject particle 이/가."),
    ('u2-l2', 2, 'lesson2.json', 'Where are you going?',
     'Say where you go and where you are using the place particle 에.'),
    ('u2-l3', 3, 'lesson3.json', "I don't drink coffee",
     "Say what you don't do by putting 안 before the verb."),
]

# 조립 문제: 에 의 오답은 방금 배운 이/가 ('집이 있어요' 는 뜻이 달라지는 대표적인 혼동)
core_engine.ALLOMORPHS['에'] = ['가']
core_engine.CATEGORY_POOL['JKB'] = ['이', '가']
core_engine.ALLOMORPH_RULES[frozenset({'에'})] = (
    "marks a place: where you go or where something is. It is the same after a consonant or a vowel.")
core_engine.ALLOMORPH_RULES[frozenset({'안'})] = "means 'not'. It goes right before the verb."

# 탭 분석: Unit 2 새 단어 뜻
generate_morphology.TOKEN_SPECIFIC_MAP.update({
    '있': 'there is / have / be at', '없': "there isn't / don't have",
    '에': 'place marker', '안': 'not',
    '네': 'yes', '오늘': 'today', '지금': 'now', '어디': 'where',
    '시간': 'time', '친구': 'friend', '돈': 'money', '우유': 'milk', '가방': 'bag',
    '학교': 'school', '집': 'home', '회사': 'company', '카페': 'café', '도서관': 'library',
})

# Kiwi 가 '아니요' 를 문장에 따라 아니+요 로 나누므로 통째로 고정
generate_morphology.CHUNK_OVERRIDE_MAP['아니요'] = 'no'


class Unit2Morphology(generate_morphology.MorphologyGenerator):
    def get_meaning(self, text, tag):
        if text == '가' and tag == 'VV':  # 주격 조사 '가' 와 글자가 같아 품사로 구분
            return 'go'
        return super().get_meaning(text, tag)


def _ends_with_consonant(word):
    return (ord(word[-1]) - 0xAC00) % 28 != 0


def fix_place_decoys(body):
    """에 문제의 🐰 오답을 받침에 맞는 이/가 로 쓴다 (집가 → 집이). 다른 레슨의 오답은 그대로."""
    if not any('에' in e['correct_turtle'] for e in body['elements']):
        return
    for o in body['options']:
        text = o['text']
        if o['mode'] == 'rabbit' and text.endswith('가') and text != '가요' and _ends_with_consonant(text[:-1]):
            o['text'] = text[:-1] + '이'


def fix_vocabulary_chunks(content):
    """낱말 카드는 활용형을 쪼개지 않고 한 토큰으로 ('마셔요' 를 문장 없이 분석하면 마+시+어요 로 잘못 나뉜다)."""
    for step in content['steps']:
        if step['title'].startswith('Vocabulary'):
            for s in step['content']['sentences']:
                s['chunks'] = [{'display': s['korean'], 'tokens': [{'text': s['korean'], 'meaning': s['english'].lower()}]}]


def _sql_str(text):
    return "'" + text.replace("'", "''") + "'"


def main():
    gen = Unit2Morphology()
    merger = ContentMerger()
    out = [
        "-- WEB-5.8.1: Unit 2 \"Daily Life\" 레슨 3개 추가 (멱등): u2-l1 있어요/없어요·이/가, u2-l2 에 + 가요/있어요, u2-l3 안 + 동사.\n",
        "-- 생성: backend/lessons/unit2/build_unit2.py (lesson*.json + curriculum.csv). 직접 고치지 말 것.\n",
        "-- lsn_001~004 이후에 적용. 다시 적용하면 메타데이터·content 가 이 파일 내용으로 맞춰진다.\n",
        "BEGIN;\n\n",
    ]
    for lesson_id, order, filename, title, description in LESSONS:
        path = os.path.join(HERE, filename)
        with open(path, encoding='utf-8') as f:
            base = json.load(f)
        inject_chunks(base, gen)
        fix_vocabulary_chunks(base)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(base, f, ensure_ascii=False, indent=2)
            f.write('\n')

        quiz_steps = merger.build_quiz_steps(CSV, lesson_id)
        for step in quiz_steps:
            fix_place_decoys(step['contentObj'])
        content = merger.merge_content(base, quiz_steps)

        out.append(
            "INSERT INTO lessons (lesson_id, unit_id, unit_title, order_num, title, description,\n"
            "                     difficulty_level, estimated_minutes, is_published, content, created_at, updated_at)\n"
            f"VALUES ('{lesson_id}', 2, '{UNIT_TITLE}', {order}, {_sql_str(title)},\n"
            f"        {_sql_str(description)}, 1, 15, true, '{{\"steps\": []}}'::jsonb, NOW(), NOW())\n"
            "ON CONFLICT (lesson_id) DO UPDATE SET unit_id = EXCLUDED.unit_id, unit_title = EXCLUDED.unit_title,\n"
            "    order_num = EXCLUDED.order_num, title = EXCLUDED.title, description = EXCLUDED.description,\n"
            "    difficulty_level = EXCLUDED.difficulty_level, estimated_minutes = EXCLUDED.estimated_minutes,\n"
            "    is_published = EXCLUDED.is_published;\n\n")
        out.append(to_sql(lesson_id, content))
        out.append("\n")
    out.append("COMMIT;\n")
    with open(PATCH, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print("wrote", os.path.normpath(PATCH))


if __name__ == '__main__':
    main()
