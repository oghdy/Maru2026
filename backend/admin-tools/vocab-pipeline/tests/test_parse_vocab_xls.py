"""
[TDD - Task 22-2] XLS 파서 단위 테스트
실제 XLS 파일 없이도 pandas DataFrame을 직접 주입하여 파서 로직만 순수하게 검증합니다.
"""
import pytest
import pandas as pd
from parse_vocab_xls import VocabEntry, parse_row, normalize_word, convert_pos, parse_level


class TestNormalizeWord:
    """단어 정규화: 'XX03' 같은 이형어 번호 제거 테스트"""

    def test_removes_trailing_number(self):
        assert normalize_word("가구03") == "가구"

    def test_removes_two_digit_number(self):
        assert normalize_word("가능14") == "가능"

    def test_keeps_normal_word_unchanged(self):
        assert normalize_word("가게") == "가게"

    def test_keeps_word_ending_in_korean_number(self):
        # 한자 번호가 아니라 단어 자체에 숫자가 없는 경우
        assert normalize_word("가까워지다") == "가까워지다"

    def test_strips_whitespace(self):
        assert normalize_word("  가게  ") == "가게"


class TestConvertPos:
    """품사 코드 한→영 변환 테스트"""

    def test_명_to_Noun(self):
        assert convert_pos("명") == "Noun"

    def test_동_to_Verb(self):
        assert convert_pos("동") == "Verb"

    def test_형_to_Adjective(self):
        assert convert_pos("형") == "Adjective"

    def test_부_to_Adverb(self):
        assert convert_pos("부") == "Adverb"

    def test_unknown_returns_Other(self):
        assert convert_pos("감") == "Other"

    def test_none_returns_Other(self):
        assert convert_pos(None) == "Other"


class TestParseLevel:
    """등급 코드 변환 테스트"""

    def test_A_to_Beginner(self):
        assert parse_level("A") == "Beginner"

    def test_B_to_Intermediate(self):
        assert parse_level("B") == "Intermediate"

    def test_C_to_Advanced(self):
        assert parse_level("C") == "Advanced"

    def test_unknown_returns_Unknown(self):
        assert parse_level("D") == "Unknown"

    def test_none_returns_Unknown(self):
        assert parse_level(None) == "Unknown"


class TestParseRow:
    """pandas Series 한 행을 VocabEntry DTO로 변환하는 핵심 파서 테스트"""

    def _make_row(self, word, pos, hanja, level):
        return pd.Series({
            "순위": 1,
            "단어": word,
            "품사": pos,
            "풀이": hanja,
            "등급": level,
        })

    def test_normal_word_parsed_correctly(self):
        row = self._make_row("가게", "명", None, "A")
        entry = parse_row(row)
        assert entry.korean_word == "가게"
        assert entry.part_of_speech == "Noun"
        assert entry.hanja_hint == ""
        assert entry.level == "Beginner"

    def test_numbered_word_normalized(self):
        """'가격03' → 'korean_word' 는 '가격'으로 정규화되어야 함"""
        row = self._make_row("가격03", "명", "價格", "B")
        entry = parse_row(row)
        assert entry.korean_word == "가격"
        assert entry.hanja_hint == "價格"
        assert entry.level == "Intermediate"

    def test_hanja_hint_stored_when_present(self):
        row = self._make_row("가구04", "명", "家具", "B")
        entry = parse_row(row)
        assert entry.hanja_hint == "家具"

    def test_nan_hanja_becomes_empty_string(self):
        """NaN 풀이는 빈 문자열로 변환되어야 함"""
        row = self._make_row("가깝다", "형", float("nan"), "A")
        entry = parse_row(row)
        assert entry.hanja_hint == ""

    def test_entry_is_vocabentry_instance(self):
        row = self._make_row("가게", "명", None, "A")
        entry = parse_row(row)
        assert isinstance(entry, VocabEntry)
