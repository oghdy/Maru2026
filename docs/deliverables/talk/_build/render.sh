#!/bin/zsh
# pptx → PDF (PowerPoint, 문서 이름으로만 지정) → PNG. 사용: render.sh <pptx> <pdf 출력> <png 폴더> [dpi]
set -e
SRC="$1"; PDF="$2"; OUTDIR="$3"; DPI="${4:-110}"
C="/Users/hadohadopapi/Library/Containers/com.microsoft.Powerpoint/Data/maru_talk_render"
mkdir -p "$C" "$OUTDIR"
NAME="talk_render_$$"
cp "$SRC" "$C/$NAME.pptx"
osascript -e 'with timeout of 280 seconds
tell application "Microsoft PowerPoint"
open POSIX file "'$C/$NAME.pptx'"
delay 6
save presentation "'$NAME.pptx'" in POSIX file "'$C/$NAME.pdf'" as save as PDF
delay 2
close presentation "'$NAME.pptx'" saving no
end tell
end timeout'
cp "$C/$NAME.pdf" "$PDF"
rm -f "$C/$NAME.pptx" "$C/$NAME.pdf"
python3 - "$PDF" "$OUTDIR" "$DPI" <<'EOF'
import sys, pymupdf
d = pymupdf.open(sys.argv[1])
for i, p in enumerate(d):
    p.get_pixmap(dpi=int(sys.argv[3])).save('%s/slide%02d.png' % (sys.argv[2], i + 1))
print('pages', len(d))
EOF
