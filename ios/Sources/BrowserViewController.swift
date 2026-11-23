import UIKit
import WebKit
import CoreMotion

/// A small browser for a phone in a Cardboard viewer.
///
/// Upright, it is an ordinary browser with an address bar. Turned sideways it becomes "viewer mode": the bars, the
/// status bar and the home indicator go away, the page fills the whole screen, the screen stays on, and the picture is
/// turned sideways even when the phone's rotation lock is on. Turning the phone upright brings the browser back.
final class BrowserViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UITextFieldDelegate {
    static let home = URL(string: "https://tbirdpower3000.github.io/VR-FruitSlicer/")!
    /// Pages on these hosts get the camera and motion sensors without being asked each time.
    static let trustedHosts: Set<String> = ["tbirdpower3000.github.io"]

    private var webView: WKWebView!
    private let bar = UIStackView()
    private let urlField = UITextField()
    private let progress = UIProgressView(progressViewStyle: .bar)
    private var backButton: UIButton!
    private var forwardButton: UIButton!
    private var autoButton: UIButton!
    private var webTopToBar: NSLayoutConstraint!
    private var webTopToView: NSLayoutConstraint!
    private var observers: [NSKeyValueObservation] = []

    private let motion = CMMotionManager()
    private var viewer = false                                   // viewer mode is on
    private var viewerSide: UIInterfaceOrientationMask = .landscapeRight
    private var pending = 0, pendingSince = Date()               // the side the phone seems to be on, and since when
    private var autoViewer: Bool {
        get { UserDefaults.standard.object(forKey: "autoViewer") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autoViewer") }
    }

    // MARK: set-up

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 7 / 255, green: 11 / 255, blue: 20 / 255, alpha: 1)
        overrideUserInterfaceStyle = .dark

        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.applicationNameForUserAgent = "Version/17.0 Mobile/15E148 Safari/604.1"
        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = view.backgroundColor
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        backButton = makeButton("chevron.backward", #selector(goBack), "Back")
        forwardButton = makeButton("chevron.forward", #selector(goForward), "Forward")
        let reload = makeButton("arrow.clockwise", #selector(reloadPage), "Reload")
        let homeButton = makeButton("house", #selector(goHome), "Home")
        autoButton = makeButton("eyeglasses", #selector(toggleAuto), "Viewer mode when the phone is sideways")

        urlField.borderStyle = .roundedRect
        urlField.keyboardType = .webSearch
        urlField.returnKeyType = .go
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.clearButtonMode = .whileEditing
        urlField.placeholder = "Search or enter address"
        urlField.font = .systemFont(ofSize: 15)
        urlField.delegate = self
        urlField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        urlField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        bar.axis = .horizontal
        bar.spacing = 2
        bar.alignment = .center
        bar.isLayoutMarginsRelativeArrangement = true
        bar.layoutMargins = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        bar.translatesAutoresizingMaskIntoConstraints = false
        [backButton, forwardButton, reload, urlField, homeButton, autoButton].forEach { bar.addArrangedSubview($0) }
        view.addSubview(bar)

        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        view.addSubview(progress)

        let safe = view.safeAreaLayoutGuide
        webTopToBar = webView.topAnchor.constraint(equalTo: bar.bottomAnchor)
        webTopToView = webView.topAnchor.constraint(equalTo: view.topAnchor)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: safe.topAnchor),
            bar.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            progress.topAnchor.constraint(equalTo: bar.bottomAnchor),
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webTopToBar,
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        observers = [
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in self?.refreshBar() },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in self?.refreshBar() },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in self?.refreshBar() },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in self?.refreshProgress() },
        ]
        refreshBar()
        refreshAutoButton()
        webView.load(URLRequest(url: Self.home))
        startMotion()
    }

    private func makeButton(_ symbol: String, _ action: Selector, _ label: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: symbol), for: .normal)
        b.accessibilityLabel = label
        b.addTarget(self, action: action, for: .touchUpInside)
        b.widthAnchor.constraint(equalToConstant: 38).isActive = true
        b.heightAnchor.constraint(equalToConstant: 38).isActive = true
        return b
    }

    // MARK: the bar

    private func refreshBar() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        if !urlField.isFirstResponder { urlField.text = webView.url?.absoluteString }
    }

    private func refreshProgress() {
        let p = Float(webView.estimatedProgress)
        progress.isHidden = viewer || p >= 1
        progress.progress = p
    }

    private func refreshAutoButton() {
        autoButton.tintColor = autoViewer ? UIColor(red: 1, green: 216 / 255, blue: 138 / 255, alpha: 1) : .secondaryLabel
        autoButton.accessibilityValue = autoViewer ? "On" : "Off"
    }

    @objc private func goBack() { webView.goBack() }
    @objc private func goForward() { webView.goForward() }
    @objc private func reloadPage() { webView.reload() }
    @objc private func goHome() { webView.load(URLRequest(url: Self.home)) }

    @objc private func toggleAuto() {
        autoViewer.toggle()
        refreshAutoButton()
        let note = UIAlertController(
            title: autoViewer ? "Viewer mode: on" : "Viewer mode: off",
            message: autoViewer
                ? "Turn the phone sideways and the page fills the screen for the viewer. Turn it upright to get the browser back."
                : "The page no longer fills the screen when the phone is turned sideways.",
            preferredStyle: .alert)
        note.addAction(UIAlertAction(title: "OK", style: .default))
        present(note, animated: true)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async { textField.selectAll(nil) }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let text = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { refreshBar(); return true }
        var target: URL?
        if text.contains("://") {
            target = URL(string: text)
        } else if !text.contains(" ") && (text.contains(".") || text.hasPrefix("localhost")) {
            target = URL(string: "https://" + text)
        }
        if target == nil {
            var c = URLComponents(string: "https://duckduckgo.com/")!
            c.queryItems = [URLQueryItem(name: "q", value: text)]
            target = c.url
        }
        if let target = target { webView.load(URLRequest(url: target)) }
        return true
    }

    // MARK: viewer mode

    /// The phone's own accelerometer says which way the phone is held, whatever the rotation lock says.
    private func startMotion() {
        guard motion.isAccelerometerAvailable else { return }
        motion.accelerometerUpdateInterval = 0.1
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let a = data?.acceleration else { return }
            // 0: upright, 1: on its side with the left edge down, 2: on its side with the right edge down, -1: unclear (flat)
            var side = -1
            if abs(a.x) > 0.75 { side = a.x < 0 ? 1 : 2 } else if abs(a.y) > 0.75 && abs(a.x) < 0.4 { side = 0 }
            if side != self.pending { self.pending = side; self.pendingSince = Date(); return }
            guard side >= 0, Date().timeIntervalSince(self.pendingSince) > 0.4 else { return }
            if side == 0 {
                if self.viewer { self.setViewer(false, side: self.viewerSide) }
            } else if self.autoViewer {
                // left edge down is the picture's "landscape right", and the other way round
                let mask: UIInterfaceOrientationMask = side == 1 ? .landscapeRight : .landscapeLeft
                if !self.viewer || mask != self.viewerSide { self.setViewer(true, side: mask) }
            }
        }
    }

    private func setViewer(_ on: Bool, side: UIInterfaceOrientationMask) {
        if on && presentedViewController != nil { return } // a message is showing
        viewer = on
        viewerSide = side
        if on { urlField.resignFirstResponder() }
        bar.isHidden = on
        progress.isHidden = on || webView.estimatedProgress >= 1
        webTopToBar.isActive = !on
        webTopToView.isActive = on
        webView.allowsBackForwardNavigationGestures = !on
        UIApplication.shared.isIdleTimerDisabled = on
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        setNeedsUpdateOfSupportedInterfaceOrientations()
        view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: on ? side : .portrait)) { _ in }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { viewer ? viewerSide : .allButUpsideDown }
    override var prefersStatusBarHidden: Bool { viewer }
    override var prefersHomeIndicatorAutoHidden: Bool { viewer }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { viewer ? .all : [] }

    // MARK: web view

    private func trusted(_ origin: WKSecurityOrigin) -> Bool {
        origin.protocol == "https" && Self.trustedHosts.contains(origin.host)
    }

    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(trusted(origin) ? .grant : .prompt)
    }

    func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(trusted(origin) ? .grant : .prompt)
    }

    /// Links that ask for a new window open here instead.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(a, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(a, animated: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let e = error as NSError
        if e.domain == NSURLErrorDomain && e.code == NSURLErrorCancelled { return }
        let a = UIAlertController(title: "The page could not be opened", message: e.localizedDescription, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
