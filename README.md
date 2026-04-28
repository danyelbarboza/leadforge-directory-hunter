# LeadForge Directory Hunter

Web scraping and data extraction pipeline for business directories, focusing on **B2B lead generation**, **structured data extraction**, and **scalable processing**.

The project was designed to simulate a real-world web scraping scenario: collecting company profile HTML from online directories, extracting relevant fields using robust parsing, normalizing the data with PySpark, and preparing a dataset for sales, research, or market intelligence.

---

## Overview

**LeadForge Directory Hunter** is a two-layer data architecture with modular extraction pipelines.

It allows you to:

- Collect and store raw HTML profiles (**Bronze Layer**)
- Extract structured fields from HTML using regex-based parsers
- Transform and enrich data using PySpark for scalability
- Parse JSON-LD schema data embedded in HTML
- Derive business intelligence metrics (ratings, reviews, services, etc.)
- Export enriched datasets for downstream use
- Serve as a foundation for lead scoring and CRM integration

---

## Project Goal

This project demonstrates practical competencies in:

- Python (3.11+)
- Web scraping and HTML parsing
- ETL (Extract, Transform, Load) with PySpark
- Regex-based data extraction
- JSON-LD schema parsing
- Data normalization and cleaning
- PySpark DataFrames and distributed computing
- Project organization and reproducibility

---

## Use Case

Imagine a client needs a database of service provider companies with structured intelligence, including:

- Company name / profile title
- Website URL
- Overall rating (from embedded schema)
- Review count
- Services offered (with percentages)
- Profile description
- Business details (min project size, hourly rate, employee range, locations, year founded, languages)

This project extracts exactly this information from raw HTML profiles and consolidates it into a clean, queryable dataset using PySpark.

---

## Architecture

Raw HTML Files (Bronze Layer)
   ↓
Load HTML into Spark DataFrame
   ↓
Extract Metadata from Filenames
   ↓
Regex-based Field Extraction
   ├─ Profile Title
   ├─ Website URL (with query param parsing)
   ├─ Profile Description
   ├─ Services (with percentages)
   ├─ Business Details (6 fields)
   └─ Ratings/Reviews (from JSON-LD schema)
   ↓
PySpark DataFrame Enrichment (UDFs)
   ↓
Flattened & Normalized Output
   ↓
Export / Downstream Processing

---

## Stack

* **Python 3.11+**
* **PySpark 4.1.1** (local execution mode)
* **Pandas** (optional, for export/analysis)
* **Standard Library** (regex, json, pathlib, urllib.parse, html.unescape)
* **Jupyter Notebooks** (for interactive exploration)
* Optional: PostgreSQL (future integration), Streamlit (future dashboarding) 

---

## Project Structure

```
leadforge-directory-hunter/
│
├── README.md
│
├── data/
│   ├── bronze/
│   │   ├── company_profile_links_cache.csv     (source URLs)
│   │   └── html_YYYYMMDD_HHMMSS/               (raw HTML storage)
│   │       └── *.html                          (profile pages)
│   ├── gold/                                   (future: processed output)
│   └── silver/                                 (future: intermediate layer)
│
├── notebooks/
│   ├── notebook_clutch_web_scrawler.ipynb      (scraper - collects HTML)
│   ├── notebook_parser.ipynb                   (parser - extracts fields)
│   └── downloaded_files/                       (temporary downloads)
│
├── venv/                                       (Python virtual environment)
│
└── (future: src/, sql/, dashboards/, tests/)
```

### Data Flow

1. **notebook_clutch_web_scrawler.ipynb**
   - Reads `company_profile_links_cache.csv`
   - Fetches HTML pages from Clutch profiles
   - Saves raw HTML to `data/bronze/html_YYYYMMDD_HHMMSS/`
   - Records metadata in filenames: `company-slug_YYYYMMDD_HHMMSS_sequence.html`

2. **notebook_parser.ipynb**
   - Loads all HTML files from bronze layer using PySpark
   - Extracts structured fields via regex-based parsing
   - Parses JSON-LD schema for ratings/reviews
   - Returns enriched Spark DataFrame (22 columns)
   - Ready for export or downstream analysis

---

## Features

### 1. **Bronze Layer Storage**
Stores raw HTML files with consistent metadata-driven naming:
- `company-slug_YYYYMMDD_HHMMSS_sequence.html`
- Enables reproducible parsing and auditability

### 2. **Metadata Extraction**
Parses filename pattern to derive:
- Company slug / identifier
- Collection timestamp
- File sequence number

### 3. **HTML-to-Structured Data Extraction**
Robust regex-based extraction (no external HTML libraries to avoid serialization issues):
- **Profile Title**: From `class="profile-header__title"`
- **Website URL**: From visit-website action, with URL parameter decoding
- **Profile Description**: From summary text block
- **Services**: Chart legend items with percentages
- **Business Details**: 6 fields from profile summary list
- **Ratings & Reviews**: From JSON-LD `aggregateRating` schema

### 4. **JSON-LD Schema Parsing**
- Extracts `<script type="application/ld+json">` blocks
- Recursively searches for `aggregateRating` objects
- Handles nested structures and variable field ordering

### 5. **PySpark Processing**
- Loads HTML files via Spark binary file source
- Applies extraction UDFs row-by-row
- Flattens nested structures
- Returns normalized DataFrame (22 columns)

### 6. **Data Quality**
- Handles missing/malformed data gracefully (returns None)
- Type safety via explicit Spark schemas
- HTML entity decoding and text normalization

### Output Dataset (22 Columns)

| Column | Type | Source |
|--------|------|--------|
| record_type | string | literal "html" |
| company_slug | string | filename parse |
| source_folder | string | file path |
| source_file | string | relative path |
| file_name | string | filename |
| extension | string | ".html" |
| file_size_bytes | long | file stat |
| file_sequence | int | filename parse |
| collected_at | timestamp | filename parse |
| html | string | file content |
| profile_title | string | HTML regex |
| website_url | string | HTML regex + URL parse |
| profile_description | string | HTML regex |
| services | string | HTML regex (semicolon-separated) |
| minimum_project_size | string | HTML regex |
| hourly_rate | string | HTML regex |
| employee_range | string | HTML regex |
| locations | string | HTML regex |
| year_founded | int | HTML regex + year extraction |
| languages | string | HTML regex |
| overall_rating | double | JSON-LD schema |
| review_count | int | JSON-LD schema |

### 7. Exporting
Generates structured files for analysis or client delivery:
* CSV
* PostgreSQL tables
* Dashboard inputs

---

## Data Model

### `raw_pages`
Stores the raw collected content.
* `id`, `source`, `url`, `html`, `fetched_at`, `status_code`, `run_id`

### `companies`
Stores structured company data.
* `id`, `source`, `company_name`, `profile_url`, `website`, `country`, `city`, `min_project_size`, `hourly_rate`, `employee_range`, `description`, `review_count`, `rating`, `lead_score`, `inserted_at`, `updated_at`

### `company_services`
Relates companies to the services found.
* `company_id`, `service_name`

## Implementation Notes

### Regex-Based Extraction

The parser uses pure Python `re` module (no external HTML libraries) to avoid Spark worker serialization issues. Key patterns:

- **Class selectors**: `class="[^"]*target-class[^"]*"`
- **Content capture**: `(?P<content>.*?)` with `re.DOTALL` flag
- **URL parsing**: `urllib.parse` for query parameter extraction
- **HTML normalization**: `html.unescape()` + regex tag removal

### JSON-LD Schema Parsing

Robust extraction that handles:
- Multiple `<script type="application/ld+json">` blocks
- Nested object structures
- Variable field ordering
- Fallback to None for missing data

### PySpark Design

- **Execution Mode**: Local (`local[*]`)
- **UDF Pattern**: Python functions → F.udf() → explicit Spark types
- **Type Safety**: StructType schemas for nested returns
- **Efficiency**: Batch processing via DataFrame operations

---

## How to Run Locally

### Prerequisites
- Python 3.11+
- Java (for PySpark)
- Jupyter Notebook or JupyterLab

### 1. Clone the repository
```bash
git clone <repository-url>
cd leadforge-directory-hunter
```

### 2. Create and activate a virtual environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Prepare data (Bronze Layer)

Ensure raw HTML files exist in:
```
data/bronze/html_YYYYMMDD_HHMMSS/
├── company-slug_YYYYMMDD_HHMMSS_001.html
├── company-slug_YYYYMMDD_HHMMSS_002.html
└── ...
```

Or run the scraper notebook first:
```bash
jupyter notebook notebooks/notebook_clutch_web_scrawler.ipynb
```

### 5. Run the parser
```bash
jupyter notebook notebooks/notebook_parser.ipynb
```

This will:
1. Load all HTML files from the bronze layer
2. Extract structured fields
3. Return an enriched PySpark DataFrame
4. Display a preview of the results

### 6. Export results

From the notebook, you can export to CSV:
```python
# Convert to Pandas for export
df_export = df_bronze.select(*preview_columns).toPandas()
df_export.to_csv('data/gold/profiles_enriched.csv', index=False)
```

---

## Output Example

Preview of extracted fields:

| profile_title | website_url | overall_rating | review_count | services | hourly_rate |
|---|---|---|---|---|---|
| Example Agency | https://example.com | 5.0 | 42 | Web Development 35%; UI/UX Design 40%; ... | $50-$99/hr |

---

## Adopted Best Practices

* Bronze/Silver/Gold data layering
* Raw HTML retention for reproducibility
* Metadata-driven file organization
* Type-safe PySpark schemas
* Graceful null handling
* Modular extraction functions
* Standard library preference (fewer dependencies)

---

## Limitations

* Clutch-specific selectors (extensible to other directories)
* HTML structure changes require selector updates
* Local execution mode (scale with Spark cluster if needed)
* JSON-LD availability depends on target site

---

## Responsible Use

This project is for educational and portfolio purposes. When using it:

* Respect target site **Terms of Use** and `robots.txt`
* Implement appropriate rate limiting
* Do not overload servers
* Respect applicable data protection regulations (GDPR, CCPA, etc.)
* Use data responsibly for intended business purpose
* Consider commercial data licensing alternatives

---

## Future Enhancements

* [ ] Silver layer with dedupe and enrichment logic
* [ ] Gold layer with lead scoring
* [ ] PostgreSQL persistence
* [ ] Streamlit dashboard
* [ ] Support for additional directories (G2, UpWork, etc.)
* [ ] Automated HTML structure change detection
* [ ] Schedule-based collection and refresh
* [ ] API endpoint for dataset access

---

## Motivation

This repository demonstrates practical competencies in:

* **Data Engineering**: ETL pipeline design with PySpark
* **Web Data Extraction**: Robust parsing of unstructured HTML
* **Schema Design**: Structured data modeling
* **Scalability**: Spark for handling large datasets
* **Code Quality**: Documented, tested, reproducible pipelines

The goal is to showcase not just the ability to extract data, but to build thoughtfully-designed, maintainable **data products**.

## Author

**Danyel Barboza**
* GitHub: [@danyelbarboza](https://github.com/danyelbarboza)

---

## License

This project is distributed under the MIT License.