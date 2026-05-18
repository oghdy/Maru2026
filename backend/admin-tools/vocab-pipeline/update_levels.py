import pandas as pd
import psycopg2
import re

def update_word_levels():
    # 1. DB 연결 설정
    conn = psycopg2.connect(
        host="localhost",
        database="maru",
        user="hadohadopapi",
        password=""
    )
    cur = conn.cursor()

    try:
        # 2. words 테이블에 level 컬럼 추가 (없으면 생성)
        print("Checking level column...")
        cur.execute("ALTER TABLE words ADD COLUMN IF NOT EXISTS level VARCHAR(10)")
        conn.commit()

        # 3. 엑셀 파일 로드 (xls 파일이므로 xlrd 엔진 사용 가능성 큼)
        excel_path = "/Users/hadohadopapi/Desktop/Maru-main/backend/admin-tools/vocab-pipeline/한국어 학습용 어휘 목록.xls"
        print(f"Loading Excel: {excel_path}")
        df = pd.read_excel(excel_path)

        # 컬럼 인덱스 확인 (단어: 1, 등급: 4 예상 - 사용자 이미지 기반)
        # 이미지 순서: 순위(0), 단어(1), 품사(2), 풀이(3), 등급(4)
        
        # 4. 데이터 업데이트
        updated_count = 0
        total_rows = len(df)
        
        print(f"Starting update for {total_rows} words...")
        
        for index, row in df.iterrows():
            raw_word = str(row[1])  # 단어 (가격03 형태 포함)
            grade = str(row[4])     # 등급 (A/B/C)
            
            # 숫자 제거 (가격03 -> 가격)
            clean_word = re.sub(r'\d+', '', raw_word)
            
            # DB 업데이트 (단어와 등급 매칭)
            # 품사 정보도 있다면 더 정확하겠지만, 일단 단어명으로 매칭
            cur.execute(
                "UPDATE words SET level = %s WHERE korean_word = %s AND level IS NULL",
                (grade, clean_word)
            )
            updated_count += cur.rowcount
            
            if index % 500 == 0:
                print(f"Progress: {index}/{total_rows}...")

        conn.commit()
        print(f"Update complete! Total words updated in DB: {updated_count}")

    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    update_word_levels()
