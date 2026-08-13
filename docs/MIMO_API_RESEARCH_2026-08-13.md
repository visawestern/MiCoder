# Xiaomi MiMo API verification — 2026-08-13

Official sources reviewed:

- https://mimo.mi.com/docs/quick-start/first-api-call
- https://mimo.mi.com/docs/en-US/api/chat/openai-api
- https://mimo.mi.com/docs/quick-start/summary/model

The official OpenAI-compatible pay-as-you-go base URL is `https://api.xiaomimimo.com/v1`; the chat completions URL is `https://api.xiaomimimo.com/v1/chat/completions`. Authentication accepts either `api-key: $MIMO_API_KEY` or `Authorization: Bearer $MIMO_API_KEY`. The repository currently uses `https://api.mimo.ai/v1`, which is the direct cause of the hostname/DNS error shown in the user screenshot.

The official current model table lists `mimo-v2.5-pro` and `mimo-v2.5`; older `mimo-v2-pro`, `mimo-v2-omni`, and `mimo-v2-flash` are deprecated. The official public API documentation does not list a model named `mimo-auto`. Therefore the app must not represent `mimo-auto` as a guaranteed public API model unless it is using a separate authenticated MiMo Auto service/route. For the official public API path, the model list should be authoritative and the UI should label free/auto access only when the actual service confirms it.
## MiMo Auto free route

The official Xiaomi MiMo Code issue tracker documents a separate MiMo Auto free route: `https://api.xiaomimimo.com/api/free-ai/openai/chat`, with model label `mimo/mimo-auto`. The same issue reports that the OAuth/login flow can claim success while credentials are not persisted and later requests return `401 Invalid API Key`; therefore this route is not safe to call as a no-key public OpenAI endpoint without a valid session credential/bootstrap token.

This explains the required architecture: the app must not send MiMo Auto through the ordinary `/v1/chat/completions` client with a synthetic no-key free assumption. It needs a dedicated free-route client and an explicit authentication/bootstrap state; when the free route is not authenticated, the UI must show a clear setup/error state instead of pretending the fallback model is ready.

Reference: https://github.com/XiaomiMiMo/MiMo-Code/issues/306
## Bootstrap details from official MiMo Code issue

The official MiMo Code issue #920 documents the free route bootstrap request as `POST https://api.xiaomimimo.com/api/free-ai/bootstrap` with `Content-Type: application/json`, `Authorization: Bearer anonymous`, and a JSON body containing a client fingerprint. It reports that the response contains a JWT and that chat is then sent to `https://api.xiaomimimo.com/api/free-ai/openai/chat/completions` using that JWT. The official issue also notes that transport/client failures and 403/401 responses can occur, so the app must surface bootstrap/auth errors explicitly.

Reference: https://github.com/XiaomiMiMo/MiMo-Code/issues/920
## Current official free API status

The current official XiaomiMiMo/MiMo-Code source contains `FREE_API_SUNSET_AT = Date.parse("2026-07-26T10:00:00.000Z")` and treats `providerID == "mimo" && modelID == "mimo-auto"` as a free API model. After that timestamp it throws: `MiMo free API service has ended. Sign in or configure a third-party API.`

This is decisive for the user-visible behavior: as of the current task date (2026-08-13), the free `mimo-auto` route is officially sunset in the reference implementation. MiCoder must not promise that an anonymous free model will work. It should either use a valid authenticated Xiaomi API/token-plan route or show a clear unavailable/sunset state. The endpoint and bootstrap findings above remain useful only for historical compatibility and must not be presented as a guarantee of free access.

Source: https://github.com/XiaomiMiMo/MiMo-Code/blob/main/packages/opencode/src/util/free-api-sunset.ts
Source: https://github.com/XiaomiMiMo/MiMo-Code/blob/main/packages/opencode/src/provider/provider.ts
