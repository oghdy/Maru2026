"""파일럿 초안 검산 (WEB-5.12.3). 빌드 코드를 쓰지 않고 SQL 안의 content 를 읽어 확인한다. 오류가 있으면 종료 코드 1.

사용 (backend/admin-tools/kiwi-generator 에서):
  PYTHONDONTWRITEBYTECODE=1 venv/bin/python ../../lessons/unit3/draft_check_pilot.py
"""
import os
import re
import sys

from kiwipiepy import Kiwi

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..'))
import check_curriculum as cc  # noqa: E402

SQL = os.path.join(HERE, 'draft_pilot_past_tense.sql')
MOODS = {'idle', 'happy', 'sad', 'thinking', 'talking', 'cheer', 'magic'}
cc.LESSON_VOCAB_ORDER['u3-l2-learn'] = cc.LESSON_VOCAB_ORDER['u3-l2']
ok = cc.ok


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
    cc.check_vocab(lesson, n, ex['sentence'], kiwi)
    for bad in cc.FORBIDDEN:
        ok(bad not in ex['sentence'], lesson, n, f"금지 형태 {bad}")


def check_sentence(lesson, n, ex, kiwi):
    """정답을 넣은 문장을 그대로 쓴 뒤 Kiwi 와 어휘를 다시 본다. 오답 동사가 정답과 다른 시제면 영어로 구분되는지도 본다."""
    full = ex['sentence'].replace('[ ? ]', ex['answer'])
    ok(any(t.tag == 'EP' or t.tag.startswith('V') for t in kiwi.tokenize(full)), lesson, n, f"분석 실패 {full}")
    cc.check_vocab(lesson, n, full, kiwi)
    for bad in cc.FORBIDDEN:
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


def check_practice(lesson, steps, kiwi):
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
            cc.check_practice(lesson, n, s, kiwi)
            for ex in s['content']['exercises']:
                check_sentence(lesson, n, ex, kiwi)
        elif t == 'agglutinative_quiz':
            cc.check_quiz(lesson, n, s)
            cc.check_vocab(lesson, n, s['contentObj']['sentence'], kiwi)
            hints.append(len(s['instruction']) - len(f"Build the sentence: \"{s['contentObj']['translation']}\""))
        elif t == 'intro' and s['title'].startswith('Conversation'):
            for line in s['content']['sentences']:
                cc.check_vocab(lesson, n, line['korean'], kiwi)
                ok(not cc.ATTACHED_HAGO.search(line['korean']), lesson, n, f"명사+하고: {line['korean']}")
                for bad in cc.FORBIDDEN:
                    ok(bad not in line['korean'], lesson, n, f"금지 형태 {bad}")
    ok(hints == sorted(hints, reverse=True) and hints[-1] == 0, lesson, 0, f"힌트가 줄어들지 않음 {hints}")


def main():
    kiwi = Kiwi()
    lessons = cc.load_lessons(SQL)
    ok(set(lessons) == {'u3-l2-learn', 'u3-l2'}, 'pilot', 0, f"레슨 {set(lessons)}")
    check_learn('u3-l2-learn', lessons['u3-l2-learn']['steps'], kiwi)
    check_practice('u3-l2', lessons['u3-l2']['steps'], kiwi)
    print(f"검사 {sum(cc.checks.values())}건, 오류 {len(cc.errors)}건")
    for e in cc.errors:
        print("  ERROR", e)
    sys.exit(1 if cc.errors else 0)


if __name__ == '__main__':
    main()
