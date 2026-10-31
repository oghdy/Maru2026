"""신규 8레슨 독립 검산 (WEB-5.8.4). 생성 코드를 쓰지 않고 SQL 패치에 실제로 들어간 content 를 읽어 확인한다.

받침·모음 규칙은 여기서 유니코드로 다시 계산한다. 오류가 하나라도 있으면 종료 코드 1.
사용 (backend/admin-tools/kiwi-generator 에서):
  PYTHONDONTWRITEBYTECODE=1 venv/bin/python ../../lessons/check_curriculum.py
"""
import json
import os
import re
import sys
from collections import Counter

from kiwipiepy import Kiwi

HERE = os.path.dirname(os.path.abspath(__file__))
PATCHES = [os.path.join(HERE, '..', 'db', 'patches', n) for n in
           ('lsn_006_add_u1_review_u2_place_review.sql', 'lsn_007_add_unit3_say_more.sql')]
# 조립 오답만 고친 기존 레슨 (WEB-5.10.1): 앞 패치와 조립 외 단계가 같아야 한다
FIX_PATCH = os.path.join(HERE, '..', 'db', 'patches', 'lsn_008_fix_unit1_quiz_decoys.sql')
FIX_BASE_PATCH = os.path.join(HERE, '..', 'db', 'patches', 'lsn_003_regenerate_unit1_content.sql')
BASE_PATCH = os.path.join(HERE, '..', 'db', 'patches', 'lsn_005_add_unit2_daily_life.sql')
# 과거형 파일럿 (WEB-5.12.3): Learn + Practice 다시 쓰기. lsn_007 의 u3-l2 와 따로 검사한다
PILOT_PATCH = os.path.join(HERE, '..', 'db', 'patches', 'lsn_009_pilot_past_tense.sql')
PILOT_ORDER = {'u3-l1': 1, 'u3-l2-learn': 2, 'u3-l2': 3, 'u3-l3': 4, 'u3-l4': 5, 'u3-l5': 6}
PILOT_PRACTICE = 'u3-l2 (lsn_009)'
MOODS = {'idle', 'happy', 'sad', 'thinking', 'talking', 'cheer', 'magic'}
ORDER = ['u1-l4', 'u2-l4', 'u2-l5', 'u3-l1', 'u3-l2', 'u3-l3', 'u3-l4', 'u3-l5']
REVIEWS = {'u1-l4', 'u2-l5', 'u3-l5'}

# CURRICULUM.md 5.2 금지 형태 + 안 배운 과거 표현 (했어요 는 대화 통째 토큰만 허용, 조립·연습 금지)
FORBIDDEN = ['갔어요', '왔어요', '봤어요', '샀어요', '만났어요', '마셨어요', '좋아했어요', '공부했어요',
             '들었어요', '추웠', '쉬웠', '고마워요', '사세요', '드세요', '먹으세요', '만나요', '입니다']
ATTACHED_HAGO = re.compile(r"\S하고 ")  # 명사+하고 (뭐 하고 싶어요 의 하+고 는 띄어 써서 걸리지 않는다)
FORBIDDEN_EN = ['personal', 'adaptive', 'tailored', 'all past', 'every past']
VOWELS = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
FINALS = ['', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ',
          'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
DEFAULT_MEANINGS = {'noun', 'verb', 'word', 'pronoun', 'adjective', 'adverb', 'Auxiliary Verb', 'adverbial marker',
                    'complement marker', 'link marker', 'tense marker', 'polite/formal ending', 'not be',
                    'root', 'prefix', 'noun suffix', 'verb suffix', 'Dependent Noun'} - {'not be'}

# 학습 순서에 따라 누적으로 허용하는 내용어 (Kiwi 기본형). 앞 레슨 어휘 재사용 확인
VOCAB = {
    'u1': {'저', '이름', '학생', '의사', '선생님', '선생', '회사원', '커피', '빵', '물', '사과', '책', '뭐', '씨', '무슨', '일',
           '하', '먹', '마시', '좋아하', '민수', '유미', '아', '제', '이'},
    'u2-l1~3': {'시간', '친구', '돈', '우유', '가방', '오늘', '네', '아니요', '있', '없', '학교', '집', '회사', '카페', '도서관',
                '어디', '지금', '가', '읽', '안', '그렇', '그래요'},
    'u2-l4': {'공부', '식당', '밥'},
    'u2-l5': set(),
    'u3-l1': {'아니'},
    'u3-l2': {'어제', '찾', '앉', '받'},
    'u3-l3': {'싶'},
    'u3-l4': {'여기'},
    'u3-l5': set(),
}
LESSON_VOCAB_ORDER = {
    'u1-l4': ['u1'],
    'u2-l4': ['u1', 'u2-l1~3', 'u2-l4'],
    'u2-l5': ['u1', 'u2-l1~3', 'u2-l4', 'u2-l5'],
    'u3-l1': ['u1', 'u2-l1~3', 'u2-l4', 'u3-l1'],
    'u3-l2': ['u1', 'u2-l1~3', 'u2-l4', 'u3-l1', 'u3-l2'],
    'u3-l3': ['u1', 'u2-l1~3', 'u2-l4', 'u3-l1', 'u3-l2', 'u3-l3'],
    'u3-l4': ['u1', 'u2-l1~3', 'u2-l4', 'u3-l1', 'u3-l2', 'u3-l3', 'u3-l4'],
    'u3-l5': ['u1', 'u2-l1~3', 'u2-l4', 'u3-l1', 'u3-l2', 'u3-l3', 'u3-l4'],
}
LESSON_VOCAB_ORDER['u3-l2-learn'] = LESSON_VOCAB_ORDER['u3-l2']
LESSON_VOCAB_ORDER[PILOT_PRACTICE] = LESSON_VOCAB_ORDER['u3-l2']
errors = []
checks = Counter()


def ok(cond, lesson, step, msg):
    checks[lesson] += 1
    if not cond:
        errors.append(f"{lesson} 단계{step}: {msg}")


def final_of(syll):
    return FINALS[(ord(syll) - 0xAC00) % 28]


def vowel_of(syll):
    return VOWELS[((ord(syll) - 0xAC00) // 28) % 21]


def has_final(word):
    return final_of(word[-1]) != ''


# 형태 쌍: (받침 뒤, 모음 뒤)
PAIRS = [('은', '는'), ('이', '가'), ('을', '를'), ('이에요', '예요'), ('으세요', '세요')]


def check_pair(word, particle, lesson, step, where):
    for after_c, after_v in PAIRS:
        if particle in (after_c, after_v):
            want = after_c if has_final(word) else after_v
            ok(particle == want, lesson, step, f"{where}: {word}+{particle} 받침 규칙 위반, {want} 이어야 함")
            return True
    return False


def check_past(stem, marker, lesson, step, where):
    want = '았' if vowel_of(stem[-1]) in 'ㅏㅗ' else '었'
    ok(marker == want, lesson, step, f"{where}: {stem}+{marker} 모음 규칙 위반, {want} 이어야 함")


def load_lessons(path):
    text = open(path, encoding='utf-8').read()
    out = {}
    for body, lesson_id in re.findall(r"UPDATE lessons SET content = \$lsn\$(.*?)\$lsn\$::jsonb\nWHERE lesson_id = '([^']+)';", text, re.S):
        out[lesson_id] = json.loads(body)
    return out


def shape(step):
    """단계의 키 구조 (값 제외)"""
    def walk(v):
        if isinstance(v, dict):
            return {k: walk(x) for k, x in sorted(v.items())}
        if isinstance(v, list):
            return [walk(v[0])] if v else []
        return type(v).__name__
    return json.dumps(walk(step), sort_keys=True)


def check_quiz(lesson, n, step):
    b = step['contentObj']
    sentence = b['sentence']
    ok(set(step) == {'stepType', 'title', 'instruction', 'contentObj'}, lesson, n, "조립 단계 키")
    ok(b['translation'] in step['instruction'], lesson, n, "안내에 번역 포함")
    restored = ' '.join(e['correct_rabbit'][0] for e in b['elements'])
    ok(restored == sentence.rstrip('.?!'), lesson, n, f"🐰 복원 {restored} != {sentence}")
    for e in b['elements']:
        ok(''.join(e['correct_turtle']) == e['correct_rabbit'][0], lesson, n, f"🐢 복원 {e['correct_turtle']}")
        ok(e['turtle_explanation'] and not re.search(r"is an? [A-Z]|adverbial|complement", e['turtle_explanation']),
           lesson, n, f"힌트 기본값: {e['turtle_explanation']}")
        ok(e['isTarget'] is True, lesson, n, 'isTarget')
    ids = [o['id'] for o in b['options']]
    ok(len(ids) == len(set(ids)), lesson, n, 'option id 중복')
    for mode, key in (('rabbit', 'correct_rabbit'), ('turtle', 'correct_turtle')):
        need = Counter(t for e in b['elements'] for t in e[key])
        have = Counter(o['text'] for o in b['options'] if o['mode'] == mode)
        for t, c in need.items():
            ok(have[t] >= c, lesson, n, f"{mode} 블록 부족: {t} 필요 {c}, 있음 {have[t]}")
        decoys = [t for t in have if t not in need]
        ok(len(decoys) >= 1, lesson, n, f"{mode} 오답 없음")
        for t, c in have.items():
            ok(c == need.get(t, 1), lesson, n, f"{mode} 선택지 개수 이상: {t} {c}개")
        for d in decoys:
            ok(not any(w in d for w in FORBIDDEN), lesson, n, f"금지 형태 오답: {d}")
    # 분해 조각 규칙
    for e in b['elements']:
        parts = e['correct_turtle']
        for i in range(1, len(parts)):
            prev, cur = parts[i - 1], parts[i]
            if cur in ('았', '었'):
                check_past(prev, cur, lesson, n, '조립')
            else:
                check_pair(prev, cur, lesson, n, '조립')
    # 🐰 오답은 정답 어절이 아니어야 하고, 🐢 오답은 정답 조각이 아니어야 한다
    correct_r = {t for e in b['elements'] for t in e['correct_rabbit']}
    correct_t = {t for e in b['elements'] for t in e['correct_turtle']}
    for o in b['options']:
        if o['mode'] == 'rabbit' and o['text'] not in correct_r:
            ok(o['text'].rstrip() != '', lesson, n, '빈 오답')
        if o['mode'] == 'turtle' and o['text'] not in correct_t:
            ok(o['text'] not in ('도', '만', '겠', '입니다'), lesson, n, f"안 배운 🐢 오답: {o['text']}")


def check_grammar_rows(lesson, n, sentences):
    for s in sentences:
        en = s['english']
        for word, kind, sign, rest in re.findall(r"(\S+) \((ends with \w+|vowel) (\S+)\) \+ (.+)", en):
            last = word[-1]
            if kind == 'vowel':
                ok(vowel_of(last) == sign, lesson, n, f"설명 행 모음 {word} {sign}")
                marker = rest.split(' ')[0]
                check_past(word, marker, lesson, n, '설명 행')
            elif 'consonant' in kind:
                ok(final_of(last) == sign, lesson, n, f"설명 행 받침 {word} {sign} (실제 {final_of(last)})")
                check_pair(word, rest.split(' ')[0], lesson, n, '설명 행')
            else:
                ok(final_of(last) == '' and vowel_of(last) == sign, lesson, n, f"설명 행 모음 끝 {word} {sign}")
                check_pair(word, rest.split(' ')[0], lesson, n, '설명 행')
        ko = s['korean'].split(' = ')[0]
        for ch in s['chunks']:
            for t in ch['tokens']:
                ok(t['text'] in ko or t['text'] in ('어요', '하', '마시', '좋아하', '가') or ch['display'] in ko,
                   lesson, n, f"토큰 {t['text']}")


def check_practice(lesson, n, step, kiwi):
    positions = []
    for i, ex in enumerate(step['content']['exercises'], 1):
        where = f"연습 {i}"
        ok(ex['type'] == 'fill_blank', lesson, n, f"{where} 형식")
        ok(ex['answer'] in ex['options'] and len(ex['options']) == len(set(ex['options'])) == 2, lesson, n, f"{where} 선택지")
        ok(ex['sentence'].count('[ ? ]') == 1, lesson, n, f"{where} 빈칸")
        positions.append(ex['options'].index(ex['answer']))
        m = re.search(r"(\S+) \[ \? \]", ex['sentence'])
        attached = bool(m)  # 앞 단어 뒤에 붙는 조사·어미 문제
        fb = ex['feedback']['correct']
        if attached:
            word = m.group(1)
            for opt in ex['options']:
                if opt == ex['answer']:
                    check_pair(word, opt, lesson, n, where)
                elif (opt, ex['answer']) in [(a, b) for a, b in PAIRS] + [(b, a) for a, b in PAIRS]:
                    # 오답은 반드시 규칙 위반이어야 한다
                    want = [a if has_final(word) else b for a, b in PAIRS if opt in (a, b)][0]
                    ok(opt != want, lesson, n, f"{where}: 오답 {word}+{opt} 이 규칙상 맞음")
        # 정답 전체 어절의 받침·모음 규칙 (먹었어요, 읽으세요)
        answer = ex['answer']
        for token in answer.split(' '):
            pm = re.fullmatch(r"(.+?)([았었])어요", token)
            if pm:
                check_past(pm.group(1), pm.group(2), lesson, n, where)
            sm = re.fullmatch(r"(.+?)(으세요|세요)", token)
            if sm:
                check_pair(sm.group(1), sm.group(2), lesson, n, where)
        # 피드백의 받침 주장 검산
        fm = re.search(r"(\S+) ends in a (vowel|consonant)", fb)
        if fm:
            ok(has_final(fm.group(1)) == (fm.group(2) == 'consonant'), lesson, n, f"{where} 피드백 받침 주장: {fb}")
        vm = re.search(r"The vowel in (\S+) is (\S),", fb)
        if vm:
            ok(vowel_of(vm.group(1)[-1]) == vm.group(2), lesson, n, f"{where} 피드백 모음 주장: {fb}")
        # Kiwi: 정답 문장이 목표대로 분석되는지 (오분석이면 표면형 복원이 깨진다)
        full = ex['sentence'].replace(' [ ? ]', ex['answer'] if attached else ' ' + ex['answer']) if attached else ex['sentence'].replace('[ ? ]', ex['answer'])
        for bad in FORBIDDEN:
            ok(bad not in full, lesson, n, f"{where} 금지 형태: {bad}")
            ok(all(bad not in o for o in ex['options']), lesson, n, f"{where} 금지 형태 오답: {bad}")
        tokens = kiwi.tokenize(full)
        ok(any(t.tag.startswith(('V', 'N')) for t in tokens), lesson, n, f"{where} 분석 실패: {full}")
        check_vocab(lesson, n, full, kiwi)
    ok(0 in positions and 1 in positions, lesson, n, f"정답 위치가 한쪽으로 고정: {positions}")


def check_vocab(lesson, n, korean, kiwi):
    allowed = set().union(*(VOCAB[k] for k in LESSON_VOCAB_ORDER[lesson]))
    text = korean.split(' = ')[0]
    if re.search(r"^(\S+):", text):
        text = text.split(':', 1)[1]
    for t in kiwi.tokenize(text):
        if t.tag[0] in 'NV' and t.tag not in ('VCP', 'NNB', 'VX'):
            ok(t.form in allowed, lesson, n, f"안 배운 내용어 {t.form}/{t.tag} ({korean})")


def check_fix_patch():
    fixed = load_lessons(FIX_PATCH)
    before = load_lessons(FIX_BASE_PATCH)
    for lesson, content in fixed.items():
        steps = content['steps']
        for n, step in enumerate(steps, 1):
            if (step.get('step_type') or step.get('stepType')) == 'agglutinative_quiz':
                check_quiz(lesson, n, step)
        def rest(c):
            return [s for s in c['steps'] if (s.get('step_type') or s.get('stepType')) != 'agglutinative_quiz']
        ok(rest(content) == rest(before[lesson]), lesson, 0, '조립 외 단계가 lsn_003 과 다름')
        def sans_options(c):
            return [{k: v for k, v in s['contentObj'].items() if k != 'options'} | {'t': s['title'], 'i': s['instruction']}
                    for s in c['steps'] if s.get('stepType') == 'agglutinative_quiz']
        ok(sans_options(content) == sans_options(before[lesson]), lesson, 0, '조립 정답·힌트·안내가 lsn_003 과 다름')
    return list(fixed)


def stype(step):
    return step.get('step_type') or step.get('stepType')


def check_concept(lesson, n, step, kiwi, character):
    c = step['content']
    ok(set(step) == {'step_type', 'title', 'instruction', 'content'}, lesson, n, '단계 키 (모르는 최상위 키는 서버가 버린다)')
    ok(step['title'] and len(step['title']) <= 40, lesson, n, '제목')
    ok(c['character'] == character, lesson, n, f"캐릭터 {c['character']}")
    ok(c['mood'] in MOODS, lesson, n, f"표정 {c['mood']}")
    text = c['explanation']
    ok(len(text.split()) <= 25, lesson, n, f"설명이 25단어 초과: {len(text.split())}")
    ok(1 <= len(re.findall(r"[.!?](?:\s|$)", text)) <= 2, lesson, n, f"설명 문장 수: {text}")
    ex = c['example']
    ok(c['tap_to_assemble'] == (ex is not None), lesson, n, '탭 조립은 예문이 있을 때만')
    if ex is None:
        return
    ok(ex['translation'] and ex['tts'] is True, lesson, n, '번역·tts')
    joined = ' '.join(''.join(p['text'] for p in w['parts']) for w in ex['words'])
    ok(joined == ex['sentence'].rstrip('.?!'), lesson, n, f"조립 복원 {joined} != {ex['sentence']}")
    ok(any(p['highlight'] for w in ex['words'] for p in w['parts']), lesson, n, '강조 없음')
    for w in ex['words']:
        for p in w['parts']:
            ok(p['meaning'].strip() != '' and p['highlight'] in (True, False), lesson, n, f"조각 {p}")
        if len(w['parts']) > 1:
            # 조각 경계가 Kiwi 표면형과 같아야 한다 (축약이면 표면형을 이어도 원형이 안 된다)
            word = ''.join(p['text'] for p in w['parts'])
            tokens = [t for t in kiwi.tokenize(word) if t.tag != 'SF']
            ok(len(tokens) == len(w['parts']) and all(word[t.start:t.start + t.len] == p['text']
                                                      for t, p in zip(tokens, w['parts'])),
               lesson, n, f"Kiwi 경계 불일치 {word}: {[(t.form, t.tag) for t in tokens]}")
    check_vocab(lesson, n, ex['sentence'], kiwi)
    for bad in FORBIDDEN:
        ok(bad not in ex['sentence'], lesson, n, f"금지 형태 {bad}")


def check_sentence(lesson, n, ex, kiwi):
    """정답을 넣은 문장을 Kiwi 와 어휘로 다시 본다."""
    full = ex['sentence'].replace('[ ? ]', ex['answer'])
    ok(any(t.tag == 'EP' or t.tag.startswith('V') for t in kiwi.tokenize(full)), lesson, n, f"분석 실패 {full}")
    check_vocab(lesson, n, full, kiwi)
    for bad in FORBIDDEN:
        ok(bad not in full and all(bad not in o for o in ex['options']), lesson, n, f"금지 형태 {bad}: {full}")


def check_learn(lesson, steps, kiwi):
    types = [stype(s) for s in steps]
    ok(8 <= len(steps) <= 12, lesson, 0, f"단계 수 {len(steps)}")
    ok(set(types) == {'concept', 'practice', 'completion'}, lesson, 0, f"단계 타입 {set(types)}")
    questions = 0
    for n, s in enumerate(steps, 1):
        if types[n - 1] == 'concept':
            check_concept(lesson, n, s, kiwi, 'turtle')
        elif types[n - 1] == 'practice':
            exercises = s['content']['exercises']
            questions += len(exercises)
            ok(s['content']['graded'] is False, lesson, n, 'Learn 확인 문제는 graded false')
            for ex in exercises:
                ok(ex['answer'] in ex['options'] and len(ex['options']) == 2, lesson, n, '선택지')
                ok(ex['feedback'].get('incorrect'), lesson, n, '틀렸을 때 안내 없음')
                check_sentence(lesson, n, ex, kiwi)
    ok(2 <= questions <= 3, lesson, 0, f"문제 수 {questions}")
    answers = [s['content']['exercises'][0] for s in steps if stype(s) == 'practice']
    ok(len({ex['options'].index(ex['answer']) for ex in answers}) == 2, lesson, 0, '정답 위치가 한쪽으로 고정')

    # 새 단어는 쓰기 전에 먼저: 어제·찾 는 소개 카드가 첫 사용보다 앞
    def first(needle):
        return next(i for i, s in enumerate(steps) if needle in str(s))
    ok(steps[first('어제')]['title'] == 'New word: 어제', lesson, 0, '어제 소개가 먼저가 아님')
    ok(steps[first('찾')]['title'] == 'Sometimes it is 았', lesson, 0, '찾 소개가 먼저가 아님')


def check_practice_lesson(lesson, steps, kiwi):
    types = [stype(s) for s in steps]
    ok(types[0] == 'concept' and types[-1] == 'completion', lesson, 0, '시작·끝')
    ok(types.count('practice') == 3, lesson, 0, f"연습 라운드 {types.count('practice')}")
    ok(types.count('agglutinative_quiz') == 5, lesson, 0, f"조립 {types.count('agglutinative_quiz')}")
    vocab_at = next(i for i, s in enumerate(steps) if s['title'].startswith('Vocabulary'))
    ok(vocab_at == 1, lesson, 0, '어휘가 먼저가 아님')
    for needle in ('앉', '받', '찾'):
        ok(next(i for i, s in enumerate(steps) if needle in str(s)) == vocab_at, lesson, 0, f"{needle} 어휘보다 먼저 나옴")
    hints = []
    for n, s in enumerate(steps, 1):
        t = types[n - 1]
        ok(len(s['instruction'] or '') <= 160, lesson, n, f"안내가 길다 {len(s['instruction'])}")
        if t == 'concept':
            check_concept(lesson, n, s, kiwi, 'rabbit')
        elif t == 'practice':
            check_practice(lesson, n, s, kiwi)
            for ex in s['content']['exercises']:
                check_sentence(lesson, n, ex, kiwi)
        elif t == 'agglutinative_quiz':
            check_quiz(lesson, n, s)
            check_vocab(lesson, n, s['contentObj']['sentence'], kiwi)
            hints.append(len(s['instruction']) - len(f"Build the sentence: \"{s['contentObj']['translation']}\""))
        elif t == 'intro' and s['title'].startswith('Conversation'):
            for line in s['content']['sentences']:
                check_vocab(lesson, n, line['korean'], kiwi)
                ok(not ATTACHED_HAGO.search(line['korean']), lesson, n, f"명사+하고: {line['korean']}")
                for bad in FORBIDDEN:
                    ok(bad not in line['korean'], lesson, n, f"금지 형태 {bad}")
    ok(hints == sorted(hints, reverse=True) and hints[-1] == 0, lesson, 0, f"힌트가 줄어들지 않음 {hints}")


def check_pilot(kiwi):
    pilot = load_lessons(PILOT_PATCH)
    ok(set(pilot) == {'u3-l2-learn', 'u3-l2'}, 'u3-l2-learn', 0, f"레슨 {set(pilot)}")
    check_learn('u3-l2-learn', pilot['u3-l2-learn']['steps'], kiwi)
    check_practice_lesson(PILOT_PRACTICE, pilot['u3-l2']['steps'], kiwi)
    text = open(PILOT_PATCH, encoding='utf-8').read()
    numbers = {lesson: int(num) for num, lesson in re.findall(r"UPDATE lessons SET order_num = (\d+) WHERE lesson_id = '([^']+)';", text)}
    ok(numbers == PILOT_ORDER, PILOT_PRACTICE, 0, f"Unit 3 순서 {numbers}")
    return ['u3-l2-learn', PILOT_PRACTICE]


def main():
    kiwi = Kiwi()
    lessons = {}
    for p in PATCHES:
        if os.path.exists(p):
            lessons.update(load_lessons(p))
    order = [k for k in ORDER if k in lessons]
    print("검사 대상:", ", ".join(order))

    # 키 구조는 기존 u2-l3 (lsn_005) 과 같아야 한다
    base_steps = load_lessons(BASE_PATCH)['u2-l3']['steps']
    base_shape = {}
    for s in base_steps:
        t = s.get('step_type') or s.get('stepType')
        base_shape.setdefault(t, shape(s))

    for lesson in order:
        steps = lessons[lesson]['steps']
        types = [s.get('step_type') or s.get('stepType') for s in steps]
        ok(types[0] == 'intro' and types[-1] == 'completion', lesson, 0, '시작·끝 단계')
        ok(set(types) <= {'intro', 'practice', 'agglutinative_quiz', 'completion'}, lesson, 0, f"단계 타입 {set(types)}")
        ok(types.count('practice') == 1, lesson, 0, 'practice 1개')
        ok(types.count('agglutinative_quiz') == (4 if lesson == 'u3-l5' else 3), lesson, 0, '조립 수')
        ok(any(s['title'] == "Today's Goal" for s in steps) and any(s['title'].startswith('Grammar') for s in steps),
           lesson, 0, '목표·문법 단계')
        if lesson not in REVIEWS:
            ok(any(s['title'].startswith('Vocabulary') for s in steps), lesson, 0, '어휘 단계')
        raw = json.dumps(lessons[lesson], ensure_ascii=False)
        for w in FORBIDDEN_EN:
            ok(w not in raw.lower(), lesson, 0, f"금지 문구 {w}")
        for n, step in enumerate(steps, 1):
            t = types[n - 1]
            ok(len(step['instruction'] or '') <= 160, lesson, n, f"안내가 길다({len(step['instruction'])})")
            if t == 'intro':
                ok(shape({k: v for k, v in step.items()}).count('step_type') == 1, lesson, n, 'intro 키')
                conversation = step['title'].startswith('Conversation')
                for s in step['content']['sentences']:
                    ko = s['korean']
                    if ' = ' not in ko:
                        for bad in FORBIDDEN:
                            ok(bad not in ko, lesson, n, f"금지 형태: {bad} in {ko}")
                        ok(not ATTACHED_HAGO.search(ko), lesson, n, f"명사+하고: {ko}")
                    for ch in s['chunks']:
                        for tok in ch['tokens']:
                            ok(tok['meaning'] not in DEFAULT_MEANINGS, lesson, n, f"탭 뜻 기본값: {tok['text']}={tok['meaning']} ({ko})")
                        if ' = ' in ko and ch['display'] in ('=',):
                            ok(ch['tokens'] == [], lesson, n, '설명 행')
                    ok(s['tts'] == (' = ' not in ko), lesson, n, f"tts 값 {ko}")
                    if conversation:
                        ok(re.match(r"(민수|유미): ", ko) and re.match(r"(Minsu|Yumi): ", s['english']), lesson, n, f"화자 {ko}")
                        ok(ko.split(':')[0] == {'Minsu': '민수', 'Yumi': '유미'}[s['english'].split(':')[0]], lesson, n, f"화자 번역 {ko}")
                    # 낱말 카드·설명 행의 활용형은 문장 없이 분석이 틀어지므로 대화·목표 문장만 어휘 검사
                    if not step['title'].startswith('Vocabulary'):
                        check_vocab(lesson, n, ko, kiwi)
                if step['title'].startswith('Grammar'):
                    check_grammar_rows(lesson, n, step['content']['sentences'])
                    ok(step['content']['explanation'].get('patterns'), lesson, n, '패턴 없음')
            elif t == 'practice':
                check_practice(lesson, n, step, kiwi)
            elif t == 'agglutinative_quiz':
                check_quiz(lesson, n, step)
                check_vocab(lesson, n, step['contentObj']['sentence'], kiwi)
            elif t == 'completion':
                ok(step['content'].get('text') and step['content'].get('highlights'), lesson, n, '완료 문구')
        # 학습자 화면에 나오는 영어 문구에 이모지·예외 문구 없음
        ok('Exception' not in raw, lesson, 0, '예외 문구')

    order += check_fix_patch()
    order += check_pilot(kiwi)
    print(f"검사 {sum(checks.values())}건, 오류 {len(errors)}건")
    for k in order:
        print(f"  {k}: {checks[k]}건")
    for e in errors:
        print("  ERROR", e)
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
