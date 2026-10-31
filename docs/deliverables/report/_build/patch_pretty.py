import re
s = open('build_report.py', encoding='utf8').read()
def R(old, new, count=1):
    global s
    n = s.count(old); assert n == count, (n, old[:70])
    s = s.replace(old, new)
# 1) 5장 그림 높이 축소 (여백 줄이기)
a = s.index("    H(2, '5.1 로그인, 홈 화면, 학습 통계'),"); b = s.index("    H(2, '5.6 운영 배포와 실기기 동작'),")
blk = s[a:b].replace("None)]),", "None)], height_in=3.25),").replace("height_in=3.3),", "height_in=3.0),")
s = s[:a] + blk + s[b:]
R("CAP('[그림 5-4] 🐰 Chunk 단계(저는 / 커피를 / 좋아해요 덩어리 조립) → 🐢 Morpheme 단계(목표 문법 이에요/예요만 분해, 다른 레슨의 문장) → 레슨 완료', center=True),",
  "CAP('[그림 5-4] 🐰 Chunk 단계(덩어리 조립) → 🐢 Morpheme 단계(목표 문법만 분해, 다른 레슨 문장) → 레슨 완료', center=True),")
# 2) 본문 참조를 토큰으로
R("3-Zone 규칙을 강제한다(표 4-3).", "3-Zone 규칙을 강제한다(@REF:zone@).")
R("앱 화면 확인(표 4-1)", "앱 화면 확인(@REF:lessonres@)")
R("그림 5-4는 이 \\\"덩어리 → 목표 문법만 분해\\\" 흐름을", "@REF:flow@는 이 \\\"덩어리 → 목표 문법만 분해\\\" 흐름을")
# 3) 캡션 없는 표·그림에 캡션 추가 + 캡션 형식 통일 + 참조 해소
R("""# =====================================================================
# 장 제목 페이지 나눔, 캡션 번호 재부여""", """# =====================================================================
# 캡션이 없는 표에 캡션 추가 (번호는 아래에서 자동 부여)
# =====================================================================
TABLE_TITLES = {
    '한계|내용': '기존 한국어 학습 앱의 구조적 한계',
    '두문자|목표|해소하는 한계': 'MARU의 개발 목표',
    '장|제목|내용': '보고서 구성',
    '선행 연구/기술|한계 또는 적용 갭|MARU의 대응': '선행 연구·기술과 MARU의 대응',
    '영역|기술|선택 이유': '기술 스택',
    '테이블|PK|주요 FK / 제약|비고': '전체 테이블 요약',
    '도메인|메서드|엔드포인트|설명': 'API 엔드포인트 목록',
    '모듈|역할': 'kiwi-generator 파이프라인 모듈',
    '구분|정규화 RDB 설계|JSONB 설계 (채택)': '정규화 설계와 JSONB 설계 비교',
    '호출|엔드포인트|역할': 'Mission Chat의 LLM 호출 구조',
    '목표|구현 내용|핵심 기술': '목표별 구현 성과',
    '구분|개발 항목|내용': '향후 개발 계획',
}
_cap0 = re.compile(r'^\\[?(그림|표) [0-9A-Z]+-\\d+')
for el in list(body):
    if el.tag != q('w:tbl'):
        continue
    nx = el.getnext()
    if nx is not None and _cap0.match(text(nx).strip()):
        continue
    hdr = '|'.join(norm(text(c)).strip() for c in el.findall(q('w:tr'))[0].findall(q('w:tc')))
    if hdr in TABLE_TITLES:
        el.addnext(CAP('표 0-0. ' + TABLE_TITLES[hdr]))
# 배치 번역 프롬프트 이미지: 굵은 라벨 → 그림 캡션
lab = [x for x in body if x.tag == q('w:p') and norm(text(x)).strip() == 'gemini_translater.py 프롬프트']
if lab:
    img = lab[0].getnext()
    body.remove(lab[0])
    img.addnext(CAP('그림 0-0. 배치 번역 프롬프트 (gemini_translator.py)'))

# =====================================================================
# 장 제목 페이지 나눔, 캡션 번호 재부여""")
R("cap_re = re.compile(r'(\\[?)(그림|표) ([0-9A-Z]+)-(\\d+)(\\]?)')", "cap_re = re.compile(r'\\[?(그림|표) ([0-9A-Z]+)-(\\d+)\\]?\\.?')\nREF_KEYS = {'zone': '서버가 강제하는 3-Zone 규칙', 'lessonres': '레슨별 목표 문법 분해 결과', 'flow': 'Chunk 단계('}\nrefs = {}")
old = s[s.index("        def sub(m):"):s.index("        if new != t:\n            d.set_text(el, new)")]
new = '''        def sub(m):
            kind = m.group(1)
            counters[(chap, kind)] = counters.get((chap, kind), 0) + 1
            return f'{kind} {chap}-{counters[(chap, kind)]}.'
        new = cap_re.sub(sub, t, count=1)
        for k_, phrase in REF_KEYS.items():
            if phrase in new:
                refs[k_] = new.split('.')[0]
'''
s = s.replace(old, new)
R("        if new != t:\n            d.set_text(el, new)\n", "        if new != t:\n            d.set_text(el, new)\nfor el in list(body.iter(q('w:p'))):\n    t = text(el)\n    if '@REF:' in t:\n        d.set_text(el, re.sub(r'@REF:(\\w+)@', lambda m: refs[m.group(1)], t))\n")
open('build_report.py', 'w', encoding='utf8').write(s)
print('ok')
