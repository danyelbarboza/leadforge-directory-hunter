# Technical Architecture

## Design Decisions

### 1. **No External HTML Parsing Libraries**

**Decision**: Use pure Python `re` module instead of BeautifulSoup or lxml

**Reasoning**:
- Spark workers cannot reliably serialize external library modules
- Regex with compiled patterns is more portable across worker nodes
- Reduces dependency footprint and installation complexity
- Standard library only → works in any Python environment

**Trade-off**: Regex is less flexible for complex DOM traversal, but sufficient for consistent HTML structures (Clutch profiles are well-formatted).

### 2. **PySpark Local Mode**

**Decision**: Run PySpark in `local[*]` mode instead of distributed cluster

**Reasoning**:
- Data volume manageable on single machine (~50 HTML files = ~30MB)
- Simplifies deployment and eliminates infrastructure overhead
- PySpark DataFrame API scales to cluster mode without code changes
- Ideal for exploratory work and development

**Scalability**: To process petabyte-scale data, simply point to a Spark cluster and adjust the master URL.

### 3. **Binary File Source for HTML Loading**

**Decision**: Use `spark.read.format("binaryFile")` instead of text source

**Reasoning**:
- Returns one row per file (natural granularity for HTML documents)
- Preserves full file content including special characters
- Metadata (path, size, modificationTime) available automatically
- Simpler than managing multiple file reads

**Example**:
```python
df = spark.read.format("binaryFile").load("data/bronze/html_*/*.html")
# Result: one row per HTML file with content, length, modificationTime
```

### 4. **Metadata-Driven File Naming**

**Format**: `company-slug_YYYYMMDD_HHMMSS_sequence.html`

**Reasoning**:
- Filename encodes company identity, collection timestamp, and order
- Regex parsing derives metadata without external lookups
- Enables reproducibility and auditability
- Sortable for time-series analysis

**Example**:
```
acme-corp_20260415_120530_001.html
└─ company_slug: acme-corp
└─ collected_at: 2026-04-15 12:05:30
└─ file_sequence: 001
```

### 5. **JSON-LD Schema for Ratings/Reviews**

**Decision**: Extract from structured data in `<script type="application/ld+json">` instead of HTML selectors

**Reasoning**:
- Schema.org JSON-LD is machine-readable and semantically correct
- Less fragile than CSS selectors when HTML structure changes
- Recursive search handles nested `aggregateRating` in complex structures
- Standard format across most modern websites

**Implementation**:
```python
# Find <script type="application/ld+json"> blocks
# Parse JSON
# Recursively search for { "@type": "AggregateRating", "ratingValue": ..., "reviewCount": ... }
```

### 6. **Struct Types for Nested Returns**

**Decision**: Use `StructType` + UDFs instead of multiple columns for complex extractions

**Reasoning**:
- Type safety at extraction layer
- Ability to flatten nested data later (drop intermediate struct)
- Cleaner code organization
- Easier to extend with new nested fields

**Example**:
```python
rating_and_count_schema = T.StructType([
    T.StructField("overall_rating", T.DoubleType(), True),
    T.StructField("review_count", T.IntegerType(), True),
])

# Later flatten:
df.withColumn("overall_rating", F.col("rating_and_count.overall_rating"))
```

---

## Data Flow

```
┌─────────────────────────────────────┐
│   Raw HTML Files (Bronze Layer)     │
│  data/bronze/html_YYYYMMDD_HHMMSS/  │
│    company-slug_*.html              │
└──────────────┬──────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│  PySpark DataFrame Initialization             │
│  - Binary file source (one row per file)      │
│  - Metadata: path, size, collection time     │
│  - Column: html (raw content)                │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│  Metadata Extraction (from filename)          │
│  - company_slug, collected_at, file_sequence │
│  - Via regex pattern match                    │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│  Field Extraction (Regex UDFs)               │
│  - profile_title, website_url,               │
│  - profile_description, services             │
│  - business details (6 fields)               │
│  - Overall rating & review count (JSON-LD)  │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│  DataFrame Enrichment                        │
│  - withColumn() for each extracted field     │
│  - Drop intermediate struct columns          │
│  - Result: 22 columns, type-safe schema      │
└──────────────┬───────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────┐
│  Output: Enriched Spark DataFrame            │
│  - Queryable via SparkSQL                    │
│  - Exportable to Pandas/CSV                  │
│  - Ready for downstream processing           │
└──────────────────────────────────────────────┘
```

---

## Extraction Functions

| Function | Input | Output | Method |
|----------|-------|--------|--------|
| `extract_profile_title` | HTML | string | Regex on `profile-header__title` class |
| `extract_website_url` | HTML | string | Regex + URL parameter parsing |
| `extract_profile_description` | HTML | string | Regex on `profile-summary__text` |
| `extract_services` | HTML | string | Regex with semicolon-separated format |
| `extract_profile_summary_details` | HTML | struct (6 fields) | Regex on `profile-summary__detail` items |
| `extract_rating_and_review_count` | HTML | struct (2 fields) | JSON-LD schema extraction |

---

## Performance Characteristics

| Operation | Time | Notes |
|-----------|------|-------|
| Load HTML files | ~80s | 50 files, Spark binary source |
| Extract fields (UDFs) | ~1s | Fast regex operations |
| Flatten struct columns | <0.1s | Column selection |
| Total pipeline | ~2 min | First run; cached on re-execution |

**Bottleneck**: File I/O dominates; extraction is negligible.

**Optimization**: Cache DataFrame after load if running multiple analyses.

```python
df_bronze.cache()  # Pins to memory
df_bronze.count()  # Trigger caching
```

---

## Schema Evolution

Current schema (v1.0):

```
record_type: string
company_slug: string
source_folder: string (nullable)
source_file: string
file_name: string
extension: string
file_size_bytes: long
file_sequence: int
collected_at: timestamp
html: string
profile_title: string (nullable)
website_url: string (nullable)
profile_description: string (nullable)
services: string (nullable)
minimum_project_size: string (nullable)
hourly_rate: string (nullable)
employee_range: string (nullable)
locations: string (nullable)
year_founded: int (nullable)
languages: string (nullable)
overall_rating: double (nullable)
review_count: int (nullable)
```

**Extension Points**:
- Add new extraction functions → new columns
- Add new regex patterns for different sites
- Add filtering/scoring UDFs for lead quality

---

## Error Handling

**Philosophy**: Graceful degradation (return None rather than fail)

```python
# All extraction functions:
if not isinstance(html_text, str) or not html_text.strip():
    return None
# ... extraction logic ...
# If pattern doesn't match or parse fails:
return None
```

**Result**: Null values indicate missing/unparseable data, but pipeline continues.

**Analysis**: Check null counts to identify potential parser issues:
```python
df_bronze.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) 
                 for c in df_bronze.columns]).show()
```

---

## Testing Strategy

Recommended test coverage:

```python
# Unit tests for extraction functions (with sample HTML)
def test_extract_profile_title():
    html_snippet = '<h1 class="profile-header__title">Example Co</h1>'
    assert extract_profile_title(html_snippet) == "Example Co"

# Integration tests (with real HTML files)
def test_parser_notebook():
    spark = get_spark_session()
    df = load_bronze_dataframe(spark)
    assert df.count() > 0
    assert "overall_rating" in df.columns
    assert df.filter(F.col("overall_rating").isNotNull()).count() > 0
```

---

## Future Improvements

1. **Incremental Updates**: Track already-parsed files to avoid re-processing
2. **Schema Detection**: Auto-detect HTML structure changes and alert on deviation
3. **Multi-Site Support**: Parameterize extraction patterns for different directories
4. **Lead Scoring**: Add downstream UDFs for quality ranking
5. **Caching Strategy**: Persist enriched DataFrame to Parquet for faster re-runs
6. **Monitoring**: Log extraction success rates and common null fields
