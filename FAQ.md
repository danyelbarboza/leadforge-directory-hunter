# Frequently Asked Questions (FAQ)

## Setup & Installation

### Q: Do I need to install Spark separately?
**A**: No. `pip install pyspark` bundles Spark. You just need Java installed.

### Q: What version of Python is required?
**A**: Python 3.11 or higher. PySpark 4.1.1 officially supports Python 3.10+.

### Q: Can I use this on macOS/Linux?
**A**: Yes. Use `Makefile` instead of `Makefile.win`, and `source venv/bin/activate` instead of `venv\Scripts\activate`.

### Q: I get "Java not found" error
**A**: Install Java JDK:
- **Windows**: Download from oracle.com or use `choco install openjdk11`
- **Mac**: `brew install openjdk`
- **Linux**: `sudo apt-get install openjdk-11-jdk`

### Q: Can I skip creating a venv?
**A**: Not recommended. Venvs isolate dependencies and prevent version conflicts. Takes <1 minute to create.

---

## Data & Processing

### Q: How long does the parser take to run?
**A**: First execution: ~2 minutes (file I/O dominates)
Subsequent runs: ~30 seconds (if DataFrame is cached)

### Q: Why are some fields null in the output?
**A**: Fields return None if:
- The HTML pattern doesn't exist in the file
- The regex pattern doesn't match (e.g., HTML structure changed)
- JSON-LD schema is missing or malformed

Check null counts:
```python
df_bronze.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) 
                 for c in df_bronze.columns]).show()
```

### Q: Can I process files not in the bronze directory?
**A**: Yes. Modify the notebook:
```python
custom_html_dir = Path("path/to/custom/html/files")
df = load_bronze_html_files(spark, bronze_dir=custom_html_dir)
```

### Q: How do I export to CSV?
**A**: 
```python
# Convert to Pandas first
df_export = df_bronze.select("profile_title", "website_url", "overall_rating").toPandas()
df_export.to_csv("output.csv", index=False)
```

### Q: Can I filter the results before exporting?
**A**: Yes:
```python
df_filtered = df_bronze.filter(F.col("overall_rating") >= 4.5)
df_filtered.select("profile_title", "overall_rating").toPandas().to_csv("top_rated.csv")
```

### Q: The rating/review count extraction returns None for all rows
**A**: The HTML likely doesn't contain JSON-LD `<script type="application/ld+json">` blocks. Verify:
```python
# Check if any file contains JSON-LD
sample_html = df_bronze.select("html").limit(1).collect()[0][0]
if '<script type="application/ld+json">' in sample_html:
    print("JSON-LD found")
else:
    print("JSON-LD not found - may need to use HTML selectors instead")
```

---

## Customization & Extension

### Q: How do I add extraction of a new field?
**A**: Follow the Contributing guide [CONTRIBUTING.md](CONTRIBUTING.md), section "Add a New Extraction Field".

In summary:
1. Create extraction function with regex pattern
2. Wrap in UDF: `F.udf(function, return_type)`
3. Apply in enrichment: `.withColumn("field_name", udf(F.col("html")))`
4. Test with sample data

### Q: How do I support a different directory (not Clutch)?
**A**: The selectors are hardcoded for Clutch's HTML structure. For another site:
1. Inspect their HTML to find equivalent CSS classes/IDs
2. Update regex patterns in extraction functions
3. Create a new scraper notebook for their site
4. Test extraction with sample files

### Q: Can I run this on a Spark cluster?
**A**: Yes! No code changes needed. Just change the Spark session initialization:
```python
# Replace local[*] with cluster master
spark = SparkSession.builder.master("spark://cluster-master:7077").getOrCreate()
```

### Q: How do I add a new column to the output?
**A**: Add extraction function → register UDF → apply in enrichment → add to preview columns (optional).

---

## Performance & Optimization

### Q: How can I speed up processing?
**A**: 
1. **Cache DataFrame** if running multiple analyses:
   ```python
   df_bronze.cache()
   df_bronze.count()
   ```

2. **Increase worker parallelism**:
   ```python
   spark = SparkSession.builder.master("local[8]").getOrCreate()
   ```

3. **Use Parquet for persistence** instead of re-parsing:
   ```python
   df_bronze.write.mode("overwrite").parquet("cache.parquet")
   # Next time: spark.read.parquet("cache.parquet")
   ```

### Q: Can I process 1 million files with this setup?
**A**: Yes, but:
- Local mode will be slow; use a Spark cluster
- Partition output for parallel I/O:
  ```python
  df_bronze.coalesce(8).write.parquet("output/")
  ```
- Monitor memory: increase Spark driver/executor memory as needed

### Q: The notebook is using too much memory
**A**: 
1. Reduce batch size:
   ```python
   df_bronze = df_bronze.limit(100)  # Process 100 files instead of all
   ```

2. Increase heap size before starting Jupyter:
   ```bash
   set SPARK_DRIVER_MEMORY=4g
   jupyter notebook
   ```

---

## Troubleshooting

### Q: "ModuleNotFoundError: No module named 'pyspark'"
**A**: 
```bash
pip install pyspark
# OR ensure venv is activated:
source venv/bin/activate  # Mac/Linux
venv\Scripts\activate     # Windows
```

### Q: "No matching files found for: data/bronze/html_*/*.html"
**A**: The bronze directory is empty. Run the scraper first:
```bash
jupyter notebook notebooks/notebook_clutch_web_scrawler.ipynb
```

### Q: Jupyter notebook won't start
**A**: 
```bash
# Ensure venv is activated
source venv/bin/activate
pip install --upgrade jupyter
jupyter notebook
```

### Q: Extraction functions are slow
**A**: Regex compilation happens per call. Cache compiled patterns (if needed):
```python
# Define at module level (outside function)
TITLE_PATTERN = re.compile(r'...', flags=re.IGNORECASE | re.DOTALL)

def extract_profile_title(html_text):
    match = TITLE_PATTERN.search(html_text)
    # ... rest of logic
```

### Q: "Py4JJavaError" when running PySpark
**A**: Java is not properly installed or not in PATH. Verify:
```bash
java -version
# Should output Java version
```

If missing, install as described above.

---

## Advanced Usage

### Q: Can I run SQL queries on the DataFrame?
**A**: Yes:
```python
df_bronze.createOrReplaceTempView("profiles")
spark.sql("SELECT profile_title, overall_rating FROM profiles WHERE overall_rating >= 4.5").show()
```

### Q: How do I save the enriched DataFrame permanently?
**A**: Export to Parquet (faster to reload) or CSV (universal):
```python
# Parquet (Spark-native, preserves types)
df_bronze.write.mode("overwrite").parquet("data/gold/profiles.parquet")

# CSV (universal, human-readable)
df_bronze.toPandas().to_csv("data/gold/profiles.csv", index=False)
```

### Q: Can I schedule this to run daily?
**A**: Yes, with Apache Airflow or Prefect (not included). Create a DAG that:
1. Calls the scraper notebook
2. Calls the parser notebook
3. Exports results

Alternatively, use `papermill` to parameterize notebook execution:
```bash
pip install papermill
papermill notebooks/notebook_parser.ipynb output.ipynb -p date "2026-04-27"
```

---

## Questions Not Answered Here?

- Check **[README.md](README.md)** for project overview
- See **[ARCHITECTURE.md](ARCHITECTURE.md)** for technical details
- Follow **[CONTRIBUTING.md](CONTRIBUTING.md)** for development
- Run **`make docs`** to see all documentation files
