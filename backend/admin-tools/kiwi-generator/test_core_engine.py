import pytest
from core_engine import KiwiEngine

def test_rabbit_turtle_chunking():
    engine = KiwiEngine()
    
    # Process sample
    quiz = engine.process_sentence("어제 친구를 만났었어", "I met a friend yesterday", "EP")
    
    # Validate Base Context
    assert quiz.sentence == "어제 친구를 만났었어"
    assert len(quiz.elements) == 3  # "어제", "친구를", "만났었어"
    
    # All are target slots in the new whole-sentence building design
    assert all(elem.isTarget for elem in quiz.elements)
    
    # 1st TDD rule: Rabbit gets unified chunk for each word slot
    assert quiz.elements[0].correct_rabbit == ["어제"]
    assert quiz.elements[1].correct_rabbit == ["친구를"]
    assert quiz.elements[2].correct_rabbit == ["만났었어"]
    
    # 2nd TDD rule: Turtle gets base splits for the target POS containing slot
    target_element = quiz.elements[2]  # "만났었어" has "EP"
    assert "만나" in target_element.correct_turtle
    assert "었었" in target_element.correct_turtle
    assert "어" in target_element.correct_turtle

def test_decoy_generation():
    engine = KiwiEngine()
    quiz = engine.process_sentence("저는 학생입니다", "I am a student", "EF")
    
    turtle_opts = [opt.text for opt in quiz.options if opt.mode == "turtle"]
    rabbit_opts = [opt.text for opt in quiz.options if opt.mode == "rabbit"]
    
    # All elements are targets
    assert len(quiz.elements) == 2  # "저는", "학생입니다"
    assert quiz.elements[0].correct_rabbit == ["저는"]
    assert quiz.elements[1].correct_rabbit == ["학생입니다"]
    
    # Authentic turtle parts should be generated and present in turtle options
    assert "학생" in turtle_opts
    assert "입니다" in turtle_opts or "ᆸ니다" in turtle_opts
    
    # Check that model conforms to schema correctly (Pydantic will auto-validate during assignment)
    assert quiz.stepType == "agglutinative_quiz"

