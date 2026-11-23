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
sideways and put it in the viewer. The round starts when you press the viewer's
button (a tap on the screen).

- **Blade: my hand.** Hold a hand out in front of the viewer and swipe with your
  index finger. The viewer must leave the rear camera uncovered.
- **Blade: my gaze.** The blade sits where you look. Used automatically if the
  camera or the hand tracker isn't available.
- **See my room** shows the rear camera behind the fruit instead of the virtual
  room.
- The page always opens the rear camera with the widest view: the ultra-wide (0.5×)
  one where the phone has it, zoomed out as far as it goes.
- When a round ends, look at the board for two seconds or press the viewer's
  button to play again. Turn the phone upright to go back to the setup page.

iPhone browsers have no WebXR, so the page draws its own side-by-side stereo
view and head tracking (no lens-distortion correction). It also works with the
phone's rotation lock on. On a desktop it shows a single view you can drag to
look around.

## iPhone app (unofficial, sideloaded)

`ios/` holds a small iPhone app, **Fruit VR**, that runs this page edge to edge in
landscape: no browser bars, the screen stays awake, and camera and motion are
allowed for this site without prompts. It is not in the App Store; it is built
unsigned and you install it on your own phone by sideloading.

1. Download **FruitVR.ipa** from the
   [ios-latest release](https://github.com/tbirdpower3000/VR-FruitSlicer/releases/tag/ios-latest).
2. Install `FruitVR.ipa` with a sideloading tool such as AltStore, SideStore or
   Sideloadly, which signs it with your own Apple ID.
3. On the phone, turn on **Settings → Privacy & Security → Developer Mode** if
   asked, and trust your Apple ID under **Settings → General → VPN & Device
   Management**.

With a free Apple ID the app stops opening after 7 days until it is refreshed
with the same tool. The app loads the game from this site, so it needs a
connection and always runs the current page. A two-finger double tap reloads.

**LiDAR distance (app only).** On an iPhone with a LiDAR sensor (Pro models, 12 Pro
and later) the setup page inside the app shows a **LiDAR distance** switch. With it on,
a line above the score shows the distance to whatever is straight ahead (📏) and to your
hand when the sensor's camera sees it (✋), about ten times a second. The sensor needs the
rear camera to itself, so with LiDAR on the blade follows your gaze and the virtual room
is shown. The app reads the sensor through ARKit and finds the hand with Apple's Vision
hand finder (`ios/Sources/Lidar.swift`), and passes the numbers to the page as
`fruitvr-lidar` events. Not yet confirmed on a phone.

It is built by `.github/workflows/ios.yml` on a macOS runner: XcodeGen makes the
project from `ios/project.yml` and `xcodebuild` builds the Swift files in `ios/Sources/`.
The app compiles and packages; it has not yet been confirmed on a phone.

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
