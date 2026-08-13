# Причинно-следственная карта

Дата: 2026-08-11. Область: все функции, которые участвуют в отправке,
выборе provider/model, web discovery/effort и сохранении первой неудачной
сессии.

## Chain A: MiMo-Auto send

```text
ContentView.task
  -> AppState.loadCustomProviders
  -> AppState.validateAndReconcileSelections
  -> AppState.selectProvider(mimo-auto)
  -> MiMoAutoProviderStore.provider.selectedModel
  -> AppState.effectiveSelectedModel
  -> SendReadinessLogic.sendValidationError
  -> SendRouteResolver.route(.mimoAuto)
  -> MiMoAutoProviderStore.selectModel
  -> MiMoAutoProviderStore.streamChat
  -> MiMoAutoClient.chatCompletion
  -> MessageStore assistant deltas
  -> finished assistant message
```

**Result:** PASS by tests. Network response remains live-QA.

## Chain B: Web model discovery

```text
WebProviderLoginView.capture
  -> WebProvidersSection.persistCookies
  -> AppState.refreshWebModels
  -> WebModelDiscovery.discover
  -> BrowserAutomationBridge.exists/click/readModelItems/readText
  -> WebModelListParser.parse
  -> ChatGPT feature filter / Qwen selector merge
  -> WebProviderStore.upsert
  -> WebProviderConnectivity.models
  -> AppState.modelsForSelectedProvider
  -> ModelSelectorMenu
```

**Result:** PASS by parser/route tests; authenticated WebKit is live-QA.

## Chain C: Web effort

```text
WebProviderCard refresh effort
  -> AppState.refreshWebEffort
  -> WebModelDiscovery.discoverEffort
  -> split vendor selectors
  -> bridge exists/click/readText
  -> WebModelListParser.parseEffortLevels
  -> WebProviderStore.upsert(discoveredEffortLevels)
  -> WebProviderCard effort status
  -> WebChatDriver.injectModelAndEffort
  -> vendor effort option click
```

**Result:** PASS by code; live selector behavior remains live-QA.

## Chain D: Failed first request

```text
sendMessage
  -> readiness/connection validation
  -> persistRejectedMessage on preflight failure
  -> ensureLocalSession
  -> AppState.upsertSession
  -> DatabaseBridge.createSession
  -> DatabaseBridge.saveMessage(user)
  -> DatabaseBridge.saveMessage(assistant error)
  -> sidebar/session reload
```

```text
sendDirectly
  -> request/route error
  -> persistUnsentMessage
  -> ensureLocalSession
  -> save user message + mark assistant error finished
```

**Result:** PASS by `failedFirstSendIsPersisted` and full suite.

## Chain E: Provider readiness

```text
InputControls send button
  -> displayed readiness reason
  -> effective model/provider
  -> SendReadinessLogic.canSendMessage
  -> connectionValidationError
  -> route resolver
  -> visible error or request
```

**Result:** PASS. No silent disabled send remains in the tested path.

## Remaining external boundary

The following cannot be proven by local tests: real WKWebView DOM selectors,
third-party login cookies, ChatGPT's current one-model page, Qwen's current
full model list, and actual MiMo API response. They remain `PARTIAL/live-QA`.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
