"""
vocab_pipeline.py
Task 22-4: 단어장 데이터 파이프라인 (메인 스크립트)

이 스크립트는 다음 과정을 순차적으로 실행합니다:
1. 국립국어원 XLS 파일 파싱
2. Gemini AI 배치 번역 및 카테고리 자동 분류
3. PostgreSQL DB Bulk Insert (멱등성 보장)
"""
import os
from parse_vocab_xls import parse_xls
from gemini_translator import GeminiTranslator
from db_inserter import DbInserter

def main():
    print("=" * 60)
    print(" 🚀 Vocabulary Pipeline Started")
    print("=" * 60)

    # 1. 엑셀 파싱
    xls_path = os.path.join(os.path.dirname(__file__), "한국어 학습용 어휘 목록.xls")
    print("\n[Step 1] 엑셀 파싱 시작...")
    entries = parse_xls(xls_path)
    
    if not entries:
        print("[ERROR] 파싱된 단어가 없습니다. 종료합니다.")
        return

    # 전체 데이터 실행
    print(f"\n[안내] 전체 {len(entries)}개 데이터 처리를 시작합니다. (약 5~10분 소요 예정)")
    test_batch = entries
    
    # 임의로 첫 번째 샘플의 등급을 기본 등급으로 지정 (실전에서는 그룹별로 적용)
    default_level = test_batch[0].level if test_batch else "Unknown"

    # 2. Gemini 번역 및 분류
    print("\n[Step 2] Gemini AI 번역 및 분류 시작...")
    translator = GeminiTranslator()
    translated_results = translator.translate_all(test_batch)

    if not translated_results:
        print("[ERROR] 번역된 결과가 없습니다. 종료합니다.")
        return

    # 3. DB 적재
    print("\n[Step 3] DB Bulk Insert 시작...")
    inserter = DbInserter()
    try:
        inserter.insert_batch(translated_results, default_level)
        print("\n🎉 모든 파이프라인 처리가 성공적으로 완료되었습니다!")
    except Exception as e:
        print(f"\n❌ 파이프라인 실패: {e}")
    finally:
        inserter.close()

if __name__ == "__main__":
    main()
