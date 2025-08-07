.PHONY: format lint check test install dev-install venv clean-venv dev-env

# Format code with ruff
format:
	uv run ruff format .

# Lint code with ruff
lint:
	uv run ruff check .

# Lint and fix issues with ruff
lint-fix:
	uv run ruff check --fix .

# Check code (lint + format check)
check:
	uv run ruff check .
	uv run ruff format --check .

# Install dependencies
install:
	uv sync

# Install development dependencies
dev-install:
	uv sync --extra dev

# Run pre-commit hooks on all files
pre-commit:
	uv run pre-commit run --all-files

# Create virtual environment
venv:
	uv venv .venv --python 3.8
	@echo "Virtual environment created at .venv with Python 3.8"
	@echo "To activate: source .venv/bin/activate (Linux/Mac) or .venv\\Scripts\\activate (Windows)"

# Remove virtual environment
clean-venv:
	rm -rf .venv
	@echo "Virtual environment removed"

# Set up complete development environment
dev-env: clean-venv venv dev-install
	@echo "Development environment ready!"
	@echo "To activate: source .venv/bin/activate (Linux/Mac) or .venv\\Scripts\\activate (Windows)"