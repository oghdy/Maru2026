import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from maru_kit import *
import slides as S

prs = new_deck()
for i, (fn, t, tm, say) in enumerate(S.DECK, 1):
    fn(prs, i)
out = os.path.join(HERE, '..', 'MARU_발표.pptx')
finish(prs, [d[3] for d in S.DECK], out)
tot = sum(int(d[2].split(':')[0]) * 60 + int(d[2].split(':')[1]) for d in S.DECK)
print('slides', len(S.DECK), 'sec', tot)
