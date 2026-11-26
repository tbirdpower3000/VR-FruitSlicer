#!/usr/bin/env node
// Launches this VR game in headless Chromium and plays a round, taking screenshots.
// Usage, from the repo root:
//   node .claude/skills/run-<name>/driver.cjs [--mode gaze|hand] [--lens on|off] [--practice] [--out DIR] [--eval 'JS'] [--size 852x393]
// It serves the repo itself, so no other server is needed. Prints one JSON summary; exits 1 on a page error or if the
// round does not finish.
const http = require('http'), fs = require('fs'), path = require('path'), os = require('os'), { execSync } = require('child_process');
const { chromium } = require('playwright');

const arg = (name, dflt) => { const i = process.argv.indexOf('--' + name); return i > 0 ? process.argv[i + 1] : dflt; };
const ROOT = process.cwd(), SKILL = __dirname;
const MODE = arg('mode', 'gaze'), LENS = arg('lens', 'on'), OUT = path.resolve(arg('out', path.join(os.tmpdir(), 'vr-run'))), EVAL = arg('eval', null);
const [W, H] = arg('size', '852x393').split('x').map(Number);
const PRACTICE = process.argv.includes('--practice'); // Skeet only: go through the practice step with the stand-in hand
if (!fs.existsSync(path.join(ROOT, 'index.html'))) { console.error('Run this from the repo root (index.html not found in ' + ROOT + ')'); process.exit(2); }

// three.js r128 comes from cdnjs, which a sandbox may block; a copy is taken from npm once and served in its place
function threeJs() {
  const dir = path.join(os.tmpdir(), 'vr-run-three'), file = path.join(dir, 'package/build/three.min.js');
  if (!fs.existsSync(file)) {
    fs.mkdirSync(dir, { recursive: true });
    execSync('npm pack three@0.128.0 --silent && tar xzf three-0.128.0.tgz', { cwd: dir, stdio: 'ignore' });
  }
  return file;
}
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.png': 'image/png', '.md': 'text/plain' };
const server = http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]); if (p.endsWith('/')) p += 'index.html';
  const f = path.join(ROOT, p);
  if (!f.startsWith(ROOT) || !fs.existsSync(f)) { res.writeHead(404); return res.end(); }
  res.writeHead(200, { 'content-type': TYPES[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(res);
});

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const url = 'http://127.0.0.1:' + server.address().port + '/?stereo=1&n=4&t=8'; // split view; a short round (n: clays in Skeet, t: seconds in Fruit Slicer)
  fs.mkdirSync(OUT, { recursive: true });
  const browser = await chromium.launch({ args: ['--use-fake-device-for-media-stream', '--use-fake-ui-for-media-stream'] });
  const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: 2, permissions: ['camera'] });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  await page.route('**/three.min.js', (r) => r.fulfill({ path: threeJs(), contentType: 'text/javascript' }));
  // the shared engine is loaded from the VR-Portal site; a checkout beside this repo is served in its place when there is one
  const engine = path.join(ROOT, '..', 'vr-portal', 'v1', 'vr-engine.js');
  if (fs.existsSync(engine)) await page.route('**/vr-engine.js', (r) => r.fulfill({ path: engine, contentType: 'text/javascript' }));
  await page.route('**/vision_bundle.mjs*', (r) => r.fulfill({ path: path.join(SKILL, 'fake-hands.mjs'), contentType: 'text/javascript' }));
  await page.addInitScript(([lens]) => { try { localStorage.setItem('vrLens', JSON.stringify({ on: lens === 'on', size: 100 })); } catch (e) {} window.__fake = { on: true, u: 0.5, v: 0.45, hw: 0.11, thumb: 0.6 }; }, [LENS]);
  await page.goto(url, { waitUntil: 'load' });
  await page.waitForFunction(() => window.__skeet || window.__fruitVR, null, { timeout: 15000 });
  const shot = async (name) => { const f = path.join(OUT, name + '.png'); await page.screenshot({ path: f }); return f; };
  const K = (fn, a) => page.evaluate(([src, a]) => { const K = window.__skeet || window.__fruitVR; return new Function('K', 'a', 'return (' + src + ')(K, a)')(K, a); }, [fn.toString(), a]);
  const shots = [await shot('01-setup')];
  const title = (await page.textContent('h1')).trim();

  if (MODE === 'gaze') { await page.check('input[value=head]'); await page.uncheck('#room'); }
  const hasPractice = await page.$('#practice');
  if (hasPractice) await page.setChecked('#practice', MODE === 'hand' && PRACTICE);
  await page.click('#go');
  if (hasPractice && MODE === 'hand' && PRACTICE) {
    // Skeet's practice: point the stand-in finger at the hanging disc, hold the thumb up, drop it; three discs
    await page.waitForFunction(() => window.__skeet.S.phase === 'practice', null, { timeout: 15000 });
    let pshot = false;
    for (let i = 0; i < 400; i++) {
      const st = await page.evaluate(() => {
        const K = window.__skeet, P = K.PR; if (K.S.phase !== 'practice') return 'done';
        if (P.disc) { // where the disc falls in the camera picture, as the head sees it now
          const d = P.disc.m.position.clone().normalize().applyQuaternion(K.camera.quaternion.clone().invert()), k = -30 / d.z;
          window.__fake.u = 0.5 + (d.x * k) / K.pic.lx; window.__fake.v = 0.5 - (d.y * k) / K.pic.ly;
        }
        window.__fake.thumb = P.disc && P.step === 2 ? 0.2 : 0.7; // thumb up (a wide gap), dropped onto the finger on the second step
        return 'step ' + P.step + ' disc ' + P.n;
      });
      if (st === 'done') break;
      if (!pshot && st.startsWith('step 2')) { shots.push(await shot('02a-practice')); pshot = true; }
      await page.waitForTimeout(100);
    }
  }
  const practised = await page.evaluate(() => { const K = window.__skeet || window.__fruitVR; return !!K.S.practice; });
  if (!practised) {
    await page.waitForFunction(() => (window.__skeet || window.__fruitVR).S.phase === 'wait', null, { timeout: 15000 });
    await page.waitForTimeout(MODE === 'hand' ? 1500 : 400);
    shots.push(await shot('02-ready'));
    await page.mouse.click(W / 4, H / 2); // the viewer's button is a tap on the screen; it starts the round
  }
  await page.waitForFunction(() => (window.__skeet || window.__fruitVR).S.phase === 'play', null, { timeout: 15000 });

  // play: look at whatever is in the air (gaze), or drop the stand-in thumb now and then (hand)
  let took = false;
  for (let i = 0; i < 900; i++) {
    const st = await K((K, [mode, i]) => {
      const S = K.S; if (S.phase !== 'play') return S.phase;
      // Skeet: a clay that has been in the air half a second (the gaze fires by resting on it). Fruit Slicer: any fruit
      // above the floor; the gaze blade only cuts while moving, so the look sweeps from one side of it to the other.
      const tgt = S.clays ? S.clays.find((o) => o.age > 0.5) : S.fruits.find((o) => o.m.position.y > -1.2);
      if (mode === 'gaze' && tgt) { const q = tgt.m.position, side = S.clays ? 0 : (i % 2 ? 6 : -6); K.look(Math.atan2(-q.x, -q.z) * 57.2958 + side, Math.atan2(q.y, Math.hypot(q.x, q.z)) * 57.2958); }
      return tgt ? 'target' : 'play';
    }, [MODE, i]);
    if (st === 'end') break;
    if (st === 'target' && !took && i > 5) { shots.push(await shot('03-play')); took = true; }
    if (MODE === 'hand') await page.evaluate((i) => (window.__fake.thumb = i % 12 < 4 ? 0.2 : 0.6), i);
    await page.waitForTimeout(80);
  }
  const phase = await K((K) => K.S.phase);
  shots.push(await shot('04-end'));
  const summary = await K((K) => {
    const rows = JSON.parse(localStorage.getItem(window.__skeet ? 'skeetVRRounds' : 'fruitVRRounds') || '[]'), r = rows[rows.length - 1] || null;
    return { version: K.VERSION, mode: K.S.mode, lens: K.lens.on, handFinder: K.handSys.on, handSightings: K.roi.found, crosshairOrBlade: K.blade.ok, practice: K.S.practice || undefined, round: r && { ver: r.ver, hit: r.hit != null ? r.hit : r.sliced, thrown: r.thrown, shots: r.shots != null ? r.shots : r.swipes, cam: r.cam, handOn: r.handOn } };
  });
  let evalResult;
  if (EVAL) evalResult = await page.evaluate(([src]) => { const K = window.__skeet || window.__fruitVR; return new Function('K', 'return (' + src + ')')(K); }, [EVAL]);
  console.log(JSON.stringify({ title, phase, ...summary, eval: evalResult, errors, screenshots: shots }, null, 1));
  await browser.close(); server.close();
  process.exit(errors.length || phase !== 'end' ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
