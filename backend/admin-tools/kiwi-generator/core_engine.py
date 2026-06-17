import random
from typing import List, Tuple
from kiwipiepy import Kiwi
from schemas import AgglutinativeElement, AgglutinativeOption, AgglutinativeQuizData

import random
import unicodedata
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
            'JX': ['은', '는', '도', '만'],
        }

    def generate_decoys(self, target_pos: str, count: int = 2) -> list:
        pool = self.decoy_pool.get(target_pos, ['고', '습니다', '요', '네'])
        return random.sample(pool, min(count, len(pool)))

    def process_sentence(self, sentence: str, translation: str, target_pos: str) -> AgglutinativeQuizData:
        tokens = self.kiwi.tokenize(sentence)
        target_pos_list = [p.strip() for p in target_pos.split(",") if p.strip()]
        
        raw_eojeols = sentence.split(" ")
        elements = []
        element_idx = 1
        current_pos = 0
        
        for i, raw_eojeol in enumerate(raw_eojeols):
            if not raw_eojeol:
                current_pos += 1
                continue
                
            eojeol_start = current_pos
            eojeol_end = current_pos + len(raw_eojeol)
            
            # Collect Kiwi tokens belonging to this eojeol range
            eojeol_tokens = []
            for t in tokens:
                if t.start >= eojeol_start and (t.start + t.len) <= eojeol_end:
                    eojeol_tokens.append(t)
                    
            # Check if this eojeol contains any of the target POS tags
            has_target = any(t.tag in target_pos_list for t in eojeol_tokens)
            
            # Rabbit correct is always the whole eojeol (users build the whole sentence)
            correct_rabbit = [raw_eojeol]
            
            # Turtle correct: split selectively based on target tags
            if has_target:
                # Split morphologically and apply custom VCP+EF merge logic
                turtle_correct = []
                j = 0
                while j < len(eojeol_tokens):
                    t = eojeol_tokens[j]
                    # Merge VCP + EF (e.g., 이 + ᆸ니다 -> 입니다)
                    if t.tag == 'VCP' and j + 1 < len(eojeol_tokens) and eojeol_tokens[j+1].tag == 'EF':
                        combined = unicodedata.normalize('NFC', t.form + eojeol_tokens[j+1].form)
                        if any(target in combined for target in ['입니다', '예요', '이에요', '이야']):
                            turtle_correct.append(combined)
                            j += 2
                            continue
                    
                    turtle_correct.append(t.form)
                    j += 1
            else:
                # If no target grammar exists, keep it as a whole word in Turtle mode too
                turtle_correct = [raw_eojeol]
                
            explanation = ""
            if has_target:
                matching_tags = [f"'{t.form}'({t.tag})" for t in eojeol_tokens if t.tag in target_pos_list]
                explanation = f"{', '.join(matching_tags)}가 포함된 부분입니다."
            else:
                explanation = "문장을 구성하는 기본 어절입니다."
                
            elements.append(AgglutinativeElement(
                id=f"e{element_idx}",
                isTarget=True,  # 🌟 Every eojeol is a quiz slot for whole-sentence building!
                correct_rabbit=correct_rabbit,
                correct_turtle=turtle_correct,
                turtle_explanation=explanation
            ))
            element_idx += 1
            current_pos += len(raw_eojeol) + 1  # count the space
            
        # 5. Generate Options Tray
        options = []
        rabbit_added = set()
        turtle_added = set()
        
        for elem in elements:
            for rb in elem.correct_rabbit:
                if rb not in rabbit_added:
                    options.append(AgglutinativeOption(text=rb, mode="rabbit"))
                    rabbit_added.add(rb)
                    # Fake rabbit decoy
                    fake_rabbit = rb[:-1] + "고" if len(rb) > 1 else rb + "고"
                    if fake_rabbit not in rabbit_added:
                        options.append(AgglutinativeOption(text=fake_rabbit, mode="rabbit"))
                        rabbit_added.add(fake_rabbit)
                        
            for tc in elem.correct_turtle:
                if tc not in turtle_added:
                    options.append(AgglutinativeOption(text=tc, mode="turtle"))
                    turtle_added.add(tc)
                    
        # Add target-specific fake turtle decoys
        decoys = []
        for pos in target_pos_list:
            decoys.extend(self.generate_decoys(pos, 2))
            
        for dc in decoys:
            if dc not in turtle_added:
                options.append(AgglutinativeOption(text=dc, mode="turtle"))
                turtle_added.add(dc)
                
        random.shuffle(options)
        
        return AgglutinativeQuizData(
            sentence=sentence,
            translation=translation,
            elements=elements,
            options=options
        )
