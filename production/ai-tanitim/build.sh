#!/usr/bin/env bash
# AI_TANITIM_30s_1080p.mp4 üretim hattı — sırasıyla çalıştırır
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FF="$ROOT/.tools/bin/ffmpeg"; FP="$ROOT/.tools/bin/ffprobe"; PY="$ROOT/.tools/venv/bin/python"
export LD_LIBRARY_PATH="$ROOT/.tools/nss:${LD_LIBRARY_PATH:-}"
OUT="${OUT:-$ROOT/test_output}"; mkdir -p "$OUT"

echo "[1/5] Ses: TTS parçaları -> 30s zaman çizgisi (vo_30s.wav)"
# vo_s1/vo_ai_tr/vo_s3/vo_s4.mp3 dosyaları $OUT içinde olmalı (araç TTS çıktıları)
"$FF" -hide_banner -loglevel error -y \
 -i "$OUT/vo_s1.mp3" -i "$OUT/vo_ai_tr.mp3" -i "$OUT/vo_s3.mp3" -i "$OUT/vo_s4.mp3" \
 -filter_complex "[0:a]aresample=48000,adelay=1000|1000[a0];[1:a]aresample=48000,adelay=4500|4500[a1];\
[2:a]aresample=48000,adelay=16000|16000[a2];[3:a]aresample=48000,adelay=25500|25500[a3];\
[a0][a1][a2][a3]amix=inputs=4:duration=longest:normalize=0,\
loudnorm=I=-16:TP=-1.5:LRA=11,apad=whole_dur=30,atrim=0:30[a]" \
 -map "[a]" -ar 48000 -c:a pcm_s16le "$OUT/vo_30s.wav"

echo "[2/5] Remotion sahneleri S1 (135f) + S3 (285f)"
cp -r "$ROOT/test_output/gen" "$ROOT/production/ai-tanitim/public/" 2>/dev/null || true
( cd "$ROOT/production/ai-tanitim" && node render.mjs )

echo "[3/5] Pillow sahneleri S2 (366f) + S4 (156f)"
"$PY" "$ROOT/production/ai-tanitim/s2_pillow.py"
"$PY" "$ROOT/production/ai-tanitim/s4_logo.py"
"$FF" -hide_banner -loglevel error -y -framerate 30 -i "$ROOT/production/ai-tanitim/frames_s2/f_%04d.png" \
  -c:v libx264 -preset medium -crf 16 -pix_fmt yuv420p "$ROOT/production/ai-tanitim/render_ext/S2.mp4"
"$FF" -hide_banner -loglevel error -y -framerate 30 -i "$ROOT/production/ai-tanitim/frames_s4/f_%04d.png" \
  -c:v libx264 -preset medium -crf 16 -pix_fmt yuv420p "$ROOT/production/ai-tanitim/render_ext/S4f.mp4"

echo "[4/5] xfade zinciri + ses (3 geçiş, 900 kare olmalı)"
"$FF" -hide_banner -loglevel error -y \
 -i "$ROOT/production/ai-tanitim/render_ext/S1f.mp4" -i "$ROOT/production/ai-tanitim/render_ext/S2.mp4" \
 -i "$ROOT/production/ai-tanitim/render_ext/S3.mp4" -i "$ROOT/production/ai-tanitim/render_ext/S4f.mp4" \
 -i "$OUT/vo_30s.wav" \
 -filter_complex "[0:v]settb=AVTB,fps=30,format=yuv420p[v0];[1:v]settb=AVTB,fps=30,format=yuv420p[v1];\
[2:v]settb=AVTB,fps=30,format=yuv420p[v2];[3:v]settb=AVTB,fps=30,format=yuv420p[v3];\
[v0][v1]xfade=transition=fade:duration=0.6:offset=3.9[x1];\
[x1][v2]xfade=transition=fade:duration=0.6:offset=15.4[x2];\
[x2][v3]xfade=transition=fadeblack:duration=0.7:offset=24.8[x3];\
[x3]trim=0:30,setpts=PTS-STARTPTS,format=yuv420p[vout]" \
 -map "[vout]" -map 4:a -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
 -c:a aac -b:a 192k -ar 48000 -t 30 -movflags +faststart "$OUT/AI_TANITIM_30s_1080p.mp4"

echo "[5/5] Doğrulama (900 kare / 30.000s bekleniyor)"
N=$("$FP" -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of csv=p=0 "$OUT/AI_TANITIM_30s_1080p.mp4")
D=$("$FP" -v error -show_entries format=duration -of csv=p=0 "$OUT/AI_TANITIM_30s_1080p.mp4")
echo "  kare=$N  süre=$D"
[ "$N" = "900" ] && echo "  ✓ kare sayısı doğru" || { echo "  ✗ KARE KAYBI — xfade offset'lerini kontrol et"; exit 1; }
