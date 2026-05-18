"""
gemini_translator.py
Task 22-3: Gemini API를 이용한 배치 번역 + 카테고리 자동 분류 모듈

역할:
- VocabEntry 리스트를 배치(10~20개)로 묶어 Gemini API 1회 호출
- 영어 번역(english), 의미 카테고리(category), 한/영 예문 자동 생성
- Rate Limit 대비 Exponential Backoff 재시도
- 파싱/API 실패 시 에러 격리 (파이프라인 중단 방지)
"""
import json
import time
import re
import csv
import os
from dataclasses import dataclass
from typing import Optional
from dotenv import load_dotenv
from google import genai
from google.genai import types

from parse_vocab_xls import VocabEntry

load_dotenv()


# ─────────────────────────────────────────────
# DTO: Gemini 번역 결과 데이터 모델
# ─────────────────────────────────────────────
@dataclass
class TranslationResult:
    korean_word: str
    english: str
    category: str
    example_kr: str
    example_en: str
    part_of_speech: str = ""


# ─────────────────────────────────────────────
# 순수 함수: 프롬프트 생성 (Unit Test 가능)
# ─────────────────────────────────────────────
def build_batch_prompt(entries: list[VocabEntry]) -> str:
    """
    VocabEntry 배치를 Gemini에 전달할 프롬프트로 변환.
    한자 풀이(hanja_hint)가 있으면 번역 정확도 향상을 위해 힌트로 포함.
    """
    word_lines = []
    for e in entries:
        hint = f" (한자: {e.hanja_hint})" if e.hanja_hint else ""
        word_lines.append(f"- {e.korean_word} [{e.part_of_speech}]{hint}")

    words_block = "\n".join(word_lines)

    return f"""아래 한국어 단어 목록을 외국인 초보 학습자(A1~B2 수준)를 위해 번역하고 분류해 주세요.

단어 목록:
{words_block}

각 단어에 대해 다음 JSON 배열 형식으로만 응답해 주세요. 다른 설명은 절대 추가하지 마세요:
```json
[
  {{
    "korean": "단어",
    "english": "가장 일반적인 영어 번역 (동사는 'to + 동사원형' 형식)",
    "category": "의미 기반 카테고리 (예: 음식, 동물, 감정, 장소, 동작, 신체, 교통, 날씨, 가족, 직업, 학교, 쇼핑, 시간, 숫자, 색상, 기타)",
    "example_kr": "10단어 이내의 자연스러운 한국어 예문",
    "example_en": "위 예문의 영어 번역"
  }}
]
```"""


# ─────────────────────────────────────────────
# 순수 함수: Gemini 응답 파싱 (Unit Test 가능)
# ─────────────────────────────────────────────
def parse_gemini_response(raw_text: str, original_entries: list[VocabEntry] = None) -> list[TranslationResult]:
    """
    Gemini 응답 텍스트에서 JSON을 추출하여 TranslationResult 리스트로 변환.
    코드 펜스(```) 유무와 관계없이 처리.
    파싱 실패 시 예외 없이 빈 리스트 반환 (에러 격리).
    """
    try:
        # 코드 펜스 제거
        cleaned = re.sub(r"```(?:json)?", "", raw_text).strip().rstrip("`").strip()
        data = json.loads(cleaned)

        results = []
        for item in data:
            # 필수 필드 검증
            if not all(k in item for k in ("korean", "english", "category")):
                continue
                
            korean_word = item["korean"]
            
            # 원본 단어에서 품사 정보 찾기
            pos = ""
            if original_entries:
                for req in original_entries:
                    if req.korean_word == korean_word:
                        pos = req.part_of_speech
                        break
                        
            results.append(TranslationResult(
                korean_word=korean_word,
                english=item["english"],
                category=item["category"],
                example_kr=item.get("example_kr", ""),
                example_en=item.get("example_en", ""),
                part_of_speech=pos
            ))
        return results

    except (json.JSONDecodeError, TypeError, KeyError):
        return []


# ─────────────────────────────────────────────
# GeminiTranslator 클래스
# ─────────────────────────────────────────────
class GeminiTranslator:
    """
    Gemini API를 통한 배치 번역/분류 클래스.
    배치 단위로 API를 호출하여 비용을 최소화하고,
    실패 시 Exponential Backoff로 자동 재시도합니다.
    """

    def __init__(self, api_key: Optional[str] = None, batch_size: int = 15, max_retries: int = 3):
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        self.batch_size = batch_size
        self.max_retries = max_retries
        self._client = genai.Client(api_key=self.api_key)
        self._failed_words: list[str] = []

    def translate_batch(self, entries: list[VocabEntry]) -> list[TranslationResult]:
        """
        VocabEntry 배치를 한 번의 Gemini 호출로 번역/분류.
        API 실패 시 빈 리스트 반환 (파이프라인 중단 방지).
        """
        if not entries:
            return []

        prompt = build_batch_prompt(entries)

        for attempt in range(self.max_retries):
            try:
                response = self._client.models.generate_content(
                    model="gemini-2.5-flash-lite",
                    contents=prompt,
                )
                results = parse_gemini_response(response.text, entries)
                return results

            except Exception as e:
                wait = 2 ** attempt  # Exponential Backoff: 1s, 2s, 4s
                print(f"[WARN] Gemini API 오류 (시도 {attempt + 1}/{self.max_retries}): {e}")
                if attempt < self.max_retries - 1:
                    print(f"  → {wait}초 후 재시도...")
                    time.sleep(wait)
                else:
                    print(f"  → 최대 재시도 초과. 이 배치 스킵.")
                    for e_entry in entries:
                        self._failed_words.append(e_entry.korean_word)

        return []

    def translate_all(self, entries: list[VocabEntry]) -> list[TranslationResult]:
        """
        전체 VocabEntry 목록을 batch_size 단위로 잘라 순차적으로 번역.
        진행 상황을 콘솔에 출력합니다.
        """
        all_results: list[TranslationResult] = []
        total = len(entries)
        batches = [entries[i:i + self.batch_size] for i in range(0, total, self.batch_size)]

        print(f"[Gemini] 총 {total}개 단어를 {len(batches)}개 배치로 처리 시작...")

        for i, batch in enumerate(batches):
            print(f"  배치 [{i + 1}/{len(batches)}] 처리 중... ({batch[0].korean_word} ~ {batch[-1].korean_word})")
            results = self.translate_batch(batch)
            all_results.extend(results)

            # API Rate Limit 방지용 딜레이
            if i < len(batches) - 1:
                time.sleep(1)

        # 실패 단어 기록
        if self._failed_words:
            self._save_failed_words()

        print(f"[Gemini] 완료: {len(all_results)}/{total}개 성공, {len(self._failed_words)}개 실패")
        return all_results

    def _save_failed_words(self):
        """실패한 단어를 failed_words.csv에 저장 (나중에 수동 검토용)"""
        path = os.path.join(os.path.dirname(__file__), "failed_words.csv")
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["korean_word"])
            for word in self._failed_words:
                writer.writerow([word])
        print(f"[Gemini] 실패 단어 {len(self._failed_words)}개 → {path} 저장 완료")


# ─────────────────────────────────────────────
# 단독 실행: 샘플 10개 미리보기 테스트
# ─────────────────────────────────────────────
if __name__ == "__main__":
    from parse_vocab_xls import parse_xls

    xls_path = os.path.join(os.path.dirname(__file__), "한국어 학습용 어휘 목록.xls")
    all_entries = parse_xls(xls_path)

    # 샘플 15개만 먼저 테스트
    sample = all_entries[:15]
    translator = GeminiTranslator()
    results = translator.translate_batch(sample)

    print(f"\n샘플 번역 결과 ({len(results)}개):")
    for r in results:
        print(f"  [{r.category}] {r.korean_word} → {r.english}")
        print(f"    예문: {r.example_kr}")
        print(f"    예문(영): {r.example_en}")
        print()
