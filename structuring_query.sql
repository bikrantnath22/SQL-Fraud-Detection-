-- Detects Structuring (Smurfing): accounts with multiple transactions each under ₹1,00,000 
-- within a rolling 24-hour window, where the sum of those transactions exceeds ₹1,00,000.
-- We use a self-join to create the 24-hour window relative to each transaction.

SELECT 
    t1.account_id,
    t1.txn_id as anchor_txn_id,
    t1.txn_date as window_start,
    MAX(t2.txn_date) as window_end,
    COUNT(t2.txn_id) as txn_count,
    SUM(t2.amount) as total_amount
FROM transactions t1
JOIN transactions t2 
  ON t1.account_id = t2.account_id 
  AND t2.txn_date >= t1.txn_date 
  AND t2.txn_date <= DATE_ADD(t1.txn_date, INTERVAL 24 HOUR)
WHERE t1.amount < 100000 
  AND t2.amount < 100000
GROUP BY t1.txn_id, t1.account_id, t1.txn_date
HAVING txn_count > 1 
   AND total_amount > 100000
ORDER BY t1.account_id, window_start;
