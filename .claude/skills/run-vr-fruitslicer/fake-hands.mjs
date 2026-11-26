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
        if (!f || !f.on) return none;
        const crop = src && src.tagName === 'CANVAS', s = crop ? K.roi.sUsed : 1, l = crop ? K.roi.lUsed : 0, t = crop ? K.roi.tUsed : 0;
        const size = (f.hw || 0.11) / s, x = (f.u - l) / s, y = (f.v - t) / s;
        if (size < 0.2 || x - size / 2 < 0 || x + size / 2 > 1 || y < 0 || y + size > 1) return none;
        const lm = Array.from({ length: 21 }, (_, i) => ({ x: x - size / 2 + (size * (i % 5)) / 4, y: y + (size * Math.floor(i / 5)) / 4, z: 0 }));
        lm[8] = { x, y, z: 0 };
        const w = Array.from({ length: 21 }, () => ({ x: 0, y: 0, z: 0 }));
        // a hand in metres: index finger along -y; the thumb at an angle to it of (thumb x 90) degrees, so thumb 0.6 is
        // 54 degrees (up) and 0.2 is 18 degrees (laid along the finger)
        w[9] = { x: 0, y: -0.09, z: 0 }; w[5] = { x: -0.02, y: -0.085, z: 0 }; w[6] = { x: -0.02, y: -0.125, z: 0 }; w[8] = { x: -0.02, y: -0.165, z: 0 }; w[17] = { x: 0.04, y: -0.075, z: 0 };
        w[2] = { x: -0.04, y: -0.05, z: 0 };
        { const a = ((f.thumb == null ? 0.6 : f.thumb) * 90 * Math.PI) / 180; w[4] = { x: w[2].x - 0.06 * Math.sin(a), y: w[2].y - 0.06 * Math.cos(a), z: 0 }; }
        return { landmarks: [lm], worldLandmarks: [w], handednesses: [[{ categoryName: 'Right' }]] };
      },
    };
  },
};
