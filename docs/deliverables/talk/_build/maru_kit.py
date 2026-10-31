"""MARU 발표자료 디자인 키트 (DLV-4.7.1) — 전 장 공통 규칙.
16:9 (13.333 x 7.5 in) · 글꼴 맑은 고딕 한 종류 · 레이아웃 4종(표지/섹션 구분/본문/마무리).
"""
import os
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE, MSO_CONNECTOR
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.oxml.ns import qn
from lxml import etree
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
SHOTS = os.path.join(DOCS, 'deliverables', 'screenshots')
CHAR = os.path.join(DOCS, 'features', 'character', 'raw')
IMG = os.path.join(HERE, 'img')
os.makedirs(IMG, exist_ok=True)

FONT = '맑은 고딕'
PURPLE, PURPLE2, NAVY, LILAC = '6B4EFF', '7D63FF', '2B1D5C', 'F0EDFF'
YELLOW, MINT, PINK = 'FFC83D', '4CD4B0', 'FF8FB1'
MINT_D, PINK_D, YELLOW_D = '1E9E7E', 'E0457B', 'B07A00'
MINT_BG, PINK_BG, YELLOW_BG = 'E3F8F2', 'FFE9F0', 'FFF4D6'
INK, GREY, WHITE = '1F1A3D', '6E6A80', 'FFFFFF'
SECTIONS = ['문제', '해결', '기술', '시연', '기대효과']
W, H = 13.333, 7.5
MX = 0.6            # 좌우 여백
PHONE_H = 4.2       # 본문 폰 화면 높이(전 장 공통)
L, C, R_ = PP_ALIGN.LEFT, PP_ALIGN.CENTER, PP_ALIGN.RIGHT
TOP, MID = MSO_ANCHOR.TOP, MSO_ANCHOR.MIDDLE


def rgb(h):
    return RGBColor.from_string(h)


def new_deck():
    prs = Presentation()
    prs.slide_width, prs.slide_height = Inches(W), Inches(H)
    prs.part._element.set('embedTrueTypeFonts', '1')
    prs.part._element.set('saveSubsetFonts', '1')
    # 테마 글꼴도 맑은 고딕으로
    for rel in prs.slide_masters[0].part.rels.values():
        if rel.reltype.endswith('/theme'):
            blob = rel.target_part.blob.decode('utf-8')
            import re
            blob = re.sub(r'<a:latin typeface="[^"]*"', '<a:latin typeface="%s"' % FONT, blob)
            blob = re.sub(r'<a:ea typeface="[^"]*"', '<a:ea typeface="%s"' % FONT, blob)
            rel.target_part._blob = blob.encode('utf-8')
    return prs


def _font(run, size, bold=False, color=INK):
    f = run.font
    f.size, f.bold, f.name = Pt(size), bold, FONT
    f.color.rgb = rgb(color)
    rPr = run._r.get_or_add_rPr()
    for tag in ('a:ea', 'a:cs'):
        el = rPr.find(qn(tag))
        if el is None:
            el = etree.SubElement(rPr, qn(tag))
        el.set('typeface', FONT)


def text(slide, x, y, w, h, paras, size=16, bold=False, color=INK, align=L, anchor=TOP, spacing=None, line=None):
    """paras: str | [str | [(text, {size,bold,color})]]"""
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tb.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    if isinstance(paras, str):
        paras = [paras]
    for i, p in enumerate(paras):
        para = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        para.alignment = align
        if spacing is not None:
            para.space_after = Pt(spacing)
        if line:
            para.line_spacing = line
        for t, o in ([(p, {})] if isinstance(p, str) else p):
            r = para.add_run()
            r.text = t
            _font(r, o.get('size', size), o.get('bold', bold), o.get('color', color))
    return tb


def box(slide, x, y, w, h, fill=LILAC, radius=0.1, shape=MSO_SHAPE.ROUNDED_RECTANGLE, line=None, lw=1.5, dash=False, alpha=None):
    s = slide.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    if shape == MSO_SHAPE.ROUNDED_RECTANGLE:
        s.adjustments[0] = radius
    if fill:
        s.fill.solid()
        s.fill.fore_color.rgb = rgb(fill)
        if alpha is not None:
            sf = s.fill._xPr.find(qn('a:solidFill'))[0]
            a = etree.SubElement(sf, qn('a:alpha')); a.set('val', str(int(alpha * 1000)))
    else:
        s.fill.background()
    if line:
        s.line.color.rgb = rgb(line)
        s.line.width = Pt(lw)
        if dash:
            s.line.dash_style = 4
    else:
        s.line.fill.background()
    s.shadow.inherit = False
    return s


def pill(slide, x, y, w, h, t, fill=PURPLE, color=WHITE, size=12, bold=True):
    box(slide, x, y, w, h, fill=fill, radius=0.5)
    return text(slide, x, y, w, h, t, size=size, bold=bold, color=color, align=C, anchor=MID)


def circle_label(slide, x, y, d, t, fill=PURPLE, color=WHITE, size=16):
    box(slide, x, y, d, d, fill=fill, shape=MSO_SHAPE.OVAL)
    text(slide, x, y, d, d, t, size=size, bold=True, color=color, align=C, anchor=MID)


def _prep(path, max_px):
    """원본을 줄여 _build/img 에 캐시(파일 크기 관리)."""
    name = os.path.splitext(os.path.basename(path))[0]
    png = path.lower().endswith('.png') and Image.open(path).mode == 'RGBA'
    out = os.path.join(IMG, f'{name}_{max_px}.' + ('png' if png else 'jpg'))
    if not os.path.exists(out):
        im = Image.open(path)
        if png:
            im = im.crop(im.getbbox())
        else:
            im = im.convert('RGB')
        im.thumbnail((max_px, max_px), Image.LANCZOS)
        im.save(out, optimize=True, quality=90)
    return out


def char(slide, name, x, y, h, px=700):
    p = _prep(os.path.join(CHAR, name + '.png'), px)
    im = Image.open(p)
    return slide.shapes.add_picture(p, Inches(x), Inches(y), width=Inches(h * im.width / im.height), height=Inches(h))


def phone(slide, shot, cx, y, h=PHONE_H):
    """폰 프레임 규칙: 남색 둥근 테두리(0.07in) + 둥근 화면. cx = 가운데 x."""
    p = _prep(os.path.join(SHOTS, shot), 1300)
    im = Image.open(p)
    w = h * im.width / im.height
    pad = 0.07
    box(slide, cx - w / 2 - pad, y - pad, w + 2 * pad, h + 2 * pad, fill=NAVY, radius=0.11)
    pic = slide.shapes.add_picture(p, Inches(cx - w / 2), Inches(y), width=Inches(w), height=Inches(h))
    geom = pic._element.spPr.find(qn('a:prstGeom'))
    geom.set('prst', 'roundRect')
    av = geom.find(qn('a:avLst'))
    if av is None:
        av = etree.SubElement(geom, qn('a:avLst'))
    gd = etree.SubElement(av, qn('a:gd')); gd.set('name', 'adj'); gd.set('fmla', 'val 8500')
    return w


def arrow(slide, x1, y1, x2, y2, color=NAVY, both=False, w=2.0):
    c = slide.shapes.add_connector(MSO_CONNECTOR.STRAIGHT, Inches(x1), Inches(y1), Inches(x2), Inches(y2))
    c.line.color.rgb = rgb(color)
    c.line.width = Pt(w)
    ln = c.line._get_or_add_ln()
    head = etree.SubElement(ln, qn('a:headEnd')); head.set('type', 'triangle' if both else 'none')
    tail = etree.SubElement(ln, qn('a:tailEnd')); tail.set('type', 'triangle')
    return c


def _blank(prs):
    return prs.slides.add_slide(prs.slide_layouts[6])


def _purple_bg(s):
    box(s, 0, 0, W, H, fill=PURPLE, shape=MSO_SHAPE.RECTANGLE)
    box(s, 7.2, -2.6, 8.5, 8.5, fill=PURPLE2, shape=MSO_SHAPE.OVAL)
    box(s, -2.2, 4.4, 5.2, 5.2, fill='5F43EE', shape=MSO_SHAPE.OVAL)


def stepper(s, section, y=0.38, dark=False):
    """섹션 표시: 문제 → 해결 → 기술 → 시연 → 기대효과 (현재 섹션만 채움)."""
    x = MX
    for name in SECTIONS:
        w = 0.62 + 0.14 * len(name)
        on = name == section
        if dark:
            pill(s, x, y, w, 0.3, name, fill=WHITE if on else '5F43EE', color=PURPLE if on else 'CFC6FF', size=10.5)
        else:
            pill(s, x, y, w, 0.3, name, fill=PURPLE if on else LILAC, color=WHITE if on else '9A93B8', size=10.5)
        x += w + 0.12


def footer(s, n, dark=False):
    col = 'CFC6FF' if dark else '9A93B8'
    text(s, MX, 7.0, 6, 0.3, 'MARU · 외국인을 위한 한국어 학습 앱', size=10, color=col, anchor=MID)
    text(s, W - MX - 1, 7.0, 1, 0.3, f'{n:02d}', size=11, bold=True, color=col, align=R_, anchor=MID)


# ------------------------------------------------------------ 레이아웃 4종
def cover(prs):
    s = _blank(prs)
    _purple_bg(s)
    return s


def section(prs, name, n):
    s = _blank(prs)
    _purple_bg(s)
    stepper(s, name, dark=True)
    footer(s, n, dark=True)
    return s


def content(prs, section_name, title, n, lead=None):
    s = _blank(prs)
    stepper(s, section_name)
    text(s, MX, 0.86, W - 2 * MX, 0.7, title, size=30, bold=True, color=NAVY, anchor=MID)
    if lead:
        text(s, MX, 1.58, W - 2 * MX, 0.4, lead, size=16, color=GREY, anchor=MID)
    footer(s, n)
    return s


def closing(prs, n=None):
    s = _blank(prs)
    _purple_bg(s)
    if n:
        footer(s, n, dark=True)
    return s


def finish(prs, notes, out):
    for sl, nt in zip(prs.slides, notes):
        sl.notes_slide.notes_text_frame.text = nt
    pe = prs.part._element
    if notes and pe.find(qn('p:notesMasterIdLst')) is None:
        rid = next(r.rId for r in prs.part.rels.values() if r.reltype.endswith('/notesMaster'))
        el = etree.Element(qn('p:notesMasterIdLst'))
        nm = etree.SubElement(el, qn('p:notesMasterId')); nm.set(qn('r:id'), rid)
        pe.find(qn('p:sldMasterIdLst')).addnext(el)
    prs.save(out)
