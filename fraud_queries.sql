-- 1. Setup the Fraud Rules in the reference table
INSERT INTO fraud_rules (rule_name, rule_description, risk_weight) VALUES
('High Velocity', '5 or more transactions within 2 minutes', 8.5),
('High Value Anomaly', 'Transaction amount is 10x the account historical average', 7.0),
('Structuring (Smurfing)', 'Multiple transactions just under threshold summing to large amount in 24 hours', 9.0);

-- 2. Detect and Flag High Velocity Transactions (Account 1 scenario)
-- Looks for a 2-minute rolling window starting from each transaction
INSERT INTO flagged_transactions (txn_id, rule_id, risk_score)
SELECT 
    t1.txn_id,
    1 AS rule_id, -- Rule 1: High Velocity
    8.5 AS risk_score
FROM transactions t1
JOIN transactions t2 
  ON t1.account_id = t2.account_id 
  AND t2.txn_date >= t1.txn_date 
  AND t2.txn_date <= DATE_ADD(t1.txn_date, INTERVAL 2 MINUTE)
GROUP BY t1.txn_id, t1.account_id, t1.txn_date
HAVING COUNT(t2.txn_id) >= 5
ON DUPLICATE KEY UPDATE risk_score = VALUES(risk_score);


-- 3. Detect and Flag High Value Anomalies (Account 2 scenario)
-- Compares individual transaction amount to the account's historical average
INSERT INTO flagged_transactions (txn_id, rule_id, risk_score)
WITH RollingStats AS (
    SELECT 
        txn_id,
        account_id,
        amount,
        AVG(amount) OVER (
            PARTITION BY account_id 
            ORDER BY txn_date 
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) as avg_amount
    FROM transactions
)
SELECT 
    txn_id, 
    2 AS rule_id, -- Rule 2: High Value Anomaly
    7.0 AS risk_score
FROM RollingStats
WHERE avg_amount IS NOT NULL 
  AND amount >= 10 * avg_amount
ON DUPLICATE KEY UPDATE risk_score = VALUES(risk_score);


-- 4. Detect and Flag Structuring / Smurfing (Account 3 scenario)
-- Looks for 4+ transactions under the reporting threshold (e.g. 1,00,000) 
-- that sum to more than the threshold within a 24-hour window
INSERT INTO flagged_transactions (txn_id, rule_id, risk_score)
SELECT 
    t1.txn_id,
    3 AS rule_id, -- Rule 3: Structuring
    9.0 AS risk_score
FROM transactions t1
JOIN transactions t2 
  ON t1.account_id = t2.account_id 
  AND t2.txn_date >= t1.txn_date 
  AND t2.txn_date <= DATE_ADD(t1.txn_date, INTERVAL 24 HOUR)
WHERE t1.amount < 100000 
  AND t2.amount < 100000
GROUP BY t1.txn_id, t1.account_id, t1.txn_date
HAVING SUM(t2.amount) > 100000 AND COUNT(t2.txn_id) >= 4
ON DUPLICATE KEY UPDATE risk_score = VALUES(risk_score);


-- 5. View the resulting flagged transactions
SELECT 
    f.flagged_at,
    a.account_id,
    r.rule_name,
    t.amount,
    t.txn_date,
    f.risk_score
FROM flagged_transactions f
JOIN transactions t ON f.txn_id = t.txn_id
JOIN accounts a ON t.account_id = a.account_id
JOIN fraud_rules r ON f.rule_id = r.rule_id
ORDER BY a.account_id, t.txn_date;
