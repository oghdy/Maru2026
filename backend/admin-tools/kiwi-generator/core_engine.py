import random
from typing import List, Tuple
from kiwipiepy import Kiwi
from schemas import AgglutinativeElement, AgglutinativeOption, AgglutinativeQuizData

class KiwiEngine:
    def __init__(self):
        self.kiwi = Kiwi()
        self.decoy_pool = {
            'EP': ['겠', '시', '더'],
            'EF': ['고', '습니다', '요', '네', '다'],
            'JKO': ['가', '은', '는'],
            'JKS': ['를', '을', '은'],
        }

    def generate_decoys(self, target_pos: str, count: int = 2) -> list:
        pool = self.decoy_pool.get(target_pos, ['고', '습니다', '요', '네'])
        return random.sample(pool, min(count, len(pool)))

    def process_sentence(self, sentence: str, translation: str, target_pos: str) -> AgglutinativeQuizData:
        tokens = self.kiwi.tokenize(sentence)
        target_token = None
        
        # 1. Find Target Token
        for t in tokens:
            if t.tag == target_pos:
                target_token = t
                break
                
        if not target_token:
            raise ValueError(f"Target POS '{target_pos}' not found in the sentence.")
            
        # 2. Extract Target Eojeol (Word boundary marked by spaces) boundaries
        eojeol_start = target_token.start
        while eojeol_start > 0 and sentence[eojeol_start - 1] != ' ':
            eojeol_start -= 1
            
        eojeol_end = target_token.start + target_token.len
        while eojeol_end < len(sentence) and sentence[eojeol_end] != ' ':
            eojeol_end += 1
            
        # 3. Slice Strings
        prefix_str = sentence[:eojeol_start].strip()
        target_str = sentence[eojeol_start:eojeol_end].strip()
        suffix_str = sentence[eojeol_end:].strip()
        
        elements = []
        
        # Context Prefix
        if prefix_str:
            elements.append(AgglutinativeElement(
                id="e1", isTarget=False, text=prefix_str, type="context_prefix"
            ))
            
        # Target Zone logic (Turtle Morph Splitting)
        turtle_correct = []
        for t in tokens:
            if t.start >= eojeol_start and (t.start + t.len) <= eojeol_end:
                turtle_correct.append(t.form)
                
        elements.append(AgglutinativeElement(
            id="e2",
            isTarget=True,
            correct_rabbit=[target_str],    # Whole chunk
            correct_turtle=turtle_correct,  # Morpheme separated
            turtle_explanation=f"'{target_token.form}'({target_token.tag})가 포함된 부분입니다."
        ))
        
        # Context Suffix
        if suffix_str:
            elements.append(AgglutinativeElement(
                id="e3", isTarget=False, text=suffix_str, type="context_suffix"
            ))
            
        # 4. Generate Option Tray (Decoys)
        options = []
        # Native Rabbit correct and fake
        options.append(AgglutinativeOption(text=target_str, mode="rabbit"))
        if len(target_str) > 1:
            fake_rabbit = target_str[:-1] + "고"
        else:
            fake_rabbit = target_str + "고"
        options.append(AgglutinativeOption(text=fake_rabbit, mode="rabbit"))
        
        # Native Turtle correct
        for tc in turtle_correct:
            options.append(AgglutinativeOption(text=tc, mode="turtle"))
            
        # Fake Turtle generated
        decoys = self.generate_decoys(target_pos, 2)
        for dc in decoys:
            options.append(AgglutinativeOption(text=dc, mode="turtle"))
            
        # Random Shuffle before output
        random.shuffle(options)
        
        return AgglutinativeQuizData(
            sentence=sentence,
            translation=translation,
            elements=elements,
            options=options
        )
