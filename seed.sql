-- Increase recursion depth to allow generating 2000 rows
SET SESSION cte_max_recursion_depth = 10000;

-- 1. Insert 20 Accounts
INSERT INTO accounts (account_id, customer_id, account_type, opening_date, avg_monthly_balance)
WITH RECURSIVE nums AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 20
)
SELECT 
  n,
  1000 + n,
  CASE WHEN n % 2 = 0 THEN 'SAVINGS' ELSE 'CURRENT' END,
  DATE_SUB(CURRENT_DATE, INTERVAL FLOOR(RAND() * 1000) DAY),
  ROUND((RAND() * 50000) + 10000, 2)
FROM nums;

-- 2. Insert 2000 bulk random transactions (for accounts 4 to 20)
-- Spread over the last 6 months (180 days)
INSERT INTO transactions (account_id, amount, txn_type, txn_date, merchant, location)
WITH RECURSIVE txn_nums AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM txn_nums WHERE n < 2000
)
SELECT
  -- Assign random accounts from 4 to 20
  FLOOR(RAND() * 17) + 4 AS account_id,
  ROUND((RAND() * 5000) + 10, 2) AS amount,
  CASE WHEN RAND() > 0.5 THEN 'DEBIT' ELSE 'CREDIT' END AS txn_type,
  DATE_SUB(NOW(), INTERVAL (RAND() * 180 * 24 * 60 * 60) SECOND) AS txn_date,
  CONCAT('Merchant_', FLOOR(RAND() * 100)) AS merchant,
  CONCAT('City_', FLOOR(RAND() * 20)) AS location
FROM txn_nums;


-- 3. Plant deliberate fraud scenarios for specific accounts (Accounts 1, 2, and 3)

-- (a) Account 1: 5 transactions within 2 minutes of each other (High velocity/bot activity)
INSERT INTO transactions (account_id, amount, txn_type, txn_date, merchant, location) VALUES
(1, 1500.00, 'DEBIT', '2026-08-01 10:00:00', 'Online Store A', 'Mumbai'),
(1, 2000.00, 'DEBIT', '2026-08-01 10:00:30', 'Online Store B', 'Mumbai'),
(1, 1200.00, 'DEBIT', '2026-08-01 10:01:00', 'Online Store C', 'Mumbai'),
(1, 3000.00, 'DEBIT', '2026-08-01 10:01:15', 'Online Store D', 'Mumbai'),
(1, 2500.00, 'DEBIT', '2026-08-01 10:01:45', 'Online Store E', 'Mumbai');

-- Add some normal background transactions for Account 1 to make it realistic
INSERT INTO transactions (account_id, amount, txn_type, txn_date, merchant, location) VALUES
(1, 500.00, 'DEBIT', '2026-07-15 12:00:00', 'Cafe', 'Mumbai'),
(1, 100.00, 'CREDIT', '2026-07-20 09:00:00', 'Refund', 'Mumbai');


-- (b) Account 2: one transaction 10x its usual amount (Anomaly detection)
-- Normal transactions around 1,000
INSERT INTO transactions (account_id, amount, txn_type, txn_date, merchant, location) VALUES
(2, 1000.00, 'DEBIT', '2026-07-01 14:00:00', 'Grocery', 'Delhi'),
(2, 950.00, 'DEBIT', '2026-07-05 15:30:00', 'Utility', 'Delhi'),
(2, 1100.00, 'DEBIT', '2026-07-10 11:20:00', 'Supermarket', 'Delhi'),
(2, 1050.00, 'DEBIT', '2026-07-15 09:45:00', 'Pharmacy', 'Delhi'),
-- The anomaly transaction 10x the normal (~15,000)
(2, 15000.00, 'DEBIT', '2026-08-05 18:00:00', 'Luxury Goods', 'International'); 


-- (c) Account 3: 4 transactions just under ₹1,00,000 within 24 hours summing above it (Structuring / Smurfing)
-- 4 transactions just under the 1,00,000 limit, summing to well over it within a 24-hour window
INSERT INTO transactions (account_id, amount, txn_type, txn_date, merchant, location) VALUES
(3, 99500.00, 'CREDIT', '2026-08-02 10:00:00', 'Cash Deposit', 'Chennai'),
(3, 99000.00, 'CREDIT', '2026-08-02 14:30:00', 'Cash Deposit', 'Chennai'),
(3, 99800.00, 'CREDIT', '2026-08-02 18:15:00', 'Cash Deposit', 'Chennai'),
(3, 98500.00, 'CREDIT', '2026-08-03 09:00:00', 'Cash Deposit', 'Chennai'); -- All within 24 hours
