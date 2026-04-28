# Quick Start Guide

## 1. Setup

```bash
# Clone and navigate to project
git clone <repository-url>
cd leadforge-directory-hunter

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

## 2. Collect Raw HTML (Optional - if not already in bronze layer)

```bash
jupyter notebook notebooks/notebook_clutch_web_scrawler.ipynb
```

This scraper:
- Reads `data/bronze/company_profile_links_cache.csv`
- Fetches HTML from Clutch profile URLs
- Saves files to `data/bronze/html_YYYYMMDD_HHMMSS/`
- Maintains metadata in filenames

## 3. Parse and Extract Data

```bash
jupyter notebook notebooks/notebook_parser.ipynb
```

This parser:
- Loads HTML files from bronze layer (PySpark)
- Extracts 20+ structured fields
- Returns `df_bronze` DataFrame
- Displays preview of first 5 records

## 4. Export Results

```python
# From notebook or Python script
df_export = df_bronze.select(
    "company_slug",
    "profile_title",
    "website_url",
    "overall_rating",
    "review_count",
    "services",
    "minimum_project_size",
    "hourly_rate",
    "employee_range"
).toPandas()

df_export.to_csv('data/gold/profiles_enriched.csv', index=False)
```

## Expected Output

22 columns including:
- Metadata: `record_type`, `company_slug`, `source_folder`, `file_name`, `collected_at`
- Extracted: `profile_title`, `website_url`, `profile_description`, `services`
- Business: `minimum_project_size`, `hourly_rate`, `employee_range`, `locations`, `year_founded`, `languages`
- Schema: `overall_rating` (float), `review_count` (int)

## Troubleshooting

### "Module not found: pyspark"
```bash
pip install pyspark
```

### "Java not found"
Install Java JDK (required for Spark):
- **Windows**: Download from [oracle.com](https://www.oracle.com/java/technologies/downloads/)
- **Mac**: `brew install openjdk`
- **Linux**: `sudo apt-get install openjdk-11-jdk`

### "No HTML files found in bronze directory"
```bash
# Run the scraper first
jupyter notebook notebooks/notebook_clutch_web_scrawler.ipynb
```

### "Rating and review count are null"
Ensure the HTML file contains JSON-LD `<script type="application/ld+json">` blocks with `aggregateRating` objects.

## Performance Notes

- First run: ~2 minutes (loading and parsing all HTML files)
- Subsequent runs: ~30 seconds (cached in memory)
- Tested with ~50 HTML files (~30MB total)
- Scales with PySpark to larger datasets on clusters

## Next Steps

- [ ] Explore `df_bronze` schema: `df_bronze.printSchema()`
- [ ] Check data quality: `df_bronze.describe().show()`
- [ ] Filter by rating: `df_bronze.filter(F.col("overall_rating") >= 4.5).show()`
- [ ] Aggregate services: `df_bronze.groupBy("services").count().show()`
- [ ] Export to PostgreSQL (future integration)
