# Decisions

## 2026-04-07: OIDC Authentication for Azure Login
**By:** Morpheus
**What:** azure/login@v2 auto-detects OIDC when client-id + tenant-id provided without client-secret. Do NOT set auth-type: OIDC.
**Why:** auth-type only accepts SERVICE_PRINCIPAL and IDENTITY. OIDC is inferred.

## 2026-04-07: Federated Identity Credential Subjects
**By:** Morpheus
**What:** When GitHub Actions uses `environment: production`, the OIDC subject claim is `repo:org/repo:environment:production`, NOT `ref:refs/heads/main`.
**Why:** Subject mismatch caused deploy failures until the correct federated credential was added.

## 2026-04-07: AzureChatCompletion endpoint parameter
**By:** Trinity
**What:** Always use `endpoint=` (not `base_url=`) for AzureChatCompletion constructor.
**Why:** `base_url=` bypasses URL auto-construction, causing 404 errors on OpenAI API calls.

## 2026-04-07: Terraform AVM Modules
**By:** Morpheus
**What:** All Azure resources use AVM (Azure Verified Modules). zone_balancing is conditional, shared_access_key_enabled=false for storage.
**Why:** Best practices for production Azure infrastructure.

## 2026-04-07: Test Infrastructure and Coverage Expansion
**By:** Tank
**What:** Created `tests/conftest.py` with environment variables required for config loading during test collection. Added `__init__.py` files to all test subdirectories. Integration tests use `httpx.AsyncClient` with `ASGITransport` against the real `app` from `app.main`. Auth tests patch `app.auth.api_keys` directly (not `get_config`) because config loads at module import time. Missing API key returns HTTP 401 (not 403) in FastAPI >=0.135.3.
**Why:** `app.auth` and `app.services.agent_orchestrator` call `get_config()` at module import time, so environment variables must be set before any test module importing these is collected by pytest. Patching `app.auth.api_keys` is the only reliable way to control auth in tests since the list is populated once at import.
**Known Issue:** `ResponseMessage.get_last_reviewed_message()` raises `AttributeError` when no ReviewerAgent messages exist (documented in test `test_get_last_reviewed_message_no_reviewer_raises`). Production code should be fixed.

## 2026-04-07: Structured Error Handling in API Routes
**By:** Trinity
**What:** API error responses now return HTTP 500 (not 200) with a structured `ErrorResponseModel` body containing `error`, `detail`, and `correlation_id`. Raw exception details are never exposed to clients — a generic "Internal server error" message is returned while the full traceback is logged server-side via `logging.exception()`. Correlation ID is extracted from `X-Correlation-ID` header (or auto-generated UUID), matching the existing InsightsMiddleware pattern.
**Why:** Returning HTTP 200 for errors broke any client-side error handling or monitoring that checks status codes. Leaking raw exception messages is a security risk (stack traces, internal paths, credentials in connection strings). Correlation IDs enable tracing errors across client → middleware → route handler → Application Insights.
**Impact:** Clients consuming `/ask` or `/fix/exceptions` should now handle HTTP 500 responses with the `ErrorResponseModel` schema. No breaking change for the happy path — successful responses are unchanged.
