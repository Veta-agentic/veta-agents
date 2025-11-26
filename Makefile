.DEFAULT_GOAL := help 

.PHONY: help
help:  ## Show this help.	
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

.PHONY: build
build: ## Install the app packages
	docker build -t veta-agents .

.PHONY: up
up: build ## Run the app inside docker
	docker run -p 8000:8000 veta-agents

.PHONY: install
install: ## Install the app packages
	uv python install 3.12.10
	uv python pin 3.12.10
	uv sync --no-install-project

.PHONY: update
update: ## Updates the app packages
	uv lock --upgrade

.PHONY: add-dev-package
add-dev-package: ## Installs a new package in the app. ex: make add-dev-package package=XXX
	uv add --dev $(package)

.PHONY: add-package
add-package: ## Installs a new package in the app. ex: make add-package package=XXX
	uv add $(package)

.PHONY: run
run: ## Runs the app in production mode
	OPENAPI_URL= fastapi run

.PHONY: dev
dev: ## Runs the app in development mode
	fastapi dev

.PHONY: check-typing
check-typing: ## Run a static analyzer over the code to find issues
	ty check .

.PHONY: check-lint
check-lint: ## Checks the code style
	ruff check

.PHONY: lint
lint: ## Lints the code format
	ruff check --fix

.PHONY: check-format
check-format: ## Check format python code
	ruff format --check

.PHONY: format
format: ## Format python code
	ruff format

.PHONY: checks
checks: check-lint check-format check-typing  ## Run all checks

.PHONY: test-unit
test-unit: ## Run unit tests
	pytest tests/unit -ra -x --durations=5

.PHONY: test-integration
test-integration: ## Run integration tests
	pytest tests/integration -ra -x --durations=5

.PHONY: test
test: test-unit test-integration ## Run all the tests

.PHONY: watch
watch: ## Run all the tests in watch mode
	ptw --runner "pytest tests -ra -x --durations=5"

.PHONY: coverage
coverage: ## Generates the coverage report
	coverage run --branch -m pytest tests
	coverage html
	@open "${PWD}/htmlcov/index.html"

.PHONY: pre-commit
pre-commit: check-lint check-format test-unit
	
.PHONY: pre-push
pre-push: test-unit

