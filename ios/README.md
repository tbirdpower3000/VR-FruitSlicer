# VR Browser for iPhone

A small browser app for a phone in a Google Cardboard viewer, made to be sideloaded.
It opens Fruit Slicer VR as its home page and can open any other address.

- **Upright:** an ordinary browser with back, forward, reload, an address bar and a home button.
- **Sideways:** viewer mode. The bars, the status bar and the home indicator go away and the
  page fills the whole screen. The screen stays on, and the picture turns sideways even when
  the phone's rotation lock is on. Turn the phone upright to get the browser back.
- The glasses button switches viewer mode on and off.
- Fruit Slicer VR gets the camera and motion sensors without a prompt on every visit. Other
  sites are asked about each time. (iOS still asks once whether the app may use the camera.)

Rounds saved in the app are separate from rounds saved in Safari.

## Install it (Windows or Mac, free Apple ID)

1. Download **VRBrowser.ipa** from the
   [ios-latest release](https://github.com/tbirdpower3000/VR-FruitSlicer/releases/tag/ios-latest).
2. Install it with [Sideloadly](https://sideloadly.io/) or [AltStore](https://altstore.io/),
   the same way as any sideloaded app: plug in the phone, choose the `.ipa`, sign in with
   your Apple ID.
3. On the phone: **Settings → General → VPN & Device Management**, trust your Apple ID.
   On iOS 16 and later also turn on **Settings → Privacy & Security → Developer Mode**.

With a free Apple ID the app stops opening after 7 days and has to be installed again
(AltStore can refresh it by itself over Wi-Fi). Nothing saved in the app is lost by a refresh.

## How it is built

No Mac is needed. `.github/workflows/ios.yml` runs on GitHub's Mac machines whenever
something in `ios/` changes on `main`: it makes the Xcode project from `project.yml` with
XcodeGen, builds the app unsigned, zips it as an `.ipa` and publishes it as the `ios-latest`
release. Sideloadly or AltStore sign it with your own Apple ID when they install it.

- `Sources/BrowserViewController.swift`: the whole browser (a `WKWebView`, the bar, viewer mode).
- `Sources/AppDelegate.swift`: starts it.
- `project.yml`: app name, bundle id, permissions text, iOS 16 minimum.

To build on a Mac instead: `brew install xcodegen && cd ios && xcodegen generate`, then open
`VRBrowser.xcodeproj`.
