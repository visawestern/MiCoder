import Testing
import Foundation
@testable import MiCoder

@Suite("Web chat event presenter — captcha in chat (plan Раздел 12 Блок 3 п.34)")
struct WebChatEventPresenterTests {

    @Test func captchaEventProducesInlineCaptcha() {
        let png = Data("PNGDATA".utf8)
        let p = WebChatEventPresenter.present(.captchaDetected(screenshotPNG: png))
        if case .captcha(let b64, let note) = p {
            #expect(b64 == png.base64EncodedString())
            #expect(note.contains("captcha"))
        } else {
            Issue.record("expected .captcha, got \(p)")
        }
    }

    @Test func finalEventProducesAnswer() {
        #expect(WebChatEventPresenter.present(.final("done")) == .answer("done"))
    }

    @Test func errorEventProducesError() {
        #expect(WebChatEventPresenter.present(.error("boom")) == .error("boom"))
    }

    @Test func streamingSuppressed() {
        #expect(WebChatEventPresenter.present(.streaming("partial")) == .none)
    }

    @Test func toolEventsAreStatusLines() {
        let call = WebToolCall(name: "read_file", arguments: ["path": "a"])
        if case .status(let s) = WebChatEventPresenter.present(.toolCall(call)) {
            #expect(s.contains("read_file"))
        } else { Issue.record("expected status") }
        if case .status(let s) = WebChatEventPresenter.present(.toolResult(name: "read_file", result: "x")) {
            #expect(s.contains("read_file"))
        } else { Issue.record("expected status") }
    }

    @Test func sessionEventsAreStatus() {
        #expect(WebChatEventPresenter.present(.sessionLimitReached) != .none)
        #expect(WebChatEventPresenter.present(.sessionRestarted) != .none)
        #expect(WebChatEventPresenter.present(.promptSplit(parts: 3)) != .none)
    }

    @Test func captchaAndLogoutBlockUntilAction() {
        #expect(WebChatEventPresenter.blocksUntilUserAction(.captchaDetected(screenshotPNG: Data())))
        #expect(WebChatEventPresenter.blocksUntilUserAction(.loggedOut))
        #expect(!WebChatEventPresenter.blocksUntilUserAction(.final("x")))
        #expect(!WebChatEventPresenter.blocksUntilUserAction(.streaming("y")))
    }
}
