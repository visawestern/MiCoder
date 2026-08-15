#!/usr/bin/env python3
"""Round 107 red/source regressions for live web-provider detection and send binding."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DISCOVERY = ROOT / "MiCoder/Sources/Services/WebModelDiscovery.swift"
PARSER = ROOT / "MiCoder/Sources/Services/WebModelListParser.swift"
DRIVER = ROOT / "MiCoder/Sources/Services/WebChatDriver.swift"
WEB_PROVIDERS = ROOT / "MiCoder/Sources/Views/Components/WebProvidersSection.swift"
IDENTITY = ROOT / "MiCoder/Sources/Services/WebRemoteChatIdentityLogic.swift"


def require(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"{label}: missing {needle!r}")


def main() -> None:
    discovery = DISCOVERY.read_text()
    parser = PARSER.read_text()
    driver = DRIVER.read_text()
    providers = WEB_PROVIDERS.read_text()

    # The live dropdown may expose only the first page until an expansion
    # control is clicked; the implementation must retain a generic visible
    # candidate fallback instead of trusting one brittle vendor class.
    require(discovery, "readVisibleModelCandidates", "generic visible model candidate extraction")
    require(discovery, "discoverAllModels", "bounded model-menu expansion")

    # AI Free must prepare/open/expand the same live model menu before asking
    # the model to read page text; body text before that action contains only
    # the currently selected model (the screenshot's one-model failure).
    ai_start = providers.index("private func findModelsWithAI")
    ai_block = providers[ai_start:]
    require(ai_block, "discoverAllModels", "AI detection expands the live menu")
    require(ai_block, "readVisibleModelCandidates", "AI detection reads structured candidates")
    require(ai_block, "pageText()", "AI detection captures text after menu preparation")

    # Effort parsing must be fail-closed: a model name or arbitrary UI text may
    # never silently become .medium and appear as a bogus effort.
    require(parser, "return nil", "unknown effort labels are rejected")
    require(parser, "normalizeEffortLabel", "effort labels use an explicit normalizer")

    # Kimi may keep the shell URL at / while exposing the active conversation
    # only in DOM attributes/history links. The driver must query that DOM and
    # parse it through a pure identity helper rather than disabling the binding
    # guard against context mixing.
    require(driver, "evaluateJS", "Kimi DOM chat identity fallback")
    require(driver, "data-chat-id", "Kimi data-chat-id extraction")
    require(driver, "data-conversation-id", "Kimi data-conversation-id extraction")
    if not IDENTITY.exists():
        raise AssertionError("pure remote chat identity helper is missing")

    print("Round 107 web-provider source acceptance: PASS")


if __name__ == "__main__":
    main()
