import json
import psycopg2
import sys
import os

# DB 연결 정보 (db_connector 모듈을 사용해도 되지만, 단독 파일로 편하게 쓰기 위해 직관적으로 작성)
DB_NAME = "maru"
DB_USER = "hadohadopapi"
DB_PASS = ""
DB_HOST = "localhost"
DB_PORT = "5432"

def update_lesson_from_json(json_file_path, target_lesson_id):
    if not os.path.exists(json_file_path):
        print(f"Error: Could not find file at {json_file_path}")
        return

    try:
        # JSON 파일 읽기 (UTF-8 인코딩 필수)
        with open(json_file_path, 'r', encoding='utf-8') as f:
            content_data = json.load(f)
            # Json 문자열로 변환 (DB의 jsonb 타입에 매핑)
            json_str = json.dumps(content_data, ensure_ascii=False)
            
        print(f"Loaded JSON containing {len(content_data.get('steps', []))} steps.")

        # DB 연결 및 업데이트
        conn = psycopg2.connect(
            dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT
        )
        conn.autocommit = False # 트랜잭션 수동 제어

        with conn.cursor() as cursor:
            # PostgreSQL jsonb 업데이트 쿼리
            update_query = """
                UPDATE lessons
                SET content = %s::jsonb, updated_at = NOW()
                WHERE id = %s
            """
            cursor.execute(update_query, (json_str, target_lesson_id))
            
            if cursor.rowcount == 0:
                print(f"Warning: No strictly matching lesson found for id={target_lesson_id}. (Row count: 0)")
                conn.rollback()
            else:
                conn.commit()
                print(f"✅ Successfully updated Lesson ID: {target_lesson_id} with the new JSON data!")

    except Exception as e:
        print(f"❌ Failed to update DB. Error: {e}")
        if 'conn' in locals() and conn is not None:
            conn.rollback()
    finally:
        if 'conn' in locals() and conn is not None:
            conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        # 실행 인자가 없으면 디폴트로 방금 전에 저장한 unit1_lesson1 경로와 id=3 적용
        default_path = "../lessons/unit1/lesson1.json"
        
        # 현재 스크립트 실행 위치(admin-tools) 기준으로 절대/상대 경로 조합
        script_dir = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(script_dir, default_path)
        
        print("Usage: python update_lesson.py [json_file_path] [lesson_db_id]")
        print("Running with default values: Unit 1, Lesson 1 (id=3)...")
        update_lesson_from_json(json_path, 3)
    else:
        # 커스텀 인자 전달 시 실행 (예: python update_lesson.py ../lessons/unit1/lesson2.json 4)
        json_path = sys.argv[1]
        db_id = int(sys.argv[2])
        update_lesson_from_json(json_path, db_id)
