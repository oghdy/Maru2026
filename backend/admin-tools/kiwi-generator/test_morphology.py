import pytest
from generate_morphology import MorphologyGenerator

def test_morphology_sarah():
    gen = MorphologyGenerator()
    sentence = "저는 Sarah입니다."
    chunks = gen.analyze(sentence)
    
    # Check chunks count
    assert len(chunks) == 2
    
    # Chunk 1: 저는
    assert chunks[0].display == "저는"
    assert len(chunks[0].tokens) == 2
    assert chunks[0].tokens[0].text == "저"
    assert chunks[0].tokens[0].meaning == "I (polite)"
    assert chunks[0].tokens[1].text == "는"
    assert "topic" in chunks[0].tokens[1].meaning
    
    # Chunk 2: Sarah입니다.
    assert chunks[1].display == "Sarah입니다."
    texts = [t.text for t in chunks[1].tokens]
    assert "Sarah" in texts
    assert "입니다" in texts
    
    # Check 입니다 meaning
    for t in chunks[1].tokens:
        if t.text == "입니다":
            assert "formal" in t.meaning

def test_morphology_yumi():
    gen = MorphologyGenerator()
    sentence = "제 이름은 유미예요."
    chunks = gen.analyze(sentence)
    
    assert chunks[0].display == "제"
    assert "저" == chunks[0].tokens[0].text
    assert "의" == chunks[0].tokens[1].text
    
    assert chunks[1].display == "이름은"
    assert chunks[1].tokens[0].text == "이름"
    assert "name" == chunks[1].tokens[0].meaning
    
    assert chunks[2].display == "유미예요."
    texts = [t.text for t in chunks[2].tokens]
    assert "유미" in texts
    # "이예요" or similar is expected due to merge logic
    found_be = False
    for t in chunks[2].tokens:
        if "am/is/are" in t.meaning:
            found_be = True
    assert found_be

if __name__ == "__main__":
    pytest.main([__file__])
