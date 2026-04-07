# Squad — Veta Agents

## Project Context

**Project:** GitHub AI Bot (veta-agents)
**Stack:** Python 3.12, FastAPI, Azure OpenAI (Semantic Kernel → Agents SDK), Docker, Terraform (AVM modules), GitHub Actions
**What it does:** Intelligent automation bot that uses 6 specialized OpenAI agents to review and resolve GitHub issues. Runs in Azure Web App for Containers.
**User:** Jordi Sune
**Repo:** Veta-agentic/veta-agents

## Members

| Name | Role | Scope | Emoji |
|------|------|-------|-------|
| Morpheus | Lead / DevOps | Architecture, IaC (Terraform/AVM), CI/CD, code review, deployment | 🏗️ Lead |
| Trinity | Backend Dev | Python, FastAPI, agents, API logic, Semantic Kernel / Agents SDK | 🔧 Backend |
| Tank | Tester | Tests, quality, edge cases, validation, pytest | 🧪 Tester |
| Oracle | Docs / DevRel | README, docs, troubleshooting guides, architecture diagrams | 📝 Docs |
| Scribe | Session Logger | Memory, decisions, session logs | 📋 Scribe |
| Ralph | Work Monitor | Work queue, backlog, keep-alive | 🔄 Monitor |

## Infrastructure

- **Resource Group:** rsg-ghbot-854 (westeurope)
- **Web App:** app-ghbot-854.azurewebsites.net (B1 Linux)
- **ACR:** crghbot854
- **OpenAI:** oai-ghbot-854 (gpt-4o + text-embedding-3-small)
- **Key Vault:** kv-ghbot-854
- **Log Analytics:** law-ghbot-854
- **OIDC App:** github-veta-agents (f65b2059-5e5a-47ab-baed-2f3851f7f8ab)

## Issue Source

- **Repository:** Veta-agentic/veta-agents
- **Connected:** 2026-04-07
