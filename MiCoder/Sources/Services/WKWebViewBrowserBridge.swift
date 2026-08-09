import Foundation
#if canImport(WebKit)
import WebKit
#endif

/// Live BrowserAutomationBridge backed by a WKWebView (plan Раздел 12 Блок 3
/// п.27/п.29). Drives the vendor's web chat in-app via JavaScript: type into
/// the input, click send, read the response container, detect the stop button,
/// grab page text/URL/cookies, and screenshot for captcha display. No external
/// Playwright process — the same in-app web view used for login is reused so
/// the captured session/cookies apply.
#if canImport(WebKit)
@MainActor
final class WKWebViewBrowserBridge: NSObject, BrowserAutomationBridge {
    let webView: WKWebView
    let selectors: WebVendorSelectors

    init(webView: WKWebView, selectors: WebVendorSelectors) {
        self.webView = webView
        self.selectors = selectors
    }

    func navigate(to url: String) async throws {
        guard let u = URL(string: url) else { return }
        webView.load(URLRequest(url: u))
        // Wait for page to start loading
        await wait(ms: 500)
        // Wait for document readyState === 'complete'
        for _ in 0..<30 {
            let ready = (try? await eval("document.readyState === 'complete'")) as? Bool ?? false
            if ready { return }
            await wait(ms: 500)
        }
    }

    func typeText(_ text: String, into selector: String, humanized: Bool) async throws {
        // Set the value and dispatch input/change so the app's React state updates.
        let escaped = Self.jsString(text)
        let js = """
        (function(){
          var el = document.querySelector(\(Self.jsString(selector)));
          if(!el){return false;}
          if(el.isContentEditable){ el.focus(); el.textContent = \(escaped); }
          else { el.focus(); el.value = \(escaped); }
          el.dispatchEvent(new Event('input', {bubbles:true}));
          el.dispatchEvent(new Event('change', {bubbles:true}));
          return true;
        })();
        """
        _ = try? await eval(js)
    }

    func click(selector: String) async throws {
        // Support :has-text() pseudo-class for text-based matching
        if let text = extractHasText(from: selector) {
            let js = """
            (function(){
              var wanted = \(Self.jsString(text));
              var all = document.querySelectorAll('button, a, div, span, li');
              for (var i = 0; i < all.length; i++) {
                var t = (all[i].innerText || all[i].textContent || '').trim();
                if (t === wanted || t.indexOf(wanted) !== -1) {
                  all[i].click();
                  return true;
                }
              }
              return false;
            })();
            """
            _ = (try? await eval(js)) as? Bool ?? false
            return
        }
        let js = """
        (function(){
          var el = document.querySelector(\(Self.jsString(selector)));
          if(!el){return false;}
          el.click(); return true;
        })();
        """
        _ = try? await eval(js)
    }

    func exists(selector: String) async throws -> Bool {
        // Support :has-text() pseudo-class for text-based matching
        if let text = extractHasText(from: selector) {
            let js = """
            (function(){
              var wanted = \(Self.jsString(text));
              var all = document.querySelectorAll('button, a, div, span, li');
              for (var i = 0; i < all.length; i++) {
                var t = (all[i].innerText || all[i].textContent || '').trim();
                if (t === wanted || t.indexOf(wanted) !== -1) {
                  return true;
                }
              }
              return false;
            })();
            """
            return (try? await eval(js)) as? Bool ?? false
        }
        let js = "!!document.querySelector(\(Self.jsString(selector)));"
        return (try? await eval(js)) as? Bool ?? false
    }

    /// Extract text content from `:has-text('...')` pseudo-class
    private func extractHasText(from selector: String) -> String? {
        guard selector.contains(":has-text(") else { return nil }
        // Match :has-text('text') or :has-text("text")
        let pattern = ":has-text\\(['\"]([^'\"]+)['\"]\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: selector, range: NSRange(selector.startIndex..., in: selector)),
              let range = Range(match.range(at: 1), in: selector) else { return nil }
        return String(selector[range])
    }

    /// Click the first element matching `selector` whose visible text contains
    /// (or exactly matches) `text`. Returns true if matched.
    @discardableResult
    func clickByText(selector: String, text: String) async throws -> Bool {
        let js = """
        (function(){
          var wanted = \(Self.jsString(text));
          var els = document.querySelectorAll(\(Self.jsString(selector)));
          // Exact match first
          for(var i=0;i<els.length;i++){
            var t=(els[i].innerText||els[i].textContent||'').trim();
            if(t===wanted){els[i].click();return true;}
          }
          // Partial match
          for(var i=0;i<els.length;i++){
            var t=(els[i].innerText||els[i].textContent||'').trim();
            if(t.indexOf(wanted)!==-1){els[i].click();return true;}
          }
          return false;
        })();
        """
        return (try? await eval(js)) as? Bool ?? false
    }

    func clickByTextExact(selector: String, text: String) async throws -> Bool {
        let js = """
        (function(){
          var wanted = \(Self.jsString(text));
          var els = document.querySelectorAll(\(Self.jsString(selector)));
          for(var i=0;i<els.length;i++){
            var t=(els[i].innerText||els[i].textContent||'').trim();
            if(t===wanted){els[i].click();return true;}
          }
          return false;
        })();
        """
        return (try? await eval(js)) as? Bool ?? false
    }

    func readText(selector: String) async throws -> String {
        let js = """
        (function(){
          var els = document.querySelectorAll(\(Self.jsString(selector)));
          if(!els || els.length===0){return "";}
          return els[els.length-1].innerText || "";
        })();
        """
        return (try? await eval(js)) as? String ?? ""
    }



    func pageText() async throws -> String {
        (try? await eval("document.body ? document.body.innerText : '';")) as? String ?? ""
    }

    func currentURL() async throws -> String {
        webView.url?.absoluteString ?? ""
    }

    func cookies() async throws -> [BrowserCookie] {
        let cookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
        return cookies.map {
            BrowserCookie(name: $0.name, value: $0.value, domain: $0.domain, path: $0.path,
                          expiresEpoch: $0.expiresDate?.timeIntervalSince1970,
                          httpOnly: $0.isHTTPOnly, secure: $0.isSecure)
        }
    }

    func setCookies(_ cookies: [BrowserCookie]) async throws {
        let store = webView.configuration.websiteDataStore.httpCookieStore
        for c in cookies {
            var props: [HTTPCookiePropertyKey: Any] = [
                .name: c.name, .value: c.value, .domain: c.domain, .path: c.path
            ]
            if let exp = c.expiresEpoch { props[.expires] = Date(timeIntervalSince1970: exp) }
            if let cookie = HTTPCookie(properties: props) {
                await store.setCookie(cookie)
            }
        }
    }

    func screenshot(selector: String?) async throws -> Data {
        await withCheckedContinuation { cont in
            let config = WKSnapshotConfiguration()
            webView.takeSnapshot(with: config) { image, _ in
                #if canImport(AppKit)
                if let image = image,
                   let tiff = image.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    cont.resume(returning: png)
                    return
                }
                #endif
                cont.resume(returning: Data())
            }
        }
    }

    func wait(ms: Int) async {
        try? await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
    }

    // MARK: - Helpers

    private func eval(_ js: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { cont in
            webView.evaluateJavaScript(js) { result, error in
                if let error = error { cont.resume(throwing: error) }
                else { cont.resume(returning: result) }
            }
        }
    }

    /// JSON-encode a string for safe embedding in JS.
    static func jsString(_ s: String) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: [s])) ?? Data("[\"\"]".utf8)
        let arr = String(data: data, encoding: .utf8) ?? "[\"\"]"
        return String(arr.dropFirst().dropLast())  // "..." from ["..."]
    }
}
#endif
