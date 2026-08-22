-- Detects transactions that are more than 5x the account's rolling average.
-- The rolling average is calculated based on the previous 30 transactions for that account.

WITH RollingStats AS (
    SELECT 
        txn_id,
        account_id,
        amount,
        txn_date,
        merchant,
        AVG(amount) OVER (
            PARTITION BY account_id 
            ORDER BY txn_date 
            ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
        ) as rolling_avg
    FROM transactions
)
SELECT 
    txn_id,
    account_id,
    amount,
    rolling_avg,
    (amount / rolling_avg) as multiple_of_avg,
    txn_date,
    merchant
FROM RollingStats
WHERE rolling_avg IS NOT NULL 
  AND amount > 5 * rolling_avg
ORDER BY account_id, txn_date;
