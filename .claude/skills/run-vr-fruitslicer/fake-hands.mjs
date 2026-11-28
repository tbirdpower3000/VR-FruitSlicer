// A stand-in for the MediaPipe hand finder, served in place of vision_bundle.mjs by driver.cjs.
// The page reads window.__fake = { on, u, v, hw, thumb }: the index fingertip at (u, v) in the whole camera picture
// (0..1 across and down), the hand hw of the picture wide, and the thumb reading (about 0.6 up, 0.2 dropped).
// Like the real finder, it cannot see a hand narrower than a fifth of the picture it is handed, so the page's
// "look at part of the picture" search is exercised too.
export const FilesetResolver = { forVisionTasks: async () => ({}) };
export const HandLandmarker = {
  createFromOptions: async (fs, opts) => {
    const delegate = opts.baseOptions.delegate;
    (window.__made = window.__made || []).push(delegate);
    if (delegate === 'GPU' && window.__gpuFails) throw new Error('stand-in: graphics chip refused');
    return {
      close() {},
      detectForVideo(src) {
        const f = window.__fake, K = window.__skeet || window.__fruitVR, none = { landmarks: [], worldLandmarks: [], handednesses: [] };
        // A recording of a real hand (the game's "Record my hand", handed over by driver.cjs --replay) is played back in
        // place of the made-up hand: each look returns the recorded points for that moment, and the head is turned to
        // where the recorded head pointed. The points are whole-picture, so they are put back into the part looked at.
        const R = window.__replay;
        if (R) {
          const t = performance.now() - (R.start = R.start || performance.now());
          let i = R.i || 0; while (i + 1 < R.f.length && R.f[i + 1][0] <= t) i++;
          R.i = i; const r = R.f[i];
          R.done = i + 1 >= R.f.length;
          let j = R.j || 0; while (j + 1 < R.f.length && R.f[j + 1][0] - R.f[j + 1][1] <= t) j++; // the head as it is now, not as it was when the picture was taken
          R.j = j; if (K.headQ) K.headQ(R.f[j].slice(2, 6).map((v) => v / 1e4));
          if (R.done || !r[6] || r === R.last) return none; // one recorded look is handed back once, as one camera picture is
          R.last = r;
          const crop = src && src.tagName === 'CANVAS', s = crop ? K.roi.sUsed : 1, l = crop ? K.roi.lUsed : 0, tp = crop ? K.roi.tUsed : 0;
          const lm = [], w = [];
          for (let k = 0; k < 21; k++) { lm.push({ x: (r[7 + 2 * k] / 1e4 - l) / s, y: (r[8 + 2 * k] / 1e4 - tp) / s, z: 0 }); w.push({ x: r[49 + 3 * k] / 1e4, y: r[50 + 3 * k] / 1e4, z: r[51 + 3 * k] / 1e4 }); }
          if (lm.some((q) => q.x < 0 || q.x > 1 || q.y < 0 || q.y > 1)) return none; // outside the part of the picture being looked at
          R.seen = (R.seen || 0) + 1;
          return { landmarks: [lm], worldLandmarks: r[112] ? [w] : [], handednesses: [[{ categoryName: 'Right' }]] };
        }
        if (!f || !f.on) return none;
        const crop = src && src.tagName === 'CANVAS', s = crop ? K.roi.sUsed : 1, l = crop ? K.roi.lUsed : 0, t = crop ? K.roi.tUsed : 0;
        const size = (f.hw || 0.11) / s, x = (f.u - l) / s, y = (f.v - t) / s;
        if (size < 0.2 || x - size / 2 < 0 || x + size / 2 > 1 || y < 0 || y + size > 1) return none;
        const lm = Array.from({ length: 21 }, (_, i) => ({ x: x - size / 2 + (size * (i % 5)) / 4, y: y + (size * Math.floor(i / 5)) / 4, z: 0 }));
        lm[8] = { x, y, z: 0 };
        const w = Array.from({ length: 21 }, () => ({ x: 0, y: 0, z: 0 }));
        // a hand in metres. The thumb's tip sits (thumb x hand size) from the base of the index finger, so thumb 0.6 is
        // a wide gap (up) and 0.2 a closed one (dropped onto the finger), which is what the game's trigger reads.
        w[9] = { x: 0, y: -0.09, z: 0 }; w[5] = { x: -0.02, y: -0.085, z: 0 }; w[6] = { x: -0.02, y: -0.125, z: 0 }; w[8] = { x: -0.02, y: -0.165, z: 0 }; w[17] = { x: 0.04, y: -0.075, z: 0 };
        w[2] = { x: -0.04, y: -0.05, z: 0 }; w[4] = { x: -0.02 - 0.086 * (f.thumb == null ? 0.6 : f.thumb), y: -0.1, z: 0 }; w[3] = { x: (w[2].x + w[4].x) / 2, y: (w[2].y + w[4].y) / 2, z: 0 };
        return { landmarks: [lm], worldLandmarks: [w], handednesses: [[{ categoryName: f.label || 'Right' }]] }; // f.label: which hand the finder says it is
      },
    };
  },
};
