import pytest
from batch_merger import ContentMerger

def test_merge_logic():
    merger = ContentMerger()
    
    # Mocking existing DB JSON
    base_content = {
        "steps": [
            {"stepType": "introduction", "contentObj": {"title": "Intro"}},
            {"stepType": "practice", "contentObj": {"title": "Practice"}},
            # This old quiz should be wiped to avoid accumulation during re-runs
            {"stepType": "agglutinative_quiz", "sentence": "old sentence"}
        ]
    }
    
    # Mocked new quizzes from core engine
    new_quizzes = [
        {"stepType": "agglutinative_quiz", "sentence": "new sentence 1"},
        {"stepType": "agglutinative_quiz", "sentence": "new sentence 2"}
    ]
    
    merged = merger.merge_content(base_content, new_quizzes)
    
    assert "steps" in merged
    steps = merged["steps"]
    
    # 1. Total steps should be 2 original non-quiz + 2 new quiz = 4
    assert len(steps) == 4
    
    # 2. Order validation (Intro -> Practice -> Quiz 1 -> Quiz 2)
    assert steps[0]["stepType"] == "introduction"
    assert steps[1]["stepType"] == "practice"
    assert steps[2]["stepType"] == "agglutinative_quiz"
    assert steps[2]["sentence"] == "new sentence 1"
    assert steps[3]["stepType"] == "agglutinative_quiz"
    assert steps[3]["sentence"] == "new sentence 2"
