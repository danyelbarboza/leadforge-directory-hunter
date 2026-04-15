# LeadForge Directory Hunter

Web scraping pipeline for public company directories, focusing on **B2B lead generation**, **data normalization**, and **business-ready delivery**.

The project was designed to simulate a real-world web scraping freelancing scenario: collecting company data from online directories, extracting relevant fields, processing the data, saving it to a database, and exporting a useful dataset for sales, research, or market intelligence.

---

## Overview

**LeadForge Directory Hunter** is a modular scraper for business directories.

It allows you to:

- Collect listing pages
- Discover company profile URLs
- Extract structured data from detail pages
- Standardize and enrich the data
- Save everything to PostgreSQL
- Export CSVs for immediate use
- Generate a lead quality score
- Serve as a foundation for future dashboards and automations

---

## Project Goal

This project was built to demonstrate practical competencies in:

- Python
- Web Scraping
- ETL (Extract, Transform, Load)
- PostgreSQL
- Data Modeling
- Data Cleaning and Standardization
- Pipeline Architecture
- Basic Observability
- Project organization for portfolios and freelancing

More than just “scraping a website,” the proposal is to deliver a **data mini-product**.

---

## Use Case

Imagine a client needs a database of companies in a specific niche, including information such as:

- Company name
- Location
- Website
- Price range
- Team size
- Services offered
- Description
- Reviews
- Lead quality score

This project solves exactly this type of problem.

---

## Architecture

List Pages
   ↓
Collect Company URLs
   ↓
Detail Page Scraper
   ↓
Raw HTML Storage
   ↓
Parser / Normalizer
   ↓
PostgreSQL
   ↓
Lead Scoring
   ↓
CSV Export + Dashboard

---

## Stack

* **Python**
* **Requests**
* **BeautifulSoup / lxml**
* **Selenium**
* **Pandas**
* **SQLAlchemy**
* **PostgreSQL**
* **Docker / Docker Compose**
* **Streamlit** 

---

## Project Structure

leadforge-directory-hunter/
│
├── README.md
├── .env.example
├── docker-compose.yml
├── pyproject.toml
├── requirements.txt
│
├── data/
│   ├── raw/
│   ├── processed/
│   └── exports/
│
├── notebooks/
│   └── exploratory_analysis.ipynb
│
├── sql/
│   ├── init.sql
│   └── queries.sql
│
├── src/
│   └── directory_hunter/
│       ├── __init__.py
│       ├── config.py
│       ├── logging.py
│       ├── main.py
│       │
│       ├── clients/
│       │   ├── base_client.py
│       │   └── http_client.py
│       │
│       ├── spiders/
│       │   ├── base_spider.py
│       │   ├── clutch_list_spider.py
│       │   └── clutch_detail_spider.py
│       │
│       ├── parsers/
│       │   ├── base_parser.py
│       │   └── clutch_parser.py
│       │
│       ├── models/
│       │   ├── raw_page.py
│       │   ├── company.py
│       │   ├── company_service.py
│       │   ├── run.py
│       │   └── error_log.py
│       │
│       ├── pipelines/
│       │   ├── collect_urls.py
│       │   ├── scrape_details.py
│       │   ├── normalize_companies.py
│       │   ├── score_leads.py
│       │   └── export_csv.py
│       │
│       ├── storage/
│       │   ├── postgres.py
│       │   └── file_store.py
│       │
│       ├── scoring/
│       │   └── lead_score.py
│       │
│       └── utils/
│           ├── helpers.py
│           ├── retry.py
│           └── validators.py
│
├── tests/
│   ├── test_parsers.py
│   ├── test_scoring.py
│   └── test_normalization.py
│
└── dashboards/
    └── streamlit_app.py

---

## Features

### 1. Listing Page Collection
Fetches public directory pages and collects links to company profiles.

### 2. Detail Page Extraction
Visits each individual profile to extract richer data fields.

### 3. Raw Storage
Saves HTML and collection metadata for auditing, reprocessing, and debugging.

### 4. Normalization
Standardizes fields such as:
* Location
* Currency
* Price range
* Employee range
* Service categories

### 5. Deduplication
Prevents duplicate records based on:
* Website domain
* Company name
* Location

### 6. Lead Scoring
Applies a simple rule set to rank the quality of the collected leads.

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

### `runs`
Tracks pipeline executions.
* `id`, `source`, `started_at`, `finished_at`, `status`, `pages_collected`, `companies_extracted`, `errors_count`

### `error_logs`
Logs process failures.
* `id`, `url`, `stage`, `error_message`, `created_at`

---

## Lead Scoring

Simple scoring example:
* +25 if it has a website
* +20 if it has an hourly rate
* +20 if it has a minimum project size
* +15 if it has a rich description
* +10 if it has reviews
* +10 if it has multiple services

Classification:
* **0–39** → Weak lead
* **40–69** → Medium lead
* **70–100** → Strong lead

---

## How to Run Locally

### 1. Clone the repository
```bash
git clone [https://github.com/danyelbarboza/leadforge-directory-hunter.git](https://github.com/danyelbarboza/leadforge-directory-hunter.git)
cd leadforge-directory-hunter
```

### 2. Create and activate a virtual environment
```bash
python -m venv .venv
source .venv/bin/activate
```
On Windows:
```bash
.venv\Scripts\activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure environment variables
Create a `.env` file based on `.env.example`.
```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=directory_hunter
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

### 5. Start the database with Docker
```bash
docker compose up -d
```

### 6. Execute the pipeline
Example commands:
```bash
python -m directory_hunter.main collect-urls --source clutch --category "web-development" --country "br"
python -m directory_hunter.main scrape-details --source clutch
python -m directory_hunter.main normalize --source clutch
python -m directory_hunter.main score-leads --source clutch
python -m directory_hunter.main export --source clutch --format csv
```

---

## Output Example

Example of exported columns:

| company_name | website     | country | city      | hourly_rate | employee_range | lead_score |
| ------------ | ----------- | ------- | --------- | ----------- | -------------- | ---------- |
| Example Co   | example.com | Brazil  | São Paulo | $25-$49     | 10-49          | 82         |

---

## Adopted Best Practices

* Separation between collection, parsing, and persistence
* Raw and structured storage
* Modular design
* Focus on reprocessing
* Extensibility for multiple sites
* Ready for light production use

---

## Limitations

* Changes in the site's HTML may require selector updates
* Some directories may use anti-bot protection
* This project does not replace manual commercial validation
* The lead score is heuristic and should be adjusted per use case

---

## Responsible Use

This project is for educational and portfolio purposes.
When using it in production, it is important to respect:
* Target site terms of use
* robots.txt where applicable
* Rate limits
* Responsible scraping best practices
* Applicable data usage laws

---

## Motivation

This repository was created as part of a portfolio focused on freelancing in:
* Web scraping
* ETL
* Data engineering
* Automated collection
* Data products

The idea is to demonstrate the ability not just to extract data, but to organize and transform collection into a useful business asset.

---

## Author

**Danyel Barboza**
* GitHub: [@danyelbarboza](https://github.com/danyelbarboza)

---

## License

This project is distributed under the MIT License.