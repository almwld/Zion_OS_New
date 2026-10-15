from pathlib import Path
from PIL import Image
import colorsys

ROOT = Path(__file__).resolve().parents[1]
FINAL = ROOT / 'assets' / 'icons'
GENERATED = FINAL / '_generated'
GPT_NAMES = {'analytics','app_store','browser','cracker','database','exploit','firewall','forensics','messages','network','process','system_ai'}
ALL = ['exploit','cracker','forensics','process','firewall','network','terminal','settings','database','security','file_manager','analytics','system_ai','browser','app_store','messages','media_player','profile','logs','storage','camera','calendar']

def cyanize(im):
    im = im.convert('RGB').resize((512, 512), Image.Resampling.LANCZOS)
    px = im.load()
    for y in range(512):
        for x in range(512):
            r,g,b = px[x,y]
            mx, mn = max(r,g,b), min(r,g,b)
            if mx < 35 or mx == mn:
                continue
            h,s,v = colorsys.rgb_to_hsv(r/255,g/255,b/255)
            # Re-map green neon / lime glow to the cyan reference palette.
            if 0.20 <= h <= 0.43 and s > 0.18:
                h = 0.50 + (h - 0.32) * 0.08
                h = max(0.47, min(0.56, h))
                px[x,y] = tuple(round(c*255) for c in colorsys.hsv_to_rgb(h,s,v))
    return im

for name in ALL:
    source = GENERATED / f'{name}.png' if name in GPT_NAMES and (GENERATED / f'{name}.png').exists() else FINAL / f'{name}.webp'
    if not source.exists():
        raise FileNotFoundError(source)
    out = cyanize(Image.open(source))
    out.save(FINAL / f'{name}.webp', 'WEBP', quality=82, method=6)

for p in GENERATED.glob('*.png'):
    p.unlink()
GENERATED.rmdir()
print(f'prepared {len(ALL)} final icons')
