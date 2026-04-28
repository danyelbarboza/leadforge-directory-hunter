.PHONY: help setup install run clean test lint docs

help:
	@echo "LeadForge Directory Hunter - Development Commands"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup          - Create virtual environment and install dependencies"
	@echo "  make install        - Install dependencies (assumes venv exists)"
	@echo "  make clean          - Remove virtual environment and cache files"
	@echo ""
	@echo "Development Commands:"
	@echo "  make run-scraper    - Launch Jupyter with scraper notebook"
	@echo "  make run-parser     - Launch Jupyter with parser notebook"
	@echo "  make check-data     - Verify data directory structure"
	@echo ""
	@echo "Documentation:"
	@echo "  make docs           - Show documentation links"

setup: install

install:
	python3 -m venv venv
	venv/bin/pip install --upgrade pip
	venv/bin/pip install -r requirements.txt
	@echo ""
	@echo "✓ Setup complete! Activate with: source venv/bin/activate"

clean:
	rm -rf venv .eggs __pycache__ .pytest_cache .ipynb_checkpoints
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Virtual environment and cache files removed"

run-scraper:
	venv/bin/jupyter notebook notebooks/notebook_clutch_web_scrawler.ipynb

run-parser:
	venv/bin/jupyter notebook notebooks/notebook_parser.ipynb

check-data:
	mkdir -p data/bronze data/gold data/silver
	@echo "✓ Data directory structure verified"

docs:
	@echo "Documentation files:"
	@echo "  - README.md: Project overview and features"
	@echo "  - QUICKSTART.md: Setup and first run guide"
	@echo "  - ARCHITECTURE.md: Technical design decisions"
	@echo "  - CONTRIBUTING.md: Development workflow"
	@echo ""
	@echo "View with: less README.md (or use your editor)"
