"""S2: 4.5-15.5s — Pillow sahnesi. Kelimeler TTS metninden, zamanlama ölçülmüş konuşmadan."""
import json, math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W,H,FPS = 1920,1080,30
T0,T1 = 4.5,16.7
N = int(round((T1-T0)*FPS))          # 330 kare
OUT="/tmp/prod/frames_s2"; os.makedirs(OUT,exist_ok=True)
FONT_DIR="/home/user/sonarena/assets/fonts"

f_head  = ImageFont.truetype(f"{FONT_DIR}/Inter-Bold.ttf", 86)
f_word  = ImageFont.truetype(f"{FONT_DIR}/Inter-Bold.ttf", 62)
f_mont  = ImageFont.truetype(f"{FONT_DIR}/Montserrat-Regular.ttf", 30)
f_lbl   = ImageFont.truetype(f"{FONT_DIR}/Montserrat-Bold.ttf", 22)

# TTS metni (kelime kelime) — zamanlar ölçülmüş konuşma bloğundan
L1 = ("Yapay zeka, bilgisayarların insan gibi öğrenmesini sağlayan bir teknolojidir.").split()
L1_START, L1_END = 4.616, 9.409
L2 = ("Verilerden örüntüler çıkarır, tahminler yapar ve kararlar alır.").split()
L2_START, L2_END = 9.998, 14.236

# ASR ağırlıkları (kelime süreleri) — test_output/words.json'dan
asr = json.load(open("/home/user/sonarena/test_output/words.json"))
def weights(tokens, a, b):
    sub=[w for w in asr if a-0.5 <= w["s"] < b+0.2]
    if len(sub)==len(tokens):
        return [max(0.09, w["e"]-w["s"]) for w in sub]
    return [max(1,len(t)) for t in tokens]
def schedule(tokens,a,b):
    wt=weights(tokens,a,b); tot=sum(wt); span=b-a; out=[]; t=a
    for tok,w in zip(tokens,wt):
        d=span*w/tot; out.append((tok,t,t+d)); t+=d
    return out
S1=schedule(L1,L1_START,L1_END)
S2=schedule(L2,L2_START,L2_END)

# arka plan: kendi ürettiğim görsel, yavaş zoom + kaydırma
BG=Image.open("/home/user/sonarena/test_output/gen/t05.png").convert("RGB").resize((W,H),Image.LANCZOS)
BG2=Image.open("/home/user/sonarena/test_output/gen/t06.png").convert("RGB").resize((W,H),Image.LANCZOS)

def draw_words(d, words, t, base_y, font, active_col=(255,255,255), maxw=1700):
    """satırı ortala (gerekirse küçültüp 2 satıra böl), kelime kelime aydınlat"""
    gap=22
    def measure(f_, ws):
        return [d.textlength(w,font=f_) for w,_,_ in ws]
    # sığana kadar küçült
    f=font
    while True:
        wd=measure(f,words); total=sum(wd)+gap*(len(wd)-1)
        if total<=maxw or f.size<=40: break
        f=ImageFont.truetype(font.path, int(f.size*0.94))
    if total>maxw:  # 2 satıra böl
        half=len(words)//2
        draw_words(d,words[:half],t,base_y,f,active_col,maxw)
        draw_words(d,words[half:],t,base_y+int(f.size*1.35),f,active_col,maxw)
        return
    x=(W-total)/2
    widths=wd
    for (w,s,e),wd2 in zip(words,widths):
        if t < s-0.12:      col=(255,255,255,40);  dy=10; sc=1.0
        elif t < s-0.02:    col=(255,255,255,120); dy=5;  sc=1.0
        elif t < e+0.10:    col=active_col;        dy=0;  sc=1.045   # vurgu anı
        else:               col=(235,240,250,255); dy=0;  sc=1.0
        if sc!=1.0:
            f2=ImageFont.truetype(f.path, int(f.size*sc))
        else: f2=f
        d.text((x, base_y+dy), w, font=f2, fill=col)
        x+=wd2+gap

for i in range(N):
    t=T0+i/FPS
    p=(t-T0)/(T1-T0)
    # crossfade arka plan t05 -> t06 (7.5s civarı)
    mix=min(1,max(0,(t-10.2)/1.6))
    bg=Image.blend(BG,BG2,mix) if mix>0 else BG.copy()
    # ken burns
    z=1.0+0.06*p
    bw,bh=int(W*z),int(H*z)
    bg=bg.resize((bw,bh),Image.LANCZOS)
    ox=int(14*math.sin(p*3)); oy=int(10*math.cos(p*2.2))
    bg=bg.crop(((bw-W)//2+ox,(bh-H)//2+oy,(bw-W)//2+ox+W,(bh-H)//2+oy+H)).resize((W,H),Image.LANCZOS)
    img=bg.convert("RGBA")
    # scrim
    ov=Image.new("RGBA",(W,H),(11,16,32,0)); od=ImageDraw.Draw(ov)
    for y in range(H):
        a=int(215*(0.25+0.75*(y/H)))         # üstten alta koyulaşan
        od.line([(0,y),(W,y)],fill=(11,16,32,a))
    img=Image.alpha_composite(img,ov)
    d=ImageDraw.Draw(img,"RGBA")

    d.text((110,80),"02 / TANIM",font=f_lbl,fill=(124,138,165,255))
    # başlık
    # (başlık 4.5-5.6 arası belirir)
    ha=min(1,max(0,(t-4.5)/0.9))
    if ha>0:
        d.text((110,170),"Yapay Zeka Nedir?",font=f_head,fill=(255,255,255,int(255*ha)))
    d.rectangle([110,300,110+int(300*min(1,max(0,(t-5.0)/0.8))),306],fill=(255,107,0,235))

    # kelime satırları
    if t < 10.0:
        draw_words(d,S1,t,455,f_word,(255,107,0))
    else:
        draw_words(d,S2,t,455,f_word,(74,222,128))

    # zaman çizgisi
    d.rectangle([110,H-96,W-110,H-90],fill=(255,255,255,28))
    d.rectangle([110,H-96,110+int((W-220)*(p)),H-90],fill=(255,107,0,235))
    for (_,s,_) in S1+S2:
        x=110+int((W-220)*((s-T0)/(T1-T0)))
        if 0<=x<=W-110: d.rectangle([x-1,H-102,x+1,H-84],fill=(74,222,128,190))
    d.text((110,H-52),"kelime senkronu · ölçülen konuşma aralıklarına çapalı",font=f_mont,fill=(90,105,128,255))
    img.convert("RGB").save(f"{OUT}/f_{i:04d}.png")

print(json.dumps({"frames":N,"T0":T0,"T1":T1,
  "line1_first":round(S1[0][1],3),"line2_first":round(S2[0][1],3)}))
