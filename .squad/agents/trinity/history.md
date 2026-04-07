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
