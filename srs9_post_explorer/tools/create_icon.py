from pathlib import Path
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
folder = root/'assets/icon'
folder.mkdir(parents=True, exist_ok=True)
# Geometric original mark: a post card and a magnifying glass.
# Artwork fits within the Android adaptive icon safe zone.
fg = Image.new('RGBA', (1024,1024))
d = ImageDraw.Draw(fg)
d.rounded_rectangle((292,270,674,710), radius=52, fill='white')
for y, end in [(350,596),(418,596),(486,500)]:
    d.rounded_rectangle((350,y,end,y+26),radius=13,fill='#285BCE')
d.ellipse((480,470,710,700), fill='#285BCE')
d.ellipse((515,505,675,665), fill='#72E4CB')
d.line((680,675,745,740), fill='#72E4CB',width=48)
d.ellipse((721,716,769,764),fill='#72E4CB')
fg.save(folder/'app_icon_foreground.png')
bg=Image.new('RGBA',(1024,1024),'#173A8A')
bg.alpha_composite(fg)
bg.convert('RGB').save(folder/'app_icon.png')
print('Created original 1024x1024 launcher icon and transparent foreground')
