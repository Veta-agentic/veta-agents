import os

# Set environment variables needed for config loading before any app imports.
# This ensures app.auth and app.services.agent_orchestrator module-level
# get_config() calls succeed during test collection.
os.environ.setdefault("ENVIRONMENT", "dev")
os.environ.setdefault("GH_TOKEN", "test-gh-token")
os.environ.setdefault("API_KEYS", "test-api-key-1,test-api-key-2")
os.environ.setdefault("IMAGES_DEPLOYMENT_NAME", "test-images")
os.environ.setdefault("IMAGES_API_KEY", "test-images-key")
os.environ.setdefault("IMAGES_BASE_URL", "https://test-images.openai.azure.com")
os.environ.setdefault("IMAGES_API_VERSION", "2024-02-01")
os.environ.setdefault("ISSUES_DEPLOYMENT_NAME", "test-issues")
os.environ.setdefault("ISSUES_API_KEY", "test-issues-key")
os.environ.setdefault("ISSUES_BASE_URL", "https://test-issues.openai.azure.com")
os.environ.setdefault("ISSUES_API_VERSION", "2024-02-01")
os.environ.setdefault("WIKIS_DEPLOYMENT_NAME", "test-wikis")
os.environ.setdefault("WIKIS_API_KEY", "test-wikis-key")
os.environ.setdefault("WIKIS_BASE_URL", "https://test-wikis.openai.azure.com")
os.environ.setdefault("WIKIS_API_VERSION", "2024-02-01")
os.environ.setdefault("REVIEWER_DEPLOYMENT_NAME", "test-reviewer")
os.environ.setdefault("REVIEWER_API_KEY", "test-reviewer-key")
os.environ.setdefault("REVIEWER_BASE_URL", "https://test-reviewer.openai.azure.com")
os.environ.setdefault("REVIEWER_API_VERSION", "2024-02-01")
