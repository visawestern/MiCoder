# MiCoder Independent Acceptance Scope

This is an acceptance scope reconstructed from the complete conversation context. Existing spreadsheet PASS values are evidence to re-check, not conclusions.

## Acceptance principles

For each item the audit must verify the full chain: visible control or trigger, state mutation, persistence, runtime consumer, user-visible result, error path, and regression coverage. Two independent scores are required: implementation quality and task-fit quality. A passing parser unit test does not prove a passing macOS/WebKit runtime path.

## Requirement groups

| ID | Requirement extracted from the dialogue | Required acceptance outcome |
|---|---|---|
| AUD-01 | Audit every application feature and create a user story with expected behavior from source code | Every feature has a canonical row and a verifiable expected outcome |
| AUD-02 | Test every user story, document errors, fix logical/UX defects, and retest | Evidence distinguishes source inspection, Foundation tests, macOS build, and manual runtime checks |
| AUD-03 | Normal MiMo Auto / MiCoder Auto Free send must work | Text reaches the intended provider, non-empty response is rendered, rate-limit/error path is visible |
| AUD-04 | Remove obsolete Mimo Auto default path and use MiCoder Auto Free naming | No stale user-facing Mimo branding or wrong default provider remains |
| AUD-05 | Use OpenCode free models such as Big Pickle without an API key | Anonymous catalog, selection, locking and sending work through the intended free route |
| AUD-06 | Switch free model after five failures/rate limit and show a prominent red alert | Failure counter, failover, locked-model behavior and alert are consistent |
| AUD-07 | Free catalog must show current model compactly, list all models, expose status/parameters, lock selection, and refresh | Catalog is complete, compact, editable where intended, and refresh changes persisted data |
| AUD-08 | Provider cards need intuitive edit/delete/refresh/login actions in provider-local ownership | Every mutable provider action is visible at the provider row and persists correctly |
| AUD-09 | Sidebar must resize without clipped/ugly controls and collapse secondary actions into a usable menu | Narrow and wide layouts have complete reachable actions with no overlap |
| AUD-10 | One unified header must remain even when no project is selected | Empty-project and selected-project states do not render duplicate headers |
| AUD-11 | Model detection in embedded browser must have separate built-in DOM mode and free-AI mode | The default detector is deterministic/browser-native; AI mode is explicitly separate and labeled |
| AUD-12 | Web providers must actually send through hidden in-app WKWebView without activating a visible browser | Cookie restore, navigation, type, click, response wait and error result are all real |
| AUD-13 | Model dropdown and effort injection must use the exact selected model/effort and never silently send a different one | Injection confirmation, failure status, no empty response false success, and retry behavior are verifiable |
| AUD-14 | System prompt must be available and sent as part of web-agent behavior | Provider card editing, persisted prompt and first-turn protocol use are connected |
| AUD-15 | Detect every web model, including nested/Expand more models entries such as Qwen Coder | Complete live menu traversal, deduplication, and restoration of the previous model |
| AUD-16 | Effort/thinking must be discovered immediately for every model and hidden for unsupported models | Per-model capability is persisted, selected model controls visibility, and no provider-wide fake effort appears |
| AUD-17 | Web model detection must reject UI noise such as Model and Model Comparison | Valid/invalid classification is explicit; only model IDs enter the catalog |
| AUD-18 | Web model catalog must distinguish active, inactive/unsupported, and removable entries | Each result has a state and the user can remove invalid/manual entries without losing valid live entries |
| AUD-19 | Model list must remain visible after detection, use a full-width accordion, and not cap at eight rows | Detected list is persistent, complete, collapsible by a large row, and understandable |
| AUD-20 | A model row should select on row click; the menu must not contain redundant Choose/Select | Current selection is obvious, parameters remain a separate action, and click behavior is direct |
| AUD-21 | Model parameter profile must capture temperature, max tokens and top-p per model without overwriting user overrides | Discovery, persistence, edit UI and send/runtime consumer are connected |
| AUD-22 | Injection failure must refresh live models/effort/parameters before retry | One bounded recovery refresh is visible and the next retry uses refreshed persisted state |
| AUD-23 | Change login must create a new independent named web session without overwriting existing cookies | Multiple sessions list, persist, activate, restore and delete independently |
| AUD-24 | Browser chats must be isolated by project and local chat and must not mix remote context | Each route has a deterministic identity and correct hidden browser instance |
| AUD-25 | The remote web chat UUID must be stored and reused for the intended local project/chat | Remote URL/ID is extracted after creation or navigation, persisted, and used on subsequent sends |
| AUD-26 | A new project, new local chat or subagent must create/select a new remote web chat when needed | No unrelated local contexts share one remote conversation; explicit continuation remains possible |
| AUD-27 | Every web send must record project, local chat, remote chat, provider, model and effort | Journal and final message provide traceable routing evidence |
| AUD-28 | Existing-chat switching must select the correct vendor conversation before typing | Local title/remote UUID mapping is deterministic and verified after navigation |
| AUD-29 | All model and provider controls must preserve the existing visual style but use clear action ownership | Visual consistency does not override direct, discoverable behavior |
| AUD-30 | The project must compile with Xcode/build-app.sh and tests must pass on macOS | Actual macOS build/test result is reported separately from Linux parse/harness results |
| AUD-31 | Canonical FEATURE_SPREADSHEET.csv is the single source of truth | New findings and statuses are synchronized with the detailed report |
| AUD-32 | Every requested change must have a manual checklist with quality and task-fit ratings | No “PASS” is accepted solely because code exists; unverified runtime items are marked unknown/fail |

## Rating scale

Implementation quality: **5** means the complete chain is implemented and verified on the target runtime; **4** means implemented with a meaningful automated check but target-runtime evidence is incomplete; **3** means partial or fragile; **2** means source scaffolding exists but the chain is broken; **1** means absent or effectively unusable; **0** means contradicted by the current behavior.

Task-fit quality uses the same 0–5 scale but asks a different question: does the result satisfy the user's stated intent and UX wording, rather than merely doing something technically related? For example, a full-width accordion in a different screen cannot earn task-fit credit for the requested provider model accordion.
