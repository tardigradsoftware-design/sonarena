import React from 'react';
import {registerRoot, Composition, useCurrentFrame, useVideoConfig, interpolate,
        spring, Sequence, AbsoluteFill, Img, staticFile} from 'remotion';

/* ---------------- ortak yardımcılar ---------------- */
const FONT = {inter: 'Inter, sans-serif', mont: 'Montserrat, sans-serif'};

// crossfade'li görsel katmanı: her imageSlot saniyelerce görünür, üstünde Ken Burns zoom
const ImageSlides: React.FC<{slots: {src: string; from: number; to: number}[]; speed?: number}> =
({slots, speed = 1}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  return (
    <>
      {slots.map((s, i) => {
        if (t < s.from - 0.35 || t > s.to + 0.35) return null;
        const op = interpolate(t, [s.from - 0.35, s.from, s.to - 0.35, s.to], [0, 1, 1, 0],
                    {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
        const zoom = interpolate(t, [s.from, s.to], [1.0, 1.10 * speed]);
        return (
          <AbsoluteFill key={i} style={{opacity: op, overflow: 'hidden'}}>
            <Img src={staticFile(s.src)}
                 style={{width: '100%', height: '100%', objectFit: 'cover',
                         transform: `scale(${zoom})`}} />
          </AbsoluteFill>
        );
      })}
    </>
  );
};

const Vignette: React.FC = () => (
  <AbsoluteFill style={{
    background: 'radial-gradient(ellipse at center, rgba(11,16,32,0.10) 30%, rgba(11,16,32,0.82) 100%)',
  }} />
);

// yazı okunabilirliği için yumuşak koyu katman (görselin üstüne)
const Scrim: React.FC<{from?: number; to?: number}> = ({from = 0.15, to = 0.85}) => (
  <AbsoluteFill style={{
    background: `linear-gradient(90deg, rgba(11,16,32,${to}) 0%, rgba(11,16,32,${from*0.85}) 48%, rgba(11,16,32,${from*0.5}) 100%)`,
  }} />
);

const Grid: React.FC<{opacity?: number}> = ({opacity = 0.06}) => (
  <AbsoluteFill style={{
    backgroundImage:
      'linear-gradient(rgba(255,255,255,0.5) 1px, transparent 1px),' +
      'linear-gradient(90deg, rgba(255,255,255,0.5) 1px, transparent 1px)',
    backgroundSize: '120px 120px', opacity,
  }} />
);

/* ---------------- SAHNE 1 : 0.0 - 4.5 sn ---------------- */
const S1: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const title = 'YAPAY ZEKA';
  const sub = 'NEDİR?';
  const outs = [0, 0.04, 0.08, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, 0.30];

  return (
    <AbsoluteFill style={{backgroundColor: '#0B1020'}}>
      <ImageSlides slots={[{src: 'gen/t00.png', from: 0, to: 2.3},
                            {src: 'gen/t01.png', from: 2.2, to: 4.6}]} />
      <Scrim from={0.25} to={0.92} />
      <Grid opacity={0.05} />
      <Vignette />
      {/* üst etiket */}
      <div style={{position: 'absolute', top: 70, left: 110, fontFamily: FONT.mont,
        fontSize: 22, letterSpacing: 8, color: '#7C8AA5', opacity:
          interpolate(t, [0, 0.6], [0, 1], {extrapolateRight: 'clamp'})}}>01 / GİRİŞ</div>
      {/* başlık: harf harf */}
      <div style={{position: 'absolute', top: 320, left: 110, width: 1000}}>
        <div style={{fontFamily: FONT.inter, fontWeight: 700, fontSize: 150, color: '#FFFFFF',
          display: 'flex'}}>
          {title.split('').map((c, i) => {
            const s = spring({frame: frame - outs[i] * fps, fps, config: {damping: 14, stiffness: 120}});
            return <span key={i} style={{opacity: s, transform: `translateY(${(1 - s) * 70}px)`,
              display: 'inline-block', width: c === ' ' ? 40 : undefined}}>{c}</span>;
          })}
        </div>
        {/* alt çizgi */}
        <div style={{width: interpolate(t, [0.9, 1.5], [0, 470], {extrapolateLeft: 'clamp',
          extrapolateRight: 'clamp'}), height: 6, background: '#FF6B00', margin: '26px 0 0'}} />
        {/* alt başlık */}
        <div style={{fontFamily: FONT.mont, fontWeight: 700, fontSize: 58, color: '#4ADE80',
          letterSpacing: 18, marginTop: 30, opacity:
            interpolate(t, [1.15, 1.6], [0, 1], {extrapolateRight: 'clamp'}),
          transform: `translateY(${interpolate(t, [1.15, 1.6], [30, 0], {extrapolateRight: 'clamp'})}px)`}}>
          {sub}</div>
      </div>
      {/* alt bilgi */}
      <div style={{position: 'absolute', bottom: 80, width: '100%', textAlign: 'center',
        fontFamily: FONT.mont, fontSize: 24, color: '#5A6980', letterSpacing: 4,
        opacity: interpolate(t, [2.2, 2.8], [0, 1], {extrapolateRight: 'clamp'})}}>
        %100 KOD İLE ÜRETİLDİ</div>
    </AbsoluteFill>
  );
};

/* ---------------- SAHNE 3 : 16.0 - 25.5 sn ---------------- */
const LINES: {txt: string; from: number; to: number}[] = [
  {txt: 'Verilerden örüntüler çıkarır.',        from: 0.11, to: 5.01}, // abs 16.11-21.01
  {txt: 'Tahminler yapar, kararlar alır.',      from: 6.1,  to: 9.6},  // abs 22.1 -27.6
];

const S3: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const col = ['#FF6B00', '#4ADE80', '#60A5FA'];

  return (
    <AbsoluteFill style={{backgroundColor: '#0B1020'}}>
      <ImageSlides slots={[
        {src: 'gen/t02.png', from: 0, to: 3.2},
        {src: 'gen/t03.png', from: 3.1, to: 6.2},
        {src: 'gen/t04.png', from: 6.1, to: 9.6},
      ]} />
      <Scrim from={0.20} to={0.90} />
      <Grid opacity={0.05} />
      <Vignette />
      <div style={{position: 'absolute', top: 70, left: 110, fontFamily: FONT.mont, fontSize: 22,
        letterSpacing: 8, color: '#7C8AA5'}}>03 / NASIL ÇALIŞIR</div>

      <div style={{position: 'absolute', top: 250, width: '100%', padding: '0 110px',
        boxSizing: 'border-box'}}>
        {LINES.map((ln, li) => {
          const active = t >= ln.from && t <= ln.to;
          const appear = interpolate(t, [ln.from - 0.05, ln.from + 0.25], [0, 1],
                          {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
          if (appear <= 0) return null;
          const words = ln.txt.split(' ');
          const total = words.reduce((a, w) => a + w.length + 1, 0);
          let acc = 0;
          const lineDur = (ln.to - ln.from - 0.25) * 0.92;
          return (
            <div key={li} style={{marginBottom: 46, display: 'flex', flexWrap: 'wrap',
              alignItems: 'baseline', gap: '0 26px',
              opacity: active ? appear : appear * 0.35}}>
              <div style={{width: 10, alignSelf: 'stretch',
                background: active ? col[li % 3] : '#2A3550'}} />
              {words.map((w, wi) => {
                const start = ln.from + 0.25 + lineDur * (acc / total);
                acc += w.length + 1;
                const k = interpolate(t, [start, start + 0.18], [0, 1],
                          {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
                const done = t >= start;
                return (
                  <span key={wi} style={{
                    fontFamily: FONT.inter, fontWeight: 700, fontSize: 82,
                    color: done ? (active ? '#FFFFFF' : '#8895AC') : 'rgba(255,255,255,0.18)',
                    transform: `translateY(${(1 - k) * 12}px)`,
                    textShadow: active && done ? '0 0 30px rgba(255,107,0,0.35)' : 'none',
                  }}>{w}</span>
                );
              })}
            </div>
          );
        })}
      </div>

      {/* alt durum çubuğu */}
      <div style={{position: 'absolute', bottom: 78, left: 110, right: 110, height: 8,
        background: 'rgba(255,255,255,0.10)'}}>
        <div style={{width: `${interpolate(t, [0.1, 9.4], [0, 100], {extrapolateRight: 'clamp'})}%`,
          height: '100%', background: '#FF6B00'}} />
      </div>
      <div style={{position: 'absolute', bottom: 26, left: 110, fontFamily: FONT.mont,
        fontSize: 20, color: '#5A6980', letterSpacing: 3}}>KARAOKE SENKRON · WHISPER İLE DOĞRULANDI</div>
    </AbsoluteFill>
  );
};

/* ---------------- kayıt ---------------- */
const Fonts: React.FC = () => (
  <style>{`
    @font-face { font-family: 'Inter'; src: url('${staticFile('fonts/Inter-Regular.ttf')}'); font-weight: 400; }
    @font-face { font-family: 'Inter'; src: url('${staticFile('fonts/Inter-Bold.ttf')}'); font-weight: 700; }
    @font-face { font-family: 'Montserrat'; src: url('${staticFile('fonts/Montserrat-Regular.ttf')}'); font-weight: 400; }
    @font-face { font-family: 'Montserrat'; src: url('${staticFile('fonts/Montserrat-Bold.ttf')}'); font-weight: 700; }
  `}</style>
);

const Root: React.FC = () => (
  <>
    <Fonts />
    <Composition id="S1" component={S1} durationInFrames={135} fps={30} width={1920} height={1080} />
    <Composition id="S3" component={S3} durationInFrames={285} fps={30} width={1920} height={1080} />
  </>
);
registerRoot(Root);
