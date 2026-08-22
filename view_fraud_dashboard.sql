-- Creates a dashboard view for easy monitoring of flagged fraud events

CREATE OR REPLACE VIEW fraud_dashboard AS
SELECT 
    a.account_id, 
    a.customer_id, 
    fr.rule_name, 
    ft.risk_score, 
    ft.flagged_at
FROM flagged_transactions ft
JOIN transactions t ON ft.txn_id = t.txn_id
JOIN accounts a ON t.account_id = a.account_id
JOIN fraud_rules fr ON ft.rule_id = fr.rule_id
ORDER BY ft.risk_score DESC;
