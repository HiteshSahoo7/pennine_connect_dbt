# Pennine Connect – Analytics Engineering Assessment

## Project Overview

This repository contains my solution for the **Pennine Connect Analytics Engineering Assessment**.

The objective was to build a production-oriented analytics solution capable of:

- Building a clean monthly subscription fact table
- Resolving data quality issues
- Classifying subscription lifecycle states
- Defining a business-appropriate annualised churn metric
- Identifying leading indicators of customer churn
- Producing executive-ready insights and recommendations

The solution follows modern Analytics Engineering principles using **Snowflake**, **dbt**, and the **Medallion Architecture**.

---

# Architecture

```
CSV Files
      │
      ▼
Azure Data Factory
      │
      ▼
Snowflake
RAW
      │
      ▼
dbt Staging
      │
      ▼
dbt Intermediate
      │
      ▼
dbt Mart
      │
      ▼
Power BI / Executive Reporting
```

---

# Technology Stack

| Component | Technology |
|-----------|------------|
| Data Ingestion | Azure Data Factory |
| Data Warehouse | Snowflake |
| Data Transformation | dbt |
| Version Control | Git & GitHub |
| Reporting | Power BI Desktop |
| Language | SQL |

---

# Project Structure

```
pennine_connect_dbt
│
├── pennine_connect_analytics
│   │
│   ├── models
│   │     ├── staging
│   │     ├── intermediate
│   │     └── marts
│   │
│   ├── macros
│   ├── tests
│   ├── snapshots
│   └── analyses
│
├── presentation
│
└── README.md
```

---

# Data Pipeline

```
Raw CSV Data
        │
        ▼
ADF Ingestion
        │
        ▼
Snowflake RAW Layer
        │
        ▼
dbt Staging Models
        │
        ▼
Business Rules
        │
        ▼
Intermediate Models
        │
        ▼
Fact Tables
        │
        ▼
Analytics & Dashboard
```

---

# Part A – Data Modelling

### Data Quality Validation

Performed comprehensive data quality checks across all datasets including:

- Duplicate detection
- Null validation
- Date range validation
- Business rule validation
- Referential integrity checks
- Status consistency validation

---

### Subscription Lifecycle Classification

Implemented a rule-based lifecycle engine to classify subscriptions into:

- Active
- Voluntary Cancellation
- Reactivation
- Cancelled Before Go Live
- Fraud
- Pending Activation

Special attention was given to lifecycle precedence to ensure mutually exclusive classifications.

---

### Monthly Subscription Fact

Built a monthly subscription fact table with grain:

> **One row per Active Subscription per Month**

Key attributes include:

- Subscription
- Customer
- Activity Month
- Product
- Plan
- Lifecycle State
- Monthly Recurring Revenue (MRR)

---

# Part B – Churn Analytics

### Annualised Churn

Implemented an annualised churn metric based on:

- Active subscriptions at the beginning of each month
- Voluntary cancellations only
- Compounded annualisation formula

Business rules:

| Scenario | Treatment |
|-----------|------------|
| Voluntary Cancellation | Included |
| Early-life Churn | Included (reported separately) |
| Fraud | Excluded |
| Cancelled Before Go Live | Excluded |
| Reactivation | Included in active population |

---

### Leading Indicator Analysis

Evaluated six independent hypotheses using a common 60-day observation window.

Signals Tested:

- Support Complaints
- Portal Support Ticket Events
- Technical Faults
- Usage Decline
- Billing Delinquency
- High Concurrent Usage

### Key Finding

The strongest leading indicator was:

> **Unpaid / Part-Paid Billing Status**

Customers with billing issues were approximately **1.65× more likely to churn within the following 60 days** compared with customers without payment issues.

---

# Executive Recommendations

- Prioritise proactive retention campaigns for customers with unpaid or partially paid invoices.
- Introduce a customer risk score combining billing health with behavioural signals.
- Continue monitoring onboarding quality and early-life churn.
- Expand the model with additional behavioural features as more historical data becomes available.

---

# Engineering Practices

Implemented following Analytics Engineering best practices:

- Medallion Architecture
- Modular dbt models
- Layered transformations
- Reusable SQL
- Business rule documentation
- Data quality validation
- Git version control
- Executive-ready documentation

---

# Future Enhancements

Potential improvements include:

- Automated orchestration using Azure Data Factory
- dbt tests and source freshness checks
- Incremental model optimisation
- CI/CD deployment using GitHub Actions
- dbt documentation hosting
- Predictive churn model using Machine Learning
- Power BI executive dashboard

---

# Repository Contents

- dbt Project
- SQL Models
- Data Quality Analysis
- Executive Presentation
- Documentation

---

# About

This project was completed as part of the Pennine Connect Analytics Engineering technical assessment using a synthetic dataset provided by the company.
