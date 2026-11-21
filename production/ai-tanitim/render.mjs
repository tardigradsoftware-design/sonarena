import {bundle} from '@remotion/bundler';
import {renderMedia, selectComposition} from '@remotion/renderer';
import path from 'path';
const EXE='/home/user/sonarena/.tools/nss/chromium';
const serveUrl = await bundle({entryPoint: path.resolve('src/index.tsx'), publicDir: path.resolve('public')});
console.log('BUNDLED');
for (const [id,out] of [['S1','render/S1.mp4'],['S3','render/S3.mp4']]) {
  const t0=Date.now();
  const composition = await selectComposition({serveUrl, id, browserExecutable:EXE});
  await renderMedia({composition, serveUrl, codec:'h264', outputLocation: path.resolve(out),
    browserExecutable:EXE, chromiumOptions:{gl:'swangle'}, concurrency:1,
    imageFormat:'jpeg', jpegQuality:95, crf:16});
  console.log(id, composition.width+'x'+composition.height, composition.durationInFrames+'f', ((Date.now()-t0)/1000).toFixed(1)+'s');
}
