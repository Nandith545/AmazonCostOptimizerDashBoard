.PHONY: dev test lint build push deploy clean

# Local development
dev:
	docker compose up -d db redis
	uv run uvicorn src.main:app --reload --port 8000

# Testing
test:
	uv run pytest tests/ -v --cov=src --cov-report=term-missing

test-unit:
	uv run pytest tests/unit/ -v

test-integration:
	uv run pytest tests/integration/ -v

# Linting
lint:
	uv run ruff check src/ tests/
	uv run ruff format src/ tests/
	uv run mypy src/

# Docker
build:
	docker build -t $(PROJECT_NAME):latest .

push:
	aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.us-west-2.amazonaws.com
	docker tag $(PROJECT_NAME):latest $(AWS_ACCOUNT_ID).dkr.ecr.us-west-2.amazonaws.com/$(PROJECT_NAME):latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.us-west-2.amazonaws.com/$(PROJECT_NAME):latest

# Infrastructure
infra-plan:
	cd infrastructure && terraform plan

infra-apply:
	cd infrastructure && terraform apply

infra-destroy:
	cd infrastructure && terraform destroy

# Cleanup
clean:
	docker compose down -v
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type d -name .pytest_cache -exec rm -rf {} +
	rm -rf .coverage htmlcov/