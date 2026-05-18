import json
import logging
import pandas as pd
import psycopg2
from psycopg2.extras import Json
from core_engine import KiwiEngine
from db_connector import db

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ContentMerger:
    def __init__(self):
        self.engine = KiwiEngine()

    def merge_content(self, base_content: dict, new_quizzes: list) -> dict:
        """
        Merges base_content with new_quizzes safely.
        """
        if not base_content:
            base_content = {"steps": []}
        elif 'steps' not in base_content:
            base_content['steps'] = []
            
        merged_steps = base_content['steps'].copy()
        
        # Filter out existing agglutinative_quiz to prevent duplicate accumulation
        filtered_steps = [s for s in merged_steps if s.get('stepType') != 'agglutinative_quiz']
        
        # Map new_quizzes to the frontend expected schema { stepType: ..., contentObj: {...}}
        formatted_quizzes = []
        for q in new_quizzes:
            # q is the dictionary dumped from AgglutinativeQuizData
            q_type = q.pop('stepType', 'agglutinative_quiz')
            formatted_quizzes.append({
                "stepType": q_type,
                "contentObj": q
            })
            
        # Find index of 'completion' to insert before it
        completion_idx = -1
        for i, s in enumerate(filtered_steps):
            if s.get('stepType') == 'completion':
                completion_idx = i
                break
                
        if completion_idx != -1:
            filtered_steps = filtered_steps[:completion_idx] + formatted_quizzes + filtered_steps[completion_idx:]
        else:
            filtered_steps.extend(formatted_quizzes)
            
        return {"steps": filtered_steps}
        
    def process_and_update_db(self, csv_file: str, unit_id: int, lesson_id_str: str):
        df = pd.read_csv(csv_file)
        
        quizzes = []
        for index, row in df.iterrows():
            if int(row['UnitID']) == unit_id and row['LessonID'] == lesson_id_str:
                sentence = row['Sentence']
                translation = row['Translation']
                target_pos = row['Target_POS']
                
                quiz_data = self.engine.process_sentence(sentence, translation, target_pos)
                quizzes.append(quiz_data.model_dump())
                
        if not quizzes:
            logger.warning(f"No quizzes found in CSV for Unit {unit_id}, Lesson {lesson_id_str}")
            return
            
        logger.info(f"Generated {len(quizzes)} quizzes.")
        
        with db.get_connection() as conn:
            with conn.cursor() as cursor:
                # Select existing content
                cursor.execute(
                    "SELECT id, content FROM lessons WHERE unit_id = %s AND lesson_id = %s;",
                    (unit_id, lesson_id_str)
                )
                row = cursor.fetchone()
                
                if row:
                    row_id = row[0]
                    base_content = row[1]
                else:
                    logger.error("Lesson not found in DB!")
                    return
                    
                # Merge
                new_content = self.merge_content(base_content, quizzes)
                
                # Update
                cursor.execute(
                    "UPDATE lessons SET content = %s WHERE id = %s;",
                    (Json(new_content), row_id)
                )
                conn.commit()
                logger.info(f"Successfully updated DB row ID {row_id} with merged JSON content!")

if __name__ == "__main__":
    merger = ContentMerger()
    # Update Unit 1, Lesson u1-l1 from the csv
    merger.process_and_update_db("curriculum.csv", 1, "u1-l1")
