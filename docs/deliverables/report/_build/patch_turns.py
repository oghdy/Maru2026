s = open('build_report.py', encoding='utf8').read()
def R(old, new, count=1):
    global s
    n = s.count(old); assert n == count, (n, old[:70])
    s = s.replace(old, new)
# 1) 4.3.3 본문(1학기 원문) — 3-Zone 문단 앞부분의 용어
R("d.replace('이로써 대화가 늘어지거나 흐지부지 끝나지 않고, 목표 달성 시점에 명확히 종료된다.',",
  "d.replace('미션의 최소 턴 수(mission_min_turns)를', '미션의 기준 턴 수(mission_min_turns, 목표 대화 길이)를')\n"
  "d.replace('이로써 대화가 늘어지거나 흐지부지 끝나지 않고, 목표 달성 시점에 명확히 종료된다.',")
# 2) 프롬프트 구성표
R("최소 턴은 난이도별 범위 안에서 지정", "목표 대화 길이(기준 턴)는 난이도별 범위 안에서 지정")
# 3) 난이도 표 행
R("['최소 턴 (minTurns, 서버가 범위로 고정)', '3~4', '4~6', '5~10'],", "['목표 대화 길이(기준 턴)', '3~4턴 안팎', '4~6턴 안팎', '5~10턴 안팎'],")
# 4) 난이도 표 아래 설명
R("\"최대 턴 규칙(maxTurns = minTurns + 3)과 3-Zone 판정은 모든 난이도에서 같다. ",
  "\"목표 대화 길이는 반드시 채워야 하는 턴 수가 아니라 대화 분량의 기준이다. 목표를 이루면 기준 턴 무렵에 마무리되고, 기준 +3턴 안에 반드시 종료된다(3-Zone 규칙은 모든 난이도에서 같다). ")
# 5) 운영 스모크 테스트
R("미션 생성 API의 기본 난이도(easy)·최소 턴 응답 확인", "미션 생성 API의 기본 난이도(easy)·기준 턴 응답 확인")
# 스크린샷 키트(최신 디자인)로 교체
K = "REPO + '/docs/deliverables/screenshots"
R("(S + '/mission/screenshots/MSN-1.7.6_after_2_chat.png', None), (S + '/mission/screenshots/MSN-1.7.3_red_card.png', None)]),",
  "(" + K + "/04b_mission_chat_yellow_card.png', None), (" + K + "/04a_mission_chat_red_card.png', None)]),")
R("d.IMGS([(S + '/lesson/screenshots/r3_LSN-1.7.1_after.png', None), (S + '/character/screenshots/apply_lesson_C1.png', None), (S + '/character/screenshots/apply_lesson_C3.png', None)]),",
  "d.IMGS([(S + '/lesson/screenshots/r3_LSN-1.7.1_after.png', None), (" + K + "/07_lesson_morpheme_turtle.png', None), (" + K + "/08_lesson_complete.png', None)]),")
open('build_report.py', 'w', encoding='utf8').write(s)
print('ok')
