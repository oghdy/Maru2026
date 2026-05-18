"""
[TDD - Task 22-4] PostgreSQL Bulk Insert 단위 테스트
실제 DB 연결 없이 psycopg2 커서를 Mocking하여 멱등성 보장 쿼리(get_or_create, ON CONFLICT DO NOTHING)가 올바르게 실행되는지 검증합니다.
"""
import pytest
from unittest.mock import MagicMock
from gemini_translator import TranslationResult
from db_inserter import DbInserter


@pytest.fixture
def mock_conn():
    conn = MagicMock()
    conn.cursor.return_value.__enter__.return_value = MagicMock()
    return conn

@pytest.fixture
def sample_results():
    return [
        TranslationResult("가게", "shop", "장소", "가게에 가요.", "I go to the shop.", "Noun"),
        TranslationResult("사과", "apple", "음식", "사과를 먹어요.", "I eat an apple.", "Noun"),
    ]

class TestDbInserter:
    def test_get_or_create_category_inserts_when_not_exist(self, mock_conn):
        cursor = mock_conn.cursor.return_value.__enter__.return_value
        # 카테고리가 DB에 없다고 가정 (첫 fetchone은 None 반환, 두 번째 RETURNING fetchone은 (7,) 반환)
        cursor.fetchone.side_effect = [None, (7,)]
        
        inserter = DbInserter(mock_conn)
        cat_id = inserter._get_or_create_category(cursor, "장소", "Beginner")
        
        # INSERT 쿼리가 실행되었는지 확인
        executed_query = cursor.execute.call_args_list[-1][0][0]
        assert "INSERT INTO word_categories" in executed_query

    def test_get_or_create_category_returns_existing_id(self, mock_conn):
        cursor = mock_conn.cursor.return_value.__enter__.return_value
        # 카테고리가 DB에 이미 존재한다고 가정 (id=5)
        cursor.fetchone.return_value = (5,)
        
        inserter = DbInserter(mock_conn)
        cat_id = inserter._get_or_create_category(cursor, "장소", "Beginner")
        
        assert cat_id == 5
        # INSERT가 호출되지 않았음을 확인 (단순 fetch만 수행)
        assert cursor.execute.call_count == 1

    def test_insert_word_uses_on_conflict_do_nothing(self, mock_conn, sample_results):
        cursor = mock_conn.cursor.return_value.__enter__.return_value
        # 카테고리 id 항상 1 반환
        cursor.fetchone.return_value = (1,)
        
        inserter = DbInserter(mock_conn)
        inserter.insert_batch(sample_results, "Beginner")
        
        # executemany 쿼리에 ON CONFLICT DO NOTHING이 포함되었는지 확인
        exec_many_call = cursor.executemany.call_args
        assert exec_many_call is not None
        
        query = exec_many_call[0][0]
        assert "ON CONFLICT (korean_word, part_of_speech)" in query
        assert "DO NOTHING" in query
        
        # 2개의 데이터가 파라미터로 넘어갔는지 확인
        params = exec_many_call[0][1]
        assert len(params) == 2
        assert params[0][1] == "가게"
        assert params[1][1] == "사과"
