# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-27

### Added

#### Core Features
- **PySpark-based HTML parsing pipeline** for processing raw profile files from bronze layer
- **22-column enriched dataset** with structured profile data extraction
- **JSON-LD schema parsing** for reliable rating and review count extraction
- **Metadata-driven file naming** (`company-slug_YYYYMMDD_HHMMSS_sequence.html`)
- **Regex-based extraction functions** (no external HTML libraries to avoid worker serialization issues)

#### Extracted Fields
- Profile metadata: title, website URL, description
- Business details: min project size, hourly rate, employee range, locations, year founded, languages
- Service offerings: semicolon-separated list with percentages
- Ratings: overall rating (float) and review count (int) from JSON-LD schema
- File metadata: company slug, collection timestamp, file sequence, source folder

#### Documentation
- **README.md**: Complete project overview with features and data flow diagram
- **QUICKSTART.md**: Setup and execution guide for first-time users
- **ARCHITECTURE.md**: Technical design decisions and performance characteristics
- **CONTRIBUTING.md**: Development workflow for extending functionality
- **Makefile**: Unix automation for common development tasks
- **Makefile.win**: Windows batch alternative for Makefile
- **.env.example**: Environment variable template for configuration

#### Configuration
- **requirements.txt**: Python dependencies (PySpark, Pandas, Jupyter)
- **.gitignore**: Updated to ignore large data files while preserving directory structure
- **.gitkeep**: Placeholder files for empty data directories

#### Notebooks
- **notebook_parser.ipynb**: Complete pipeline
  - Cell 1: Imports (datetime, html, json, pathlib, re, urllib.parse, pyspark)
  - Cell 2: Spark session initialization with local[*] mode
  - Cell 3: 8 extraction helper functions + JSON-LD recursive search
  - Cell 4: HTML file loaders and bronze dataframe builder
  - Cell 5: Raw HTML loading (triggers ~80s file I/O)
  - Cell 6: UDF registration and enrichment pipeline (applies all extractors)
  - Cell 7: Preview display (vertical format for wide dataframes)

### Technical Highlights

- **No external HTML libraries**: Pure Python `re` module for Spark worker compatibility
- **Recursive JSON-LD search**: Handles nested aggregateRating in complex structures
- **Type-safe schemas**: StructType definitions for nested extractions
- **Graceful error handling**: Null returns for missing/unparseable data
- **Local execution**: Scales to distributed Spark without code changes

### Known Limitations

- Clutch-specific HTML selectors (extensible to other sites)
- Requires local Java installation for PySpark
- HTML structure changes may require selector updates
- JSON-LD availability depends on target site implementation

---

## [0.1.0] - Initial Project Structure

### Added
- Project scaffolding and documentation templates
- Example data directory structure (bronze/silver/gold layers)
- Git repository initialization

---

## Future Roadmap

- [ ] **v1.1.0**: Silver layer with deduplication and enrichment
- [ ] **v1.2.0**: Gold layer with lead scoring and business intelligence
- [ ] **v2.0.0**: PostgreSQL persistence layer
- [ ] **v2.1.0**: Streamlit dashboard for data exploration
- [ ] **v3.0.0**: Multi-site support (Upwork, G2, Glassdoor, etc.)
- [ ] **v3.1.0**: Automated HTML structure change detection
- [ ] **v3.2.0**: REST API for dataset access
- [ ] **v4.0.0**: Production-ready orchestration (Airflow/Prefect)

---

## Contributors

- Initial implementation: Data engineering portfolio project

---

## License

Not yet specified. See LICENSE file when added.
