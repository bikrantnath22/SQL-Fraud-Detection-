# 🛡️ SQL Bank — Fraud Detection System

A comprehensive **SQL-based fraud detection system** for banking transactions, featuring advanced analytical queries, real-time triggers, and stored procedures.

Built with pure SQL (MySQL 8.x) as a portfolio project.

---

## 🏗️ Architecture

```
SQL_Bank/
├── 📄 schema.sql                    # Database schema (4 tables)
├── 📄 seed.sql                      # 2000+ transactions + planted fraud scenarios
├── 📄 fraud_queries.sql             # Core fraud detection INSERT queries
├── 📄 trigger_fraud_check.sql       # AFTER INSERT trigger for real-time detection
├── 📄 evaluate_transaction_sp.sql   # Stored procedure for on-demand evaluation
├── 📄 view_fraud_dashboard.sql      # SQL VIEW for dashboard reporting
├── 📄 lag_velocity_query.sql        # LAG() window function approach
├── 📄 rolling_avg_anomaly.sql       # Rolling average anomaly detection
├── 📄 structuring_query.sql         # Smurfing/structuring detection
└── 📄 test_trigger.sql              # Trigger test script
```

---

## 🎯 Fraud Detection Rules

| # | Rule Name | Description | Risk Weight |
|---|-----------|-------------|:-----------:|
| 1 | **High Velocity** | 5+ transactions within a 2-minute window | 8.5 |
| 2 | **High Value Anomaly** | Transaction ≥ 10× the account's historical average | 7.0 |
| 3 | **Structuring (Smurfing)** | Multiple transactions just under ₹1,00,000 summing above the threshold in 24 hours | 9.0 |

---

## 🗃️ Database Schema

```sql
accounts              -- Customer bank accounts
  ├── account_id (PK)
  ├── customer_id
  ├── account_type     -- SAVINGS / CURRENT
  ├── opening_date
  └── avg_monthly_balance

transactions          -- All financial transactions
  ├── txn_id (PK)
  ├── account_id (FK → accounts)
  ├── amount
  ├── txn_type         -- DEBIT / CREDIT
  ├── txn_date
  ├── merchant
  └── location

fraud_rules           -- Configurable fraud detection rules
  ├── rule_id (PK)
  ├── rule_name
  ├── rule_description
  └── risk_weight

flagged_transactions  -- Transactions flagged by fraud rules
  ├── txn_id (FK → transactions)
  ├── rule_id (FK → fraud_rules)
  ├── risk_score
  └── flagged_at
```

---

## 🧠 SQL Techniques Demonstrated

- **Window Functions**: `LAG()`, `AVG() OVER()` with `ROWS BETWEEN` for rolling calculations
- **Common Table Expressions (CTEs)**: `WITH RECURSIVE` for bulk data generation, analytical CTEs
- **Self-Joins**: Rolling time-window fraud detection (2-minute and 24-hour windows)
- **Triggers**: `AFTER INSERT` trigger for real-time fraud scoring
- **Stored Procedures**: `evaluate_transaction()` with `IN`/`OUT` parameters
- **Views**: `fraud_dashboard` view for aggregated reporting
- **Upserts**: `ON DUPLICATE KEY UPDATE` for idempotent flag insertion
- **Indexing**: Strategic indexes on `account_id` and `txn_date` for query performance

---

## 🚀 Getting Started

### Prerequisites

- **MySQL 8.x** installed and running

### Set Up the Database

```bash
# Connect to MySQL
mysql -u root -p

# Create the database
CREATE DATABASE bank_fraud;
USE bank_fraud;

# Run the SQL files in order
SOURCE schema.sql;
SOURCE seed.sql;
SOURCE fraud_queries.sql;
SOURCE trigger_fraud_check.sql;
SOURCE evaluate_transaction_sp.sql;
SOURCE view_fraud_dashboard.sql;
```

---

## 🔬 Running Fraud Detection Queries

After setting up the database, you can run the detection queries directly:

```sql
-- Run all fraud detection rules
SOURCE fraud_queries.sql;

-- Check the fraud dashboard view
SELECT * FROM fraud_dashboard;

-- Evaluate a specific transaction
CALL evaluate_transaction(5, @score);
SELECT @score;

-- Test the real-time trigger
SOURCE test_trigger.sql;
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Database** | MySQL 8.x |

---

## 📝 SQL File Reference

| File | Purpose |
|------|---------|
| `schema.sql` | Creates 4 tables with proper constraints, indexes, and foreign keys |
| `seed.sql` | Generates 2000 random transactions + 3 deliberate fraud scenarios |
| `fraud_queries.sql` | Detects and flags fraud using all 3 rules |
| `trigger_fraud_check.sql` | Real-time `AFTER INSERT` trigger with composite risk scoring |
| `evaluate_transaction_sp.sql` | Stored procedure for on-demand risk evaluation |
| `view_fraud_dashboard.sql` | Aggregated dashboard view joining all tables |
| `lag_velocity_query.sql` | Alternative velocity detection using `LAG()` window function |
| `rolling_avg_anomaly.sql` | Rolling 30-transaction average anomaly detection |
| `structuring_query.sql` | Standalone smurfing detection with self-join |
| `test_trigger.sql` | Script to test the trigger with a suspicious transaction |

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
