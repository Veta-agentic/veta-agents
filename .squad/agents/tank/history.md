# Tank — History

## Core Context
- Project: GitHub AI Bot (veta-agents) — Python/FastAPI + Azure OpenAI agents
- User: Jordi Sune
- Test framework: pytest (14 tests passing)
- Test location: tests/ directory

## Learnings
- 2026-04-07: 14/14 pytest tests passing on main
- 2026-04-07: Tests cover agent initialization, API endpoints, middleware behavior
- 2026-04-07: Live app tested successfully: GET /docs → 200, POST /ask → 200 with AI response
- 2026-04-07: Expanded to 40/40 tests passing. Added integration tests (test_routes.py) and unit tests for models, auth, agent_contracts, config, and error handling.
- 2026-04-07: tests/conftest.py sets env vars for config loading — required because app.auth and agent_orchestrator call get_config() at module import time.
- 2026-04-07: FastAPI APIKeyHeader returns 401 (not 403) for missing header in fastapi>=0.135.3. Auth tests patch app.auth.api_keys directly (module-level list).
- 2026-04-07: ResponseMessage.get_last_reviewed_message() has a bug — raises AttributeError when no ReviewerAgent messages exist (None.message access). Test documents this behavior.
- 2026-04-07: ExceptionWatchRequestModel uses BaseSchema with to_camel validation alias — JSON payloads must use camelCase field names.
- 2026-04-07: Run tests with: python -m uv run pytest tests/ -v (uv not on PATH directly, use python -m uv)
