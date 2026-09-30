"""curriculum.csv 의 문장으로 2단계 조립 문제를 만들어 레슨 content 에 병합한다.

기본 흐름 (파일이 원본, DB·패치는 결과물):
  python batch_merger.py --lesson u1-l1 --base-json ../../lessons/unit1/lesson1.json --chunks \
      --db maru_lesson --sql-out ../../db/patches/lsn_00N_x.sql

  --base-json  손으로 쓴 소개·연습·완료 단계 JSON (없으면 --db 의 현재 content 를 사용)
  --chunks     소개 단계의 탭 분석 chunks 도 다시 생성
  --db         결과를 이 DB 의 lessons 행에 저장 (필수 아님. 원본 maru 는 PM 만)
  --sql-out    같은 결과를 재실행 가능한 UPDATE 문으로 기록 (--append 로 이어쓰기)
  --dry-run    DB 에 쓰지 않고 결과 JSON 을 출력
기존 조립 단계는 지우고 새로 넣으므로(completion 앞), 몇 번 돌려도 결과가 같다.
"""
import argparse
import json
import logging
import sys

import pandas as pd

from core_engine import KiwiEngine

logging.basicConfig(level=logging.INFO, format='%(levelname)s %(message)s')
logger = logging.getLogger(__name__)


def _step_type(step: dict) -> str:
    return step.get('stepType') or step.get('step_type')


class ContentMerger:
    def __init__(self, engine: KiwiEngine = None):
        self.engine = engine or KiwiEngine()

    def build_quiz_steps(self, csv_file: str, lesson_id: str) -> list:
        df = pd.read_csv(csv_file)
        rows = df[df['LessonID'] == lesson_id]
        steps = []
        for n, (_, row) in enumerate(rows.iterrows(), start=1):
            quiz = self.engine.process_sentence(row['Sentence'], row['Translation'], row['Target_POS'])
            body = quiz.model_dump(exclude_none=True)
            body.pop('stepType', None)
            steps.append({
                "stepType": "agglutinative_quiz",
                "title": f"Sentence Building #{n}",
                "instruction": f"Build the sentence: \"{row['Translation']}\"",
                "contentObj": body,
            })
        return steps

    @staticmethod
    def merge_content(base_content: dict, quiz_steps: list) -> dict:
        """기존 조립 단계를 지우고 새 조립 단계를 completion 바로 앞(없으면 끝)에 넣는다."""
        steps = [s for s in (base_content or {}).get('steps', []) if _step_type(s) != 'agglutinative_quiz']
        idx = next((i for i, s in enumerate(steps) if _step_type(s) == 'completion'), len(steps))
        return {"steps": steps[:idx] + list(quiz_steps) + steps[idx:]}


def to_sql(lesson_id: str, content: dict) -> str:
    body = json.dumps(content, ensure_ascii=False)
    assert "$lsn$" not in body
    return (f"UPDATE lessons SET content = $lsn${body}$lsn$::jsonb\n"
            f"WHERE lesson_id = '{lesson_id}';\n")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--lesson', required=True, help="lessons.lesson_id (예: u1-l1)")
    ap.add_argument('--csv', default='curriculum.csv')
    ap.add_argument('--base-json')
    ap.add_argument('--chunks', action='store_true')
    ap.add_argument('--db')
    ap.add_argument('--sql-out')
    ap.add_argument('--append', action='store_true')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args(argv)
    if not args.base_json and not args.db:
        ap.error("--base-json 또는 --db 중 하나는 필요")

    conn = None
    if args.db:
        from db_connector import connect
        conn = connect(args.db)

    if args.base_json:
        with open(args.base_json, encoding='utf-8') as f:
            base = json.load(f)
    else:
        with conn.cursor() as cur:
            cur.execute("SELECT content FROM lessons WHERE lesson_id = %s", (args.lesson,))
            row = cur.fetchone()
        if not row:
            sys.exit(f"Lesson not found in DB {args.db}: {args.lesson}")
        base = row[0]

    merger = ContentMerger()
    if args.chunks:
        from inject_morphology import inject_chunks
        logger.info("chunks regenerated for %d sentences", inject_chunks(base))
    quiz_steps = merger.build_quiz_steps(args.csv, args.lesson)
    if not quiz_steps:
        logger.warning("No rows in %s for lesson %s — existing quizzes will be removed", args.csv, args.lesson)
    content = merger.merge_content(base, quiz_steps)
    logger.info("%s: %d steps (%d agglutinative_quiz)", args.lesson, len(content['steps']), len(quiz_steps))

    if args.dry_run:
        print(json.dumps(content, ensure_ascii=False, indent=2))
    elif conn is not None:
        with conn, conn.cursor() as cur:
            cur.execute("UPDATE lessons SET content = %s::jsonb, updated_at = NOW() WHERE lesson_id = %s",
                        (json.dumps(content, ensure_ascii=False), args.lesson))
            if cur.rowcount != 1:
                sys.exit(f"Lesson not found in DB {args.db}: {args.lesson}")
        logger.info("updated %s in DB %s", args.lesson, args.db)

    if args.sql_out:
        with open(args.sql_out, 'a' if args.append else 'w', encoding='utf-8') as f:
            f.write(to_sql(args.lesson, content))
        logger.info("wrote %s", args.sql_out)
    if conn is not None:
        conn.close()


if __name__ == "__main__":
    main()
