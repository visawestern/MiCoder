# OpenCode Big Pickle research — 2026-08-13

## Verified official facts

Official OpenCode Zen documentation lists **Big Pickle** with model ID `big-pickle`, endpoint `https://opencode.ai/zen/v1/chat/completions`, and the `@ai-sdk/openai-compatible` protocol. The model is listed as free during a limited-time free period, not as a permanently anonymous entitlement.

**Live verification, 2026-08-13:** `GET https://opencode.ai/zen/v1/models` returned HTTP 200 and a 61-model catalog both with no `Authorization` header and with `Authorization: Bearer anonymous`. The returned unauthenticated catalog contained `big-pickle` and these official temporary free candidates: `deepseek-v4-flash-free`, `mimo-v2.5-free`, `hy3-free`, `laguna-s-2.1-free`, `ling-3.0-tiny-free`, `nemotron-3-ultra-free`, and `nemotron-3.5-lightning-free`.

**Live chat verification, 2026-08-13:** `POST https://opencode.ai/zen/v1/chat/completions` with model `big-pickle`, `stream: false`, a minimal prompt, and no Authorization header returned HTTP 200, assistant content `OK`, and `cost: "0"`.

The Zen documentation narrative still tells users to log in and obtain an API key for the overall paid catalog. MiCoder Auto Free therefore uses the observed anonymous **free-model catalog only**, never selects a paid model automatically, and treats every free route as revocable. Runtime availability rather than a hard-coded entitlement decides readiness.

The OpenCode model name in its own config is `opencode/big-pickle`; MiCoder sends the upstream model ID `big-pickle` while using the distinct internal provider ID `micoder-auto-free`.

The runtime provider prioritizes Big Pickle, then tries the remaining current free candidates if Big Pickle disappears, returns rate-limit/unavailable, or accumulates five consecutive failed sends.

## Sources

1. https://opencode.ai/docs/zen/ — OpenCode Zen documentation, including model IDs, endpoints, pricing, temporary free models and privacy notes.
2. `GET https://opencode.ai/zen/v1/models` — direct unauthenticated HTTP probe on 2026-08-13; HTTP 200 and 61 models with/without `Authorization: Bearer anonymous`.
3. `POST https://opencode.ai/zen/v1/chat/completions` — direct unauthenticated Big Pickle probe on 2026-08-13; HTTP 200, `OK`, `cost: "0"`.
4. https://opencode.ai/zen — OpenCode Zen overview and account/balance requirements.
5. https://opencode.ai/docs/providers/ — OpenCode provider credentials and configuration documentation.
