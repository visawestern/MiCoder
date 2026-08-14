# MiCoder Fix Round — Definition of Done

## Quality model

A requirement is **100/100 accepted** only when both dimensions are complete. Code quality requires a deterministic implementation, explicit error states, persistence invariants, unit/regression tests, no silent fallback, and no dead production path. Task-fit quality requires the exact interaction requested by the user, not a technically adjacent substitute. A Linux Foundation pass alone cannot close a macOS/WebKit requirement.

| Dimension | 100/100 gate |
|---|---|
| Code quality | Source chain is complete, state is persisted atomically, failures are actionable, tests cover success/failure/edge cases, and adversarial review finds no bypass |
| Task-fit quality | Visible control has the requested placement and semantics; no redundant action, hidden cap, fake status, or unrelated substitute remains |
| Runtime quality | macOS build/test and live Kimi/Qwen/WebKit checks pass; otherwise status remains `UNVERIFIED`, never 100/100 |

## P0 contract: model discovery

The discovery output must be a structured candidate, not a raw string. Each candidate contains `rawLabel`, normalized `name`, `source`, `isVisible`, `isSelectable`, `isDisabled`, `isActive`, `status`, and a stable DOM identity where available. Only visible selectable leaf options can enter `discoveredModels`.

The validator must reject generic headings, actions, descriptions, counts, effort labels, plan labels and known UI chrome, including `Model`, `Model Comparison`, `All models`, `More models`, `Expand more models`, `Settings`, `Upgrade`, `New`, `Fast`, `Quick`, `Auto`, `Thinking`, `Deep thinking`, and their localized equivalents. It must also reject a candidate when its visible text is a parent/container aggregation of multiple descendants. A model-like string is not sufficient without an option-node role or vendor-specific model-item anchor.

The recursive traversal must open the exact model menu, inspect visible leaf options, identify exact expansion controls, wait for a DOM fingerprint/count change, repeat until no new branch exists, and restore the original model. The result must include a trace of expansion attempts and a reason for every rejected label. The traversal must handle at least two nested levels and a Qwen Coder branch in tests.

## P0 contract: capabilities

After each validated model is selected, effort and parameter probes run in the same browser instance. Effort status is one of `supported`, `unsupported`, `notDetected`, or `error`; an empty array is not allowed to mean all four. Parameter profile stores available keys/labels and discovered values, while `ModelCallParametersStore` user overrides remain authoritative. Login refresh, manual refresh, and recovery refresh use one atomic catalog transaction and preserve the selected model.

## P0 contract: remote chat identity

Persist a mapping keyed by `providerID + activeSessionID + projectID + localChatID`. The value stores `remoteChatID`, remote URL, verified title, creation timestamp, last-used timestamp, and status. On first turn the runtime must either open the stored remote UUID or create a new provider chat, extract and validate its UUID, persist it before sending, and journal it. A local project/chat/subagent switch may never reuse an unmapped remote page. Title matching is fallback-only and must be followed by URL/UUID verification.

The tool preamble state must be keyed by the same mapping key, not provider-global. A provider session switch invalidates only that provider/session mapping. A failed first send must retain the local chat and remote mapping state needed for a safe retry.

## P1 contract: UX

The detected catalog is a full-width accordion in the provider model surface, displays every validated candidate, and exposes explicit active/unsupported/not-detected states. It must not use `prefix(8)` or a count-only popover. Clicking the row selects the model immediately; the row has a visible selected state. The vertical-dots menu contains parameters and secondary actions only; `Выбрать`/`Select` is removed.

Invalid or manually added entries have an explicit remove action. Removing an invalid entry cannot remove a live validated model with the same normalized ID. Effort controls are shown only for the selected model when status is `supported`.

## Adversarial review checklist

Before marking a requirement complete, try to break it with a parent container text, duplicate model names with different case, localized labels, disabled options, hidden options, nested expansion with no DOM change, expansion that changes the menu node identity, a model that has no effort control, a user parameter override, a new local project using the same provider, a new local chat using the same browser pool, a provider session switch, a failed first send, a stale remote UUID, and a remote navigation that lands on the wrong chat.
