# Independent acceptance evidence

## Environment boundary

The current sandbox is Linux. Running the complete repository package test fails at compilation because `MiCoder/Sources/App/MiCoderApp.swift` imports unavailable `SwiftUI` and `AppKit`. This is a target-environment limitation, not a passing test result. The full run therefore cannot verify SwiftUI/WebKit/AppKit chains.

A manually composed Foundation-only web harness was run after copying the current web service sources and relevant tests. It completed with **55 tests passed**, including web driver orchestration, model discovery fakes, selection guards, browser instance identity, action journal, named sessions, and Codable migrations. This proves only the pure/Foundation subset; it does not prove live WKWebView DOM behavior, macOS SwiftUI rendering, cookies in WebKit, or external provider responses.

## Current acceptance consequence

Any registry row whose evidence is only `swiftc -parse`, a Foundation harness, or source inspection cannot be rated as target-runtime PASS. It must receive a separate implementation score and task-fit score, with macOS/WebKit status marked unverified unless a real macOS build and interactive provider run are present.
