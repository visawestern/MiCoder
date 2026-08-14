<docs/screenshots/logo-mi.png width=120 align=left>

# MiCoder

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.3-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-lightgrey.svg)](https://www.apple.com/macos/)
[![Localization](https://img.shields.io/badge/Localization%20-10%20languages-green.svg)](#localization)

**MiCoder** is a free, independent, open-source AI coding workspace for macOS.

It combines an AI chat, project-scoped history, file tools, terminal access, Git
workflows, provider configuration, skills, MCP servers, and local storage administration
in one native SwiftUI application.

> **No Xiaomi affiliation:** MiCoder is an independent community project. It is not made,
> sponsored, endorsed, licensed, or otherwise associated with Xiaomi Corporation or any
> Xiaomi subsidiary. "Xiaomi" is a trademark of its respective owner.

## What MiCoder Does

- Native macOS application built with SwiftUI and AppKit.
- AI chat with streaming responses, Markdown, tool calls, images, file attachments, and plan questions.
- Provider selection for local, custom, remote, OpenAI-compatible, ACP, and supported web transports.
- Project-scoped SQLite history at `<project>/.micoder/project.db`.
- Read-only/system-path fallback under `~/.micoder/projects/<stable-hash>/project.db`.
- WAL journaling, integrity checks, automatic backups, restore, per-project undo, and request history.
- Terminal panel with bounded command execution and AccessLevel approval gates.
- Git status, branches, commit, push, pull, publish, and review flows.
- Skills and MCP server catalog/install management.
- Slash commands, project file indexing, FTS5 message search, usage statistics, and localization support.

## Status

The current codebase has been audited screen-by-screen and tracked in the canonical feature
spreadsheet (`docs/FEATURE_SPREADSHEET.csv`, 264 user stories):

- `233 PASS`
- `21 PARTIAL`
- `5 MISSING`
- `5 FUTURE`

The send-chain recovery rounds added explicit coverage for web model/effort coherence, verified
browser controls, embedded-browser stop, MiCoder Auto Free feedback, and startup connection
readiness. The macOS UI/WebKit target requires macOS for the final runtime regression; the
Linux-only sandbox cannot compile SwiftUI, AppKit, or WebKit. Incomplete behavior is intentionally
marked `PARTIAL` in the canonical spreadsheet and is not presented as complete functionality.

## Requirements

- macOS 13 or later.
- Swift 5.9 toolchain or later.
- A configured local/remote AI provider for chat generation.
- GitHub CLI (`gh`) only for GitHub publish/PR workflows.

## Build And Test

```bash
swift build
swift test
```

Build the application bundle with:

```bash
./build-app.sh
```

## Project Layout

```text
MiCoder/
  Sources/
    App/              Application state and macOS menu commands
    Models/           Domain models and settings contracts
    Services/         Providers, storage, Git, indexing, tools, and safety gates
    Views/            SwiftUI screens and reusable components
    Resources/        App resources and bundled catalogs
  Tests/              Logic, storage, provider, safety, and integration tests
  activity-checklists/    Manual code-based checklist for every activity
  FEATURE_SPREADSHEET.csv Canonical user-story/status registry
  FEATURE_TEST_REPORT.md  Round-by-round verification and error report
  CONSOLIDATED_PROJECT_REPORT.md  Current project-wide summary
```

## Privacy And Storage

MiCoder is designed around local project storage. Project history, indexes, settings, and
resource registries are stored locally unless a configured provider or remote service is used.
API keys use the macOS Keychain where available. Review provider terms and privacy policies
before connecting third-party services.

## Safety

Tool permissions are explicit. Read-only tools are separated from write and command execution;
`run_command` is gated by the selected AccessLevel and executed with bounded process behavior.
Still review commands and provider output before allowing changes to important files.

## License

MiCoder is released under the MIT License. See [`LICENSE`](LICENSE).

## Trademarks And Branding

MiCoder is free and open source, but free distribution does not automatically eliminate
trademark risk. The project does not claim any Xiaomi rights and must not use Xiaomi logos,
wordmarks, or trade dress as branding. The name “MiCoder” and the visual identity should be
reviewed and, if they could cause confusion with Xiaomi branding, replaced with an independent
name and logo before public release. The disclaimer above is informational, not legal advice
or a guarantee against a trademark complaint.

Contributions that add third-party logos, names, screenshots, or provider branding must include
the relevant permission or attribution and must not imply endorsement.

## Contributing

1. Create a focused change with a clear user story.
2. Update the relevant activity checklist and `docs/FEATURE_SPREADSHEET.csv`.
3. Add or update tests for behavior and error paths.
4. Run `swift build` and `swift test`.
5. Keep incomplete work marked `PARTIAL`, `MISSING`, or `FUTURE` until it is verified.

## Disclaimer

MiCoder is provided “as is”, without warranty. AI-generated code and commands can be
incorrect, destructive, insecure, or incompatible with a project. Review generated output
before applying it.
