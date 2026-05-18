from kiwipiepy import Kiwi
from schemas import MorphologyChunk, MorphologyToken
import unicodedata
from typing import List

# Rule-based mapping: POS Tag -> Human friendly meaning (Learner friendly)
POS_MAP = {
    'NNG': 'Noun',
    'NNP': 'Proper Noun',
    'NNB': 'Dependent Noun',
    'NP': 'Pronoun',
    'NR': 'Numeral',
    'VV': 'Verb',
    'VA': 'Adjective',
    'VX': 'Auxiliary Verb',
    'VCP': 'be (copula)',
    'VCN': 'not be',
    'JKS': 'subject marker',
    'JKC': 'complement marker',
    'JKG': 'possessive marker',
    'JKO': 'object marker',
    'JKB': 'adverbial marker',
    'JKV': 'vocative marker',
    'JKQ': 'quotation marker',
    'JX': "topic marker",
    'JC': 'conjunction marker',
    'EP': 'tense marker',
    'EF': 'polite/formal ending',
    'EC': 'link marker',
    'ETN': 'nominal ending',
    'ETM': 'adnominal ending',
    'XPN': 'prefix',
    'XSN': 'noun suffix',
    'XSV': 'verb suffix',
    'XSA': 'adjective suffix',
    'XR': 'root',
    'MAG': 'adverb',
    'MAJ': 'conjunction adverb',
    'SL': 'word',
    'SN': 'Number',
    'SF': 'Punctuation',
}

# Special mappings for high-frequency tokens or specific meanings
TOKEN_SPECIFIC_MAP = {
    '저': 'I (polite)',
    '나': 'I (informal)',
    '제': 'My (polite)',
    '내': 'My (informal)',
    '이름': 'name',
    '학생': 'student',
    '선생님': 'teacher',
    '입니다': 'am/is/are (formal)',
    '예요': 'am/is/are (polite)',
    '이에요': 'am/is/are (polite)',
    '이야': 'am/is/are (informal)',
    '안녕하세요': 'Hello',
    '무슨': 'what',
    '일': 'work/job',
    '하세요': 'do you do (polite)',
    '의사': 'doctor',
    '학생': 'student',
    '선생님': 'teacher',
    '회사원': 'office worker',
    '씨': 'Mr./Ms.',
    '아': 'Ah',
    '민수': 'Minsu',
    '유미': 'Yumi',
    '는': "topic marker",
    '은': "topic marker",
    '의': 'possessive marker',
}

# Entire chunk overrides for fixed expressions (Greetings, etc.)
CHUNK_OVERRIDE_MAP = {
    '안녕하세요': 'Hello',
    '반갑습니다': 'Nice to meet you',
}

class MorphologyGenerator:
    def __init__(self):
        self.kiwi = Kiwi()

    def get_meaning(self, text: str, tag: str) -> str:
        # Normalize text for specific map lookup
        norm_text = unicodedata.normalize('NFC', text)
        if norm_text in TOKEN_SPECIFIC_MAP:
            return TOKEN_SPECIFIC_MAP[norm_text]
        if text in TOKEN_SPECIFIC_MAP:
            return TOKEN_SPECIFIC_MAP[text]
        
        return POS_MAP.get(tag, 'word')

    def analyze(self, sentence: str) -> List[MorphologyChunk]:
        tokens = self.kiwi.tokenize(sentence)
        chunks = []
        raw_chunks = sentence.split(' ')
        token_idx = 0
        current_pos = 0
        
        for i, raw_chunk in enumerate(raw_chunks):
            if not raw_chunk and i < len(raw_chunks) - 1:
                current_pos += 1
                continue
                
            clean_chunk = raw_chunk.strip('.,?!;')
            if clean_chunk in CHUNK_OVERRIDE_MAP:
                punct = raw_chunk[len(clean_chunk):]
                override_tokens = [MorphologyToken(text=clean_chunk, meaning=CHUNK_OVERRIDE_MAP[clean_chunk])]
                if punct:
                    override_tokens.append(MorphologyToken(text=punct, meaning="Punctuation"))
                
                chunks.append(MorphologyChunk(
                    display=raw_chunk,
                    tokens=override_tokens
                ))
                
                # Fast-forward token index to skip these tokens
                while token_idx < len(tokens):
                    if tokens[token_idx].start < current_pos + len(raw_chunk):
                        token_idx += 1
                    else:
                        break
                        
                current_pos += len(raw_chunk) + 1
                continue

            chunk_tokens_data = []
            while token_idx < len(tokens):
                token = tokens[token_idx]
                if token.start >= current_pos and token.start < current_pos + len(raw_chunk):
                    chunk_tokens_data.append({
                        'text': token.form,
                        'tag': token.tag,
                        'meaning': self.get_meaning(token.form, token.tag)
                    })
                    token_idx += 1
                else:
                    break
            
            merged_tokens = []
            j = 0
            while j < len(chunk_tokens_data):
                item = chunk_tokens_data[j]
                # Try to merge VCP + EF
                if item['tag'] == 'VCP' and j + 1 < len(chunk_tokens_data) and chunk_tokens_data[j+1]['tag'] == 'EF':
                    combined = unicodedata.normalize('NFC', item['text'] + chunk_tokens_data[j+1]['text'])
                    if any(target in combined for target in ['입니다', '예요', '이에요', '이야']):
                        # Find the correct full form from raw_chunk if possible
                        # For simplicity, we just use the combined form
                        # Note: '이' + 'ᆸ니다' becomes '입니다' (NFC)
                        merged_tokens.append(MorphologyToken(
                            text=combined,
                            meaning=TOKEN_SPECIFIC_MAP.get(combined, 'am/is/are')
                        ))
                        j += 2
                        continue
                
                merged_tokens.append(MorphologyToken(
                    text=item['text'],
                    meaning=item['meaning']
                ))
                j += 1
            
            if merged_tokens or raw_chunk:
                chunks.append(MorphologyChunk(
                    display=raw_chunk,
                    tokens=merged_tokens
                ))
            current_pos += len(raw_chunk) + 1
            
        return chunks

if __name__ == "__main__":
    import json
    gen = MorphologyGenerator()
    sentences = ["저는 Sarah입니다.", "제 이름은 유미예요."]
    for s in sentences:
        res = gen.analyze(s)
        print(f"\n{s}")
        print(json.dumps([c.dict() for c in res], ensure_ascii=False, indent=2))
