# 📚 Documentation Index

Welcome to **LeadForge Directory Hunter**! This index helps you navigate all project documentation.

---

## 🚀 Getting Started

**New to the project?** Start here:

1. **[EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)** ⭐
   - 2-minute overview of what the project does
   - Key capabilities and output dataset
   - Best for managers, stakeholders, and new contributors

2. **[QUICKSTART.md](QUICKSTART.md)**
   - Step-by-step setup (5 minutes)
   - How to run the parser notebook
   - Common troubleshooting

3. **[README.md](README.md)**
   - Detailed project overview
   - Features and architecture
   - Use cases and stack

---

## 🔍 Deep Dives

**Want to understand the technical details?**

- **[ARCHITECTURE.md](ARCHITECTURE.md)**
  - Design decisions and rationale
  - Data flow and processing pipeline
  - Performance characteristics
  - Schema documentation
  - Testing strategy

- **[CONTRIBUTING.md](CONTRIBUTING.md)**
  - How to add new extraction fields
  - Support for new websites/directories
  - Code style and testing guidelines
  - Common issues and solutions

---

## ❓ Help & Support

**Looking for answers?**

- **[FAQ.md](FAQ.md)** - Frequently asked questions
  - Setup & installation
  - Data processing questions
  - Customization tips
  - Advanced usage
  - Troubleshooting

---

## 📖 Reference

**Project information and history:**

- **[CHANGELOG.md](CHANGELOG.md)**
  - What's new in each version
  - Future roadmap
  - Breaking changes (when applicable)

- **[requirements.txt](requirements.txt)**
  - Python package dependencies
  - Versions and installation info

- **[.env.example](.env.example)**
  - Environment variable template
  - Optional configurations

---

## 🛠️ Quick Commands

### Setup
```bash
make setup          # Create venv and install dependencies (Unix/Mac)
make -f Makefile.win setup  # Windows
```

### Run
```bash
make run-parser     # Launch parser notebook
make run-scraper    # Launch scraper notebook
```

### Utilities
```bash
make check-data     # Verify data directory structure
make docs           # Show documentation links
make clean          # Remove venv and cache
```

---

## 📁 Project Structure

```
leadforge-directory-hunter/
│
├── 📄 README.md                    # Project overview
├── 📄 EXECUTIVE_SUMMARY.md         # High-level summary
├── 📄 QUICKSTART.md                # Setup & first run
├── 📄 ARCHITECTURE.md              # Technical details
├── 📄 CONTRIBUTING.md              # Development guide
├── 📄 FAQ.md                       # Q&A
├── 📄 CHANGELOG.md                 # Version history
├── 📄 requirements.txt             # Dependencies
├── 📄 .env.example                 # Config template
│
├── 📓 notebooks/
│   ├── notebook_clutch_web_scrawler.ipynb  (HTML collection)
│   └── notebook_parser.ipynb                (Data extraction)
│
├── 📂 data/
│   ├── bronze/                     (Raw HTML files)
│   ├── silver/                     (Future: intermediate)
│   └── gold/                       (Future: final output)
│
├── 🔧 Makefile                     (Unix automation)
├── 🔧 Makefile.win                 (Windows automation)
└── .gitignore                      (Version control rules)
```

---

## 🎯 Documentation Map by Role

### 👨‍💼 Manager / Stakeholder
1. [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md) - Business overview
2. [README.md](README.md) - Features and use cases
3. [ARCHITECTURE.md](ARCHITECTURE.md) - Technical feasibility

### 👨‍💻 Developer (First Time)
1. [QUICKSTART.md](QUICKSTART.md) - Setup and run
2. [README.md](README.md) - Full context
3. [ARCHITECTURE.md](ARCHITECTURE.md) - How it works

### 👨‍🔧 Developer (Contributing)
1. [CONTRIBUTING.md](CONTRIBUTING.md) - Workflow
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Design decisions
3. [FAQ.md](FAQ.md) - Troubleshooting
4. Notebook comments - Inline documentation

### 🔬 Data Scientist / Analyst
1. [QUICKSTART.md](QUICKSTART.md) - Get data
2. [README.md](README.md) - Understand columns
3. [FAQ.md](FAQ.md) - Data quality questions

### 🏭 DevOps / Production
1. [ARCHITECTURE.md](ARCHITECTURE.md) - Performance notes
2. [CONTRIBUTING.md](CONTRIBUTING.md) - Scaling section
3. [FAQ.md](FAQ.md) - Advanced usage

---

## 🔗 Key Links

### Internal
- Notebooks: `notebooks/`
- Data: `data/bronze/` (raw HTML)
- Configuration: `.env.example`

### External
- **PySpark Docs**: https://spark.apache.org/docs/latest/api/python/
- **Keep a Changelog**: https://keepachangelog.com
- **Semantic Versioning**: https://semver.org

---

## 📊 Documentation Stats

| Document | Length | Read Time | Purpose |
|----------|--------|-----------|---------|
| EXECUTIVE_SUMMARY.md | 400 lines | 5 min | Business overview |
| README.md | 300 lines | 10 min | Technical overview |
| QUICKSTART.md | 150 lines | 5 min | Setup guide |
| ARCHITECTURE.md | 400 lines | 15 min | Technical deep dive |
| CONTRIBUTING.md | 300 lines | 10 min | Development guide |
| FAQ.md | 350 lines | 10 min | Q&A reference |
| CHANGELOG.md | 100 lines | 5 min | Version history |

**Total**: ~2000 lines of documentation

---

## ✅ Documentation Completeness

- ✅ User setup and quickstart
- ✅ Architecture and design rationale
- ✅ API documentation (via docstrings)
- ✅ Contributing guidelines
- ✅ FAQ and troubleshooting
- ✅ Version history and roadmap
- ✅ Examples and code snippets
- ✅ Performance notes

---

## 💬 Questions or Feedback?

1. **Check [FAQ.md](FAQ.md)** - Your question may already be answered
2. **Review [ARCHITECTURE.md](ARCHITECTURE.md)** - Technical explanations
3. **Check [CONTRIBUTING.md](CONTRIBUTING.md)** - Coding questions
4. **Open an issue** - For bugs or feature requests

---

## 🚦 Navigation Shortcuts

- [Home](README.md) | [Setup](QUICKSTART.md) | [Architecture](ARCHITECTURE.md) | [Contributing](CONTRIBUTING.md) | [FAQ](FAQ.md)

---

**Last Updated**: 2026-04-27  
**Version**: 1.0.0  
**Status**: Production-ready
