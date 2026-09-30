from kiwipiepy import Kiwi
from schemas import MorphologyChunk, MorphologyToken
import unicodedata
from typing import List

# Rule-based mapping: POS Tag -> Human friendly meaning (Learner friendly)
POS_MAP = {
    'NNG': 'noun',
    'NNP': 'name',
    'NNB': 'Dependent Noun',
    'NP': 'pronoun',
    'NR': 'Numeral',
    'VV': 'verb',
    'VA': 'adjective',
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
    'SL': 'name',
    'SN': 'number',
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
    '하세요': 'do (polite)',
    '하': 'do',
    '세요': 'polite ending',
    '의사': 'doctor',
    '학생': 'student',
    '선생님': 'teacher',
    '회사원': 'office worker',
    '씨': 'Mr./Ms.',
    '아': 'Ah',
    '민수': 'Minsu (name)',
    '유미': 'Yumi (name)',
    '는': "topic marker",
    '은': "topic marker",
    '의': 'possessive marker',
    # u1-l3 (을/를)
    '을': 'object marker',
    '를': 'object marker',
    '뭐': 'what',
    '커피': 'coffee',
    '빵': 'bread',
    '물': 'water',
    '사과': 'apple',
    '책': 'book',
    '좋아하': 'like',
    '먹': 'eat',
    '마시': 'drink',
    '읽': 'read',
    '어요': 'polite ending',
    '아요': 'polite ending',
}

# Entire chunk overrides for fixed expressions (Greetings, etc.)
CHUNK_OVERRIDE_MAP = {
    '안녕하세요': 'Hello',
    '반갑습니다': 'Nice to meet you',
}

# 탭 분석에서 뺄 기호 태그 (마침표·쉼표·콜론·괄호·등호 등)
SYMBOL_TAGS = {'SF', 'SP', 'SS', 'SE', 'SO', 'SW'}


class MorphologyGenerator:
    """문장을 띄어쓰기 단위 청크로 나누고, 청크마다 형태소(표면형)와 학습자용 뜻을 붙인다.
    - display 는 원문 그대로(화면에 문장이 그대로 보이게), tokens 에는 기호를 넣지 않는다.
    - "저는 = I (topic)" 같은 설명 행은 '=' 오른쪽(영어)을 분석하지 않는다 → tokens 빈 청크(탭 불가).
    - "민수: ..." 대화 화자 표시는 '<이름> (speaker)' 한 토큰."""

    def __init__(self):
        self.kiwi = Kiwi()

    def get_meaning(self, text: str, tag: str) -> str:
        norm_text = unicodedata.normalize('NFC', text)
        if norm_text in TOKEN_SPECIFIC_MAP:
            return TOKEN_SPECIFIC_MAP[norm_text]
        if tag == 'SL':
            return f"{text} (name)" if text[:1].isupper() else text
        return POS_MAP.get(tag, 'word')

    def _surface_tokens(self, sentence: str, toks, start: int, end: int) -> List[MorphologyToken]:
        """[start, end) 안의 형태소를 원문 표면형으로 묶어 뜻을 붙인다.
        - 축약(제 = 저 + 의): 원형 형태소를 각각 표시
        - 서술격 조사 + 어미: 원문 그대로 한 토큰 (입니다 / 이에요 / 예요 — '이예요' 가 생기지 않음)
        - 접미사 '님': 앞 명사와 한 토큰 (선생님)"""
        groups = []
        for t in toks:
            if t.tag in SYMBOL_TAGS or not (start <= t.start and t.start + t.len <= end):
                continue
            ts, te = t.start, t.start + t.len
            g = groups[-1] if groups else None
            if g and (ts < g['end'] or t.len == 0 or g['tags'][-1] == 'VCP' or t.tag == 'XSN'):
                g['end'] = max(g['end'], te)
                g['tags'].append(t.tag)
                g['forms'].append(t.form)
                g['starts'].append(ts)
                g['overlap'] = g['overlap'] or (ts < g['starts'][-2] + len(g['forms'][-2]) and t.len > 0)
            else:
                groups.append({'start': ts, 'end': te, 'tags': [t.tag], 'forms': [t.form], 'starts': [ts], 'overlap': False})

        out: List[MorphologyToken] = []
        for g in groups:
            tags, forms = g['tags'], g['forms']
            surface = sentence[g['start']:g['end']]
            if 'VCP' in tags and tags[0] != 'VCP':
                # 명사 + 길이 0 서술격 조사 (유미예요) → [유미][예요]
                cut = g['starts'][tags.index('VCP')]
                out.append(MorphologyToken(text=sentence[g['start']:cut], meaning=self.get_meaning(forms[0], tags[0])))
                cop = sentence[cut:g['end']]
                out.append(MorphologyToken(text=cop, meaning=TOKEN_SPECIFIC_MAP.get(cop, 'am/is/are')))
            elif 'VCP' in tags:
                out.append(MorphologyToken(text=surface, meaning=TOKEN_SPECIFIC_MAP.get(surface, 'am/is/are')))
            elif g['overlap']:
                out.extend(MorphologyToken(text=f, meaning=self.get_meaning(f, tg)) for f, tg in zip(forms, tags))
            elif 'XSN' in tags:
                out.append(MorphologyToken(text=surface, meaning=TOKEN_SPECIFIC_MAP.get(surface, self.get_meaning(forms[0], tags[0]))))
            else:
                out.append(MorphologyToken(text=surface, meaning=self.get_meaning(surface, tags[0])))
        return out

    def analyze(self, sentence: str) -> List[MorphologyChunk]:
        chunks: List[MorphologyChunk] = []
        toks = self.kiwi.tokenize(sentence)
        gloss_from = sentence.find(' = ')  # 설명 행: '=' 부터는 영어 풀이
        pos = 0
        for i, raw in enumerate(sentence.split(' ')):
            start, end = pos, pos + len(raw)
            pos = end + 1
            if not raw:
                continue
            core = raw.strip('.,?!;:()')
            if gloss_from != -1 and start > gloss_from:
                chunks.append(MorphologyChunk(display=raw, tokens=[]))
                continue
            if i == 0 and raw.endswith(':') and len(sentence.split(' ')) > 1:
                name = core
                meaning = TOKEN_SPECIFIC_MAP.get(name, name).replace(' (name)', '')
                chunks.append(MorphologyChunk(display=raw, tokens=[MorphologyToken(text=name, meaning=f"{meaning} (speaker)")]))
                continue
            if core in CHUNK_OVERRIDE_MAP:
                chunks.append(MorphologyChunk(display=raw, tokens=[MorphologyToken(text=core, meaning=CHUNK_OVERRIDE_MAP[core])]))
                continue
            chunks.append(MorphologyChunk(display=raw, tokens=self._surface_tokens(sentence, toks, start, end)))
        return chunks

if __name__ == "__main__":
    import json
    gen = MorphologyGenerator()
    sentences = ["저는 Sarah입니다.", "제 이름은 유미예요."]
    for s in sentences:
        res = gen.analyze(s)
        print(f"\n{s}")
        print(json.dumps([c.model_dump() for c in res], ensure_ascii=False, indent=2))
