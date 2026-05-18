"""
[TDD - Task 22-3] Gemini 번역/카테고리 분류 모듈 단위 테스트
실제 Gemini API를 호출하지 않고, unittest.mock으로 응답을 대체하여
파싱 로직과 에러 처리 로직만 순수하게 검증합니다.
"""
import json
import pytest
from unittest.mock import MagicMock, patch
from parse_vocab_xls import VocabEntry
from gemini_translator import (
    GeminiTranslator,
    TranslationResult,
    parse_gemini_response,
    build_batch_prompt,
)


# ────────────────────────────────────────────────
# 픽스처: 테스트용 샘플 VocabEntry 배치
# ────────────────────────────────────────────────
@pytest.fixture
def sample_entries():
    return [
        VocabEntry(korean_word="가게", part_of_speech="Noun", hanja_hint="", level="Beginner"),
        VocabEntry(korean_word="강아지", part_of_speech="Noun", hanja_hint="", level="Beginner"),
        VocabEntry(korean_word="달리다", part_of_speech="Verb", hanja_hint="", level="Beginner"),
    ]


# ────────────────────────────────────────────────
# 1. parse_gemini_response 파싱 로직 단위 테스트
# ────────────────────────────────────────────────
class TestParseGeminiResponse:
    """Gemini 응답 JSON 파싱 로직 검증 (API 호출 없음)"""

    def _make_mock_response(self, data: list) -> str:
        """Gemini가 실제로 반환하는 형태의 JSON 문자열 생성"""
        return f"```json\n{json.dumps(data, ensure_ascii=False)}\n```"

    def test_parses_valid_response_correctly(self):
        raw = self._make_mock_response([
            {"korean": "가게", "english": "store", "category": "장소",
             "example_kr": "가게에 갑니다.", "example_en": "I go to the store."},
        ])
        results = parse_gemini_response(raw)
        assert len(results) == 1
        assert results[0].korean_word == "가게"
        assert results[0].english == "store"
        assert results[0].category == "장소"
        assert results[0].example_kr == "가게에 갑니다."
        assert results[0].example_en == "I go to the store."

    def test_parses_multiple_results(self):
        raw = self._make_mock_response([
            {"korean": "가게", "english": "store", "category": "장소",
             "example_kr": "가게에 갑니다.", "example_en": "I go to the store."},
            {"korean": "강아지", "english": "puppy", "category": "동물",
             "example_kr": "강아지가 귀엽습니다.", "example_en": "The puppy is cute."},
        ])
        results = parse_gemini_response(raw)
        assert len(results) == 2
        assert results[1].korean_word == "강아지"
        assert results[1].category == "동물"

    def test_parses_response_without_code_fence(self):
        """코드 펜스(```) 없이 순수 JSON만 온 경우도 처리"""
        raw = json.dumps([
            {"korean": "달리다", "english": "to run", "category": "동작",
             "example_kr": "빠르게 달립니다.", "example_en": "I run fast."}
        ], ensure_ascii=False)
        results = parse_gemini_response(raw)
        assert len(results) == 1
        assert results[0].english == "to run"

    def test_returns_empty_list_on_invalid_json(self):
        """JSON 파싱 실패 시 예외 없이 빈 리스트 반환 (에러 격리)"""
        results = parse_gemini_response("이건 JSON이 아닙니다")
        assert results == []

    def test_skips_entry_with_missing_fields(self):
        """필수 필드(korean, english, category)가 없는 항목은 스킵"""
        raw = json.dumps([
            {"korean": "가게"},  # english, category 없음 → 스킵
            {"korean": "강아지", "english": "puppy", "category": "동물",
             "example_kr": ".", "example_en": "."},
        ], ensure_ascii=False)
        results = parse_gemini_response(raw)
        assert len(results) == 1
        assert results[0].korean_word == "강아지"


# ────────────────────────────────────────────────
# 2. build_batch_prompt 프롬프트 생성 테스트
# ────────────────────────────────────────────────
class TestBuildBatchPrompt:
    """프롬프트 문자열이 올바른 형식으로 생성되는지 검증"""

    def test_prompt_contains_all_words(self, sample_entries):
        prompt = build_batch_prompt(sample_entries)
        assert "가게" in prompt
        assert "강아지" in prompt
        assert "달리다" in prompt

    def test_prompt_requests_json_output(self, sample_entries):
        prompt = build_batch_prompt(sample_entries)
        assert "JSON" in prompt

    def test_prompt_includes_required_fields(self, sample_entries):
        prompt = build_batch_prompt(sample_entries)
        assert "english" in prompt
        assert "category" in prompt
        assert "example_kr" in prompt
        assert "example_en" in prompt


# ────────────────────────────────────────────────
# 3. GeminiTranslator 클래스 통합 테스트 (API Mock)
# ────────────────────────────────────────────────
class TestGeminiTranslator:
    """실제 API 호출 없이 Gemini SDK를 Mock으로 대체하여 클래스 동작 검증"""

    def _make_mock_gemini_text(self, words: list) -> str:
        data = [
            {"korean": w, "english": f"{w}_en", "category": "테스트",
             "example_kr": f"{w} 예문.", "example_en": f"{w} example."}
            for w in words
        ]
        return json.dumps(data, ensure_ascii=False)

    @patch("gemini_translator.genai")
    def test_translate_batch_returns_correct_count(self, mock_genai, sample_entries):
        """배치 번역 시 입력한 단어 수만큼 결과가 나오는지 검증"""
        mock_client = MagicMock()
        mock_genai.Client.return_value = mock_client
        mock_client.models.generate_content.return_value.text = self._make_mock_gemini_text(
            ["가게", "강아지", "달리다"]
        )

        translator = GeminiTranslator(api_key="fake-key")
        results = translator.translate_batch(sample_entries)

        assert len(results) == 3

    @patch("gemini_translator.genai")
    def test_translate_batch_calls_api_once_per_batch(self, mock_genai, sample_entries):
        """배치 단위로 API를 1번만 호출하는지 검증 (비용 최적화)"""
        mock_client = MagicMock()
        mock_genai.Client.return_value = mock_client
        mock_client.models.generate_content.return_value.text = self._make_mock_gemini_text(
            ["가게", "강아지", "달리다"]
        )

        translator = GeminiTranslator(api_key="fake-key")
        translator.translate_batch(sample_entries)

        assert mock_client.models.generate_content.call_count == 1

    @patch("gemini_translator.genai")
    def test_translate_batch_returns_empty_on_api_failure(self, mock_genai, sample_entries):
        """API 호출 실패 시 예외 없이 빈 리스트 반환 (에러 격리)"""
        mock_client = MagicMock()
        mock_genai.Client.return_value = mock_client
        mock_client.models.generate_content.side_effect = Exception("API Error")

        translator = GeminiTranslator(api_key="fake-key")
        results = translator.translate_batch(sample_entries)

        assert results == []
