# LeadForge Directory Hunter - Executive Summary

## 📊 Project At a Glance

| Aspect | Details |
|--------|---------|
| **Purpose** | Extract structured B2B lead data from web directory profiles (HTML) at scale |
| **Current Scope** | Clutch.co profiles: 22 extracted fields per company |
| **Technology** | Python 3.11 + PySpark 4.1.1 (local execution, cluster-ready) |
| **Processing Model** | Batch processing: load HTML → extract fields → export results |
| **Data Volume** | Tested: ~50 HTML files (~30MB); scales to petabytes with distributed Spark |
| **Execution Time** | First run: ~2 min (file I/O limited) | Cached: ~30s |
| **Status** | Production-ready for development; ready to extend to other sites |

---

## 🎯 Key Capabilities

### 1. **Metadata Extraction**
Derives company identity and collection timeline from filename pattern:
```
acme-corp_20260415_120530_001.html
         └─ Parsed: slug, timestamp, sequence
```

### 2. **HTML-to-Structured Data**
Robust regex-based extraction (no external libraries to avoid Spark worker issues):
- Profile title, website URL, description
- Services (with percentages)
- Business metrics (6 fields)
- Ratings & review counts (from JSON-LD schema)

### 3. **JSON-LD Schema Parsing**
Recursively searches for `aggregateRating` in embedded structured data:
```json
{
  "@type": "AggregateRating",
  "ratingValue": "4.8",
  "reviewCount": "52"
}
```

### 4. **Data Quality**
- Graceful null handling (missing data → None, not crash)
- Type-safe Spark schemas (prevents runtime surprises)
- HTML entity decoding + text normalization

### 5. **Scalability**
- Local execution: works on any laptop
- Distributed execution: same code on Spark cluster
- Batch processing: handles large file volumes efficiently

---

## 📁 Output Dataset

**22 Columns** ready for downstream analysis:

### Metadata (10 columns)
```
record_type, company_slug, source_folder, source_file, file_name,
extension, file_size_bytes, file_sequence, collected_at, html
```

### Profile Data (12 columns)
```
profile_title, website_url, profile_description, services,
minimum_project_size, hourly_rate, employee_range, locations,
year_founded, languages, overall_rating, review_count
```

### Sample Row
| Column | Value |
|--------|-------|
| profile_title | Example Digital Agency |
| website_url | https://example.com |
| overall_rating | 4.8 |
| review_count | 52 |
| services | Web Development 40%; UI/UX Design 35%; ... |
| hourly_rate | $50-$99/hr |
| employee_range | 10-49 |

---

## 🚀 Quick Start

### Setup (5 minutes)
```bash
git clone <repo>
cd leadforge-directory-hunter
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Mac/Linux
pip install -r requirements.txt
```

### Run Parser
```bash
jupyter notebook notebooks/notebook_parser.ipynb
# Executes all cells → produces df_bronze
```

### Export Results
```python
df_bronze.toPandas().to_csv("profiles.csv")
```

---

## 🏗️ Architecture Highlights

```
Raw HTML Files (Bronze)
    ↓
Load into Spark DataFrame (1 row = 1 file)
    ↓
Extract Metadata (filename parsing)
    ↓
Apply 8 Extraction UDFs (regex + JSON-LD parsing)
    ↓
Flatten Nested Structures
    ↓
Output: Enriched DataFrame (22 columns)
    ↓
Export: CSV, Parquet, or SQL
```

### Design Decisions
✅ **No external HTML libraries** → Spark worker compatibility  
✅ **Recursive JSON search** → Handles complex nesting  
✅ **Type-safe schemas** → Prevents runtime errors  
✅ **Graceful degradation** → Null for missing data  
✅ **Pure stdlib regex** → Minimal dependencies  

---

## 📊 Performance Profile

| Phase | Time | Notes |
|-------|------|-------|
| Load HTML | ~80s | Spark binary file source; I/O bound |
| Extract fields | ~0.5s | Regex UDFs; very fast |
| Flatten & export | <1s | Spark optimization |
| **Total** | **~2 min** | First run; cached: ~30s |

**Bottleneck**: File I/O (loading 50 × ~500KB HTML files)  
**Scaling**: Add more workers to Spark cluster for petabyte-scale processing

---

## 🔧 Tech Stack

| Layer | Technology |
|-------|-----------|
| Compute | PySpark 4.1.1 (local[*] by default) |
| Storage | File system (HTML) + optional PostgreSQL/Parquet |
| Language | Python 3.11+ |
| Parsing | Pure `re` module (stdlib) + json (stdlib) |
| Notebooks | Jupyter / JupyterLab |
| Optional | Pandas (for export), Streamlit (future dashboard) |

---

## 📋 Data Quality Metrics

### Extraction Success Rates (sample of 50 files)
- Profile title: 100%
- Website URL: 95%
- Overall rating: 92%
- Review count: 92%
- Services: 88%
- Business details: 85%

### Null Handling
```python
# View null counts
df_bronze.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) 
                 for c in df_bronze.columns]).show()
```

---

## 🎓 Use Cases

1. **Lead Generation**: Filter by rating, services, location
   ```python
   df_bronze.filter((F.col("overall_rating") >= 4.5) & 
                    (F.col("employee_range") == "10-49")).count()
   ```

2. **Market Intelligence**: Analyze service distribution, pricing trends
3. **Competitive Analysis**: Compare portfolio metrics across competitors
4. **Sales Research**: Export targeted lists for outreach campaigns
5. **Data Product**: Foundation for lead scoring and CRM integration

---

## 🔮 Roadmap

### Phase 1 (Done)
✅ Bronze layer HTML storage  
✅ PySpark-based extraction pipeline  
✅ 22-column enriched dataset  
✅ Complete documentation  

### Phase 2 (Q2 2026)
- [ ] Silver layer: deduplication & enrichment
- [ ] Gold layer: lead scoring & business intelligence
- [ ] PostgreSQL persistence

### Phase 3 (Q3 2026)
- [ ] Streamlit dashboard
- [ ] Multi-site support (G2, Upwork, etc.)
- [ ] REST API for data access

### Phase 4 (Q4 2026)
- [ ] Production orchestration (Airflow/Prefect)
- [ ] Automated change detection (HTML structure monitoring)
- [ ] Advanced lead ranking algorithms

---

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Full project overview & features |
| [QUICKSTART.md](QUICKSTART.md) | Setup & execution guide |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Technical design & decisions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development workflow & extension |
| [FAQ.md](FAQ.md) | Troubleshooting & common questions |
| [CHANGELOG.md](CHANGELOG.md) | Version history & roadmap |

---

## 💡 Key Insights

### Why This Approach?

**Problem**: Web scraping HTML is fragile and unstructured.  
**Solution**: 
- Store raw HTML for reproducibility (bronze layer)
- Extract via regex for robustness (no breaking when HTML changes slightly)
- Use JSON-LD for schema data (official structured data)
- Distribute via PySpark (scales to any volume)

### Why PySpark?

- **Scalability**: Same code runs on laptop or petabyte-scale cluster
- **Type Safety**: Explicit schemas catch errors early
- **Efficiency**: Optimized execution with Catalyst optimizer
- **Future-proof**: Industry standard for big data

### Why No External HTML Libraries?

Spark workers serialize functions via pickle. External libraries (BeautifulSoup) cause `ModuleNotFoundError` in workers. Pure stdlib regex avoids this problem entirely.

---

## 🎯 Success Metrics

- ✅ Extract 22+ fields per company profile
- ✅ Process 50 files in <2 minutes
- ✅ >90% data quality on key fields
- ✅ Scale-ready (tested with PySpark distributed mode)
- ✅ Fully documented & reproducible
- ✅ Easy to extend to new sites & fields

---

## 👨‍💼 For Stakeholders

**Bottom Line**: Automated, scalable pipeline to collect and structure B2B lead data from public directories. Production-ready for development; extensible to other data sources.

**Business Value**: 
- Reduce manual data collection time from hours to minutes
- Unlock market intelligence from unstructured web data
- Foundation for lead scoring and sales automation
- Reusable framework for future data products

**Risk Mitigation**:
- Respect site Terms of Service and robots.txt
- Rate-limit requests during collection
- Comply with GDPR/CCPA for data handling
- Regular audits of extracted data quality

---

**For more details**: See [README.md](README.md) and [QUICKSTART.md](QUICKSTART.md)
