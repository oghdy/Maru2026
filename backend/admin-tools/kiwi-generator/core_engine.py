import random
from typing import List, Optional

from kiwipiepy import Kiwi
from schemas import AgglutinativeElement, AgglutinativeOption, AgglutinativeQuizData

# 문장부호·기호 태그: 조립 블록에서 제외한다 (SL 영문, SN 숫자, SH 한자는 단어로 취급해 유지)
PUNCT_TAGS = {'SF', 'SP', 'SS', 'SE', 'SO', 'SW'}

# 같은 자리에 올 수 있는 형태(이형태) — 오답 선택지의 1순위. 학습자가 실제로 헷갈리는 선택만 낸다.
ALLOMORPHS = {
    '은': ['는'], '는': ['은'],
    '이': ['가'], '가': ['이'],
    '을': ['를'], '를': ['을'],
    '이에요': ['예요'], '예요': ['이에요'],
    '입니다': ['이에요', '예요'],
    '이야': ['야'], '야': ['이야'],
}

# 같은 문법 범주의 다른 형태 — 오답 선택지 2순위
CATEGORY_POOL = {
    'JX': ['도', '만'],
    'JKS': ['이', '가'],
    'JKO': ['을', '를'],
    'COPULA': ['입니다', '이에요', '예요'],
    'EF': ['아요', '어요', '습니다'],
    'EP': ['았', '었', '겠'],
}

TAG_NAMES = {
    'JX': 'topic particle', 'JKS': 'subject particle', 'JKO': 'object particle',
    'JKG': 'possessive particle', 'JKB': 'adverbial particle',
    'EF': 'sentence ending', 'EP': 'tense/honorific marker', 'EC': 'connective ending',
    'COPULA': 'am/is/are',
}

# 받침 유무로 형태가 갈리는 문법 설명 (영어 UI)
ALLOMORPH_RULES = {
    frozenset({'은', '는'}): "marks the topic. After a vowel use 는, after a consonant use 은.",
    frozenset({'이', '가'}): "marks the subject. After a vowel use 가, after a consonant use 이.",
    frozenset({'을', '를'}): "marks the object. After a vowel use 를, after a consonant use 을.",
    frozenset({'이에요', '예요'}): "means 'am/is/are'. After a consonant use 이에요, after a vowel use 예요.",
}


class _Unit:
    """어절 안의 표면형 조각 하나 (겹치는 토큰·서술격 조사+어미는 한 조각으로 묶임)."""

    def __init__(self, start: int, end: int, tags: List[str]):
        self.start, self.end, self.tags = start, end, list(tags)

    @property
    def category(self) -> str:
        return 'COPULA' if 'VCP' in self.tags else self.tags[-1]


class KiwiEngine:
    def __init__(self, seed: Optional[int] = None):
        self.kiwi = Kiwi()
        self.seed = seed

    # ---------- 분해 ----------
    def _units(self, sentence: str, tokens) -> List[_Unit]:
        units: List[_Unit] = []
        for t in tokens:
            if t.tag in PUNCT_TAGS:
                continue
            start, end = t.start, t.start + t.len
            if units and (start < units[-1].end or t.len == 0 or units[-1].tags[-1] == 'VCP'):
                # 겹침(제 = 저+의), 길이 0 토큰('유미예요' 의 VCP), 서술격 조사 뒤 어미 → 앞 조각에 합침
                units[-1].end = max(units[-1].end, end)
                units[-1].tags.append(t.tag)
            else:
                units.append(_Unit(start, end, [t.tag]))
        return self._split_copula(tokens, units)

    @staticmethod
    def _split_copula(tokens, units: List[_Unit]) -> List[_Unit]:
        """명사+이(VCP)+어미 가 한 조각으로 묶였으면 [명사][이+어미] 로 나눈다."""
        out: List[_Unit] = []
        for u in units:
            if 'VCP' not in u.tags or u.tags[0] == 'VCP':
                out.append(u)
                continue
            vcp = next(t for t in tokens if t.tag == 'VCP' and u.start <= t.start <= u.end)
            boundary = vcp.start
            i = u.tags.index('VCP')
            out.append(_Unit(u.start, boundary, u.tags[:i]))
            out.append(_Unit(boundary, u.end, u.tags[i:]))
        return [u for u in out if u.end > u.start]

    @staticmethod
    def _is_target(unit: _Unit, targets: List[str]) -> bool:
        if 'VCP' in unit.tags:  # 서술격 조사+어미 조각 (입니다/이에요/예요)
            return any(t in targets for t in ('VCP', 'COPULA', 'EF'))
        return any(tag in targets for tag in unit.tags)

    # ---------- 오답 ----------
    @staticmethod
    def _turtle_decoys(piece: str, category: str, exclude: set) -> List[str]:
        out = []
        for d in ALLOMORPHS.get(piece, []) + CATEGORY_POOL.get(category, []):
            if d != piece and d not in exclude and d not in out:
                out.append(d)
        return out[:2]

    @staticmethod
    def _explain(piece: str, category: str) -> str:
        for group, rule in ALLOMORPH_RULES.items():
            if piece in group:
                return f"'{piece}' {rule}"
        if piece == '입니다':
            return "'입니다' is the formal way to say 'am/is/are'."
        return f"'{piece}' is a {TAG_NAMES.get(category, category)}."

    # ---------- 메인 ----------
    def process_sentence(self, sentence: str, translation: str, target_pos: str) -> AgglutinativeQuizData:
        rng = random.Random(self.seed if self.seed is not None else sentence)
        targets = [p.strip() for p in target_pos.split(",") if p.strip()]
        tokens = self.kiwi.tokenize(sentence)

        elements: List[AgglutinativeElement] = []
        rabbit_decoys: List[str] = []
        turtle_decoys: List[str] = []
        correct_turtle_all: set = set()

        pos = 0
        for raw in sentence.split(" "):
            start, end = pos, pos + len(raw)
            pos = end + 1
            if not raw:
                continue
            units = self._units(sentence, [t for t in tokens if start <= t.start and t.start + t.len <= end])
            if not units:  # 기호만 있는 어절 (예: "-") → 칸 없음
                continue
            core = sentence[units[0].start:units[-1].end]

            pieces: List[str] = []
            target_pieces = []  # (piece, category)
            buf_start = None
            for u in units:
                if self._is_target(u, targets):
                    if buf_start is not None:
                        pieces.append(sentence[buf_start:u.start])
                        buf_start = None
                    piece = sentence[u.start:u.end]
                    pieces.append(piece)
                    target_pieces.append((piece, u.category))
                elif buf_start is None:
                    buf_start = u.start
            if buf_start is not None:
                pieces.append(sentence[buf_start:units[-1].end])

            if target_pieces:
                explanation = " ".join(self._explain(p, c) for p, c in target_pieces)
                # 토끼 단계 오답: 목표 형태를 이형태로 바꾼 어절 (예: 저는 → 저은)
                for p, _ in target_pieces:
                    for alt in ALLOMORPHS.get(p, [])[:1]:
                        wrong = "".join(alt if x == p else x for x in pieces)
                        if wrong != core:
                            rabbit_decoys.append(wrong)
            else:
                pieces = [core]
                explanation = f"Keep '{core}' as one block — it is not this lesson's focus."

            correct_turtle_all.update(pieces)
            for p, c in target_pieces:
                turtle_decoys.extend(self._turtle_decoys(p, c, set()))

            elements.append(AgglutinativeElement(
                id=f"e{len(elements) + 1}",
                isTarget=True,  # 문장 전체를 조립하므로 모든 어절이 칸
                correct_rabbit=[core],
                correct_turtle=pieces,
                turtle_explanation=explanation,
            ))

        # 선택지: 정답 조각은 등장 횟수만큼(같은 텍스트 2개 허용), 오답은 정답과 겹치지 않게 1개씩
        texts = []
        for e in elements:
            texts += [(t, "rabbit") for t in e.correct_rabbit]
            texts += [(t, "turtle") for t in e.correct_turtle]
        correct_rabbit_all = {t for e in elements for t in e.correct_rabbit}
        for d in dict.fromkeys(rabbit_decoys):
            if d not in correct_rabbit_all:
                texts.append((d, "rabbit"))
        for d in dict.fromkeys(turtle_decoys):
            if d not in correct_turtle_all:
                texts.append((d, "turtle"))
        rng.shuffle(texts)
        options = [AgglutinativeOption(id=f"o{i + 1}", text=t, mode=m) for i, (t, m) in enumerate(texts)]

        return AgglutinativeQuizData(sentence=sentence, translation=translation, elements=elements, options=options)
