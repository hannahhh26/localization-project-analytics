# Localization Operations Analytics

**Python • SQL • SQLite • pandas • matplotlib • pytest • Jupyter Notebook • Git**

An end-to-end analytics project for a fictional Localization Service Provider (LSP), using synthetic operational data, SQLite, SQL, Python, and data visualisation.

> **Note:** All data is synthetically generated for portfolio purposes and does not represent any real clients or business operations.

## Overview

Rather than analysing an existing public dataset, this project simulates a real localization business using synthetic data.

The project covers the full analytics workflow:

* Designing a relational database
* Generating realistic synthetic business data
* Writing business-focused SQL queries
* Analysing results with Python and pandas
* Creating visualisations to communicate operational insights
* Validating the dataset with automated tests

---

## Key Business Questions

The analysis focuses on answering questions such as:

### Project Performance

* Which projects are overdue?
* What is the average turnaround time by project type and client?
* Which project types require the most effort?

### Clients

* Which clients generate the most work?

### Translator Performance

* Which translators achieve the highest QA scores?
* Which languages have insufficient translator coverage?

---

## Database Schema

![ER Diagram](images\er_diagram.png)

The database is normalised to reduce data duplication and models clients, projects, translators, locales, project assignments, and QA results using primary and foreign key relationships.

---

## Sample Analysis

### Average Turnaround by Project Type

![Average Turnaround by Project Type](images\avg_turnaround_project_type.png)

Documentation projects have the longest average turnaround time, while subtitle projects are completed the quickest.

---

### Project Type Distribution of Top Clients

![Project Type Distribution by Client](images\project_type_distribution_of_top_clients.png)

Comparing project type distribution across the highest-volume clients highlights differences in the mix of localisation work requested by each client.

---

### Top 10 High-Volume Translators by QA Pass Rate

![High-Volume Translators by QA Pass Rate](images\high_volume_high_quality_translators.png)

This analysis highlights translators who combine high output with strong QA performance, helping identify reliable contributors who deliver quality work at scale.

---

## Running the Project

Clone the repository

```bash
git clone https://github.com/<your-username>/localization-project-analytics.git
cd localization-project-analytics
```

Create a virtual environment

```bash
python -m venv .venv
```

Activate it

**Windows**

```bash
.venv\Scripts\activate
```

**macOS / Linux**

```bash
source .venv/bin/activate
```

Install dependencies

```bash
pip install -r requirements.txt
```

Create the SQLite database

```bash
python src/database/import_csv.py
```

Launch Jupyter

```bash
jupyter lab
```

---

## Future Improvements

* Interactive Power BI dashboard
* Streamlit web application
* Docker support
* Additional financial and operational metrics