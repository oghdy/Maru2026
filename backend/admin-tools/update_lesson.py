"""레슨 JSON 파일 전체를 DB 레슨 행의 content 에 그대로 덮어쓴다.

사용: python update_lesson.py --db maru_lesson <lesson.json> <lesson_id>
  예: python update_lesson.py --db maru_lesson ../lessons/unit1/lesson2.json lesson2

주의: 파일 내용 그대로 덮어쓰므로 Kiwi 로 만든 조립 문제가 파일에 없으면 사라진다.
조립 문제가 있는 레슨은 kiwi-generator/batch_merger.py --base-json <파일> 로 한 번에 반영할 것
(파일 → chunks → 조립 문제 → DB/패치 순서가 한 명령 안에서 고정됨).
"""
import argparse
import getpass
import json
import os
import sys

import psycopg2


def update_lesson_from_json(dbname: str, json_file_path: str, lesson_id: str) -> None:
    with open(json_file_path, encoding='utf-8') as f:
        content = json.load(f)
    print(f"Loaded {len(content.get('steps', []))} steps from {json_file_path}")

    conn = psycopg2.connect(dbname=dbname, user=os.environ.get("PGUSER", getpass.getuser()),
                            password=os.environ.get("PGPASSWORD", ""),
                            host=os.environ.get("PGHOST", "localhost"), port=os.environ.get("PGPORT", "5432"))
    try:
        with conn, conn.cursor() as cur:
            cur.execute("UPDATE lessons SET content = %s::jsonb, updated_at = NOW() WHERE lesson_id = %s",
                        (json.dumps(content, ensure_ascii=False), lesson_id))
            if cur.rowcount != 1:
                sys.exit(f"No lesson with lesson_id={lesson_id!r} in DB {dbname}")
        print(f"Updated {lesson_id} in {dbname}")
    finally:
        conn.close()


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--db', required=True, help="대상 DB (예: maru_lesson). 원본 maru 는 PM 만")
    ap.add_argument('json_path')
    ap.add_argument('lesson_id', help="lessons.lesson_id 문자열 (예: u1-l1)")
    a = ap.parse_args()
    update_lesson_from_json(a.db, a.json_path, a.lesson_id)
