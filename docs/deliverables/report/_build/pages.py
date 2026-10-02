import pymupdf, json, re
pdf='/Users/hadohadopapi/Desktop/Maru-main/docs/deliverables/report/MARU_최종보고서_2학기.pdf'
d=pymupdf.open(pdf); heads=json.load(open('heads.json'))
nz=lambda s: re.sub(r'\s+','',s)
pt=[nz(p.get_text()) for p in d]
# 목차 끝 = '1.서론' 이 본문 제목으로 나오는 첫 페이지 찾기: 목차 페이지는 '목차' 포함
start=max(i for i,t in enumerate(pt[:8]) if '목차' in t or '..' in t)+1
res={}; cur=start
for h in heads:
    key=nz(h.replace('1.1 개발 배경','개발 배경'))
    key2=key.replace('(2학기추가)','').replace('(2학기재작성)','')
    found=None
    for i in range(cur,len(pt)):
        if key2[:30] in pt[i]:
            found=i;break
    if found is None: print('MISSING',h); continue
    res[h]=found+1; cur=found
json.dump(res,open('pages.json','w'),ensure_ascii=False)
print(d.page_count,'pages; toc start',start); print(list(res.items())[:6], list(res.items())[-5:])
