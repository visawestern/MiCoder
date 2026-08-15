import Foundation
import Testing
@testable import MiCoder

@Suite("CHAT-19: MiCoder Auto Free attachment payload")
struct MiCoderAutoFreeContentLogicTests {
    @Test("text plus image preserves an image_url part")
    func imagePartSurvives() {
        let parts = MiCoderAutoFreeContentLogic.parts(
            text: "inspect this",
            imageDataURLs: ["data:image/png;base64,abc"],
            textFiles: []
        )
        #expect(parts == [
            .text("inspect this"),
            .imageURL("data:image/png;base64,abc")
        ])
    }

    @Test("text files become explicit text attachment parts")
    func filePartSurvives() {
        let parts = MiCoderAutoFreeContentLogic.parts(
            text: "review",
            imageDataURLs: [],
            textFiles: [.init(name: "main.swift", content: "print(1)")]
        )
        #expect(parts == [
            .text("review"),
            .fileText(name: "main.swift", content: "print(1)")
        ])
    }

    @Test("unsupported PDF and binary attachments are identified before text fallback")
    func unsupportedBinaryClassification() {
        #expect(MiCoderAutoFreeContentLogic.isUnsupportedForTextRoute(fileName: "report.pdf", mimeType: "application/pdf"))
        #expect(MiCoderAutoFreeContentLogic.isUnsupportedForTextRoute(fileName: "archive.zip", mimeType: "application/octet-stream"))
        #expect(!MiCoderAutoFreeContentLogic.isUnsupportedForTextRoute(fileName: "notes.txt", mimeType: "application/octet-stream"))
    }

    @Test("empty input still produces a valid text part")
    func emptyInputIsValid() {
        #expect(MiCoderAutoFreeContentLogic.parts(text: "", imageDataURLs: [], textFiles: []) == [.text("")])
    }
}
