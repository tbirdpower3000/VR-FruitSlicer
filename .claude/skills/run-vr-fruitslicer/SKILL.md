---
name: run-vr-fruitslicer
description: Run, drive, test and screenshot Fruit Slicer VR (the Cardboard VR game in this repo). Use when asked to run or start the game, play a round, take a screenshot of it, check a change works, or test the hand tracking, lens fitting or camera code.
---

Fruit Slicer VR is one static page, `index.html`, with no build step. Drive it with
`.claude/skills/run-vr-fruitslicer/driver.cjs`: it serves the repo, opens the game in headless
Chromium with a stand-in camera and hand tracker, plays a short round, saves four
screenshots and prints a JSON summary. Paths are relative to the repo root.

## Prerequisites

Node with Playwright and its Chromium (both preinstalled in Claude's cloud container;
`require('playwright')` resolves from any directory). The first run takes three.js
r128 from npm, so npm must be reachable.

## Run (agent path)

A round aimed by gaze, no camera:

```bash
node .claude/skills/run-vr-fruitslicer/driver.cjs
```

A round with the hand tracker (stand-in camera and stand-in hand), lens fitting off,
screenshots to a folder of your choice, and a value read out of the page at the end:

```bash
node .claude/skills/run-vr-fruitslicer/driver.cjs --mode hand --lens off --out /tmp/vr-run-hand --eval 'K.roi.found'
```

- **Options:** `--mode gaze|hand` (default gaze), `--lens on|off` (the Cardboard lens
  fitting, default on), `--out DIR` (default `/tmp/vr-run`), `--size 852x393`,
  `--eval 'JS'` (an expression evaluated in the page after the round; `K` is the
  game's test hook, `window.__fruitVR`).
- **Screenshots:** `01-setup.png`, `02-ready.png`, `03-play.png`, `04-end.png` in the
  out folder. Look at them: the summary can be clean while the picture is wrong.
- **Summary:** title with version, final phase (`end` when the round finished), the
  saved round, which hand finder ran, how many hand sightings, and page errors.
- **Exit code:** 1 if the page threw an error or the round did not reach `end`.

What a healthy gaze run prints: `"phase": "end"`, a round with most of the fruit sliced (8 of 8 when written), and `"errors": []`.

The hook `window.__fruitVR` exposes the state (`S`, with `S.phase` going
`wait → count → play → end`), `look(yawDeg, pitchDeg)` to point the head,
`blade`, `lens`, `roi`, `handSys` and `VERSION`. The stand-in hand is
`window.__fake = { on, u, v, hw, thumb }` (see `fake-hands.mjs`).

## Check the page parses

Run this after every edit to `index.html`; a syntax error otherwise shows up only as
a timeout in the driver.

```bash
node -e "const s=require('fs').readFileSync('index.html','utf8'); for (const x of s.matchAll(/<script>([\\s\\S]*?)<\\/script>/g)) new Function(x[1]); console.log('scripts parse')"
```

## Run (human path)

```bash
python3 -m http.server 8765
```

Then open `http://localhost:8765/?stereo=1` in a desktop browser, choose **My gaze**,
press Start, click the picture to begin, and drag to look around. Useless headless.

## After a change

Raise `VERSION` in `index.html` by one and add a line to **Versions** in `README.md`.
GitHub Pages deploys `main`; the live site cannot be fetched from Claude's sandbox,
so confirm the deploy with:

```bash
gh run list --repo tbirdpower3000/VR-FruitSlicer --limit 1
```

## Gotchas

- **three.js comes from cdnjs, which the sandbox blocks.** Without the driver's
  substitution the page loads but the game script never runs, and the hook is
  undefined. The driver serves an npm copy of three 0.128.0 in its place.
- **The hand tracker comes from jsDelivr and Google storage.** The driver swaps in
  `fake-hands.mjs`. Like the real one, it cannot see a hand narrower than a fifth of
  the picture it is given, so the page's zoomed search still gets exercised.
- **No camera in headless Chromium** unless it is launched with
  `--use-fake-device-for-media-stream --use-fake-ui-for-media-stream` and the context
  is granted `camera`. Without them the game falls back to gaze. The stand-in camera
  picture is a green screen with a moving shape; that is what "See my room" shows.
- **The round waits for a tap.** After Start the phase is `wait` until the picture is
  clicked (the viewer's button). A drag does not count as a tap.
- **The split view only appears on touch devices.** Add `?stereo=1` on a desktop.
- **Short rounds:** `?n=4` sets the clays in a Skeet round, `?t=8` the seconds in a
  Fruit Slicer round. The driver passes both.
- **Lens fitting is a shared setting.** It lives in `localStorage.vrLens` and is shared
  by every game on the site; the driver sets it before the page loads.
- **"GPU stall due to ReadPixels" console warnings** come from taking screenshots with
  software rendering. They are harmless.
- **The gaze blade only cuts while it is moving** (12 degrees a second or more), so the driver sweeps the look from one side of a fruit to the other. Looking straight at a fruit cuts nothing.
- **A fruit's `age` stops counting at 0.2 s** (it only drives the grow-in), so do not use it to pick targets.
- **The `ios/` folder** is a Swift wrapper app built by GitHub Actions on a Mac runner. It cannot be built or run in this container.

## Troubleshooting

- **Driver times out waiting for the hook:** the game script did not run. Check the
  page parses (above), and that `/tmp/vr-run-three/package/build/three.min.js` exists;
  delete `/tmp/vr-run-three` to make the driver fetch it again.
- **`mode` in the summary is `head` when you asked for hand:** the camera or tracker
  did not start. Press Exit in a headed run, or read `#status`, for the reason.
- **`handSightings` is 0 in hand mode:** the stand-in hand is outside every part of the
  picture the page looks at, or smaller than a tenth of the picture; check `__fake`.
