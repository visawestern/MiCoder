from pathlib import Path

root = Path('/home/ubuntu/MiCoder')
checks = {
    'no_model_list_prefix_cap': ('MiCoder/Sources/Views/Components/WebProvidersSection.swift', 'prefix(8)' not in (root / 'MiCoder/Sources/Views/Components/WebProvidersSection.swift').read_text()),
    'no_select_action_menu': ('MiCoder/Sources/Views/Settings/ModelSettingsView.swift', 'Label(L.t(AppLocalizationKey.locSelect)' not in (root / 'MiCoder/Sources/Views/Settings/ModelSettingsView.swift').read_text()),
    'strict_model_validator': ('MiCoder/Sources/Services/WebModelListParser.swift', 'isValidModelLabel' in (root / 'MiCoder/Sources/Services/WebModelListParser.swift').read_text()),
    'structured_dom_candidates': ('MiCoder/Sources/Services/WKWebViewBrowserBridge.swift', 'readModelCandidates' in (root / 'MiCoder/Sources/Services/WKWebViewBrowserBridge.swift').read_text()),
    'exact_injection': ('MiCoder/Sources/Services/WebChatDriver.swift', 'clickVisibleTextExact' in (root / 'MiCoder/Sources/Services/WebChatDriver.swift').read_text()),
    'pre_send_injection_abort': ('MiCoder/Sources/Services/WebChatDriver.swift', 'blocks duplicate' in (root / 'MiCoder/Sources/Services/WebChatDriver.swift').read_text() or 'injectionSucceeded' in (root / 'MiCoder/Sources/Services/WebChatDriver.swift').read_text()),
    'remote_mapping_store': ('MiCoder/Sources/Services/WebRemoteChatStore.swift', (root / 'MiCoder/Sources/Services/WebRemoteChatStore.swift').exists()),
    'remote_id_journal': ('MiCoder/Sources/Services/WebBrowserSessionPool.swift', 'remoteChatID' in (root / 'MiCoder/Sources/Services/WebBrowserSessionPool.swift').read_text()),
    'session_is_browser_key': ('MiCoder/Sources/Services/WebBrowserSessionPool.swift', 'activeSessionID' in (root / 'MiCoder/Sources/Services/WebBrowserSessionPool.swift').read_text()),
    'automatic_retry': ('MiCoder/Sources/Views/ChatPanelView.swift', 'Refreshing model catalog before retry' in (root / 'MiCoder/Sources/Views/ChatPanelView.swift').read_text()),
    'ai_candidates_unselectable': ('MiCoder/Sources/Views/Components/WebProvidersSection.swift', 'isSelectable: false' in (root / 'MiCoder/Sources/Views/Components/WebProvidersSection.swift').read_text()),
    'compact_auto_free_catalog': ('MiCoder/Sources/Views/Settings/ProvidersSettingsView.swift', all(marker in (root / 'MiCoder/Sources/Views/Settings/ProvidersSettingsView.swift').read_text() for marker in ['locChooseFromList', 'Menu {', 'locSwitchFreeModel', 'locLiveFreeModels'])),
}
for name, (_, value) in checks.items():
    print(f'{name}={"PASS" if value else "FAIL"}')
if not all(value for _, value in checks.values()):
    raise SystemExit(1)
