"""파일럿 초안 빌드 (WEB-5.12.3): 과거형 Learn(u3-l2-learn) + Practice(u3-l2 다시 쓰기).

concept 위젯이 나오기 전에는 DB 에 적용하지 않는다. 결과 SQL 은 db/patches 가 아니라 이 폴더에 둔다.
PM 이 적용을 지시하면 draft_pilot_past_tense.sql 을 backend/db/patches/lsn_0NN_*.sql 로 옮긴다.

사용 (backend/admin-tools/kiwi-generator 에서):
  PYTHONDONTWRITEBYTECODE=1 venv/bin/python ../../lessons/unit3/draft_build_pilot.py
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..'))

import build_curriculum as bc  # noqa: E402  (표 확장도 이 import 로 적용된다)
from batch_merger import ContentMerger, to_sql  # noqa: E402
from inject_morphology import inject_chunks  # noqa: E402

UNIT_TITLE = bc.UNIT_TITLES[3]
QUIZ_CSV = os.path.join(HERE, 'draft_u3_l2_practice.csv')
OUT = os.path.join(HERE, 'draft_pilot_past_tense.sql')

LEARN = ('u3-l2-learn', 2, 'draft_u3_l2_learn.json', 'Learn: Past tense',
         'Slowly learn how 았/었 makes the past. Only three small checks, with no score.', 5)
PRACTICE = ('u3-l2', 3, 'draft_u3_l2_practice.json', 'What did you do?',
            'Practice saying what you did using 았/었어요.', 10)
# 끼워 넣기 후 Unit 3 순서. 목록 화면이 order_num 을 그대로 숫자로 보여 주므로 빈 번호 없이 맞춘다.
ORDER = [('u3-l1', 1), ('u3-l2-learn', 2), ('u3-l2', 3), ('u3-l3', 4), ('u3-l4', 5), ('u3-l5', 6)]


def load(name):
    with open(os.path.join(HERE, name), encoding='utf-8') as f:
        return json.load(f)


def fill_chunks(path_name, gen):
    """소개 단계에 탭 분석을 넣어 소스 파일에 다시 쓴다 (다른 레슨 소스와 같은 방식)."""
    base = load(path_name)
    inject_chunks(base, gen)
    bc.fix_vocabulary_chunks(base)
    with open(os.path.join(HERE, path_name), 'w', encoding='utf-8') as f:
        json.dump(base, f, ensure_ascii=False, indent=2)
        f.write('\n')
    return base


def place_quizzes(base, merger):
    """quiz_slot 자리에 조립 문제를 넣는다. 힌트는 뒤로 갈수록 줄어든다 (소스의 hint)."""
    bc.R[frozenset({'이', '가'})] = bc.NOT_RULE
    quizzes = merger.build_quiz_steps(QUIZ_CSV, 'u3-l2')
    steps = []
    for step in base['steps']:
        if step['step_type'] != 'quiz_slot':
            steps.append(step)
            continue
        quiz = quizzes[step['quiz'] - 1]
        quiz['title'] = step['title']
        quiz['instruction'] += step['hint']
        steps.append(quiz)
    return {'steps': steps}


def upsert(lesson_id, order, title, description, minutes):
    return (
        "INSERT INTO lessons (lesson_id, unit_id, unit_title, order_num, title, description,\n"
        "                     difficulty_level, estimated_minutes, is_published, content, created_at, updated_at)\n"
        f"VALUES ('{lesson_id}', 3, {bc._sql_str(UNIT_TITLE)}, {order}, {bc._sql_str(title)},\n"
        f"        {bc._sql_str(description)}, 1, {minutes}, true, '{{\"steps\": []}}'::jsonb, NOW(), NOW())\n"
        "ON CONFLICT (lesson_id) DO UPDATE SET title = EXCLUDED.title, description = EXCLUDED.description,\n"
        "    estimated_minutes = EXCLUDED.estimated_minutes, is_published = EXCLUDED.is_published;\n")


def main():
    gen = bc.CurriculumMorphology()
    merger = ContentMerger()
    learn = fill_chunks(LEARN[2], gen)
    practice = place_quizzes(fill_chunks(PRACTICE[2], gen), merger)

    out = [
        "-- 초안 (WEB-5.12.3). concept 위젯이 앱에 들어가기 전에는 적용 금지. 옛 앱은 'Unknown Step Type: concept' 을 보여 준다.\n",
        "-- 생성: backend/lessons/unit3/draft_build_pilot.py. 직접 고치지 말 것. lsn_007 이후에 적용, 멱등.\n",
        "-- 되돌리기: DELETE FROM lessons WHERE lesson_id = 'u3-l2-learn'; 후 lsn_007 재적용 (u3-l2 내용과 순서 복원).\n",
        "BEGIN;\n",
    ]
    for lesson_id, order, _file, title, description, minutes in (LEARN, PRACTICE):
        out.append(upsert(lesson_id, order, title, description, minutes))
    out.append(to_sql(LEARN[0], learn))
    out.append(to_sql(PRACTICE[0], practice))
    for lesson_id, order in ORDER:
        out.append(f"UPDATE lessons SET order_num = {order} WHERE lesson_id = '{lesson_id}';\n")
    out.append("COMMIT;\n")
    with open(OUT, 'w', encoding='utf-8') as f:
        f.writelines(out)
    print("wrote", os.path.normpath(OUT))


if __name__ == '__main__':
    main()
