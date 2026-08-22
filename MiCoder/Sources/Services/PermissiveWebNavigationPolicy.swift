import Foundation
#if canImport(WebKit)
import WebKit

/// Round 30 — maximally permissive embedded-browser policy.
///
/// Vendors region-redirect their chat pages (kimi.com → kimi.ai outside China).
/// The embedded WKWebView previously had NO navigation/UI delegates, so:
///   • top-level redirects worked, but `window.open` / `target=_blank` hops —
///     the way kimi.ai handoff is often implemented — were silently dropped;
///   • a blocked JS alert/confirm/prompt could freeze page scripts.
/// This policy allows every navigation/response regardless of host or scheme,
/// re-loads popup requests in the SAME view (in-place redirect), adopts truly
/// unresolvable popups as new views instead of dropping them, and auto-answers
/// JS dialogs so automated pages never hang.

/// Pure decision logic (unit-testable without WebKit objects).
enum WebPopupPolicy {
    enum PopupAction: Equatable {
        /// Navigate the originating web view to this URL in place.
        case loadInPlace(String)
        /// No recoverable URL: adopt the popup as a real new view.
        case adoptNewView
    }

    static func popupAction(requestURL: String?) -> PopupAction {
        guard let raw = requestURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw),
              url.scheme != nil, !url.scheme!.isEmpty else {
            return .adoptNewView
        }
        return .loadInPlace(raw)
    }

    static func promptResponse(defaultText: String?) -> String {
        defaultText ?? ""
    }
}

#if canImport(AppKit)
@MainActor
final class PermissiveWebNavigationPolicy: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var ownerWebView: WKWebView?

    init(ownerWebView: WKWebView? = nil) {
        self.ownerWebView = ownerWebView
        super.init()
    }

    // MARK: Navigation — allow everything

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }

    // MARK: Popups — same-view redirect, never a silent drop

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        switch WebPopupPolicy.popupAction(requestURL: navigationAction.request.url?.absoluteString) {
        case .loadInPlace(let url):
            if let u = URL(string: url) {
                webView.load(URLRequest(url: u))
            }
            return nil
        case .adoptNewView:
            let wv = WKWebView(frame: webView.frame, configuration: configuration)
            wv.navigationDelegate = self
            wv.uiDelegate = self
            return wv
        }
    }

    // MARK: JS dialogs — auto-answer so pages never hang

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        completionHandler(WebPopupPolicy.promptResponse(defaultText: defaultText))
    }
}
#endif
#endif
