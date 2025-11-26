FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_CACHE_DIR=/opt/uv-cache/
# ENV VIRTUAL_ENV=/opt/venv
# ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /app
RUN uv venv
ADD . /app
RUN uv sync --frozen --no-cache
RUN uv run pytest tests/
EXPOSE 8000
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000" ]
