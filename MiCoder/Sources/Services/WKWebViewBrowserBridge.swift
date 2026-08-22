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
enum WKWebViewBridgeError: LocalizedError {
    case invalidURL(String)
    case elementNotFound(String)
    case navigationTimeout

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid web provider URL: \(url)"
        case .elementNotFound(let selector): return "Web provider element not found: \(selector)"
        case .navigationTimeout: return WebBrowserTransportLogic.navigationTimeoutMessage
        }
    }
}

@MainActor
final class WKWebViewBrowserBridge: NSObject, BrowserAutomationBridge {
    let webView: WKWebView
    let selectors: WebVendorSelectors

    init(webView: WKWebView, selectors: WebVendorSelectors) {
        self.webView = webView
        self.selectors = selectors
    }

    func navigate(to url: String) async throws {
        guard let u = URL(string: url) else { throw WKWebViewBridgeError.invalidURL(url) }
        webView.load(URLRequest(url: u))
        // Wait for page to start loading
        await wait(ms: 500)
        // Wait for document readyState === 'complete'. A timeout is a
        // transport failure, not a successful navigation with a half-loaded DOM.
        for _ in 0..<30 {
            let ready = (try? await eval("document.readyState === 'complete'")) as? Bool ?? false
            if case .ready = WebBrowserTransportLogic.navigationOutcome(documentReady: ready) {
                return
            }
            await wait(ms: 500)
        }
        throw WKWebViewBridgeError.navigationTimeout
    }

    func typeText(_ text: String, into selector: String, humanized: Bool, pressEnter: Bool = true) async throws {
        // React/Vue editors do not observe a plain `value = ...` assignment.
        // Use the native setter and the same beforeinput/input/change sequence a
        // real keystroke produces, then dispatch Enter so submit handlers see a
        // background keyboard interaction without requiring an active window.
        let escaped = Self.jsString(text)
        let js = """
        (function(){
          var el = document.querySelector(\(Self.jsString(selector)));
          if(!el){return false;}
          el.focus();
          var before = null;
          try {
            before = new InputEvent('beforeinput', {
              bubbles: true, cancelable: true, inputType: 'insertText', data: \(escaped)
            });
          } catch (_) {}
          if (before) { el.dispatchEvent(before); }

          if (el.isContentEditable) {
            var inserted = false;
            try { inserted = document.execCommand('insertText', false, \(escaped)); } catch (_) {}
            if (!inserted) {
              el.textContent = \(escaped);
            }
          } else {
            var proto = el instanceof HTMLTextAreaElement
              ? HTMLTextAreaElement.prototype
              : HTMLInputElement.prototype;
            var descriptor = Object.getOwnPropertyDescriptor(proto, 'value');
            if (descriptor && descriptor.set) {
              descriptor.set.call(el, \(escaped));
            } else {
              el.value = \(escaped);
            }
          }

          var inputEvent = null;
          try {
            inputEvent = new InputEvent('input', {
              bubbles: true, cancelable: false, inputType: 'insertText', data: \(escaped)
            });
          } catch (_) {
            inputEvent = new Event('input', {bubbles: true});
          }
          el.dispatchEvent(inputEvent);
          el.dispatchEvent(new Event('change', {bubbles:true}));

          if (!\(pressEnter ? "true" : "false")) { return true; }
          var keyOptions = {key:'Enter', code:'Enter', keyCode:13, which:13,
                            bubbles:true, cancelable:true};
          try { el.dispatchEvent(new KeyboardEvent('keydown', keyOptions)); } catch (_) {}
          try { el.dispatchEvent(new KeyboardEvent('keypress', keyOptions)); } catch (_) {}
          try { el.dispatchEvent(new KeyboardEvent('keyup', keyOptions)); } catch (_) {}
          return true;
        })();
        """
        guard (try await eval(js) as? Bool) == true else {
            throw WKWebViewBridgeError.elementNotFound(selector)
        }
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
            guard (try await eval(js) as? Bool) == true else {
                throw WKWebViewBridgeError.elementNotFound(selector)
            }
            return
        }
        let js = """
        (function(){
          var el = document.querySelector(\(Self.jsString(selector)));
          if(!el){return false;}
          var target = el.matches('button, [role="button"], input[type="submit"]')
            ? el
            : (el.querySelector('button, [role="button"], input[type="submit"]') || el);
          if (target.disabled || target.getAttribute('aria-disabled') === 'true') { return false; }
          try { target.dispatchEvent(new PointerEvent('pointerdown', {bubbles:true, pointerType:'mouse'})); } catch (_) {}
          target.dispatchEvent(new MouseEvent('mousedown', {bubbles:true, cancelable:true, view:window}));
          target.dispatchEvent(new MouseEvent('mouseup', {bubbles:true, cancelable:true, view:window}));
          target.click();
          return true;
        })();
        """
        guard (try await eval(js) as? Bool) == true else {
            throw WKWebViewBridgeError.elementNotFound(selector)
        }
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
    /// (or exactly matches) `text`. Uses fuzzy matching: case-insensitive,
    /// normalized (spaces/hyphens/dots removed) comparison for robust model matching.
    @discardableResult
    func clickByText(selector: String, text: String) async throws -> Bool {
        let escaped = Self.jsString(text)
        let js = """
        (function(){
          var wanted = \(escaped);
          var wantedNorm = wanted.toLowerCase().replace(/[\\s\\-\\.\\.]/g,'');
          var els = document.querySelectorAll(\(Self.jsString(selector)));
          // 1) Exact match (case-insensitive)
          for(var i=0;i<els.length;i++){
            var t=(els[i].innerText||els[i].textContent||'').trim();
            if(t.toLowerCase()===wanted.toLowerCase()){els[i].click();return true;}
          }
          // 2) Contains match (case-insensitive)
          for(var i=0;i<els.length;i++){
            var t=(els[i].innerText||els[i].textContent||'').trim();
            var tLow = t.toLowerCase();
            if(tLow.indexOf(wanted.toLowerCase())!==-1 || wanted.toLowerCase().indexOf(tLow)!==-1){
              els[i].click();return true;
            }
          }
          // 3) Normalized fuzzy match (spaces/hyphens/dots ignored)
          for(var i=0;i<els.length;i++){
            var t=(els[i].innerText||els[i].textContent||'').trim();
            var tNorm = t.toLowerCase().replace(/[\\s\\-\\.\\.]/g,'');
            if(tNorm.indexOf(wantedNorm)!==-1 || wantedNorm.indexOf(tNorm)!==-1){
              els[i].click();return true;
            }
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

    @discardableResult
    func clickVisibleTextExact(selector: String, text: String) async throws -> Bool {
        let js = """
        (function(){
          var wanted = String(\(Self.jsString(text))).trim().toLowerCase().replace(/\\s+/g,' ');
          var els = document.querySelectorAll(\(Self.jsString(selector)));
          function visible(el){
            var style = window.getComputedStyle(el);
            return style.display !== 'none' && style.visibility !== 'hidden';
          }
          function norm(el){
            return String(el.innerText || el.textContent || '').trim().toLowerCase().replace(/\\s+/g,' ');
          }
          function clickThrough(el){
            var target = el.closest('[role="option"], [role="menuitem"], button, a, [tabindex]') || el;
            target.click();
          }
          var i, el;
          // Pass 1: exact normalized equality.
          for (i = 0; i < els.length; i++) {
            el = els[i];
            if (!visible(el)) { continue; }
            if (norm(el) === wanted) { clickThrough(el); return true; }
          }
          // Round 30 pass 2: vendor menus often render "Name<description>"
          // inside ONE option element ("Qwen3.7-Plus The high-performance…"),
          // which broke exact matching. Accept a prefix ONLY when the next
          // character is a space, so "…Plus-Max" can never satisfy "…Plus".
          for (i = 0; i < els.length; i++) {
            el = els[i];
            if (!visible(el)) { continue; }
            var actual = norm(el);
            if (actual.length > wanted.length &&
                actual.charAt(wanted.length) === ' ' &&
                actual.lastIndexOf(wanted, 0) === 0) {
              clickThrough(el);
              return true;
            }
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
          for (var i = els.length - 1; i >= 0; i--) {
            var el = els[i];
            var text = (el.innerText || el.textContent || '').trim();
            var style = window.getComputedStyle(el);
            if (text && style.display !== 'none' && style.visibility !== 'hidden') {
              return text;
            }
          }
          return "";
        })();
        """
        return (try? await eval(js)) as? String ?? ""
    }

    func responseFingerprint(selector: String) async throws -> String {
        let js = """
        (function(){
          var els = document.querySelectorAll(\(Self.jsString(selector)));
          if(!els || els.length===0){return "";}
          var visible = [];
          for (var i = 0; i < els.length; i++) {
            var el = els[i];
            var style = window.getComputedStyle(el);
            if (style.display !== 'none' && style.visibility !== 'hidden') {
              visible.push(el);
            }
          }
          if (!visible.length) { return ""; }
          var last = visible[visible.length - 1];
          var markup = last.outerHTML || last.textContent || '';
          return String(visible.length) + ':' + markup.length + ':' + markup.slice(-1200);
        })();
        """
        return (try? await eval(js)) as? String ?? ""
    }

    /// Wait for a selector to appear in the DOM (up to timeoutMs).
    func waitForSelector(selector: String, timeout: Int = 5000) async throws {
        let deadline = Date().addingTimeInterval(Double(timeout) / 1000.0)
        while Date() < deadline {
            if (try? await exists(selector: selector)) == true { return }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    /// Read model names from a custom dropdown using a vendor-specific selector.
    /// Falls back to universal selectors if the vendor-specific one finds nothing.
    func readModelItems(modelItemSelector: String = "div.model-item") async throws -> [String] {
        let escaped = Self.jsString(modelItemSelector)
        let js = """
        (function(){
          var items = document.querySelectorAll(\(escaped));
          var result = [];
          for (var i = 0; i < items.length; i++) {
            // Use innerText (respects CSS display) instead of textContent
            // to avoid picking up hidden description text.
            var t = (items[i].innerText || items[i].textContent || '').trim();
            if (t && t.length > 0 && t.length < 60) { result.push(t); }
          }
          if (result.length > 0) { return JSON.stringify(result); }
          // Fallback: try universal selectors — use innerText and strict length filter
          var fallbacks = ['[role="option"]', '[class*="option"]', 'li'];
          for (var f = 0; f < fallbacks.length; f++) {
            var fb = document.querySelectorAll(fallbacks[f]);
            for (var j = 0; j < fb.length; j++) {
              var ft = (fb[j].innerText || fb[j].textContent || '').trim();
              // Only include short texts (model names are short, descriptions are long)
              if (ft && ft.length > 2 && ft.length < 50) { result.push(ft); }
            }
            if (result.length > 0) { break; }
          }
          return JSON.stringify(result);
        })();
        """
        guard let json = (try? await eval(js)) as? String,
              let data = json.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [String] else { return [] }
        return arr
    }

    func readModelCandidates(modelItemSelector: String) async throws -> [WebModelDOMItem] {
        let selector = Self.jsString(modelItemSelector)
        let js = """
        (function(){
          var els = document.querySelectorAll(\(selector));
          var result = [];
          for (var i = 0; i < els.length; i++) {
            var el = els[i];
            var style = window.getComputedStyle(el);
            var rect = el.getBoundingClientRect();
            var visible = style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0;
            var label = String(el.innerText || el.textContent || '').trim().replace(/\\s+/g, ' ');
            var parent = el.closest('[role="option"], [role="menuitem"], button, a, li, [class*="model-item"], [class*="option"]');
            var role = String(el.getAttribute('role') || (parent && parent.getAttribute('role')) || '').toLowerCase();
            var tag = String(el.tagName || '').toLowerCase();
            var parentTag = String(parent && parent.tagName || '').toLowerCase();
            var cls = String((el.className && el.className.toString()) || '') + ' ' + String((parent && parent.className && parent.className.toString()) || '');
            var selectable = role === 'option' || role === 'menuitem' || tag === 'button' || tag === 'option' || parentTag === 'button' || parentTag === 'a' || parentTag === 'li' || /model-item|model-option|option|model-selector/i.test(cls);
            var nestedOptions = el.querySelectorAll('[role="option"], [role="menuitem"], [class*="model-item"]');
            var leaf = nestedOptions.length === 0;
            var disabled = el.hasAttribute('disabled') || el.getAttribute('aria-disabled') === 'true' || (parent && (parent.hasAttribute('disabled') || parent.getAttribute('aria-disabled') === 'true'));
            var key = el.getAttribute('data-model-id') || el.getAttribute('data-id') || el.getAttribute('aria-label') || (parent && (parent.getAttribute('data-model-id') || parent.getAttribute('data-id') || parent.getAttribute('aria-label'))) || (label + '|' + cls.trim());
            if (label && label.length <= 100) {
              result.push({label: label, identity: String(key), isVisible: visible, isSelectable: selectable, isDisabled: disabled, isLeaf: leaf, sourceSelector: \(selector)});
            }
          }
          return JSON.stringify(result);
        })();
        """
        guard let json = (try? await eval(js)) as? String,
              let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([WebModelDOMItem].self, from: data)) ?? []
    }

    func readVisibleModelCandidates() async throws -> [WebModelDOMItem] {
        let js = """
        (function(){
          const visible = el => {
            const style = window.getComputedStyle(el), rect = el.getBoundingClientRect();
            return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0;
          };
          const roots = Array.from(document.querySelectorAll(
            '[role="listbox"], [role="menu"], [class*="model"], [class*="dropdown"], [class*="popover"], [class*="menu"]'
          )).filter(visible);
          const nodes = [];
          roots.forEach(root => {
            if (visible(root)) nodes.push(root);
            root.querySelectorAll('*').forEach(el => { if (visible(el)) nodes.push(el); });
          });
          const result = [];
          const seen = new Set();
          nodes.forEach(el => {
            const role = String(el.getAttribute('role') || '').toLowerCase();
            const cls = String((el.className && el.className.toString()) || '');
            const selectable = role === 'option' || role === 'menuitem' ||
              el.tagName.toLowerCase() === 'button' || el.tagName.toLowerCase() === 'a' ||
              /model|option|menu-item|select/i.test(cls) ||
              el.hasAttribute('data-model-id') || el.hasAttribute('data-conversation-id');
            if (!selectable) return;
            const raw = String(el.getAttribute('aria-label') || el.innerText || el.textContent || '');
            const label = raw.split(/\\n/).map(s => s.trim()).filter(Boolean)[0] || '';
            if (!label || label.length > 100) return;
            const nested = el.querySelector('[role="option"], [role="menuitem"], [class*="model-item"], [class*="model-option"]');
            const parent = el.closest('[role="option"], [role="menuitem"], button, a, li');
            const identity = el.getAttribute('data-model-id') || el.getAttribute('data-id') ||
              el.getAttribute('data-conversation-id') || el.getAttribute('aria-label') ||
              label + '|' + cls;
            const key = String(identity) + '|' + label;
            if (seen.has(key)) return;
            seen.add(key);
            result.push({
              label: label,
              identity: String(identity),
              isVisible: true,
              isSelectable: selectable || !!parent,
              isDisabled: el.hasAttribute('disabled') || el.getAttribute('aria-disabled') === 'true',
              isLeaf: !nested,
              sourceSelector: 'visible-model-scan'
            });
          });
          return JSON.stringify(result);
        })();
        """
        guard let json = (try? await eval(js)) as? String,
              let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([WebModelDOMItem].self, from: data)) ?? []
    }

    func evaluateJS(_ script: String) async throws -> Any? {
        try await eval(script)
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
            let attributes = WebCookieRestoreLogic.attributes(for: c)
            if attributes.secure { props[.secure] = "TRUE" }
            if attributes.httpOnly { props[HTTPCookiePropertyKey("HttpOnly")] = "TRUE" }
            if let exp = c.expiresEpoch { props[.expires] = Date(timeIntervalSince1970: exp) }
            if let cookie = HTTPCookie(properties: props) {
                await store.setCookie(cookie)
            }
        }
    }

    func setLocalStorage(_ values: [String: String]) async throws {
        guard !values.isEmpty else { return }
        for (key, value) in values {
            let script = "localStorage.setItem(\(Self.jsString(key)), \(Self.jsString(value))); true;"
            guard (try await eval(script) as? Bool) == true else {
                throw WKWebViewBridgeError.elementNotFound("localStorage")
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

    func stopGeneration() async throws {
        let selectors = [
            self.selectors.stopButton,
            "button[data-testid='stop-button']",
            "button[aria-label*='stop' i]",
            "button[aria-label*='停止']",
            "button[class*='stop' i]"
        ].filter { !$0.isEmpty }
        for selector in selectors {
            if (try? await exists(selector: selector)) == true {
                try await click(selector: selector)
                return
            }
        }
        // Some providers expose no stable stop button but still accept Escape.
        _ = try? await eval("document.activeElement && document.activeElement.dispatchEvent(new KeyboardEvent('keydown', {key:'Escape', bubbles:true})); true;")
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
