import sys, glob
from PIL import Image
src, out, cols = sys.argv[1], sys.argv[2], int(sys.argv[3])
fs = sorted(glob.glob(src + '/slide*.png'))
ims = [Image.open(f).convert('RGB') for f in fs]
tw = 640; th = int(tw * ims[0].height / ims[0].width); g = 16
rows = (len(ims) + cols - 1) // cols
sheet = Image.new('RGB', (cols * tw + (cols + 1) * g, rows * th + (rows + 1) * g), '#E9E6F5')
for i, im in enumerate(ims):
    sheet.paste(im.resize((tw, th), Image.LANCZOS), (g + (i % cols) * (tw + g), g + (i // cols) * (th + g)))
sheet.save(out)
print(sheet.size)
