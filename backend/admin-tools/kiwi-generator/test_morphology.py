from generate_morphology import MorphologyGenerator

gen = MorphologyGenerator()


def pairs(chunk):
    return [(t.text, t.meaning) for t in chunk.tokens]


def test_morphology_sarah():
    chunks = gen.analyze("저는 Sarah입니다.")
    assert [c.display for c in chunks] == ["저는", "Sarah입니다."]
    assert pairs(chunks[0]) == [("저", "I (polite)"), ("는", "topic marker")]
    assert pairs(chunks[1]) == [("Sarah", "Sarah (name)"), ("입니다", "am/is/are (formal)")]


def test_morphology_yumi_uses_standard_copula():
    chunks = gen.analyze("제 이름은 유미예요.")
    assert pairs(chunks[0]) == [("저", "I (polite)"), ("의", "possessive marker")]
    assert pairs(chunks[1]) == [("이름", "name"), ("은", "topic marker")]
    assert pairs(chunks[2]) == [("유미", "Yumi (name)"), ("예요", "am/is/are (polite)")]


def test_no_symbol_tokens_and_no_word_fallback():
    for s in ["민수: 반갑습니다. 저는 민수입니다.", "민수: 아, 저는 의사예요.", "안녕하세요! 제 이름은 Sarah예요."]:
        for c in gen.analyze(s):
            for t in c.tokens:
                assert t.text not in {".", ",", ":", "!", "?", "=", "(", ")"}
                assert t.meaning != "word"
                assert t.text != "이예요"


def test_speaker_label_and_gloss_row():
    speaker = gen.analyze("민수: 안녕하세요?")[0]
    assert speaker.display == "민수:" and pairs(speaker) == [("민수", "Minsu (speaker)")]
    gloss = gen.analyze("저는 = I (topic)")
    assert [c.display for c in gloss] == ["저는", "=", "I", "(topic)"]
    assert all(c.tokens == [] for c in gloss[1:])  # 영어 풀이 쪽은 탭 분석 없음


def test_suffix_nim_kept_with_noun():
    assert pairs(gen.analyze("선생님")[0]) == [("선생님", "teacher")]
