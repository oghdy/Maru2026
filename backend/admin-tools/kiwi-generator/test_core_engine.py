from collections import Counter

from core_engine import KiwiEngine

engine = KiwiEngine()


def turtle(quiz):
    return [e.correct_turtle for e in quiz.elements]


def test_only_target_morpheme_is_split():
    # JKO 레슨: '저는' 은 통째로, '사과를' 만 [사과][를]
    quiz = engine.process_sentence("저는 사과를 먹어요.", "I eat an apple.", "JKO")
    assert turtle(quiz) == [["저는"], ["사과", "를"], ["먹어요"]]


def test_target_split_keeps_rest_of_word_whole():
    # 선생님은 → [선생님][은] (선생+님 으로 쪼개지 않음)
    quiz = engine.process_sentence("선생님은 한국 사람이에요.", "", "JX")
    assert quiz.elements[0].correct_turtle == ["선생님", "은"]


def test_punctuation_is_not_a_block():
    quiz = engine.process_sentence("저는 Sarah입니다.", "I am Sarah.", "JX")
    all_texts = [o.text for o in quiz.options]
    assert "." not in all_texts
    assert quiz.elements[1].correct_rabbit == ["Sarah입니다"]


def test_copula_uses_standard_forms():
    after_vowel = engine.process_sentence("제 이름은 유미예요.", "", "VCP")
    after_consonant = engine.process_sentence("저는 학생이에요.", "", "VCP")
    assert after_vowel.elements[2].correct_turtle == ["유미", "예요"]
    assert after_consonant.elements[1].correct_turtle == ["학생", "이에요"]
    texts = [o.text for q in (after_vowel, after_consonant) for o in q.options]
    assert "이예요" not in texts


def test_formal_copula_with_ef_target():
    quiz = engine.process_sentence("저는 Sarah입니다.", "", "EF")
    assert quiz.elements[1].correct_turtle == ["Sarah", "입니다"]


def test_decoys_are_grammar_alternatives_not_go_suffix():
    quiz = engine.process_sentence("저는 Sarah입니다.", "", "JX")
    texts = [o.text for o in quiz.options]
    assert not any(t.endswith("고") for t in texts)
    assert "은" in texts            # 는 ↔ 은 이형태 오답 (거북이)
    assert "저은" in texts          # 토끼 오답도 이형태로


def test_options_have_unique_ids_and_repeated_morpheme_is_solvable():
    quiz = engine.process_sentence("친구는 학생이고 저는 의사예요.", "", "JX")
    ids = [o.id for o in quiz.options]
    assert len(ids) == len(set(ids))
    needed = Counter(p for e in quiz.elements for p in e.correct_turtle)
    available = Counter(o.text for o in quiz.options if o.mode == "turtle")
    assert needed["는"] == 2
    for text, n in needed.items():
        assert available[text] >= n, text


def test_every_turtle_answer_is_available_and_rebuilds_the_word():
    for sentence, pos in [("저는 Sarah입니다.", "JX"), ("제 이름은 유미예요.", "JX"), ("저는 의사예요.", "VCP")]:
        quiz = engine.process_sentence(sentence, "", pos)
        for e in quiz.elements:
            assert "".join(e.correct_turtle) == e.correct_rabbit[0]


def test_output_is_reproducible():
    a = engine.process_sentence("저는 학생이에요.", "", "VCP")
    b = engine.process_sentence("저는 학생이에요.", "", "VCP")
    assert a.model_dump() == b.model_dump()


def test_explanations_are_english():
    quiz = engine.process_sentence("저는 학생이에요.", "", "VCP")
    for e in quiz.elements:
        # 예전 한국어 설명("…가 포함된 부분입니다", "문장을 구성하는 기본 어절입니다") 이 아닌 영어 설명
        assert "부분입니다" not in e.turtle_explanation and "어절입니다" not in e.turtle_explanation
