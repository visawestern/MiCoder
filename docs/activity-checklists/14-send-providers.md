# Send Providers Checklist

Дата проверки: 2026-08-11. Проверка полного send routing:
`composer -> effective model -> readiness -> route -> transport -> assistant result/error`.

| Provider | Readiness | Route | Transport/function | Test quality |
|---|---|---|---|---|
| MiMo-Auto | Free tier accepted without Serve/API key | `.mimoAuto` | `MiMoAutoProviderStore.streamChat` -> `MiMoAutoClient.chatCompletion` | PASS by tests; live API pending |
| MiMo Serve | Requires connected server | `.mimoServe` | `MimoServeClient.createSession/sendMessage` + SSE | PASS by tests; live Serve pending |
| Custom OpenAI-compatible | URL/key validation | `.openAICompatible` | `DirectChatClient.send` | PASS with scripted transport |
| Ollama | Local endpoint accepted | `.openAICompatible(.../v1)` | `DirectChatClient.send` | PASS by route/scripted tests |
| OpenCode local | Local `/v1` endpoint | `.openAICompatible(.../v1)` | `DirectChatClient.send` | PASS by route/scripted tests |
| Local Agent | Local endpoint accepted | `.openAICompatible` | `DirectChatClient.send` | PASS by route tests |
| ACP custom/local | ACP endpoint route | `.acp` | `ACPClient.sendChatCompletion` | PASS by ACP tests |
| Web Kimi | Cookie + ToS + discovered model | `.web(kimi)` | `WebChatDriver.runTurn` | PASS by readiness/route; live send pending |
| Web Qwen | Cookie + ToS + discovered model | `.web(qwen)` | `WebChatDriver.runTurn` | PASS by readiness/route; live send pending |
| Web ChatGPT | Cookie + ToS + one discovered model | `.web(chatgpt)` | `WebChatDriver.runTurn` | PASS by readiness/route; live send pending |

## Verified route invariants

- MiMo-Auto never falls into MiMo Serve.
- Web Kimi/Qwen/ChatGPT never fall into MiMo Serve.
- Local ACP never falls into OpenAI-compatible HTTP.
- `.none` never creates a server session.
- Selected web models are passed into `WebChatDriver.injectModelAndEffort`.
- Failed route/request persists an error message in the project session.

## Evidence

- `SendRoutingTests`: 19 tests pass.
- Full `swift test`: **1858 tests / 265 suites / 0 failures**.
- Live model menus: Kimi 3 detected entries, Qwen 3 detected entries.
- Kimi live effort popup: `Быстрый`, `Стандартный`, `Высокий`.

## External boundary

Actual response delivery to each third-party account is not simulated by local
tests. It requires one disposable prompt per provider and a live network result.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
