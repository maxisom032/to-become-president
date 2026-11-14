from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parent
records = []
for folder in ('characters', 'backgrounds'):
    files = sorted((ROOT / folder).glob('*.png'))
    if not files:
        continue
    cols = 4
    cw, ch = 300, 440
    sheet = Image.new('RGB', (cols*cw, ((len(files)+cols-1)//cols)*ch), '#eee1c9')
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(files):
        with Image.open(path) as source:
            im = source.convert('RGBA')
            alpha = im.getchannel('A')
            records.append({'file': str(path.relative_to(ROOT)), 'size': list(im.size), 'alpha_extrema': list(alpha.getextrema()), 'bounds': alpha.getbbox()})
            im.thumbnail((280, 390))
            x, y = (i%cols)*cw+(cw-im.width)//2, (i//cols)*ch+10
            sheet.paste(im, (x,y), im)
            draw.text(((i%cols)*cw+8, (i//cols)*ch+405), path.stem, fill='#342f36')
    sheet.save(ROOT / (folder+'-overview.jpg'), quality=92)
(ROOT/'validation.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
print(json.dumps(records, indent=2))
