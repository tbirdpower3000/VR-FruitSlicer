import UIKit
import WebKit

// Fruit VR: a small shell around the Fruit Slicer VR web page.
// It shows the page edge to edge in landscape with no browser bars, keeps the screen awake, and answers the page's
// camera and motion requests itself so there are no prompts inside the viewer. It is not a general browser: only the
// game's own site is shown, and any other link opens in Safari.

let gameHost = "tbirdpower3000.github.io"
let gameURL = URL(string: "https://tbirdpower3000.github.io/VR-FruitSlicer/?app=1")!

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    let w = UIWindow(frame: UIScreen.main.bounds)
    w.rootViewController = GameViewController()
    w.makeKeyAndVisible()
    window = w
    application.isIdleTimerDisabled = true
    return true
  }
}

final class GameViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
  private var web: WKWebView!
  private let message = UILabel()
  private let retry = UIButton(type: .system)
  private let lidar = Lidar()

  override var prefersStatusBarHidden: Bool { true }
  override var prefersHomeIndicatorAutoHidden: Bool { true }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    let cfg = WKWebViewConfiguration()
    cfg.allowsInlineMediaPlayback = true
    cfg.mediaTypesRequiringUserActionForPlayback = []
    // lets the page know it is running inside this app
    // (and whether this phone has a LiDAR sensor)
    cfg.userContentController.addUserScript(WKUserScript(source: "window.FRUITVR_APP = { version: 2, lidar: \(Lidar.supported) };", injectionTime: .atDocumentStart, forMainFrameOnly: true))
    // the page switches the LiDAR sensor on and off with webkit.messageHandlers.fruitvr.postMessage({ lidar: true })
    cfg.userContentController.add(self, name: "fruitvr")
    lidar.onReading = { [weak self] r in self?.send(r) }

    web = WKWebView(frame: view.bounds, configuration: cfg)
    web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    web.uiDelegate = self
    web.navigationDelegate = self
    web.isOpaque = false
    web.backgroundColor = .black
    web.scrollView.backgroundColor = .black
    web.scrollView.contentInsetAdjustmentBehavior = .never
    web.scrollView.bounces = false
    view.addSubview(web)

    message.textColor = .white
    message.numberOfLines = 0
    message.textAlignment = .center
    message.isHidden = true
    retry.setTitle("Try again", for: .normal)
    retry.titleLabel?.font = .boldSystemFont(ofSize: 20)
    retry.isHidden = true
    retry.addTarget(self, action: #selector(load), for: .touchUpInside)
    let stack = UIStackView(arrangedSubviews: [message, retry])
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      stack.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8),
    ])

    // two fingers, tapped twice: load the page again (there is no reload button without browser bars)
    let reload = UITapGestureRecognizer(target: self, action: #selector(load))
    reload.numberOfTouchesRequired = 2
    reload.numberOfTapsRequired = 2
    view.addGestureRecognizer(reload)

    load()
  }

  // the page's messages to the app; only the game's own site may switch the sensor
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.frameInfo.isMainFrame, message.frameInfo.securityOrigin.host == gameHost,
          let body = message.body as? [String: Any], let on = body["lidar"] as? Bool else { return }
    if on { lidar.start() } else { lidar.stop() }
  }

  // a LiDAR reading goes to the page as a "fruitvr-lidar" event: { c: metres straight ahead, hand: { u, v, d } }
  private func send(_ r: Lidar.Reading) {
    guard lidar.running else { return }
    // the camera's picture is the right way up with the phone's charging end to the right; the other way it is turned over
    let flip = view.window?.windowScene?.interfaceOrientation == .landscapeLeft
    var hand = "null"
    if let h = r.hand {
      let u = flip ? 1 - h.u : h.u, v = flip ? 1 - h.v : h.v
      hand = String(format: "{u:%.4f,v:%.4f,d:%@}", u, v, h.d.map { String(format: "%.3f", $0) } ?? "null")
    }
    let c = r.centre.map { String(format: "%.3f", $0) } ?? "null"
    web.evaluateJavaScript("window.dispatchEvent(new CustomEvent('fruitvr-lidar',{detail:{c:\(c),hand:\(hand)}}))", completionHandler: nil)
  }

  // a new page starts with the sensor off
  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { lidar.stop() }

  @objc private func load() {
    message.isHidden = true
    retry.isHidden = true
    web.isHidden = false
    web.load(URLRequest(url: gameURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 30))
  }

  private func fail(_ error: Error) {
    let e = error as NSError
    if e.domain == NSURLErrorDomain && e.code == NSURLErrorCancelled { return }
    web.isHidden = true
    message.text = "The game could not be loaded.\n\(e.localizedDescription)"
    message.isHidden = false
    retry.isHidden = false
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail(error) }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail(error) }

  // only the game's own site is shown here; anything else goes to Safari
  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
    if navigationAction.targetFrame?.isMainFrame == false || url.host == gameHost || url.scheme == "about" || url.scheme == "blob" {
      return decisionHandler(.allow)
    }
    UIApplication.shared.open(url)
    decisionHandler(.cancel)
  }

  // the page's camera and motion requests: allowed for the game's own site, asked about for anything else
  func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
    decisionHandler(origin.host == gameHost && type == .camera ? .grant : .prompt)
  }

  func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
    decisionHandler(origin.host == gameHost ? .grant : .prompt)
  }
}
