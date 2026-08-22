-- Insert a highly suspicious transaction for Account 4
-- Since Account 4 was seeded with random small transactions (average ~2,500), 
-- an 85,000 transaction will be > 10x its historical average, triggering the anomaly rule.

INSERT INTO transactions (account_id, amount, txn_type, txn_date, merchant, location) 
VALUES (4, 85000.00, 'DEBIT', NOW(), 'Suspicious Vendor', 'Unknown');

-- Query the dashboard to see the newly flagged transaction!
-- NOTE: If you haven't lowered the '50' threshold in the trigger we created earlier, 
-- you'll need to do that first for this to show up! (Changing it to '5' is recommended).

SELECT * FROM fraud_dashboard ORDER BY flagged_at DESC;
