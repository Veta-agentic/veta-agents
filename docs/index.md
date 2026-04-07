# veta-agents Documentation

Welcome to the **veta-agents** documentation. This AI-powered GitHub bot exposes a REST API (FastAPI) that orchestrates **six specialized Semantic Kernel agents** to:

1. **Answer questions** using contextual information from Wikis, Issues, and Images (`POST /ask`).
2. **Detect production exceptions** from Azure Log Analytics and automatically create GitHub issues assigned to Copilot for autonomous PR creation (`POST /fix/exceptions`).

## Navigation

| Document | Contents |
|----------|----------|
| [Architecture](architecture.md) | Component diagram, 6 agents, orchestration strategy, key bug fixes |
| [Use Cases](use-cases.md) | Detailed sequence diagrams for Q&A and exception detection flows |
| [API & Models](api.md) | Full endpoint reference, request/response schemas, curl examples |
| [Configuration](configuration.md) | Environment variables, Key Vault setup, `endpoint` vs `base_url` gotcha |

## Quick Start

```bash
# 1. Install
pip install uv && uv sync

# 2. Configure
cp .env.sample .env    # Edit with your Azure OpenAI + GitHub credentials

# 3. Run
uvicorn app.main:app --reload --env-file .env
# Open http://localhost:8000/docs
```

## The 6 Agents

| Agent | Flow | What it does |
|-------|------|-------------|
| **WikiAgent** | `/ask` | Downloads and parses wiki pages for contextual answers |
| **IssuesAgent** | `/ask` | Searches existing GitHub issues for related resolutions |
| **ImagesAgent** | `/ask` | Processes images from wiki content into text descriptions |
| **ExceptionsAgent** | `/fix/exceptions` | Queries Azure Log Analytics `AppExceptions` via KQL |
| **IssuesCreationAgent** | `/fix/exceptions` | Creates GitHub issues and assigns to Copilot bot |
| **ReviewerAgent** | Both | Synthesizes outputs from all agents; sends `TERMINATE` to end the loop |

## Requirements

- **Python** 3.12.10
- **FastAPI** + **Semantic Kernel** (≥ 1.41.1)
- **Azure OpenAI** resource with a deployed model (e.g., GPT-4o)
- **Azure** (Log Analytics + Identity) for the exception flow
- **GitHub** personal access token (scopes: `repo` / `public_repo`)

## Project Layout

```
veta-agents/
├── app/
│   ├── agents/              # 6 agent implementations
│   │   ├── wikis/           # WikiAgent + plugin + accessor
│   │   ├── issues/          # IssuesAgent + plugin + accessor
│   │   ├── images/          # ImagesAgent + plugin + accessor
│   │   ├── exceptions/      # ExceptionsAgent + plugin + accessor
│   │   ├── issues_creation/ # IssuesCreationAgent + plugin + accessor
│   │   └── reviewer_agent.py
│   ├── core/                # Config, secrets, middleware, logging
│   ├── services/            # AgentOrchestrator, contracts, token tracking
│   ├── main.py              # FastAPI app entry point
│   ├── routes.py            # /ask and /fix/exceptions route handlers
│   ├── auth.py              # X-API-Key authentication
│   └── models.py            # Pydantic request/response models
├── iac/TF/                  # Terraform infrastructure (AVM modules)
├── scripts/                 # Deploy scripts (deploy-all.ps1, etc.)
├── tests/                   # Unit and integration tests
├── docs/                    # This documentation
├── samples/                 # Example .rest files for VS Code REST Client
├── Dockerfile               # Multi-stage build (Python 3.12-slim + uv)
├── Makefile                 # Dev workflow commands
├── pyproject.toml           # Project metadata and dependencies
└── .env.sample              # Template for local environment variables
```

## License

Pending.
