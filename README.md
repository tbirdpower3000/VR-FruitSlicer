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
- **Camera lens:** Auto, Fisheye (the widest, 0.5×, zoomed out as far as it goes) or
  Regular. Fisheye sees more and keeps your hand in view further out; Regular shows your
  hand larger and steadier.
- When a round ends, look at the board for two seconds or press the viewer's
  button to play again. Turn the phone upright to go back to the setup page.

iPhone browsers have no WebXR, so the page draws its own side-by-side stereo
view and head tracking, with each eye's picture fitted to a 2015 Google Cardboard's lenses. It also works with the
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

## Fitting the picture to the lenses

With **Fit the picture to the lenses** on (the default), each eye's picture is made for
a Google Cardboard of 2015 (I/O 2015, "version 2"), using the figures in Google's own
viewer profile: lenses 63.9 mm apart and 39.3 mm from the screen, their centres 35 mm
above the edge the phone rests on, and distortion coefficients k1 = 0.33582564,
k2 = 0.55348791.

- **Centred on each lens.** Each eye's view is drawn about its own lens's axis, not
  about the middle of its half of the screen.
- **True size.** Angles on screen match angles in the scene, from the screen's real
  size (taken as an iPhone's, 460 pixels to the inch).
- **Lens stretch taken out.** The lenses stretch the picture more towards the edges.
  Each eye is first drawn flat, off screen, then put on the screen squeezed the
  opposite way, so through the lens straight lines look straight.
- **Field of view.** Google designed this lens for a round field 80° across, so the
  picture is drawn out to 45° from the lens's axis and fades to black from 41°.

**Picture size** (80% to 125%) is for phones whose screens are not an iPhone's size per
pixel. Both settings are kept in the browser (`vrLens`) and shared by the games on
this site. Checked in a desktop browser; not yet looked at through a viewer.

## Versions

The version is shown beside the title on the setup page and saved with every round
(`ver`). It goes up by one with every change to the game. Newest first.

- **v0.15** (27 Nov 2026): Clean-up, no change to play: fields that were written and never read are gone, and this page's notes on the camera and the lens fitting are brought up to date.
- **v0.14** (26 Nov 2026): A choice of camera lens on the setup page: Auto, Fisheye (widest) or Regular. In Auto the widest camera is tried again after a single failure and left alone only after failing twice running (engine 1.1.0)
- **v0.13** (26 Nov 2026): Runs on the shared VR engine (the VR-Portal repo, engine 1.0.0): the drawing surface, lens fitting, text signs, camera, hand finder, sound and saved settings are loaded from there and no longer kept in this page. Nothing should look or play differently
- **v0.12** (26 Nov 2026): Version numbers: shown beside the title, saved with each round
- **v0.11** (26 Nov 2026): Hand finder: look at a part of the picture that follows the hand
- **v0.10** (26 Nov 2026): Hand finder: fall back to the processor, and say what went wrong
- **v0.9** (26 Nov 2026): Ask the camera for 60 pictures a second
- **v0.8** (26 Nov 2026): Fit the picture to the lenses of a Google Cardboard (2015)
- **v0.7** (23 Nov 2026): Throw the fruit ahead of where the player looks as the round begins
- **v0.6** (23 Nov 2026): Safer camera switch, as in Skeet VR
- **v0.5** (23 Nov 2026): Always open the rear camera with the widest view
- **v0.4** (23 Nov 2026): Throw the fruit from further away
- **v0.3** (23 Nov 2026): Wait for the viewer's button before the first round
- **v0.2** (23 Nov 2026): LiDAR distance: a switch and an in-view readout (iPhone app)
- **v0.1** (23 Nov 2026): Fruit Slicer VR: standalone spin-out of fruit-vr.html

## Design notes

**The shared engine.** About half of this page used to be the same code as Skeet VR's,
copied by hand. That half now lives once, in the
[VR-Portal](https://github.com/tbirdpower3000/VR-Portal) repo, and this page loads it
from `https://tbirdpower3000.github.io/VR-Portal/v1/vr-engine.js`. Before the change, each
shared part of this page was compared with the code the engine was made from and found
identical. The page keeps what is Fruit Slicer's own: head tracking, the blade, the aim
correction, the fruit, the scoring and the LiDAR readout. If the engine cannot be loaded,
the setup page says so and Start is switched off.

**Finding a small hand through the widest camera.** With the fisheye lens (the choice on the start page; Auto prefers it) the game opens
the widest rear camera, and through it a hand at arm's length is only about a tenth of the
picture's width. The hand finder first shrinks the picture to a small square, where a
hand that size cannot be made out. So the hand finder is given a part of the picture
half as wide and half as tall, in which the hand looks twice the size. The part follows
the hand; while no hand is found it steps round the picture (middle, below, sides,
above, then the whole picture for a hand held close). The view behind the game still
shows the whole wide picture.

**The hand finder's two ways of running.** It is tried on the phone's graphics chip
first. If it cannot be set up there, or fails on twenty pictures running, it is made on
the ordinary processor instead. After a round, the line under Start says which is in
use and what went wrong, and both are saved with the round.

**Safari's address bar in the viewer.** On an iPhone a web page cannot hide Safari's
address bar or toolbar: iPhone Safari does not offer full screen to pages (Android
browsers and iPads do). So the page does not try. The ways to play without the bar:

- **Add to Home Screen** (Share → Add to Home Screen) and open the game from its icon.
  It then runs with no browser bars. This is the recommended way. Rounds saved in a
  Safari tab are kept separately from rounds saved from the icon.
- **Hide Toolbar** from Safari's page menu (the aA button). The bar returns when the
  top of the screen is tapped, so it is less dependable inside a viewer.
- A wrapper app with no browser bars (the sideloaded Fruit VR app).

The lens fitting measures up from the bottom edge of the picture, which is the edge
the phone rests on in the viewer. A bar across the top therefore costs a strip of
picture but does not move the picture off the lenses.

Not built yet: asking for full screen on Start where the browser allows it (Android,
iPad), and a one-line tip on the setup page when the game is open in an iPhone Safari
tab.

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
