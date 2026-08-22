import Testing
import Foundation
@testable import MiCoder

/// Round 30 — maximally permissive embedded-browser policy (user report:
/// kimi.com asks to hand off to kimi.ai and the embedded webview appeared to
/// forbid it; root cause: no WKUIDelegate, so window.open / target=_blank
/// popups were silently dropped, and JS dialogs could hang the page).
@Suite("Round 30 — WebPopupPolicy pure decisions")
struct WebPopupPolicyTests {

    @Test("popup with a real URL loads in the same view")
    func popupLoadsInPlace() {
        let action = WebPopupPolicy.popupAction(requestURL: "https://www.kimi.ai/chat?next=1")
        #expect(action == .loadInPlace("https://www.kimi.ai/chat?next=1"))
    }

    @Test("cross-vendor popup also loads in place — no host allowlist")
    func crossHostPopupAllowed() {
        let action = WebPopupPolicy.popupAction(requestURL: "https://other-vendor.example.org/login")
        #expect(action == .loadInPlace("https://other-vendor.example.org/login"))
    }

    @Test("non-http schemes are allowed in place as well")
    func arbitrarySchemeAllowed() {
        let action = WebPopupPolicy.popupAction(requestURL: "about:blank")
        #expect(action == .loadInPlace("about:blank"))
    }

    @Test("nil or empty URL adopts a new view instead of dropping the popup")
    func missingURLAdoptsNewView() {
        #expect(WebPopupPolicy.popupAction(requestURL: nil) == .adoptNewView)
        #expect(WebPopupPolicy.popupAction(requestURL: "") == .adoptNewView)
        #expect(WebPopupPolicy.popupAction(requestURL: "   ") == .adoptNewView)
    }

    @Test("URL without scheme cannot navigate — adopt new view")
    func schemelessURLAdoptsNewView() {
        #expect(WebPopupPolicy.popupAction(requestURL: "not-a-url") == .adoptNewView)
    }

    @Test("JS prompt auto-answers with the page-provided default text")
    func promptUsesDefault() {
        #expect(WebPopupPolicy.promptResponse(defaultText: "prefilled") == "prefilled")
        #expect(WebPopupPolicy.promptResponse(defaultText: nil) == "")
    }
}
