# Contributing

## Project Structure

```
leadforge-directory-hunter/
├── README.md                    # Project overview
├── QUICKSTART.md               # Setup and execution guide
├── ARCHITECTURE.md             # Technical design decisions
├── CONTRIBUTING.md             # This file
├── requirements.txt            # Python dependencies
├── .env.example                # Environment variables template
│
├── notebooks/
│   ├── notebook_clutch_web_scrawler.ipynb  # HTML collection
│   └── notebook_parser.ipynb                # Data extraction
│
└── data/
    ├── bronze/                 # Raw HTML files
    │   ├── company_profile_links_cache.csv
    │   └── html_YYYYMMDD_HHMMSS/
    ├── silver/                 # Future: dedupe, enrich
    └── gold/                   # Future: final output
```

## Development Workflow

### 1. Add a New Extraction Field

Example: Extracting `client_focus` from a new HTML element.

**Step 1**: Identify the HTML pattern
```html
<div class="client-focus-list">
  <span class="item">Startups</span>
  <span class="item">SMBs</span>
</div>
```

**Step 2**: Add extraction function to `notebook_parser.ipynb` (cell #VSC-ecb06c73)
```python
def extract_client_focus(html_text):
    """Extract client focus areas as comma-separated string."""
    if not isinstance(html_text, str) or not html_text.strip():
        return None
    
    pattern = re.compile(
        r'<div[^>]*class="[^"]*client-focus-list[^"]*"[^>]*>(?P<content>.*?)</div>',
        flags=re.IGNORECASE | re.DOTALL,
    )
    match = pattern.search(html_text)
    if not match:
        return None
    
    items = re.findall(r'<span[^>]*class="[^"]*item[^"]*"[^>]*>(?P<content>.*?)</span>', 
                       match.group("content"),
                       flags=re.IGNORECASE | re.DOTALL)
    return ", ".join(normalize_html_text(item) for item in items) if items else None
```

**Step 3**: Register UDF in cell #VSC-5bbe083e
```python
client_focus_udf = F.udf(extract_client_focus, T.StringType())
```

**Step 4**: Apply in enrichment function
```python
def enrich_profile_dataframe(df):
    enriched_df = (
        df
        # ... existing columns ...
        .withColumn("client_focus", client_focus_udf(F.col("html")))
    )
    return enriched_df
```

**Step 5**: Add to preview columns in cell #VSC-d84ff2a7
```python
preview_columns = [
    # ... existing columns ...
    "client_focus",
]
```

**Step 6**: Test
```bash
jupyter notebook notebooks/notebook_parser.ipynb
# Execute all cells and verify client_focus values are extracted
```

### 2. Support a New Directory (e.g., Upwork instead of Clutch)

**Step 1**: Create new scraper notebook
```
notebooks/notebook_upwork_web_scrawler.ipynb
```

**Step 2**: Adjust extraction functions for new HTML selectors
- Upwork may use different class names than Clutch
- Create new extraction functions or parameterize existing ones

**Step 3**: Update file naming convention in metadata
- Include source directory in filename: `upwork_acme-corp_YYYYMMDD_*.html`

**Step 4**: Update notebook to detect source and apply correct patterns
```python
def extract_profile_title_smart(html_text, source="clutch"):
    if source == "upwork":
        return extract_profile_title_upwork(html_text)
    else:
        return extract_profile_title(html_text)
```

### 3. Optimize for Scale

**Current**: Local[*] PySpark, ~50 files

**To 10,000 files**:
1. No code changes needed; just point to Spark cluster:
   ```python
   spark = SparkSession.builder.master("spark://master:7077").getOrCreate()
   ```

2. Partition output for parallel writing:
   ```python
   df_bronze.coalesce(8).write.parquet("data/gold/profiles/")
   ```

3. Monitor with Spark UI: http://localhost:4040

### 4. Add Lead Scoring

Create new cell in parser notebook:
```python
from pyspark.sql.functions import when, col

def score_lead(df):
    """Simple rule-based lead scoring."""
    scored_df = df.withColumn("lead_score",
        when(col("website_url").isNotNull(), 25).otherwise(0) +
        when(col("hourly_rate").isNotNull(), 20).otherwise(0) +
        when(col("minimum_project_size").isNotNull(), 20).otherwise(0) +
        when(col("profile_description").isNotNull(), 15).otherwise(0) +
        when(col("overall_rating") >= 4.5, 10).otherwise(0) +
        when(col("services").isNotNull(), 10).otherwise(0)
    )
    return scored_df

df_bronze = score_lead(df_bronze)
```

---

## Code Style Guidelines

### Python
- Follow PEP 8
- Use type hints where helpful
- Add docstrings with Parameters/Returns sections
- Keep functions focused and testable

### Regex Patterns
- Use named groups: `(?P<name>...)`
- Always include `flags=re.IGNORECASE | re.DOTALL` for robustness
- Document expected HTML structure in function docstring
- Test with multiple variations (different whitespace, attribute order, etc.)

### Notebooks
- One logical task per cell
- Add markdown headers for cell purposes
- Use descriptive variable names
- Comment non-obvious logic

---

## Testing

### Manual Testing
```bash
# Run parser notebook end-to-end
jupyter notebook notebooks/notebook_parser.ipynb

# Validate output
# - Check df_bronze.count() > 0
# - Check null counts: df_bronze.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) for c in df_bronze.columns]).show()
# - Inspect sample data: df_bronze.select("profile_title", "website_url").show(5, truncate=False)
```

### Unit Testing (future)
```bash
# Create tests/test_extractors.py
pytest tests/

# Example:
def test_extract_rating():
    html = '''<script type="application/ld+json">{"aggregateRating": {"ratingValue": "4.8", "reviewCount": "52"}}</script>'''
    rating, count = extract_rating_and_review_count(html)
    assert rating == 4.8
    assert count == 52
```

---

## Documentation

When adding features, update:

1. **README.md**: High-level overview of new capability
2. **ARCHITECTURE.md**: Technical details and design rationale
3. **Function docstrings**: Purpose, parameters, return values
4. **Inline comments**: Non-obvious logic in extraction functions

---

## Commit Message Style

```
feat: add client_focus extraction from HTML

- Parse <div class="client-focus-list"> elements
- Return comma-separated focus areas
- Add UDF and apply in enrichment pipeline
- Update preview columns

Closes #42
```

### Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring
- `docs`: Documentation updates
- `test`: Test additions
- `perf`: Performance improvement

---

## Common Issues and Solutions

### "RuntimeError: broadcast variables not supported in UDFs"
**Problem**: Trying to use external variables in UDF
**Solution**: Pass data as parameters or use global constants

```python
# ❌ Wrong
def extract_field(html_text):
    # Can't access external_list here in Spark
    return value in external_list

# ✅ Correct
def extract_field(html_text):
    # Hard-code or pass as parameter
    valid_values = ["a", "b", "c"]
    return value in valid_values
```

### "Parsing JSON-LD returns None"
**Problem**: Regex not matching `<script type="application/ld+json">`
**Solution**: Verify HTML actually contains the script tag

```python
# Debug
import re
scripts = re.findall(r'<script[^>]*type\s*=\s*["\']application/ld\+json', html_text)
print(f"Found {len(scripts)} JSON-LD scripts")
```

### "Notebook execution time > 2 minutes"
**Problem**: Reprocessing all files
**Solution**: Cache the DataFrame

```python
df_bronze.cache()
df_bronze.count()  # Trigger caching
```

---

## Questions?

Open an issue or refer to:
- [README.md](README.md) - Project overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - Design decisions
- [QUICKSTART.md](QUICKSTART.md) - Setup guide
- Notebook comments and docstrings
