# Trinity — History

## Core Context
- Project: GitHub AI Bot (veta-agents) — Python/FastAPI + Azure OpenAI agents
- User: Jordi Sune
- Stack: Python 3.12, FastAPI, Semantic Kernel → Agents SDK migration
- 6 agents in app/agents/: analyze, fix, review, summarize, triage, validate

## Learnings
- 2026-04-07: AzureChatCompletion must use `endpoint=` (not `base_url=`) — base_url bypasses URL auto-construction → 404
- 2026-04-07: RequestModel requires: question, githubWikis (list[str]), githubWikiBaseImageUrl (str), githubRepo (str)
- 2026-04-07: insightsmiddleware.py fixed JSON crash on non-POST requests (method check + try/except)
- 2026-04-07: Agent SDK migration changed constructor patterns for all 6 agents
- 2026-04-07: OpenAI deployments: gpt-4o + text-embedding-3-small on oai-ghbot-854
- 2026-07-22: ErrorResponseModel added to app/models.py (error, detail, correlation_id) for structured HTTP 500 responses
- 2026-07-22: Routes use JSONResponse(status_code=500) with sanitized error messages; raw exceptions logged server-side only via logging.exception()
- 2026-07-22: Correlation ID pattern: X-Correlation-ID header → fallback uuid4(), same pattern as InsightsMiddleware
- 2026-07-22: Agent instructions enhanced for IssuesCreationAgent, IssuesAgent, ExceptionsAgent — added rules, output format, edge cases
- 2026-07-22: ruff linter runs via `python -m ruff check` (uv not on PATH in this env)
