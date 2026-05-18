"""
db_inserter.py
Task 22-4: PostgreSQL Bulk Insert 파이프라인

역할:
- DB에 연결 (psycopg2)
- 카테고리(`word_categories`) get_or_create 처리
- 단어(`words`) bulk insert (ON CONFLICT DO NOTHING 멱등성 보장)
"""
import os
import psycopg2
from dotenv import load_dotenv
from gemini_translator import TranslationResult

load_dotenv()

class DbInserter:
    def __init__(self, conn=None):
        self.conn = conn

    def connect(self):
        if self.conn is None:
            self.conn = psycopg2.connect(
                host=os.getenv("DB_HOST", "127.0.0.1"),
                port=os.getenv("DB_PORT", "5432"),
                dbname=os.getenv("DB_NAME", "maru"),
                user=os.getenv("DB_USER", "hadohadopapi"),
                password=os.getenv("DB_PASS", "")
            )
        return self.conn

    def close(self):
        if self.conn:
            self.conn.close()

    def _get_or_create_category(self, cursor, category_name: str, level: str) -> int:
        """주어진 이름의 카테고리가 있으면 ID 반환, 없으면 생성 후 ID 반환"""
        cursor.execute("SELECT id FROM word_categories WHERE title = %s", (category_name,))
        row = cursor.fetchone()
        
        if row:
            return row[0]
        
        # 카테고리가 없으면 새로 생성 (기본 정렬 순서 deck_order=0)
        cursor.execute(
            "INSERT INTO word_categories (title, level, deck_order) VALUES (%s, %s, %s) RETURNING id",
            (category_name, level, 0)
        )
        return cursor.fetchone()[0]

    def insert_batch(self, results: list[TranslationResult], default_level: str):
        """번역 완료된 DTO 리스트를 카테고리 분류와 함께 멱등성 Bulk Insert"""
        if not results:
            return

        conn = self.connect()
        try:
            with conn.cursor() as cursor:
                # 1. 카테고리별로 단어 나누기 (미리 캐싱)
                category_ids = {}
                for r in results:
                    if r.category not in category_ids:
                        category_ids[r.category] = self._get_or_create_category(cursor, r.category, default_level)
                
                # 2. Bulk Insert 쿼리 준비
                insert_query = """
                    INSERT INTO words (category_id, korean_word, primary_meaning, part_of_speech, example_sentence, example_translation)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    ON CONFLICT (korean_word, part_of_speech) DO NOTHING
                """
                
                # 3. 파라미터 리스트 만들기
                params = [
                    (
                        category_ids[r.category],
                        r.korean_word,
                        r.english,
                        r.part_of_speech,
                        r.example_kr,
                        r.example_en
                    )
                    for r in results
                ]
                
                # 4. 일괄 실행 (속도 최적화)
                cursor.executemany(insert_query, params)
                inserted_count = cursor.rowcount  # ON CONFLICT DO NOTHING으로 인해 실제로 삽입된 건수
                conn.commit()
                
                print(f"[DB] {len(results)}건 중 {inserted_count}건 Insert 완료 (나머진 중복 스킵)")
        except Exception as e:
            conn.rollback()
            print(f"[DB ERROR] 롤백 됨: {e}")
            raise
