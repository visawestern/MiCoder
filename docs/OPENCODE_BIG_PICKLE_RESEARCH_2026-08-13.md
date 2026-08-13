# OpenCode Big Pickle research — 2026-08-13

## Verified official facts

Official OpenCode Zen documentation lists **Big Pickle** with model ID `big-pickle`, endpoint `https://opencode.ai/zen/v1/chat/completions`, and the `@ai-sdk/openai-compatible` protocol. The model is listed as free during a limited-time free period, not as a permanently anonymous endpoint.

OpenCode Zen documentation says users must log in to OpenCode Zen and obtain an API key. The provider is pay-as-you-go overall, and the free model status is time-limited. Therefore MiCoder must not call the endpoint without an API key or promise unlimited/free access permanently.

The OpenCode model name in its own config is `opencode/big-pickle`; MiCoder's internal provider can use a separate stable ID such as `MiCoderAutoFree` while sending upstream model ID `big-pickle`.

The official Zen page also lists other temporary free models, but this change specifically targets Big Pickle.

## Sources

1. https://opencode.ai/docs/zen/ — OpenCode Zen documentation, including model IDs, endpoints, auth, pricing, free-period and privacy notes.
2. https://opencode.ai/zen — OpenCode Zen overview and account/balance requirements.
3. https://opencode.ai/docs/providers/ — OpenCode provider credentials and configuration documentation.
