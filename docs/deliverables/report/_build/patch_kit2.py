s = open('build_report.py', encoding='utf8').read()
def B(start, end, new):
    global s
    assert s.count(start) == 1, (s.count(start), start[:70])
    a = s.index(start); b = s.index(end, a); s = s[:a] + new + s[b + len(end):]
K = "REPO + '/docs/deliverables/screenshots"
B("    H(2, '5.1 홈 화면과 학습 통계'),", "    H(2, '5.3 Vocabulary System — FSRS 간격 반복 단어 학습'),\n", f'''    H(2, '5.1 로그인, 홈 화면, 학습 통계'),
    P("앱을 실행하면 Google 또는 Apple 계정으로 로그인한다. 홈에서는 토끼와 거북이가 인사하고, 연속 학습일(스트릭)과 별, 오늘 복습할 단어 수, 네 가지 기능 카드가 표시된다. "
      "복습할 단어가 없으면 All caught up 카드로 바뀐다. Stats 탭은 연속 학습일·별·완료 레슨 수·학습 시간을 보여준다."),
    d.IMGS([({K}/00_login.png', None), (SH + '/01_home.png', None), (S + '/lab/screenshots/r5/after_5_home_lab_subtitle.png', None), (SH + '/02_stats.png', None)], height_in=3.3),
    CAP('[그림 5-1] 로그인(Google·Apple), 홈 화면(복습할 단어가 있을 때 / 없을 때), 학습 통계', center=True),
    H(2, '5.2 Korean Lesson — 한글 레슨과 형태소 조립'),
    P("레슨은 유닛별로 구성된다. Unit 0은 한글 12레슨, Unit 1은 문법 3레슨이며, 레슨 목록에는 완료 표시와 점수에 따른 별이 나타난다. 한글 레슨은 자모 카드와 발음 듣기, 듣기 퀴즈로 진행한다."),
    d.IMGS([(SH + '/03_units.png', None), ({K}/15_lesson_list_stars.png', None), (SH + '/05_hangeul_card.png', None)]),
    CAP('[그림 5-2] 유닛 선택, 문법 레슨 목록(완료 표시·별), 한글 자모 카드', center=True),
    P("문법 레슨은 예문 소개에서 시작한다. 예문의 어절을 탭하면 그 어절을 이루는 형태소와 뜻이 Grammar Analysis 패널에 나타난다(Tap-to-Translate). 예를 들어 \\"커피를\\"을 탭하면 "
      "커피 = coffee, 를 = object marker로 나뉘어 보인다. 이어지는 패턴 연습에서는 받침 유무에 따라 을/를 중 맞는 형태를 고르고, 토끼가 이유와 함께 정답 여부를 알려준다."),
    d.IMGS([({K}/16_lesson_tap_analysis.png', None), ({K}/17_lesson_pattern_practice.png', None)]),
    CAP('[그림 5-3] 탭 분석(커피를 → 커피 + 를), 패턴 연습(을/를 고르기와 토끼 피드백)', center=True),
    P("조립 문제는 같은 유형의 문장을 두 단계로 조립한다. 🐰 Chunk 단계에서는 의미 덩어리(어절) 블록으로 문장을 조립하고, 🐢 Morpheme 단계에서는 그 레슨의 목표 문법만 형태소로 분리된 블록으로 다시 조립한다. "
      "목표가 아닌 어절은 회색 고정 블록으로 유지되고, 오답이면 거북이가 힌트를 준다. 그림 5-4는 이 \\"덩어리 → 목표 문법만 분해\\" 흐름을 나란히 보여준다. 완료 화면은 학습한 내용을 정리한다."),
    d.IMGS([({K}/18_lesson_chunk_rabbit.png', None), ({K}/07_lesson_morpheme_turtle.png', None), ({K}/08_lesson_complete.png', None)]),
    CAP('[그림 5-4] 🐰 Chunk 단계(저는 / 커피를 / 좋아해요 덩어리 조립) → 🐢 Morpheme 단계(목표 문법 이에요/예요만 분해, 다른 레슨의 문장) → 레슨 완료', center=True),
    H(2, '5.3 Vocabulary System — FSRS 간격 반복 단어 학습'),
''')
open('build_report.py', 'w', encoding='utf8').write(s)
print('ok')
