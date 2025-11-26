# veta-agents Documentation

Welcome to the `veta-agents` documentation. This bot exposes a REST API (FastAPI) that orchestrates several Semantic Kernel agents to:

1. Answer questions using contextual information from Wikis, Issues and Images (`/ask`).
2. Detect recent exceptions from Azure Log Analytics and create GitHub issues if needed (`/fix/exceptions`).

## Navigation
- [Architecture](architecture.md)
- [Use Cases](use-cases.md)
- [API & Models](api.md)
- [Configuration](configuration.md)
- [Quick Start](#quick-start)

## Quick Start
```bash
uv sync            # Install dependencies
uvicorn app.main:app --reload --env-file .env
# Open http://localhost:8000/docs
```

## Requirements
- Python 3.12.10
- FastAPI
- Semantic Kernel
- Azure (Log Analytics, Identity) for exception flow
- GitHub token (scopes: repo / public_repo)

## License
Pending.
