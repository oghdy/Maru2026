import getpass
import os

import psycopg2


def connect(dbname: str):
    """DB 이름은 반드시 인자로 받는다 (기본값으로 원본 `maru` DB 를 건드리지 않도록).
    접속 정보는 PGUSER / PGHOST / PGPORT / PGPASSWORD 환경변수, 없으면 로컬 기본값."""
    if not dbname:
        raise ValueError("dbname is required (e.g. maru_lesson)")
    return psycopg2.connect(
        dbname=dbname,
        user=os.environ.get("PGUSER", getpass.getuser()),
        password=os.environ.get("PGPASSWORD", ""),
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5432"),
    )


if __name__ == "__main__":
    import sys
    with connect(sys.argv[1]) as conn, conn.cursor() as cur:
        cur.execute("SELECT version();")
        print(cur.fetchone()[0])
