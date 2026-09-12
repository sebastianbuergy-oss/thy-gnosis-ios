import UIKit
import WebKit

/// Hosts the bundled Thy Gnosis web app. The page itself is local (file://),
/// the Bandcamp players are https iframes inside it, and the page fetches
/// its live feed (concerts, news) over https on launch. Anything that would
/// leave the page in the main frame (Bandcamp, Spotify, YouTube, tickets,
/// mailto) is handed to the system instead, so Safari, Mail or the store app
/// opens and this app stays on its own screen.
@MainActor
final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var webRoot: URL!
    private let ground = UIColor(red: 11 / 255, green: 11 / 255, blue: 13 / 255, alpha: 1)

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ground

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        if configuration.preferences.responds(to: NSSelectorFromString("_setAllowFileAccessFromFileURLs:")) {
            configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        }

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = ground
        webView.scrollView.backgroundColor = ground
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        guard let root = Bundle.main.url(forResource: "web", withExtension: nil) else {
            showFailure("Die App-Dateien fehlen im Build.")
            return
        }
        webRoot = root.standardizedFileURL
        webView.loadFileURL(root.appendingPathComponent("index.html"), allowingReadAccessTo: root)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    /// Coming back to the app re-checks the live feed (new dates, news).
    @objc private func didBecomeActive() {
        webView?.evaluateJavaScript("window.dispatchEvent(new Event('app-active'))")
    }

    private func isBundled(_ url: URL?) -> Bool {
        guard let url, url.isFileURL, let webRoot else { return false }
        return url.standardizedFileURL.path.hasPrefix(webRoot.path + "/")
    }

    private func openExternally(_ url: URL) {
        guard ["https", "http", "mailto"].contains(url.scheme ?? "") else { return }
        UIApplication.shared.open(url)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let url = navigationAction.request.url
        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true

        if isMainFrame {
            if isBundled(url) || url?.absoluteString == "about:blank" {
                decisionHandler(.allow)
            } else {
                if let url { openExternally(url) }
                decisionHandler(.cancel)
            }
            return
        }

        // Sub-frames: the Bandcamp players and whatever they load themselves.
        if let url, ["https", "about"].contains(url.scheme ?? "") {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }

    // target="_blank" / window.open from the page or from a player frame.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url { openExternally(url) }
        return nil
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { webView.reload() }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        showFailure("Die App konnte nicht geladen werden. Bitte starte sie erneut.")
    }

    private func showFailure(_ text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.frame = view.bounds.insetBy(dx: 25, dy: 60)
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(label)
    }
}
