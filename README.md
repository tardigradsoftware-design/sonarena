# sonarena — kodla video üretim ortamı

Sandbox'ta `apt` ve birçok CDN kapalı; erişilebilen kaynaklar yalnızca
**pypi.org**, **registry.npmjs.org** ve **github.com**. Bu depo o kısıtlar
altında kurulabilen ücretsiz video/medya araç zincirini ve doğrulanmış
test çıktılarını içerir.

## Tek komutla kurulum

```bash
bash setup.sh          # idempotent, ~24 sn
export PATH="$PWD/.tools/bin:$PATH"
```

Kurulanlar:

| Araç | Kaynak | Sürüm |
|---|---|---|
| ffmpeg (libx264, libx265, libsvtav1, prores_ks, drawtext, subtitles, xfade, zoompan, lut3d) | pip `imageio-ffmpeg` | 9.0.2 |
| ffprobe | npm `ffprobe-static` | 4.0.2 |
| Python venv (Pillow, numpy, moviepy, fonttools, faster-whisper) | pip | — |
| Inter + Montserrat TTF (latin + latin-ext birleşik, tam Türkçe) | npm `@fontsource/*` → woff→ttf | — |
| espeak-ng Türkçe TTS (`libespeak-ng.so` + veri) | pip `espeakng-loader` | 1.52 |
| Whisper small CTranslate2 int8 (240 MB, sha256 doğrulamalı) | npm `@skillninja/shortmovie-telop-model-p{0..3}` | — |

## Çalışan / çalışmayan

**ÇALIŞIYOR:** FFmpeg render, TTS (espeak-ng tr), STT (faster-whisper tr),
Pillow ile kare kare animasyon, font/tipografi, parçalı render + concat.

**ÇALIŞMIYOR:** Chromium/Playwright/Remotion (`@sparticuz/chromium` indiriliyor
ama sistemde `libnspr4/libnss3` yok; stub NSS ile ağ servisi çöküyor),
Manim (`libcairo/libpango` yok, apt kapalı), Piper nöral TTS (ses modelleri
HF/release CDN'inde), apt paketleri.

## Test çıktıları

`test_output/` (git'e girmez, `setup.sh` sonrası üretilir):
`FINAL_10s_1080p.mp4`, `canvas_anim.mp4`, `concat_30s_4k.mp4`,
`perf_60s_1080p.mp4`, `perf_10s_4k.mp4`.
