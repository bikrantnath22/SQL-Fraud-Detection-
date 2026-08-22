-- Alternative approach using LAG() Window Function
-- Detects accounts with 3 or more transactions within a 2-minute window.
-- By looking back 2 rows (LAG(txn_date, 2)), we capture a sequence of 3 transactions.
-- If the time difference between the 1st and 3rd transaction is <= 120 seconds, it's flagged.

WITH LaggedTransactions AS (
    SELECT 
        txn_id,
        account_id,
        amount,
        txn_date,
        LAG(txn_date, 2) OVER (PARTITION BY account_id ORDER BY txn_date) as prev_txn_date
    FROM transactions
)
SELECT 
    account_id,
    txn_id as latest_txn_id,
    prev_txn_date as window_start,
    txn_date as window_end,
    TIMESTAMPDIFF(SECOND, prev_txn_date, txn_date) as seconds_gap
FROM LaggedTransactions
WHERE prev_txn_date IS NOT NULL 
  AND TIMESTAMPDIFF(SECOND, prev_txn_date, txn_date) <= 120;
