"""MARU 발표자료 장별 내용 (DLV-4.7.1). 각 함수 = 슬라이드 1장."""
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE, XL_LABEL_POSITION
from pptx.util import Inches, Pt
from maru_kit import *


def s_cover(prs, n):
    s = cover(prs)
    pill(s, MX, 0.6, 1.75, 0.42, 'TEAM  MARU', fill=WHITE, color=PURPLE, size=14)
    text(s, MX + 1.95, 0.6, 7, 0.42, [[('팀원 ', {'color': 'E6E0FF'}), ('하도윤', {'bold': True}), ('  컴퓨터공학과 20200679', {'color': 'E6E0FF', 'size': 13})]],
         size=16, color=WHITE, anchor=MID)
    text(s, MX, 1.12, 7, 0.35, '2026년 졸업작품 · 지도교수 한경수 교수', size=13, color='E6E0FF', anchor=MID)
    text(s, MX - 0.05, 1.75, 8, 2.2, 'MARU', size=138, bold=True, color=WHITE, anchor=MID)
    text(s, MX, 4.05, 8, 0.5, [[('마루', {'bold': True, 'color': YELLOW}), (' · 외국인을 위한 한국어 학습 앱', {})]], size=22, color=WHITE, anchor=MID)
    text(s, MX, 4.95, 8, 1.3,
         [[('토끼처럼 ', {}), ('빠르게 체험', {'bold': True, 'color': YELLOW}), ('하고,', {})],
          [('거북이처럼 ', {}), ('천천히 이해', {'bold': True, 'color': MINT}), ('한다.', {})]],
         size=26, color=WHITE, spacing=4)
    char(s, 'rabbit_cheer', 7.35, 2.15, 4.6)
    char(s, 'turtle_happy', 10.25, 3.05, 3.9)
    return s


def s_demand(prs, n):
    s = content(prs, '문제', '한국어를 배우려는 사람이 늘고 있다', n)
    # 왼쪽: K-컬처
    box(s, MX, 2.0, 5.75, 4.75, fill=LILAC, radius=0.06)
    text(s, MX + 0.35, 2.2, 5, 0.45, 'K-컬처의 세계적 확산', size=20, bold=True, color=NAVY, anchor=MID)
    text(s, MX + 0.35, 2.68, 5.1, 0.4, '콘텐츠를 즐기다가, 언어를 배우고 싶어진다', size=14, color=GREY, anchor=MID)
    chips = [('K-POP', PURPLE), ('드라마 · 영화', PINK_D), ('웹툰', MINT_D), ('K-푸드', YELLOW_D), ('K-뷰티', '8A5BD6')]
    pos = [(0.35, 3.35, 1.55), (2.05, 3.35, 2.1), (0.35, 4.05, 1.3), (1.8, 4.05, 1.45), (0.35, 4.75, 1.45)]
    for (t, col), (dx, y, w) in zip(chips, pos):
        pill(s, MX + dx, y, w, 0.5, t, fill=WHITE, color=col, size=15)
    char(s, 'rabbit_happy', MX + 3.55, 3.9, 2.75)
    # 오른쪽: 시장 규모 (원본 그래프를 같은 스타일로 다시 그림)
    box(s, 6.65, 2.0, 6.08, 4.75, fill=LILAC, radius=0.06)
    text(s, 7.0, 2.2, 5.4, 0.45, '한국어 학습 시장 규모 전망', size=20, bold=True, color=NAVY, anchor=MID)
    text(s, 7.0, 2.68, 5.4, 0.4, '2034년 670억 달러 — 연평균 25.1% 성장 (단위: 달러)', size=14, color=GREY, anchor=MID)
    cd = CategoryChartData()
    cd.categories = ['2024', '2034']
    cd.add_series('억 달러', (72, 670))
    gf = s.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, Inches(7.0), Inches(3.15), Inches(3.4), Inches(3.05), cd)
    ch = gf.chart
    ch.has_legend = False
    ch.has_title = False
    ch.font.name = FONT
    ch.font.size = Pt(13)
    ch.font.color.rgb = rgb(NAVY)
    va = ch.value_axis
    va.visible = False
    va.has_major_gridlines = False
    va.maximum_scale = 800
    ca = ch.category_axis
    ca.format.line.fill.background()
    ca.tick_labels.font.size = Pt(14)
    ca.tick_labels.font.bold = True
    plot = ch.plots[0]
    plot.gap_width = 70
    plot.has_data_labels = True
    dl = plot.data_labels
    dl.position = XL_LABEL_POSITION.OUTSIDE_END
    dl.font.size = Pt(15)
    dl.font.bold = True
    dl.number_format = '#,##0"억"'
    dl.number_format_is_linked = False
    ser = plot.series[0]
    for i, col in enumerate(['B9ABFF', PURPLE]):
        pt = ser.points[i]
        pt.format.fill.solid()
        pt.format.fill.fore_color.rgb = rgb(col)
    text(s, 10.45, 3.55, 2.1, 0.9, '약 9배', size=40, bold=True, color=PURPLE, align=C, anchor=MID)
    text(s, 10.45, 4.45, 2.1, 0.7, ['10년 사이', '시장 규모'], size=14, color=GREY, align=C)
    text(s, 7.0, 6.3, 5.5, 0.3, '출처: Research and Markets (2024), Korean Language Learning Market Report', size=10, color=GREY, anchor=MID)
    return s


def _phone_col(s, shot, cx, num, cap, y=2.05):
    phone(s, shot, cx, y)
    circle_label(s, cx - 0.95, y + PHONE_H + 0.22, 0.34, str(num), size=12)
    text(s, cx - 0.52, y + PHONE_H + 0.2, 1.75, 0.4, cap, size=13, bold=True, color=NAVY, anchor=MID)


def _fact(s, x, y, w, head, body, col=PURPLE, bg=LILAC, h=0.98):
    box(s, x, y, w, h, fill=bg, radius=0.16)
    text(s, x + 0.25, y + 0.1, w - 0.5, 0.38, head, size=15, bold=True, color=col, anchor=MID)
    text(s, x + 0.25, y + 0.48, w - 0.5, h - 0.55, body, size=12.5, color=INK, anchor=TOP)


def s_mission(prs, n):
    s = content(prs, '해결', [[('R', {'color': PINK_D}), ('oleplay 미션 — 토끼와 대화하고, 거북이가 코칭한다', {})]], n)
    _phone_col(s, '02_mission_setup_difficulty.png', 1.75, 1, '난이도 선택')
    _phone_col(s, '04a_mission_chat_red_card.png', 4.15, 2, '레드카드 교정')
    _phone_col(s, '06_mission_certificate_cleared.png', 6.55, 3, '클리어 판정')
    x, w = 8.0, 4.73
    _fact(s, x, 2.0, w, '토끼가 역할로 변신', '카페 직원·친구 등 상황 속 상대가 되어 한국어로 대화한다', PURPLE, LILAC)
    _fact(s, x, 3.1, w, '난이도 3단계 · 기본 Easy', '초급자는 짧은 대화부터 — Easy 는 3~4턴 안팎, 토끼 답은 한 문장', PINK_D, PINK_BG)
    _fact(s, x, 4.2, w, '거북이의 레드 · 옐로카드', '큰 실수는 레드카드, 작은 실수는 옐로카드 — 대화는 계속된다', MINT_D, MINT_BG)
    _fact(s, x, 5.3, w, 'AI 코치의 클리어 판정', '목표를 이루면 클리어, 못 이루면 재도전 권유. 피드백은 항상 제공', YELLOW_D, YELLOW_BG)
    return s


# ================================================================ 공통 블록
def feature(prs, n, title, shots, facts, extra=None):
    """기능 소개 장 공통: 왼쪽 폰 화면(번호+캡션), 오른쪽 사실 카드 4개."""
    s = content(prs, '해결', title, n)
    for i, (shot, cap) in enumerate(shots):
        _phone_col(s, shot, 1.75 + 2.4 * i, i + 1, cap)
    x = MX + 2.4 * len(shots) + 0.2
    w = W - MX - x
    pal = [(PURPLE, LILAC), (PINK_D, PINK_BG), (MINT_D, MINT_BG), (YELLOW_D, YELLOW_BG)]
    for i, (head, body) in enumerate(facts):
        _fact(s, x, 2.0 + 1.1 * i, w, head, body, *pal[i])
    if extra:
        extra(s)
    return s


def tok(s, x, y, t, col, w=None, size=22):
    w = w or (0.34 + 0.3 * len(t))
    box(s, x, y, w, 0.62, fill=col, radius=0.3)
    text(s, x, y, w, 0.62, t, size=size, bold=True, color=WHITE, align=C, anchor=MID)
    return x + w


SUBJ, OBJ, VERB, PART = '3D7BFF', 'F0506E', '1E9E7E', '8A5BD6'


# ================================================================ 문제
def s_agglutinative(prs, n):
    s = content(prs, '문제', "한국어는 '붙여서' 만드는 언어다", n)
    box(s, MX, 2.0, 5.9, 3.3, fill=LILAC, radius=0.07)
    text(s, MX + 0.35, 2.2, 5.2, 0.45, '영어 — 단어의 순서로 뜻을 만든다', size=18, bold=True, color=NAVY, anchor=MID)
    x = MX + 0.45
    for t, col, w in [('I', SUBJ, 0.7), ('study', VERB, 1.55), ('Korean', OBJ, 1.75)]:
        x = tok(s, x, 3.2, t, col, w) + 0.18
    text(s, MX + 0.35, 4.3, 5.2, 0.6, '주어 → 동사 → 목적어, 자리가 역할을 정한다', size=14, color=GREY, anchor=MID)

    box(s, 6.83, 2.0, 5.9, 3.3, fill=LILAC, radius=0.07)
    text(s, 7.18, 2.2, 5.2, 0.45, '한국어 — 조사·어미를 붙여 뜻을 만든다', size=18, bold=True, color=NAVY, anchor=MID)
    x = 7.2
    for word, wcol, ww, part, pw in [('나', SUBJ, 0.65, '는', 0.6), ('한국어', OBJ, 1.25, '를', 0.6)]:
        x = tok(s, x, 3.2, word, wcol, ww) + 0.04
        x = tok(s, x, 3.2, part, PART, pw) + 0.22
    tok(s, x, 3.2, '공부한다', VERB, 1.6)
    text(s, 7.18, 4.3, 5.3, 0.6, "'는'·'를'이 붙어야 누가, 무엇을 하는지 정해진다", size=14, color=GREY, anchor=MID)

    lx = MX + 0.2
    for t, col in [('주어', SUBJ), ('목적어', OBJ), ('동사', VERB), ('조사', PART)]:
        box(s, lx, 5.62, 0.24, 0.24, fill=col, shape=MSO_SHAPE.OVAL)
        text(s, lx + 0.33, 5.54, 0.9, 0.4, t, size=13, color=GREY, anchor=MID)
        lx += 1.25
    box(s, MX, 6.1, W - 2 * MX, 0.68, fill=NAVY, radius=0.4)
    text(s, MX, 6.1, W - 2 * MX, 0.68, '교착어 — 단어만 외워서는 문장을 만들 수 없다', size=18, bold=True, color=WHITE, align=C, anchor=MID)
    return s


def s_fsi(prs, n):
    s = content(prs, '문제', '영어권 학습자에게 가장 오래 걸리는 언어', n)
    box(s, MX, 2.0, 9.2, 4.75, fill=LILAC, radius=0.06)
    rows = [('프랑스어 · 이탈리아어 · 스페인어', 600), ('독일어', 750), ('인도네시아어 · 스와힐리어', 900),
            ('그리스어 · 러시아어 · 베트남어', 1100), ('한국어 · 일본어 · 중국어', 2200)]
    for i, (lang, hrs) in enumerate(rows):
        y = 2.3 + i * 0.84
        last = i == 4
        text(s, MX + 0.3, y, 0.95, 0.56, f'LEVEL {i + 1}', size=11, bold=True, color=PURPLE if last else '9A93B8', anchor=MID)
        text(s, MX + 1.25, y, 2.9, 0.56, lang, size=13.5, bold=last, color=NAVY if last else INK, anchor=MID)
        bw = 3.5 * hrs / 2200
        box(s, MX + 4.2, y + 0.08, bw, 0.4, fill=PURPLE if last else 'C9BFFF', radius=0.5)
        text(s, MX + 4.2 + bw + 0.15, y, 1.4, 0.56, f'{hrs:,}시간', size=15 if last else 13, bold=last, color=PURPLE if last else GREY, anchor=MID)
    text(s, MX + 0.3, 6.38, 8.6, 0.3, '출처: 미국 외교관 연수기관(FSI) 언어 난이도 분류 — 비정상회담 169화(JTBC, 2017. 10. 9)', size=10, color=GREY, anchor=MID)
    box(s, 10.05, 2.0, 2.68, 4.75, fill=NAVY, radius=0.1)
    text(s, 10.05, 2.35, 2.68, 0.9, '2,200', size=44, bold=True, color=YELLOW, align=C, anchor=MID)
    text(s, 10.05, 3.2, 2.68, 0.4, '시간', size=18, bold=True, color=WHITE, align=C, anchor=MID)
    text(s, 10.3, 3.75, 2.18, 0.9, ['프랑스어의', '약 3.7배'], size=14, color='CFC6FF', align=C)
    char(s, 'turtle_thinking', 10.6, 4.75, 1.75)
    return s


def s_existing(prs, n):
    s = content(prs, '문제', '기존 학습 앱은 고르고 외우는 문제가 중심이다', n)
    cards = [('듣고 고르기', ['에', '애', '아', '이'], 1), ('뜻 고르기', ['학교', '병원', '집', '회사'], 0), ('단어 블록 고르기', ['저는', '학생', '입니다', '은'], 2)]
    for i, (head, opts, pick) in enumerate(cards):
        x = MX + i * 2.78
        box(s, x, 2.0, 2.58, 3.75, fill=LILAC, radius=0.08)
        text(s, x, 2.15, 2.58, 0.45, head, size=16, bold=True, color=NAVY, align=C, anchor=MID)
        box(s, x + 0.94, 2.72, 0.7, 0.7, fill=PURPLE if i == 0 else WHITE, shape=MSO_SHAPE.OVAL)
        text(s, x + 0.94, 2.72, 0.7, 0.7, ['♪', 'A', '?'][i], size=20, bold=True, color=WHITE if i == 0 else PURPLE, align=C, anchor=MID)
        for k, o in enumerate(opts):
            ox, oy = x + 0.25 + (k % 2) * 1.07, 3.65 + (k // 2) * 0.9
            on = k == pick
            box(s, ox, oy, 1.0, 0.74, fill=MINT if on else WHITE, radius=0.2)
            text(s, ox, oy, 1.0, 0.74, o, size=15, bold=True, color=WHITE if on else INK, align=C, anchor=MID)
    box(s, 9.1, 2.0, 3.63, 3.75, fill=NAVY, radius=0.08)
    text(s, 9.4, 2.3, 3.05, 1.9, ['고르면 끝.', '문장을 직접', '만들어 보지 않는다'], size=20, bold=True, color=WHITE, spacing=4)
    char(s, 'rabbit_sad', 10.5, 3.95, 1.75)
    box(s, MX, 6.05, W - 2 * MX, 0.72, fill=PINK_BG, radius=0.4)
    text(s, MX, 6.05, W - 2 * MX, 0.72, [[('암기·객관식만으로는 ', {}), ('문장이 어떻게 조립되는지', {'bold': True, 'color': PINK_D}), (' 체험하기 어렵다', {})]],
         size=18, color=INK, align=C, anchor=MID)
    return s


# ================================================================ 해결
def s_overview(prs, n):
    s = content(prs, '해결', 'MARU 는 한국어의 구조를 체험하는 앱이다', n)
    phone(s, '01_home.png', 1.75, 2.05, 4.55)
    items = [('M', 'Morpheme 레슨', '덩어리로 조립하고, 레슨 목표 문법만 쪼갠다', YELLOW, NAVY),
             ('A', 'Adaptive 단어', 'FSRS-4.5 로 잊기 전에 복습한다', MINT, WHITE),
             ('R', 'Roleplay 미션', '토끼와 역할극으로 대화하고, 거북이가 코칭한다', PINK, WHITE),
             ('U', 'Upgrade 실험실', '한글과 문장을 직접 조합하고 바꿔 본다', PURPLE, WHITE)]
    for i, (lt, name, line, col, fg) in enumerate(items):
        x = 3.45 + (i % 2) * 4.72
        y = 2.0 + (i // 2) * 2.4
        box(s, x, y, 4.52, 2.2, fill=LILAC, radius=0.1)
        circle_label(s, x + 0.3, y + 0.3, 0.75, lt, fill=col, color=fg, size=26)
        text(s, x + 1.25, y + 0.3, 3.1, 0.75, name, size=21, bold=True, color=NAVY, anchor=MID)
        text(s, x + 0.32, y + 1.25, 3.9, 0.8, line, size=14.5, color=INK)
    return s


def s_lesson(prs, n):
    return feature(prs, n, [[('M', {'color': YELLOW_D}), ('orpheme 레슨 — 덩어리로 조립하고, 목표 문법만 쪼갠다', {})]],
                   [('07_lesson_morpheme_turtle.png', '목표 문법 분해'), ('08_lesson_complete.png', '레슨 완료')],
                   [('토끼 단계 — 덩어리로 조립', '의미 덩어리 블록을 끌어다 문장을 먼저 만들어 본다'),
                    ('거북이 단계 — 목표 문법만 분해', "예) 을/를 레슨 — '저는'·'좋아해요'는 통째로, '커피를'만 커피 + 를 로 나눈다"),
                    ('Kiwi 콘텐츠 파이프라인', 'CSV(문장 + 목표 품사) → 조립 문제·탭 분석 데이터 → 멱등 SQL 패치로 DB 반영'),
                    ('한글 12레슨 + 문법 3레슨', '점수는 첫 시도 정답률, 별은 점수 기준. 중간부터 이어서 학습')])


def s_vocab(prs, n):
    return feature(prs, n, [[('A', {'color': MINT_D}), ('daptive 단어 — 잊기 전에 다시 만난다', {})]],
                   [('09_vocab_card_rating.png', '평가와 다음 간격'), ('10_vocab_match_complete.png', '짝맞추기')],
                   [('FSRS-4.5 표준 공식', '단어별 안정성·난이도·인출가능성을 계산해 다음 복습일을 정한다'),
                    ('오늘의 복습', '복습 기한이 된 단어만 나온다. 평가 버튼에 다음 간격 미리보기(Again 5m · Good 4d)'),
                    ('5,561단어 · 14개 주제 덱', '국립국어원 학습용 어휘 기반, 30단어 레슨. 번역·예문은 AI(Gemini) 생성'),
                    ('짝맞추기 게임', '라운드당 5쌍 — 뜻과 단어를 맞히며 가볍게 복습한다')])


def s_mission(prs, n):
    return feature(prs, n, [[('R', {'color': PINK_D}), ('oleplay 미션 — 토끼와 대화하고, 거북이가 코칭한다', {})]],
                   [('02_mission_setup_difficulty.png', '난이도 선택'), ('04a_mission_chat_red_card.png', '레드카드 교정'),
                    ('06_mission_certificate_cleared.png', '클리어 판정')],
                   [('토끼가 역할로 변신', '카페 직원·친구 등 상황 속 상대가 되어 한국어로 대화한다'),
                    ('난이도 3단계 · 기본 Easy', '초급자는 짧은 대화부터 — Easy 는 3~4턴 안팎, 토끼 답은 한 문장'),
                    ('거북이의 레드 · 옐로카드', '큰 실수는 레드카드, 작은 실수는 옐로카드 — 대화는 계속된다'),
                    ('AI 코치의 클리어 판정', '목표를 이루면 클리어, 못 이루면 재도전 권유. 피드백은 항상 제공')])


def s_lab(prs, n):
    def extra(s):
        char(s, 'rabbit_lab_happy', 10.55, 0.42, 1.25)
        char(s, 'turtle_lab_idle', 11.65, 0.42, 1.25)
    return feature(prs, n, [[('U', {'color': PURPLE}), ('pgrade 실험실 — 글자와 문장을 직접 실험한다', {})]],
                   [('11_lab_menu.png', '실험실 메뉴'), ('12_lab_hangeul.png', '한글랩'), ('14_lab_sentence_result.png', 'Sentence Lab')],
                   [('한글랩', '자음·모음·받침을 골라 글자를 조합하고 소리를 듣는다'),
                    ('Sentence Lab · Explore', '시제·높임·부정·감정 중 하나를 골라 문장 변형 3개를 본다'),
                    ('Sentence Lab · Combine', '여러 수식어를 한 문장에 조합한다. 분석 중엔 "거북이 실험 중"'),
                    ('AI(Gemini) 기반 + DB 캐시', '같은 요청은 캐시로 1~2ms 에 응답, 새 요청은 3~5초')], extra)


def s_characters(prs, n):
    s = content(prs, '해결', '토끼와 거북이 — 다른 걸음, 같은 길', n)
    for i, (nm, role, line, img, col, bg) in enumerate([
            ('토끼', '빠른 체험 · 연기', '덩어리로 먼저 조립해 보고, 미션에서는 대화 상대로 변신한다', 'rabbit_cheer', PURPLE, LILAC),
            ('거북이', '느린 분석 · 코칭', '목표 문법을 쪼개 보여 주고, 틀리면 힌트와 레드·옐로카드를 준다', 'turtle_thinking', MINT_D, MINT_BG)]):
        x = MX + i * 6.17
        box(s, x, 2.0, 5.97, 2.75, fill=bg, radius=0.08)
        char(s, img, x + 0.25, 2.2, 2.35)
        text(s, x + 2.75, 2.3, 3.0, 0.55, nm, size=26, bold=True, color=col, anchor=MID)
        text(s, x + 2.75, 2.85, 3.0, 0.45, role, size=17, bold=True, color=NAVY, anchor=MID)
        text(s, x + 2.75, 3.4, 2.95, 1.2, line, size=14, color=INK)
    box(s, MX, 4.95, W - 2 * MX, 1.82, fill='F7F5FF', radius=0.1)
    faces = ['rabbit_idle', 'rabbit_happy', 'rabbit_thinking', 'rabbit_magic', 'turtle_idle', 'turtle_happy', 'turtle_talking', 'turtle_lab_idle']
    for i, f in enumerate(faces):
        char(s, f, MX + 0.3 + i * 0.83, 5.2, 0.8, px=300)
    text(s, 7.75, 5.1, 4.8, 0.75, [[('정답·오답·완료·대기·교정', {'bold': True, 'color': PURPLE}), ('에 실시간 반응', {})],
                                    [('4개 기능 21개 화면 지점 + 홈', {'bold': True})]], size=15, color=INK, spacing=2)
    text(s, MX + 0.3, 6.15, 11.5, 0.5, '표정은 이미지(21장), 몸짓은 코드 모션(숨쉬기·깜빡임·점프·찌그러짐)으로 분리 — 그림을 바꿔도 기능 코드 수정 0줄',
         size=12.5, color=GREY, anchor=MID)
    return s


# ================================================================ 기술
def s_arch(prs, n):
    s = content(prs, '기술', '시스템 구성', n)
    # 앱
    box(s, MX, 2.0, 3.0, 3.25, fill=LILAC, radius=0.08)
    text(s, MX + 0.25, 2.12, 2.6, 0.4, 'Flutter 앱', size=19, bold=True, color=PURPLE, anchor=MID)
    text(s, MX + 0.25, 2.52, 2.6, 0.3, 'iOS · Android 단일 코드', size=11.5, color=GREY, anchor=MID)
    for k, t in enumerate(['레슨 · 단어 · 미션 · 실험실', '토끼 · 거북이 캐릭터', 'Google · Apple 로그인', '발음 재생 (서버 TTS)']):
        pill(s, MX + 0.2, 2.98 + k * 0.54, 2.6, 0.42, t, fill=WHITE, color=NAVY, size=11.5, bold=False)
    # 서버
    box(s, 4.5, 2.0, 4.35, 3.25, fill=NAVY, radius=0.06)
    text(s, 4.75, 2.12, 3.9, 0.4, 'Spring Boot 3.5 · Java 17', size=18, bold=True, color=WHITE, anchor=MID)
    text(s, 4.75, 2.52, 3.9, 0.3, 'Railway 운영 배포', size=11.5, color='C9C2F5', anchor=MID)
    mods = [('인증', 'Google·Apple 토큰 검증 → JWT'), ('레슨·진도', '점수 · 별 · 이어하기'), ('FSRS-4.5', '다음 복습일 계산'),
            ('미션', '난이도 · 3-Zone 판정 · 병렬 호출'), ('캐시', 'AI 응답 · TTS 음성')]
    for k, (a, b) in enumerate(mods):
        y = 2.95 + k * 0.44
        box(s, 4.7, y, 3.95, 0.37, fill='3B2C78', radius=0.3)
        text(s, 4.85, y, 1.05, 0.37, a, size=11.5, bold=True, color=YELLOW, anchor=MID)
        text(s, 5.9, y, 2.7, 0.37, b, size=11.5, color=WHITE, anchor=MID)
    # 외부 AI / DB
    box(s, 9.75, 2.0, 2.98, 1.5, fill=YELLOW_BG, radius=0.12)
    text(s, 9.95, 2.08, 2.6, 0.38, '외부 AI', size=17, bold=True, color=YELLOW_D, anchor=MID)
    text(s, 9.95, 2.48, 2.7, 1.0, [[('OpenAI GPT-4o', {'bold': True}), (' 미션 대화·채점', {})],
                                    [('gpt-4o-mini-tts', {'bold': True}), (' 발음', {})],
                                    [('Gemini 2.5 Flash', {'bold': True}), (' 문장 변형', {})]], size=10.5, color=INK, spacing=2)
    box(s, 9.75, 3.7, 2.98, 1.55, fill=MINT_BG, radius=0.12)
    text(s, 9.95, 3.78, 2.6, 0.38, 'PostgreSQL', size=17, bold=True, color=MINT_D, anchor=MID)
    text(s, 9.95, 4.2, 2.7, 1.0, ['레슨 데이터 (JSONB)', '단어 5,561 · FSRS 기록', 'AI · TTS 캐시'], size=11, color=INK, spacing=2)
    # 연결
    arrow(s, 3.62, 3.6, 4.48, 3.6, both=True)
    text(s, 3.55, 3.05, 1.0, 0.5, ['HTTPS', 'JWT'], size=9.5, bold=True, color=NAVY, align=C)
    arrow(s, 8.87, 2.75, 9.73, 2.75, both=True)
    arrow(s, 8.87, 4.45, 9.73, 4.45, both=True)
    # 파이프라인
    box(s, MX, 5.45, W - 2 * MX, 1.35, fill=None, line=PURPLE, radius=0.1, dash=True)
    text(s, MX + 0.22, 5.52, 4, 0.32, '오프라인 콘텐츠 파이프라인', size=13, bold=True, color=PURPLE, anchor=MID)
    text(s, 4.9, 5.52, 5.3, 0.32, '단어: 국립국어원 학습용 어휘 → Gemini 번역·예문 → DB', size=10, color=GREY, align=R_, anchor=MID)
    steps = ['CSV 문장 + 목표 품사', 'Kiwi 형태소 분석', '조립 문제 · 탭 분석 JSON', '멱등 SQL 패치', 'DB 반영']
    sw = 2.08
    for k, t in enumerate(steps):
        x = MX + 0.2 + k * (sw + 0.33)
        pill(s, x, 5.98, sw, 0.62, t, fill=LILAC if k < 4 else MINT_D, color=NAVY if k < 4 else WHITE, size=11.5)
        if k < 4:
            arrow(s, x + sw + 0.04, 6.29, x + sw + 0.29, 6.29, color=PURPLE, w=1.5)
    arrow(s, 11.45, 5.95, 11.45, 5.28, color=MINT_D, w=2.25)
    return s


def s_quality(prs, n):
    s = content(prs, '기술', '완성도와 검증', n)
    tiles = [('1.5~2초', '미션 한 턴', ['연기·채점 병렬 호출', '순차 호출 대비 30~50% 단축'], PURPLE, LILAC),
             ('1~2ms', 'AI 캐시 HIT', ['같은 요청은 DB 캐시로 응답', '새 요청(Gemini)은 3~5초'], MINT_D, MINT_BG),
             ('135 · 83', '자동 테스트 통과', ['서버 135개', '앱 83개'], PINK_D, PINK_BG),
             ('Railway', '운영 배포', ['운영 서버에 배포', 'iPhone 실기기에서 동작'], YELLOW_D, YELLOW_BG)]
    tw = 2.88
    for i, (big, lab, sub, col, bg) in enumerate(tiles):
        x = MX + i * (tw + 0.2)
        box(s, x, 2.0, tw, 3.3, fill=bg, radius=0.09)
        text(s, x, 2.3, tw, 0.95, big, size=38, bold=True, color=col, align=C, anchor=MID)
        text(s, x, 3.3, tw, 0.45, lab, size=17, bold=True, color=NAVY, align=C, anchor=MID)
        text(s, x + 0.15, 3.95, tw - 0.3, 1.1, sub, size=12.5, color=GREY, align=C, spacing=2)
    box(s, MX, 5.55, W - 2 * MX, 1.2, fill=NAVY, radius=0.3)
    char(s, 'turtle_happy', MX + 0.35, 5.62, 1.06, px=300)
    char(s, 'rabbit_happy', MX + 1.35, 5.62, 1.06, px=300)
    text(s, MX + 2.7, 5.55, 9, 1.2, [[('사용자 검증', {'bold': True, 'color': YELLOW, 'size': 15})],
                                      [('실제로 써 보며 4차례 다듬었다', {'bold': True, 'size': 22})]], color=WHITE, anchor=MID, spacing=2)
    return s


# ================================================================ 시연
def s_demo(prs, n):
    s = section(prs, '시연', n)
    char(s, 'rabbit_magic', 0.7, 2.35, 3.6)
    char(s, 'turtle_happy', 9.85, 2.6, 3.3)
    text(s, 3.6, 1.35, 6.13, 1.5, 'DEMO', size=96, bold=True, color=WHITE, align=C, anchor=MID)
    text(s, 3.6, 2.9, 6.13, 0.5, '시연 — iPhone 실기기 · 운영 서버', size=20, bold=True, color=WHITE, align=C, anchor=MID)
    steps = [('1  홈', '0:30'), ('2  레슨', '1:00'), ('3  단어', '0:45'), ('4  미션 Easy', '1:00'), ('5  Sentence Lab', '0:45'), ('6  마무리', '0:30')]
    for k, (a, b) in enumerate(steps):
        x = 4.25 + (k % 3) * 1.65
        y = 3.75 + (k // 3) * 0.95
        box(s, x, y, 1.53, 0.8, fill=WHITE, radius=0.5)
        text(s, x, y, 1.53, 0.8, [[(a, {'bold': True, 'size': 12.5})], [(b, {'size': 11})]], color=PURPLE, align=C, anchor=MID)
    return s


# ================================================================ 기대효과 · 마무리
def s_effects(prs, n):
    s = content(prs, '기대효과', '기대효과', n)
    cards = [('학습자', PURPLE, LILAC, 'rabbit_happy',
              ['외우는 대신 조립하며 한국어의 구조를 익힌다', '잊기 전에 복습해 오래 기억한다', '목적과 끝이 있는 대화로 말하기를 연습한다']),
             ('콘텐츠', MINT_D, MINT_BG, 'turtle_thinking',
              ['CSV 한 줄(문장 + 목표 품사)로 문법 레슨이 만들어진다', '어휘 파이프라인으로 단어 데이터를 넓힌다', '멱등 SQL 패치로 운영 DB 에 안전하게 반영한다']),
             ('기술', PINK_D, PINK_BG, 'turtle_cheer',
              ['AI 캐시·병렬 호출로 응답 속도와 호출 비용을 줄인다', '캐릭터 그림과 모션을 분리해 교체가 쉽다', '자동 테스트(서버 135 · 앱 83)가 동작을 지킨다'])]
    cw = 3.91
    for k, (h, col, bg, img, items) in enumerate(cards):
        x = MX + k * (cw + 0.2)
        box(s, x, 2.0, cw, 4.75, fill=bg, radius=0.07)
        char(s, img, x + 0.3, 2.2, 1.05, px=300)
        text(s, x + 1.5, 2.2, 2.2, 1.05, h, size=24, bold=True, color=col, anchor=MID)
        for j, it in enumerate(items):
            y = 3.6 + j * 1.02
            box(s, x + 0.35, y + 0.1, 0.18, 0.18, fill=col, shape=MSO_SHAPE.OVAL)
            text(s, x + 0.7, y, cw - 1.0, 0.9, it, size=14.5, color=INK)
    return s


def s_name(prs, n):
    s = content(prs, '기대효과', "'마루'라는 이름", n)
    defs = [('마루', '¹', '등성이를 이루는 지붕이나 산 따위의 꼭대기', '오르는 곳', '학습자가 저마다의 정상에 오른다', 'rabbit_cheer', PURPLE, LILAC),
            ('마루', '³', '집채 안에 바닥과 사이를 띄우고 깐 널빤지. 또는 그 널빤지를 깔아 놓은 곳', '모이는 곳', '둘러앉는 마루처럼, 함께 모인다', 'turtle_happy', MINT_D, MINT_BG)]
    for i, (w, sup, d, head, line, img, col, bg) in enumerate(defs):
        x = MX + i * 6.17
        box(s, x, 2.0, 5.97, 3.55, fill=bg, radius=0.08)
        text(s, x + 0.4, 2.2, 3.4, 0.6, [[(w, {'bold': True, 'size': 28, 'color': col}), (sup, {'size': 18, 'color': col}), ('  명사', {'size': 12, 'color': GREY})]], anchor=MID)
        text(s, x + 0.4, 2.9, 3.55, 0.9, d, size=12, color=GREY)
        text(s, x + 0.4, 3.95, 3.4, 0.5, head, size=24, bold=True, color=NAVY, anchor=MID)
        text(s, x + 0.4, 4.5, 3.55, 0.8, line, size=14, color=INK)
        char(s, img, x + 3.95, 2.85, 2.2)
    text(s, MX, 5.62, 8, 0.3, '뜻풀이 출처: 국립국어원 표준국어대사전', size=10, color=GREY, anchor=MID)
    box(s, MX, 6.03, W - 2 * MX, 0.74, fill=NAVY, radius=0.4)
    text(s, MX, 6.03, W - 2 * MX, 0.74, [[('MARU', {'color': YELLOW}), (' 는 한국어를 배우는 사람이 오르고, 모이는 자리다', {})]], size=19, bold=True, color=WHITE, align=C, anchor=MID)
    return s


def s_thanks(prs, n):
    s = closing(prs)
    text(s, MX, 2.1, 7.5, 1.3, '감사합니다', size=66, bold=True, color=WHITE, anchor=MID)
    text(s, MX, 3.55, 7.5, 0.5, [[('MARU', {'bold': True, 'color': YELLOW}), (' · 외국인을 위한 한국어 학습 앱', {})]], size=22, color=WHITE, anchor=MID)
    text(s, MX, 4.35, 7.5, 0.8, ['컴퓨터공학과 20200679 하도윤', '지도교수 한경수 교수'], size=15, color='E6E0FF', spacing=3)
    char(s, 'rabbit_cheer', 7.35, 2.15, 4.6)
    char(s, 'turtle_happy', 10.25, 3.05, 3.9)
    return s


# ---- 3장·16장 (10-03 하도윤 수정 요청 반영: 굴절어 3개 언어 비교 / '마루' 세 가지 뜻)
def _tok(s, x, y, t, col, w, h=0.5, size=17):
    box(s, x, y, w, h, fill=col, radius=0.3)
    text(s, x, y, w, h, t, size=size, bold=True, color=WHITE, align=C, anchor=MID)
    return x + w


def s_agglutinative(prs, n):
    s = content(prs, '문제', "한국어는 어순이 다르고, 조사를 '붙여서' 만든다", n)
    # 왼쪽: 굴절어 3개 언어
    box(s, MX, 2.0, 5.9, 3.55, fill=LILAC, radius=0.07)
    text(s, MX + 0.35, 2.15, 5.3, 0.45, '굴절어 — 단어의 순서로 뜻을 만든다', size=18, bold=True, color=NAVY, anchor=MID)
    rows = [('영어', [('I', SUBJ, 0.6), ('study', VERB, 1.2), ('Korean', OBJ, 1.35)]),
            ('스페인어', [('Yo', SUBJ, 0.6), ('estudio', VERB, 1.2), ('coreano', OBJ, 1.35)]),
            ('프랑스어', [("J'", SUBJ, 0.6), ('étudie', VERB, 1.2), ('le coréen', OBJ, 1.35)])]
    for i, (lang, toks) in enumerate(rows):
        y = 2.8 + i * 0.64
        text(s, MX + 0.35, y, 1.1, 0.5, lang, size=13, bold=True, color=GREY, anchor=MID)
        x = MX + 1.55
        for t, col, w in toks:
            x = _tok(s, x, y, t, col, w) + 0.12
    text(s, MX + 0.35, 4.85, 5.3, 0.5, [[('주어 → 동사 → 목적어', {'bold': True, 'color': NAVY}), ('   자리가 역할을 정한다', {})]], size=14, color=GREY, anchor=MID)
    # 오른쪽: 한국어
    box(s, 6.83, 2.0, 5.9, 3.55, fill=NAVY, radius=0.07)
    text(s, 7.18, 2.15, 5.3, 0.45, '한국어 — 교착어', size=18, bold=True, color=WHITE, anchor=MID)
    x = 7.2
    for word, wcol, ww, part in [('나', SUBJ, 0.7, '는'), ('한국어', OBJ, 1.3, '를')]:
        x = _tok(s, x, 2.85, word, wcol, ww, h=0.62, size=21) + 0.04
        x = _tok(s, x, 2.85, part, YELLOW_D, 0.62, h=0.62, size=21) + 0.2
    _tok(s, x, 2.85, '공부한다', VERB, 1.6, h=0.62, size=21)
    for i, (num, head, line) in enumerate([('1', '어순이 다르다', '주어 → 목적어 → 동사, 동사가 맨 끝에 온다'),
                                           ('2', '조사가 붙는다', "'는'·'를'이 붙어야 누가, 무엇을 하는지 정해진다")]):
        y = 3.8 + i * 0.82
        circle_label(s, 7.2, y + 0.06, 0.42, num, fill=YELLOW, color=NAVY, size=14)
        text(s, 7.8, y, 4.7, 0.32, head, size=15.5, bold=True, color=WHITE, anchor=MID)
        text(s, 7.8, y + 0.33, 4.75, 0.3, line, size=12.5, color='CFC6FF', anchor=MID)
    lx = MX + 0.2
    for t, col in [('주어', SUBJ), ('동사', VERB), ('목적어', OBJ), ('조사', YELLOW_D)]:
        box(s, lx, 5.8, 0.22, 0.22, fill=col, shape=MSO_SHAPE.OVAL)
        text(s, lx + 0.31, 5.71, 0.9, 0.4, t, size=12.5, color=GREY, anchor=MID)
        lx += 1.2
    box(s, MX, 6.2, W - 2 * MX, 0.6, fill=PINK_BG, radius=0.45)
    text(s, MX, 6.2, W - 2 * MX, 0.6, [[('굴절어 화자에게는 ', {}), ('어순도, 조사도', {'bold': True, 'color': PINK_D}), (' 낯설다 — 단어만 외워서는 문장을 만들 수 없다', {})]],
         size=16, color=INK, align=C, anchor=MID)
    return s


def s_name(prs, n):
    s = content(prs, '기대효과', "'마루'에는 세 가지 뜻이 있다", n)
    defs = [('¹', '등성이를 이루는 지붕이나 산 따위의 꼭대기.', '오르는 곳', '저마다의 정상에 오른다', 'rabbit_cheer', PURPLE, LILAC),
            ('²', '어떤 사물의 첫째. 또는 어떤 일의 기준.', '기준이 되는 것', '구조를 학습의 기준으로 삼는다', 'turtle_thinking', PINK_D, PINK_BG),
            ('³', '집채 안에 바닥과 사이를 띄우고 깐 널빤지. 또는 그 널빤지를 깔아 놓은 곳.', '모이는 곳', '마루에 둘러앉듯 함께 배운다', 'turtle_happy', MINT_D, MINT_BG)]
    cw = 3.91
    for i, (sup, d, head, line, img, col, bg) in enumerate(defs):
        x = MX + i * (cw + 0.2)
        box(s, x, 2.0, cw, 3.65, fill=bg, radius=0.08)
        text(s, x + 0.35, 2.2, 2.3, 0.7, [[('마루', {'bold': True, 'size': 32, 'color': col}), (sup, {'bold': True, 'size': 22, 'color': col})]], anchor=MID)
        text(s, x + 0.35, 2.9, 2.1, 0.3, '명사', size=11, color=GREY, anchor=MID)
        char(s, img, x + cw - 1.55, 2.15, 1.3, px=400)
        text(s, x + 0.35, 3.55, cw - 0.6, 0.7, d, size=11, color=GREY)
        text(s, x + 0.35, 4.3, cw - 0.7, 0.5, head, size=24, bold=True, color=NAVY, anchor=MID)
        text(s, x + 0.35, 4.88, cw - 0.6, 0.6, line, size=15, color=INK)
    text(s, MX, 5.72, 8, 0.28, '뜻풀이 출처: 국립국어원 표준국어대사전', size=10, color=GREY, anchor=MID)
    box(s, MX, 6.08, W - 2 * MX, 0.72, fill=NAVY, radius=0.4)
    text(s, MX, 6.08, W - 2 * MX, 0.72, [[('MARU', {'color': YELLOW}), (' — 오르고, 기준을 세우고, 모이는 자리', {})]], size=20, bold=True, color=WHITE, align=C, anchor=MID)
    return s


DECK = [
    (s_cover, '표지', '0:08', "안녕하세요. 외국인을 위한 한국어 학습 앱, 마루를 만든 컴퓨터공학과 하도윤입니다."),
    (s_demand, '한국어를 배우려는 사람이 늘고 있다', '0:18', "K-팝과 드라마, 웹툰 같은 한국 콘텐츠가 세계로 퍼지면서 한국어를 배우려는 사람이 빠르게 늘고 있습니다. 한국어 학습 시장은 2024년 72억 달러에서 2034년 670억 달러까지 커질 것으로 전망됩니다."),
    (s_agglutinative, "한국어는 어순이 다르고, 조사를 '붙여서' 만든다", '0:20', "그런데 한국어는 쉽지 않습니다. 영어, 스페인어, 프랑스어는 주어, 동사, 목적어 순서로 단어를 놓아 뜻을 만듭니다. 한국어는 동사가 맨 끝에 오고, '나는', '한국어를'처럼 조사를 붙여야 역할이 정해집니다. 어순도 조사도 낯설어서, 단어만 외워서는 문장을 만들 수 없습니다."),
    (s_fsi, '영어권 학습자에게 가장 오래 걸리는 언어', '0:10', "미국 외교관 연수기관 FSI는 한국어를 영어권 학습자에게 가장 오래 걸리는 등급, 2,200시간으로 분류합니다."),
    (s_existing, '기존 학습 앱은 고르고 외우는 문제가 중심이다', '0:12', "하지만 기존 학습 앱은 듣고 고르거나 뜻을 맞히는 객관식 문제가 중심입니다. 한국어 문장이 어떻게 조립되는지 직접 체험하기는 어렵습니다."),
    (s_overview, 'MARU 는 한국어의 구조를 체험하는 앱이다', '0:12', "마루는 한국어의 구조를 직접 체험하는 앱입니다. 이름의 네 글자, M, A, R, U가 곧 네 가지 기능입니다."),
    (s_lesson, 'Morpheme 레슨', '0:18', "M, 형태소 레슨입니다. 토끼 단계에서 의미 덩어리로 문장을 조립하고, 거북이 단계에서는 그 레슨의 목표 문법만 형태소로 쪼갭니다. '커피를'만 '커피'와 '를'로 나뉘고, 나머지는 통째로 둡니다."),
    (s_vocab, 'Adaptive 단어', '0:13', "A, 단어장입니다. FSRS-4.5 표준 공식으로 단어마다 다음 복습일을 계산하고, 오늘의 복습에는 기한이 된 단어만 나옵니다."),
    (s_mission, 'Roleplay 미션', '0:22', "R, 미션 대화입니다. 토끼가 카페 직원 같은 역할로 변신해 대화 상대가 됩니다. 난이도는 세 단계이고, 초급자는 기본값인 Easy로 서너 턴 안팎의 짧은 대화부터 시작합니다. 실수하면 거북이가 레드카드나 옐로카드로 바로잡고, 끝나면 AI 코치가 목표 달성 여부를 판정합니다."),
    (s_lab, 'Upgrade 실험실', '0:13', "U, 실험실입니다. 한글랩에서 자모를 조합해 글자를 만들고, Sentence Lab에서는 AI가 문장의 시제나 높임을 바꿔 보여 줍니다."),
    (s_characters, '토끼와 거북이', '0:12', "이 모든 화면에 토끼와 거북이가 함께합니다. 토끼는 빠른 체험, 거북이는 느린 분석을 맡아, 정답과 오답, 완료 순간마다 반응합니다."),
    (s_arch, '시스템 구성', '0:23', "시스템 구성입니다. 앱은 Flutter, 서버는 Spring Boot, 데이터는 PostgreSQL이고 Railway에서 운영합니다. 미션 대화와 발음은 OpenAI, 문장 변형은 Gemini를 쓰며, 같은 요청은 DB 캐시로 바로 응답합니다. 레슨의 조립 문제는 Kiwi 형태소 분석기로 미리 만들어 SQL 패치로 반영합니다."),
    (s_quality, '완성도와 검증', '0:20', "완성도입니다. 미션은 연기와 채점을 병렬로 호출해 한 턴에 약 1.5초에서 2초, 캐시된 요청은 1~2밀리초에 응답합니다. 서버 135개, 앱 83개의 자동 테스트를 통과했고, 운영 서버에 배포해 실제 iPhone에서 동작합니다. 그리고 실제로 써 보며 네 차례 다듬었습니다."),
    (s_demo, 'DEMO (시연 구분)', '0:02', "그럼 실제 iPhone 화면으로 보여 드리겠습니다."),
    (s_effects, '기대효과', '0:20', "마루의 기대효과입니다. 학습자는 외우는 대신 조립하며 한국어의 구조를 익히고, 잊기 전에 복습하고, 목적과 끝이 있는 대화로 말하기를 연습합니다. 문법 레슨은 CSV 한 줄로 만들어지고, AI 캐시와 병렬 호출이 응답 속도를 지킵니다."),
    (s_name, "'마루'에는 세 가지 뜻이 있다", '0:18', "마루에는 세 가지 뜻이 있습니다. 산의 꼭대기, 어떤 일의 기준, 그리고 사람들이 모여 앉는 자리입니다. 마루는 학습자가 저마다의 정상에 오르고, 한국어의 구조를 기준으로 배우고, 함께 모이는 자리입니다."),
    (s_thanks, '감사합니다', '0:04', "감사합니다."),
]
