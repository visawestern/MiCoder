from pathlib import Path

root = Path(__file__).resolve().parent.parent
checks = {
    'no_model_list_prefix_cap': ('myCoder/Sources/Views/Components/WebProvidersSection.swift', 'prefix(8)' not in (root / 'myCoder/Sources/Views/Components/WebProvidersSection.swift').read_text()),
    'no_select_action_menu': ('myCoder/Sources/Views/Settings/ModelSettingsView.swift', 'Label(L.t(AppLocalizationKey.locSelect)' not in (root / 'myCoder/Sources/Views/Settings/ModelSettingsView.swift').read_text()),
    'strict_model_validator': ('myCoder/Sources/Services/WebModelListParser.swift', 'isValidModelLabel' in (root / 'myCoder/Sources/Services/WebModelListParser.swift').read_text()),
    'structured_dom_candidates': ('myCoder/Sources/Services/WKWebViewBrowserBridge.swift', 'readModelCandidates' in (root / 'myCoder/Sources/Services/WKWebViewBrowserBridge.swift').read_text()),
    'exact_injection': ('myCoder/Sources/Services/WebChatDriver.swift', 'clickVisibleTextExact' in (root / 'myCoder/Sources/Services/WebChatDriver.swift').read_text()),
    'pre_send_injection_abort': ('myCoder/Sources/Services/WebChatDriver.swift', 'blocks duplicate' in (root / 'myCoder/Sources/Services/WebChatDriver.swift').read_text() or 'injectionSucceeded' in (root / 'myCoder/Sources/Services/WebChatDriver.swift').read_text()),
    'remote_mapping_store': ('myCoder/Sources/Services/WebRemoteChatStore.swift', (root / 'myCoder/Sources/Services/WebRemoteChatStore.swift').exists()),
    'remote_id_journal': ('myCoder/Sources/Services/WebBrowserSessionPool.swift', 'remoteChatID' in (root / 'myCoder/Sources/Services/WebBrowserSessionPool.swift').read_text()),
    'session_is_browser_key': ('myCoder/Sources/Services/WebBrowserSessionPool.swift', 'activeSessionID' in (root / 'myCoder/Sources/Services/WebBrowserSessionPool.swift').read_text()),
    'automatic_retry': ('myCoder/Sources/Views/ChatPanelView.swift', 'Refreshing model catalog before retry' in (root / 'myCoder/Sources/Views/ChatPanelView.swift').read_text()),
    'ai_candidates_unselectable': ('myCoder/Sources/Views/Components/WebProvidersSection.swift', 'isSelectable: false' in (root / 'myCoder/Sources/Views/Components/WebProvidersSection.swift').read_text()),
    'compact_auto_free_catalog': ('myCoder/Sources/Views/Settings/ProvidersSettingsView.swift', all(marker in (root / 'myCoder/Sources/Views/Settings/ProvidersSettingsView.swift').read_text() for marker in ['locChooseFromList', 'Menu {', 'locSwitchFreeModel', 'locLiveFreeModels'])),
}
for name, (_, value) in checks.items():
    print(f'{name}={"PASS" if value else "FAIL"}')
if not all(value for _, value in checks.values()):
    raise SystemExit(1)
