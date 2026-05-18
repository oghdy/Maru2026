import psycopg2
from psycopg2.pool import SimpleConnectionPool
from contextlib import contextmanager
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PostgresPool:
    def __init__(self, dbname="maru", user="hadohadopapi", password="", host="localhost", port="5432"):
        try:
            self.pool = SimpleConnectionPool(
                1, 10,
                dbname=dbname,
                user=user,
                password=password,
                host=host,
                port=port
            )
            logger.info("Successfully initialized PostgreSQL connection pool.")
        except Exception as e:
            logger.error(f"Error connecting to PostgreSQL: {e}")
            raise e
            
    @contextmanager
    def get_connection(self):
        conn = self.pool.getconn()
        try:
            yield conn
        finally:
            self.pool.putconn(conn)
            
    def test_connection(self):
        with self.get_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT version();")
                record = cursor.fetchone()
                logger.info(f"You are connected to - {record[0]}")

# Singleton instance
db = PostgresPool()

if __name__ == "__main__":
    db.test_connection()
