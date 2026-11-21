#!/usr/bin/env bash
# ============================================================================
#  setup.sh — kodla video üretim ortamını tek komutla geri kurar
#  Kullanım:  bash setup.sh          (idempotent, tekrar çalıştırılabilir)
#
#  Neden bu yöntem: sandbox'ta apt/deb.debian.org ve Google/HF CDN'leri KAPALI.
#  Erişilebilen tek kaynaklar: pypi.org, registry.npmjs.org, github.com
#  Bu yüzden ffmpeg/ffprobe/fontlar/modeller statik paketlerden çekilir.
# ============================================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$ROOT/.tools/bin"
VENV="$ROOT/.tools/venv"
MODELS="$ROOT/.tools/models"
FONTS="$ROOT/assets/fonts"
mkdir -p "$BIN" "$MODELS" "$FONTS"

say(){ printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ok(){  printf '    \033[32m✓ %s\033[0m\n' "$*"; }
bad(){ printf '    \033[31m✗ %s\033[0m\n' "$*"; }

# ---------------------------------------------------------------- 1) python venv
say "Python venv"
if [ ! -x "$VENV/bin/python" ]; then
  python3 -m venv "$VENV" && ok "venv: $VENV" || { bad "venv kurulamadı"; exit 1; }
else ok "venv zaten var"; fi
PIP="$VENV/bin/pip"; PY="$VENV/bin/python"

say "pip paketleri (imageio-ffmpeg, Pillow, numpy, fonttools, brotli, faster-whisper, espeakng-loader)"
"$PIP" install -q --upgrade pip >/dev/null 2>&1
"$PIP" install -q imageio-ffmpeg pillow numpy fonttools brotli faster-whisper espeakng-loader \
  && ok "pip OK" || bad "pip paketlerinde hata"

# ---------------------------------------------------------------- 2) ffmpeg/ffprobe
say "ffmpeg (static) + ffprobe (static)"
if [ -x "$BIN/ffmpeg" ] && "$BIN/ffmpeg" -version >/dev/null 2>&1; then
  ok "ffmpeg hazır: $("$BIN/ffmpeg" -version | head -1 | cut -c1-40)"
else
  FF=$("$PY" -c 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())')
  cp "$FF" "$BIN/ffmpeg" && chmod +x "$BIN/ffmpeg" && ok "ffmpeg kuruldu"
fi
if [ -x "$BIN/ffprobe" ] && "$BIN/ffprobe" -version >/dev/null 2>&1; then
  ok "ffprobe hazır"
else
  tmp=$(mktemp -d); ( cd "$tmp" && npm init -y >/dev/null 2>&1 && npm i -q ffprobe-static >/dev/null 2>&1 ) \
    && cp "$tmp/node_modules/ffprobe-static/bin/linux/x64/ffprobe" "$BIN/ffprobe" \
    && chmod +x "$BIN/ffprobe" && ok "ffprobe kuruldu" || bad "ffprobe alınamadı"
  rm -rf "$tmp"
fi
# PATH ipucu
grep -q "$BIN" ~/.bashrc 2>/dev/null || echo "export PATH=\"$BIN:\$PATH\"" >> ~/.bashrc

# ---------------------------------------------------------------- 3) fonts
say "Inter + Montserrat TTF (Türkçe tam: ğüşıöç İ)  ->  assets/fonts/"
if [ -f "$FONTS/Inter-Bold.ttf" ] && [ -f "$FONTS/Montserrat-Bold.ttf" ]; then
  ok "fontlar zaten var"
else
  tmp=$(mktemp -d)
  ( cd "$tmp" && npm init -y >/dev/null 2>&1 && npm i -q @fontsource/inter @fontsource/montserrat >/dev/null 2>&1 )
  "$PY" - "$tmp" "$FONTS" <<'PY'
import sys, os
from fontTools.ttLib import TTFont
from fontTools.merge import Merger
tmp, out = sys.argv[1], sys.argv[2]
jobs = [("inter","400","Inter-Regular"),("inter","700","Inter-Bold"),
        ("montserrat","400","Montserrat-Regular"),("montserrat","700","Montserrat-Bold")]
for fam,w,name in jobs:
    a=f"{tmp}/node_modules/@fontsource/{fam}/files/{fam}-latin-{w}-normal.woff"
    b=f"{tmp}/node_modules/@fontsource/{fam}/files/{fam}-latin-ext-{w}-normal.woff"
    if not (os.path.exists(a) and os.path.exists(b)): print("SKIP",name); continue
    t=[]
    for src in (a,b):
        f=TTFont(src); f.flavor=None; p=src+".ttf"; f.save(p); t.append(p)
    m=Merger().merge(t); dst=os.path.join(out,name+".ttf"); m.save(dst)
    cm=TTFont(dst).getBestCmap()
    miss=[c for c in "ğüşıöçİĞÜŞÖÇ" if ord(c) not in cm]
    print(f"  {name}: {os.path.getsize(dst)}B  eksik_TR={miss or 'YOK'}")
PY
  rm -rf "$tmp"
fi

# ---------------------------------------------------------------- 4) whisper model
say "Whisper small (CTranslate2 int8) — npm'den 4 parça olarak çekilir (~240 MB)"
WHDIR="$MODELS/whisper-small-ct2"
if [ -f "$WHDIR/model.bin" ]; then ok "model zaten var"; else
  tmp=$(mktemp -d)
  ( cd "$tmp" && npm init -y >/dev/null 2>&1
    for p in p0 p1 p2 p3; do npm i -q "@skillninja/shortmovie-telop-model-$p" >/dev/null 2>&1; done )
  S="$tmp/node_modules/@skillninja"
  if [ -d "$S/shortmovie-telop-model-p0" ]; then
    mkdir -p "$WHDIR"
    cat "$S"/shortmovie-telop-model-p{0,1,2,3}/model.bin.part* > "$WHDIR/model.bin"
    cp "$S/shortmovie-telop-model-p0"/{config.json,tokenizer.json,vocabulary.json,preprocessor_config.json} "$WHDIR/"
    EXP=$(cat "$S/shortmovie-telop-model-p0/model.sha256" | awk '{print $1}')
    GOT=$(sha256sum "$WHDIR/model.bin" | awk '{print $1}')
    [ "$EXP" = "$GOT" ] && ok "sha256 doğrulandı" || bad "sha256 UYUŞMUYOR ($GOT)"
  else bad "whisper modeli indirilemedi"; fi
  rm -rf "$tmp"
fi

# ---------------------------------------------------------------- 5) doğrulama
say "Doğrulama"
# NOT: `cmd | grep -q` + pipefail = SIGPIPE yanlış negatifi. Önce çıktıyı topla.
ENCODERS=$("$BIN/ffmpeg" -hide_banner -encoders 2>/dev/null)
FILTERS=$("$BIN/ffmpeg" -hide_banner -filters 2>/dev/null)
case "$ENCODERS" in *libx264*) ok "libx264";; *) bad "libx264 yok";; esac
case "$ENCODERS" in *libx265*) ok "libx265";; *) bad "libx265 yok";; esac
case "$ENCODERS" in *aac*) ok "aac";; *) bad "aac yok";; esac
for f in drawtext subtitles xfade zoompan lut3d overlay; do
  if printf '%s\n' "$FILTERS" | awk '{print $2}' | grep -qx "$f"; then ok "filter:$f"; else bad "filter:$f"; fi
done
"$PY" -c "
import ctypes, espeakng_loader as el
lib=ctypes.CDLL(el.get_library_path()); lib.espeak_Initialize.restype=ctypes.c_int
sr=lib.espeak_Initialize(2,0,el.get_data_path().encode(),0)
print('    ✓ espeak-ng TTS (tr) sr=%d' % sr)
" 2>/dev/null || bad "espeak-ng çalışmıyor"

cat <<EOF

────────────────────────────────────────────────────────────
 KURULUM TAMAM
   ffmpeg/ffprobe : $BIN
   python venv    : $VENV/bin/python
   fontlar        : $FONTS
   whisper modeli : $WHDIR  (varsa)
 Kullanım:
   export PATH="$BIN:\$PATH"
   $PY script.py
────────────────────────────────────────────────────────────
EOF
