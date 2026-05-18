import pytest
from core_engine import KiwiEngine

def test_rabbit_turtle_chunking():
    engine = KiwiEngine()
    
    # Process sample
    quiz = engine.process_sentence("어제 친구를 만났었어", "I met a friend yesterday", "EP")
    
    # Validate Base Context
    assert quiz.sentence == "어제 친구를 만났었어"
    assert len(quiz.elements) == 2  # Prefix + Target (No suffix)
    
    # Validate Prefix
    assert quiz.elements[0].type == "context_prefix"
    assert quiz.elements[0].text == "어제 친구를"
    assert quiz.elements[0].isTarget == False
    
    # Validate Target Morph Analysis
    target_element = quiz.elements[1]
    assert target_element.isTarget == True
    
    # 1st TDD rule: Rabbit gets unified chunk
    assert target_element.correct_rabbit == ["만났었어"]
    
    # 2nd TDD rule: Turtle gets base splits
    assert "만나" in target_element.correct_turtle
    assert "었었" in target_element.correct_turtle
    assert "어" in target_element.correct_turtle

def test_decoy_generation():
    engine = KiwiEngine()
    quiz = engine.process_sentence("저는 학생입니다", "I am a student", "EF")
    
    turtle_opts = [opt.text for opt in quiz.options if opt.mode == "turtle"]
    rabbit_opts = [opt.text for opt in quiz.options if opt.mode == "rabbit"]
    
    # 3rd TDD rule: Decoys mix with authentic choices
    assert "이" in turtle_opts
    assert "ᆸ니다" in turtle_opts
    
    # Total turtle options = authentic(3: 학생, 이, ᆸ니다) + decoys(2) = 5
    assert len(turtle_opts) == 5
    
    # Total rabbit options = authentic(1) + fake(1) = 2
    assert len(rabbit_opts) == 2
    assert "학생입니다" in rabbit_opts
    
    # Check that model conforms to schema correctly (Pydantic will auto-validate during assignment)
    assert quiz.stepType == "agglutinative_quiz"
