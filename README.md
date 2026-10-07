# 🏛️ SQL Data Warehouse Project

![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Medallion-orange)
![Model](https://img.shields.io/badge/Model-Star%20Schema-blue)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

> A SQL Server data warehouse that turns messy CRM and ERP sales data into clean, analysis-ready tables, using a Bronze → Silver → Gold pipeline.

---

## 📌 Problem Statement

Sales, customer and product data lived in **two separate systems (CRM and ERP)** as 6 CSV files, with duplicate records, inconsistent codes, invalid dates and mismatched sales values. Reporting on this data wasn't reliable. The goal was to build **one clean, trusted data model** for sales analysis.

---

## 🏗️ Architecture

![Data Architecture](docs/data_architecture.png)

| Layer | Purpose | How |
|---|---|---|
| 🥉 **Bronze** | Raw data, exactly as received | `BULK INSERT` via stored procedure |
| 🥈 **Silver** | Cleaned and standardised data | Transformations in stored procedure |
| 🥇 **Gold** | Business-ready star schema | SQL views |

---

## 📊 At a Glance

| | |
|---|---|
| Source systems | 2 (CRM and ERP) |
| Source files | 6 CSVs, about 116K rows |
| Tables per layer | 6 Bronze, 6 Silver |
| Gold model | 1 fact and 2 dimensions |
| Quality test scripts | 2 (Silver and Gold) |

---

## 🧹 Data Cleaning Done in Silver

| Issue Found | Fix |
|---|---|
| Duplicate customer records | Kept the latest record using `ROW_NUMBER()` |
| Extra spaces in names | `TRIM()` |
| Short codes (M/F, S/M, R/M/T) | Mapped to readable labels |
| Invalid dates | Validated and converted to `DATE` |
| Wrong sales or price values | Recalculated from quantity and price |
| Missing product end dates | Derived with `LEAD()` |

---

## ⭐ Data Model (Gold Layer)

![Data Model](docs/data_model.png)

- `gold.dim_customers` – customer details from CRM and ERP combined
- `gold.dim_products` – product, category and cost details
- `gold.fact_sales` – orders linked to customers and products

---

## ✅ Data Quality Checks

Test scripts in `tests/` verify that:
- There are no duplicate or NULL primary keys
- There are no unwanted spaces or invalid dates
- Order dates never come after ship or due dates
- Sales = Quantity × Price
- Gold surrogate keys join correctly

---

## 🔍 Sample Query

```sql
-- Top 5 products by sales
SELECT TOP 5
    p.product_name,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_sales DESC;
```

---

## 📁 Repository Structure

```
├── datasets/   # Source CRM & ERP files
├── docs/       # Architecture, data model, data catalog, naming conventions
├── scripts/    # Bronze, Silver, Gold SQL scripts
└── tests/      # Data quality checks
```

📚 More docs: [Data Catalog](docs/data_catalog.md) · [Naming Conventions](docs/naming_conventions.md)

---

## 🗒️ Notes & Next Steps

- Covers the latest data snapshot only; historical tracking is not implemented
- Next: SQL analysis (customer behaviour, product performance, sales trends) and a Power BI dashboard on the Gold layer

---

## 👤 About Me

**Ashish** · Software Engineer moving into Data Analytics · Pune, India
[LinkedIn](#) · [GitHub](#)
