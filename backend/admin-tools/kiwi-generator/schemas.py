from pydantic import BaseModel, Field
from typing import List, Optional

class AgglutinativeOption(BaseModel):
    id: str    # 선택지 고유 ID — 같은 텍스트가 두 번 필요한 문장도 풀 수 있게
    text: str
    mode: str  # "rabbit" or "turtle"

class AgglutinativeElement(BaseModel):
    id: str
    isTarget: bool
    text: Optional[str] = None
    type: Optional[str] = None  # "context_prefix", "context_suffix"
    correct_rabbit: Optional[List[str]] = None
    correct_turtle: Optional[List[str]] = None
    turtle_explanation: Optional[str] = None

class AgglutinativeQuizData(BaseModel):
    stepType: str = "agglutinative_quiz"
    sentence: str
    translation: str
    elements: List[AgglutinativeElement]
    options: List[AgglutinativeOption]

# Phase 6: Tap-to-Translate Morphology
class MorphologyToken(BaseModel):
    text: str
    meaning: str

class MorphologyChunk(BaseModel):
    display: str
    tokens: List[MorphologyToken]
