Here is the English version of the project description you provided:

-----

# 🚦 Automated Annual Air Quality Monitoring for Bandung

## 📄 Overview

This project implements an end-to-end data pipeline to monitor annual air quality (PM2.5) in Bandung. Starting with historical data from public reports as a foundation, the architecture is designed to be extensible with dynamic data sources such as APIs in the future. The primary goal is to automate long-term trend analysis to support environmental policy and empower the community with easily accessible data.

The pipeline is orchestrated by **Apache Airflow**, utilizing **Python** for data extraction into **Neon DB (PostgreSQL)**, which serves as both the staging area and data warehouse. Data transformation and aggregation are executed by **Apache Spark**, with the final results visualized on an interactive **Streamlit** dashboard. The platform is also designed to send automated notifications via Email or Telegram if pollution levels exceeding thresholds are detected.

## 🎯 Objectives

  - Consolidate annual air quality data (PM2.5) from the provided Excel files.
  - Calculate annual averages, maximum values, and detect outliers for pollution metrics.
  - Flag years with unusual pollution spikes based on threshold logic.
  - Visualize long-term trends via an interactive dashboard.
  - Automatically notify stakeholders via email or Telegram.

## 📁 Project Structure

```
bandung_airbatch/
├── data/
│   ├── Kesehatan_Udara_Bandung_2022.xlsx
│   ├── Kesehatan_Udara_Bandung_2023.xlsx
│   ├── Kesehatan_Udara_Bandung_2024.xlsx
│   └── Kesehatan_Udara_Bandung_2025.xlsx
├── dags/
│   ├── Dag_Bandung_yearly_air_quality_pipeline.py
│   ├── Python Script_extract_local_csv.py
│   └── create_table_staging_raw_air_quality.sql
├── spark_jobs/
├── streamlit_app/
│   ├── Streamlit requirements.txt
│   └── Streamlit.py
├── docker-compose.yml
├── PySpark Job_Bandung_yearly_air_quality.py
└── requirements.txt
```

## 📚 Data Sources

Currently uses datasets from Nafas Indonesia in Excel format. For future development, it will be integrated with:

  - [Databoks](https://databoks.katadata.co.id/layanan-konsumen-kesehatan/statistik/3b72788adeb2920/kualitas-udara-di-kota-besar-indonesia-buruk-jauh-dari-standar-who)
  - BMKG API – archived daily JSON data
  - data.go.id – downloadable CSV/JSON datasets
  - Nafas Indonesia – sensor reports in PDF/Excel format
  - IQAir Bandung – scraped AQI and pollutant archive

## ✨ Features

  - 🌐 **Automated Data Extraction**: Automatically reads Excel files with potential expansion to APIs and web scraping.
  - 🗄️ **Data Storage**: PostgreSQL staging and partitioned warehouse for fast querying.
  - ⚡ **Batch Processing**: Spark jobs to calculate annual statistics.
  - 📊 **Interactive Dashboard**: Streamlit dashboard with filters and visualizations.
  - 🔔 **Alert System**: Automated notifications via Telegram/email when pollution exceeds thresholds.
  - 🔁 **Orchestration**: Automated scheduling with Apache Airflow.
  - 🐳 **Containerization**: Docker Compose for easy deployment.

## 🛠️ Tech Stack

| Component | Tool |
|-----------|------|
| **Orchestration** | Apache Airflow |
| **Extraction & ETL** | Python (requests, pandas, tabula-py) |
| **Batch Processing** | Apache Spark |
| **Data Storage** | PostgreSQL (Neon DB) |
| **Visualization** | Streamlit |
| **Alerting** | SMTP, Telegram Bot |
| **Containerization** | Docker, Docker Compose |

## 🔄 Pipeline Overview

```
[1. Data Source]
    (Excel Files)
         ↓
[2. Data Extraction] ——— (Orchestrated by Apache Airflow)
    (Python Script)
         ↓
[3. Staging Area]
    (Neon DB PostgreSQL)
         ↓
[4. Data Transformation] ——— (Orchestrated by Apache Airflow)
    (Apache Spark)
         ↓
[5. Data Warehouse]
    (Neon DB PostgreSQL)
         ↓
[6. Visualization & Actions]
    (Streamlit Dashboard)
```

### Workflow Detail

#### 1\. ETL (Airflow DAG yearly\_air\_quality\_pipeline)

  - **Extract**: Reads data from the provided annual Excel files.
  - **Load (Staging)**: Saves raw data to the `staging.raw_air_quality` table in PostgreSQL.

#### 2\. Analytics Generation (Spark Job)

  - **Transform**: Reads data from staging, validates schema, and performs basic transformations.
  - **Load (Warehouse)**: Saves the processed, mature data to the `warehouse.fact_yearly_air_quality` table.

#### 3\. Visualization (Streamlit)

  - **Query**: The Streamlit application queries directly from the warehouse table in PostgreSQL.
  - **Display**: Displays annual air quality trends in the form of bar charts and interactive tables.

## 🚀 Quick Start

### Prerequisites

  - Docker & Docker Compose
  - Git

### Setup

1.  **Clone repository**

<!-- end list -->

```bash
git clone <repository-url>
cd bandung_airbatch
```

2.  **Setup environment**

<!-- end list -->

```bash
docker-compose up -d
```

3.  **Access services**
      - **Airflow**: http://localhost:8080
      - **Streamlit**: http://localhost:8501

### Database Connection

```bash
psql 'postgresql://neondb_owner:npg_odbj5JHY0pwO@ep-cold-grass-a18xlnz0-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require'
```

## ⚠️ Current Limitations

  - Dataset is static; does not yet support incremental load or streaming.
  - Not all fields (such as transaction dates) are processed as time-series (current focus is on annual aggregation).
  - Not yet connected to other BI tools like Looker/Power BI.
  - The data extraction process still relies on semi-manually prepared Excel files.
  - The platform only runs in batch mode (annual), suitable for historical analysis but not for real-time monitoring.

## 🔮 Future Development Plans

  - **Time Dimension Enhancement**: Add monthly or daily analytics for more granular trend analysis.
  - **Automated Reporting**: Scheduler for automated PNG export from the dashboard.
  - **API Integration**: Data synchronization from external APIs (BMKG, OpenAQ) for full automation.
  - **Real-time Processing**: Implementation of streaming using Apache Kafka and Spark Streaming.
  - **Advanced Analytics**: Predictive analysis (forecasting) and correlation with weather or traffic data.
  - **BI Tools Integration**: Connection to Looker, Power BI, or other enterprise visualization tools.

## 👤 Author

**Rafli Firmansyah**
This project was built for educational purposes and portfolio development in the field of data engineering.

## 📝 License

This project is intended for educational and portfolio use.

## 📞 Support

If you have any questions or development suggestions, please create an issue or contact the author.

-----

> **Note**: This project is still under development and will continue to be refined with additional features.
