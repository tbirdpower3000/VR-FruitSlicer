# Fruit Slicer VR

Slice flying fruit in VR with a phone in a Google Cardboard viewer. The phone's
motion sensors follow your head, the fruit is thrown up in front of you, and the
blade is your own hand, seen by the phone's rear camera and tracked in the
browser by [MediaPipe](https://developers.google.com/mediapipe). Rounds last 60
seconds.

This is a standalone spin-out of `fruit-vr.html` from the
[hand-control training app](https://github.com/tbirdpower3000/hand-control-training),
like [Fruitslicer](https://github.com/tbirdpower3000/Fruitslicer) is for the
desktop webcam game.

## Play

Open <https://tbirdpower3000.github.io/VR-FruitSlicer/> on the phone (or scan the QR code on the page from
a computer), press **Start**, allow motion and the camera, turn the phone
sideways and put it in the viewer.

- **Blade: my hand.** Hold a hand out in front of the viewer and swipe with your
  index finger. The viewer must leave the rear camera uncovered.
- **Blade: my gaze.** The blade sits where you look. Used automatically if the
  camera or the hand tracker isn't available.
- **See my room** shows the rear camera behind the fruit instead of the virtual
  room.
- **Widest camera (0.5×)** uses the ultra-wide rear camera where the phone has
  one.
- When a round ends, look at the board for two seconds or press the viewer's
  button to play again. Turn the phone upright to go back to the setup page.

iPhone browsers have no WebXR, so the page draws its own side-by-side stereo
view and head tracking (no lens-distortion correction). It also works with the
phone's rotation lock on. On a desktop it shows a single view you can drag to
look around.

## iPhone app (sideload)

`ios/` holds **VR Browser**, a small browser app for the iPhone that opens this game
full-screen when the phone is turned sideways. GitHub builds it as an `.ipa` you can
sideload with AltStore or Sideloadly; see [ios/README.md](ios/README.md).

## Aim correction

Each round is saved in the browser (`fruitVRRounds`): fruit sliced, swipes that
cut, swipe speed, how often the hand was lost, the tracker's rate, and how far to
the side of each fruit the blade passed. From those side misses the page fits any
steady aim error of the hand blade and moves the blade half-way back for the next
round (`fruitVRBias`, at most 6°). The setup page lists recent rounds and can copy
them as JSON.

## Test switches (URL options)

- `?stereo=0` / `?stereo=1`: force one view or the split view.
- `?t=20`: round length in seconds.
- `window.__fruitVR` in the console exposes the state, `look(yaw, pitch)`,
  `hand(u, v)` and other hooks for automated checks.

## What's inside

A single `index.html` (HTML + CSS + inline JS, no build step) using three.js r128
from cdnjs and MediaPipe Tasks Vision 0.10.14 from jsDelivr, plus
`vendor/qrcode-generator.js` (Kazuhiko Arase, MIT) for the QR code. All sounds
are made in the page with the Web Audio API.

The camera picture is processed on the phone and never leaves it; see
`PRIVACY.md`. Not a medical or diagnostic device; see `DISCLAIMER.md`.

## Credits

Built with Claude by tbirdpower3000 and contributors. Hand tracking by Google
MediaPipe Tasks (Apache-2.0); 3D by three.js (MIT). Code released under the
Apache-2.0 licence (see `LICENSE`).
