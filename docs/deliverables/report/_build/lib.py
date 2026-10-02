"""docx(document.xml) 편집 도우미 — 1학기 보고서 서식을 그대로 복제해 쓴다."""
import re, os, shutil, copy
from xml.sax.saxutils import escape
from lxml import etree
from PIL import Image

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
R = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
NS = {'w': W, 'r': R,
      'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
      'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
      'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture',
      'w14': 'http://schemas.microsoft.com/office/word/2010/wordml'}
WRAP = '<root ' + ' '.join(f'xmlns:{k}="{v}"' for k, v in NS.items()) + '>%s</root>'


def q(tag):
    p, t = tag.split(':')
    return '{%s}%s' % (NS[p], t)


def frag(xml):
    root = etree.fromstring(WRAP % xml)
    return list(root)


def norm(s):
    return re.sub(r'[ \t\u00a0]+', ' ', s)


def text(el):
    return ''.join(t.text or '' for t in el.iter(q('w:t')))


# ---------- runs ----------
def runs_xml(s, rpr=''):
    """**굵게** 표기 지원"""
    out = []
    for i, part in enumerate(re.split(r'\*\*', s)):
        if not part:
            continue
        b = '<w:b/><w:bCs/>' if i % 2 else ''
        out.append(f'<w:r><w:rPr>{b}{rpr}</w:rPr><w:t xml:space="preserve">{escape(part)}</w:t></w:r>')
    return ''.join(out)


# ---------- blocks ----------
def H(level, s, page_break=False):
    pb = '<w:pageBreakBefore/>' if page_break else ''
    return frag(f'<w:p><w:pPr><w:pStyle w:val="{level}"/>{pb}<w:rPr><w:b/><w:bCs/></w:rPr></w:pPr>'
                f'<w:r><w:rPr><w:b/><w:bCs/></w:rPr><w:t xml:space="preserve">{escape(s)}</w:t></w:r></w:p>')[0]


def P(s):
    return frag('<w:p><w:pPr><w:spacing w:after="160" w:line="320" w:lineRule="auto"/><w:jc w:val="both"/></w:pPr>'
                + runs_xml(s) + '</w:p>')[0]


def BUL(s):
    rpr = '<w:rFonts w:asciiTheme="minorHAnsi" w:eastAsiaTheme="minorHAnsi" w:hAnsiTheme="minorHAnsi"/><w:sz w:val="20"/><w:szCs w:val="20"/>'
    return frag('<w:p><w:pPr><w:pStyle w:val="ab"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="3"/></w:numPr>'
                '<w:spacing w:after="60" w:line="300" w:lineRule="auto"/></w:pPr>' + runs_xml(s, rpr) + '</w:p>')[0]


CAP_RPR = '<w:i/><w:iCs/><w:color w:val="595959"/><w:sz w:val="18"/><w:szCs w:val="18"/>'


def CAP(s, center=False):
    jc = '<w:jc w:val="center"/>' if center else ''
    return frag(f'<w:p><w:pPr><w:spacing w:before="60" w:after="180"/>{jc}</w:pPr>'
                f'<w:r><w:rPr>{CAP_RPR}</w:rPr><w:t xml:space="preserve">{escape(s)}</w:t></w:r></w:p>')[0]


def _cell(s, w, header=False):
    fill = '1F3864' if header else 'FFFFFF'
    mar = 70 if header else 60
    rpr = '<w:color w:val="FFFFFF"/><w:sz w:val="19"/><w:szCs w:val="19"/>' if header else '<w:sz w:val="19"/><w:szCs w:val="19"/>'
    b = '<w:b/><w:bCs/>' if header else ''
    paras = ''.join(
        f'<w:p><w:pPr><w:spacing w:after="0" w:line="260" w:lineRule="auto"/></w:pPr>'
        + (runs_xml(line, b + rpr) if not header else
           f'<w:r><w:rPr>{b}{rpr}</w:rPr><w:t xml:space="preserve">{escape(line)}</w:t></w:r>') + '</w:p>'
        for line in str(s).split('\n'))
    bd = ''.join(f'<w:{k} w:val="single" w:sz="1" w:space="0" w:color="BFBFBF"/>' for k in ('top', 'left', 'bottom', 'right'))
    return (f'<w:tc><w:tcPr><w:tcW w:w="{w}" w:type="dxa"/><w:tcBorders>{bd}</w:tcBorders>'
            f'<w:shd w:val="clear" w:color="auto" w:fill="{fill}"/><w:tcMar><w:top w:w="{mar}" w:type="dxa"/>'
            f'<w:left w:w="110" w:type="dxa"/><w:bottom w:w="{mar}" w:type="dxa"/><w:right w:w="110" w:type="dxa"/></w:tcMar>'
            f'</w:tcPr>{paras}</w:tc>')


def TABLE(headers, rows, widths):
    tot = sum(widths)
    widths = [round(w * 9360 / tot) for w in widths]
    widths[-1] += 9360 - sum(widths)
    bd = ''.join(f'<w:{k} w:val="single" w:sz="4" w:space="0" w:color="auto"/>' for k in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'))
    x = (f'<w:tbl><w:tblPr><w:tblW w:w="9360" w:type="dxa"/><w:tblBorders>{bd}</w:tblBorders>'
         '<w:tblLayout w:type="fixed"/><w:tblCellMar><w:left w:w="10" w:type="dxa"/><w:right w:w="10" w:type="dxa"/></w:tblCellMar>'
         '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/></w:tblPr><w:tblGrid>'
         + ''.join(f'<w:gridCol w:w="{w}"/>' for w in widths) + '</w:tblGrid>')
    x += '<w:tr><w:trPr><w:tblHeader/><w:cantSplit/></w:trPr>' + ''.join(_cell(h, w, True) for h, w in zip(headers, widths)) + '</w:tr>'
    for r in rows:
        x += '<w:tr><w:trPr><w:cantSplit/></w:trPr>' + ''.join(_cell(c, w) for c, w in zip(r, widths)) + '</w:tr>'
    x += '</w:tbl>'
    return frag(x)[0]


def CODE(code):
    bd = ''.join(f'<w:{k} w:val="single" w:sz="4" w:space="0" w:color="2E75B6"/>' for k in ('top', 'left', 'bottom', 'right'))
    rpr = '<w:rFonts w:ascii="Consolas" w:eastAsia="Consolas" w:hAnsi="Consolas" w:cs="Consolas"/><w:sz w:val="17"/><w:szCs w:val="17"/>'
    paras = ''.join(f'<w:p><w:pPr><w:spacing w:after="0" w:line="252" w:lineRule="auto"/></w:pPr>'
                    f'<w:r><w:rPr>{rpr}</w:rPr><w:t xml:space="preserve">{escape(l)}</w:t></w:r></w:p>'
                    for l in code.strip('\n').split('\n'))
    x = ('<w:tbl><w:tblPr><w:tblW w:w="9360" w:type="dxa"/><w:tblLayout w:type="fixed"/>'
         '<w:tblLook w:val="0000" w:firstRow="0" w:lastRow="0" w:firstColumn="0" w:lastColumn="0" w:noHBand="0" w:noVBand="0"/></w:tblPr>'
         '<w:tblGrid><w:gridCol w:w="9360"/></w:tblGrid><w:tr><w:tc><w:tcPr><w:tcW w:w="9360" w:type="dxa"/>'
         f'<w:tcBorders>{bd}</w:tcBorders><w:shd w:val="clear" w:color="auto" w:fill="F4F5F7"/>'
         '<w:tcMar><w:top w:w="120" w:type="dxa"/><w:left w:w="160" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/><w:right w:w="160" w:type="dxa"/></w:tcMar>'
         f'</w:tcPr>{paras}</w:tc></w:tr></w:tbl>')
    return frag(x)[0]


class Doc:
    def __init__(self, folder):
        self.folder = folder
        self.path = os.path.join(folder, 'word/document.xml')
        self.tree = etree.parse(self.path)
        self.body = self.tree.getroot().find(q('w:body'))
        self.rels_path = os.path.join(folder, 'word/_rels/document.xml.rels')
        self.rels = etree.parse(self.rels_path)
        self.img_id = 900000000

    # ----- find -----
    def find(self, s, nth=0, scope=None):
        hits = [p for p in (scope if scope is not None else self.body).iter(q('w:p')) if norm(s) in norm(text(p))]
        if not hits:
            raise KeyError('not found: ' + s)
        if len(hits) > 1 and nth == 0 and os.environ.get('STRICT'):
            print('WARN multiple', s, len(hits))
        return hits[nth]

    def block(self, el):
        """본문 직계 자식(표 안 단락이면 그 표)"""
        while el.getparent() is not self.body:
            el = el.getparent()
        return el

    def table_after(self, s):
        el = self.block(self.find(s))
        n = el.getnext()
        while n.tag != q('w:tbl'):
            n = n.getnext()
        return n

    def table_with(self, s):
        return self.block(self.find(s))

    # ----- edit -----
    def set_text(self, p, s):
        rs = p.findall(q('w:r'))
        rpr = None
        for r in rs:
            if r.find(q('w:t')) is not None:
                rpr = r.find(q('w:rPr'))
                break
        for r in list(p):
            if r.tag in (q('w:r'), q('w:hyperlink'), q('w:bookmarkStart'), q('w:bookmarkEnd'), q('w:proofErr')):
                p.remove(r)
        r = etree.SubElement(p, q('w:r'))
        if rpr is not None:
            r.append(copy.deepcopy(rpr))
        t = etree.SubElement(r, q('w:t'))
        t.text = s
        t.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')

    def replace(self, old, new, nth=0):
        p = self.find(old, nth)
        assert norm(old) in norm(text(p))
        self.set_text(p, norm(text(p)).replace(norm(old), new))
        return p

    def set_para(self, startswith, new):
        p = self.find(startswith)
        self.set_text(p, new)
        return p

    def insert_after(self, anchor, els):
        anchor = self.block(anchor)
        for e in els:
            anchor.addnext(e)
            anchor = e
        return anchor

    def insert_before(self, anchor, els):
        anchor = self.block(anchor)
        for e in els:
            anchor.addprevious(e)
        return els[-1]

    def remove(self, el):
        el = self.block(el)
        self.body.remove(el)

    # ----- images -----
    def add_image(self, src, max_w_px=700, crop=None):
        im = Image.open(src).convert('RGB')
        if crop:
            im = im.crop(crop)
        if im.width > max_w_px:
            im = im.resize((max_w_px, round(im.height * max_w_px / im.width)), Image.LANCZOS)
        self.img_id += 1
        name = f'v2_{self.img_id}.jpg'
        im.save(os.path.join(self.folder, 'word/media', name), 'JPEG', quality=86)
        rid = f'rIdV2{self.img_id}'
        root = self.rels.getroot()
        e = etree.SubElement(root, '{http://schemas.openxmlformats.org/package/2006/relationships}Relationship')
        e.set('Id', rid)
        e.set('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image')
        e.set('Target', 'media/' + name)
        return rid, im.size

    def IMGS(self, specs, height_in=3.9):
        """specs: [(path, crop)] — 한 단락에 가로로 나란히"""
        runs = ''
        n = len(specs)
        for path, crop in specs:
            rid, (w, h) = self.add_image(path, crop=crop)
            hh = height_in
            ww = hh * w / h
            maxw = 6.3 / n - 0.08
            if ww > maxw:
                ww = maxw
                hh = ww * h / w
            cx, cy = int(ww * 914400), int(hh * 914400)
            self.img_id += 1
            did = self.img_id
            runs += (f'<w:r><w:rPr><w:noProof/></w:rPr><w:drawing><wp:inline distT="0" distB="0" distL="38100" distR="38100">'
                     f'<wp:extent cx="{cx}" cy="{cy}"/><wp:effectExtent l="0" t="0" r="0" b="0"/>'
                     f'<wp:docPr id="{did}" name="그림 {did}"/><wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>'
                     f'<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic>'
                     f'<pic:nvPicPr><pic:cNvPr id="{did}" name="그림 {did}"/><pic:cNvPicPr/></pic:nvPicPr>'
                     f'<pic:blipFill><a:blip r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
                     f'<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
                     f'<a:ln w="3175"><a:solidFill><a:srgbClr val="D9D9D9"/></a:solidFill></a:ln></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>'
                     '<w:r><w:t xml:space="preserve"> </w:t></w:r>')
        return frag('<w:p><w:pPr><w:keepNext/><w:spacing w:before="120" w:after="0"/><w:jc w:val="center"/></w:pPr>' + runs + '</w:p>')[0]

    def save(self):
        self.tree.write(self.path, xml_declaration=True, encoding='UTF-8', standalone=True)
        self.rels.write(self.rels_path, xml_declaration=True, encoding='UTF-8', standalone=True)
        ct = os.path.join(self.folder, '[Content_Types].xml')
        s = open(ct, encoding='utf8').read()
        if 'Extension="jpg"' not in s:
            s = s.replace('<Default ', '<Default Extension="jpg" ContentType="image/jpeg"/><Default ', 1)
            open(ct, 'w', encoding='utf8').write(s)
