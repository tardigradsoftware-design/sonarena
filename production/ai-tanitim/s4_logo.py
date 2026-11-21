"""S4: 25.5-30.0s — logo/başlık kartı. Vektörel logo Pillow ile çizilir."""
import math, os, json
from PIL import Image, ImageDraw, ImageFont, ImageFilter
W,H,FPS = 1920,1080,30
T0,T1 = 25.5,30.0
N=int(round((T1-T0)*FPS)); OUT="/tmp/prod/frames_s4"; os.makedirs(OUT,exist_ok=True)
FD="/home/user/sonarena/assets/fonts"
f_logo = ImageFont.truetype(f"{FD}/Inter-Bold.ttf", 118)
f_tag  = ImageFont.truetype(f"{FD}/Montserrat-Regular.ttf", 38)
f_small= ImageFont.truetype(f"{FD}/Montserrat-Bold.ttf", 22)

BG=Image.open("/home/user/sonarena/test_output/bg_ai_1080p.png").convert("RGB")

def ease_out(x): return 1-(1-x)**3
def clamp(x,a=0.0,b=1.0): return max(a,min(b,x))

for i in range(N):
    t=25.5+i/FPS; p=(t-T0)/(T1-T0)
    img=BG.copy().convert("RGBA")
    # koyu degradan + blur'lu merkez ışıması
    ov=Image.new("RGBA",(W,H),(11,16,32,0)); od=ImageDraw.Draw(ov)
    for y in range(H):
        od.line([(0,y),(W,y)],fill=(8,12,26,int(150+70*(1-y/H))))
    img=Image.alpha_composite(img,ov)
    # logo yapısı: dönen halkalar + düğüm
    lay=Image.new("RGBA",(W,H),(0,0,0,0)); ld=ImageDraw.Draw(lay)
    cx,cy = W/2, 430
    r0 = 92
    appears = clamp((t-T0)/0.55)
    # dış halkalar
    for k in range(3):
        r = r0 + 34*k + 26*clamp((t-T0-k*0.22)/0.9)
        alpha = int(210*appears*(1-k*0.28))
        ld.ellipse([cx-r,cy-r,cx+r,cy+r], outline=(255,107,0,alpha), width=5-k)
    # dönen yay (oran: 1 tur / 3s)
    ang0 = (t-T0)*120
    for j in range(3):
        a0 = math.radians(ang0 + j*120)
        ld.arc([cx-160,cy-160,cx+160,cy+160], math.degrees(a0), math.degrees(a0)+38,
               fill=(96,165,250,int(200*appears)), width=6)
    # merkez düğüm + bağlantılar
    nr=int(15*appears)
    ld.ellipse([cx-nr,cy-nr,cx+nr,cy+nr], fill=(255,255,255,int(240*appears)))
    for j in range(4):
        a=math.radians(45+90*j+(t-T0)*40)
        x2,y2=cx+64*math.cos(a),cy+64*math.sin(a)
        ld.line([(cx,cy),(x2,y2)], fill=(255,107,0,int(150*appears)), width=3)
        ld.ellipse([x2-6,y2-6,x2+6,y2+6], fill=(255,107,0,int(220*appears)))
    lay=lay.filter(ImageFilter.GaussianBlur(0.6))
    img=Image.alpha_composite(img,lay)
    d=ImageDraw.Draw(img,"RGBA")

    # logo yazısı: harf harf
    brand="KODLA VİDEO"
    la=clamp((t-T0-0.45)/0.9)
    widths=[d.textlength(c,font=f_logo) for c in brand]
    total=sum(widths); x=(W-total)/2
    for k,c in enumerate(brand):
        ca=clamp((la*len(brand))-k)
        d.text((x, 600-(1-ease_out(ca))*40), c, font=f_logo,
               fill=(255,255,255,int(255*ca)))
        x+=widths[k]

    # turuncu çizgi
    lw=int(360*clamp((t-T0-0.95)/0.6))
    d.rectangle([W/2-lw/2, 762, W/2+lw/2, 768], fill=(255,107,0,240))

    # slogan
    sa=clamp((t-T0-1.15)/0.8)
    tag="kod + ölçüm + teslim"
    tw=d.textlength(tag,font=f_tag)
    d.text(((W-tw)/2, 812-(1-ease_out(sa))*22), tag, font=f_tag,
           fill=(74,222,128,int(255*sa)))

    # alt bilgi
    d.text((110,H-70),"AI TANITIM VİDEOSU · 30s · 1080p30",font=f_small,fill=(90,105,128,200))
    rw=d.textlength("Render: Remotion + Pillow + FFmpeg",font=f_small)
    d.text((W-110-rw,H-70),"Render: Remotion + Pillow + FFmpeg",font=f_small,fill=(90,105,128,200))

    # son 0.5s hafif parlama
    if p>0.88:
        fl=int(28*(p-0.88)/0.12)
        img=Image.alpha_composite(img, Image.new("RGBA",(W,H),(255,255,255,fl)))
    img.convert("RGB").save(f"{OUT}/f_{i:04d}.png")
print(json.dumps({"frames":N,"T0":T0,"T1":T1}))
