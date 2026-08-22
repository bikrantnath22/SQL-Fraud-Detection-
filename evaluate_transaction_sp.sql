-- Stored Procedure: evaluate_transaction
-- Evaluates a single transaction against the 3 fraud rules.
-- Sums up the risk weights for any triggered rules and returns the total score.

DELIMITER //

DROP PROCEDURE IF EXISTS evaluate_transaction //

-- Note: Changed the OUT parameter to DECIMAL(5,2) to properly match 
-- the risk_weight column in fraud_rules and risk_score in flagged_transactions.
CREATE PROCEDURE evaluate_transaction(IN p_txn_id BIGINT, OUT p_risk_score DECIMAL(5,2))
sp_lbl: BEGIN
    DECLARE v_account_id BIGINT;
    DECLARE v_amount DECIMAL(15,2);
    DECLARE v_txn_date DATETIME;
    
    DECLARE v_velocity_count INT;
    DECLARE v_avg_amount DECIMAL(15,2);
    DECLARE v_structuring_sum DECIMAL(15,2);
    DECLARE v_structuring_count INT;
    
    DECLARE v_rule_weight DECIMAL(5,2);

    -- Initialize OUT parameter
    SET p_risk_score = 0;

    -- 1. Fetch the transaction details
    SELECT account_id, amount, txn_date 
    INTO v_account_id, v_amount, v_txn_date
    FROM transactions
    WHERE txn_id = p_txn_id;

    -- Exit if transaction doesn't exist
    IF v_account_id IS NULL THEN
        LEAVE sp_lbl;
    END IF;

    -- 2. Rule 1: High Velocity Check (5+ txns within 2 minutes leading up to this txn)
    SELECT COUNT(*) INTO v_velocity_count
    FROM transactions
    WHERE account_id = v_account_id
      AND txn_date BETWEEN DATE_SUB(v_txn_date, INTERVAL 2 MINUTE) AND v_txn_date;
      
    IF v_velocity_count >= 5 THEN
        SELECT risk_weight INTO v_rule_weight FROM fraud_rules WHERE rule_name = 'High Velocity' LIMIT 1;
        SET p_risk_score = p_risk_score + IFNULL(v_rule_weight, 0);
    END IF;

    -- 3. Rule 2: High Value Anomaly (10x historical average, excluding current)
    SELECT AVG(amount) INTO v_avg_amount
    FROM transactions
    WHERE account_id = v_account_id AND txn_id != p_txn_id;
    
    IF v_avg_amount IS NOT NULL AND v_amount >= 10 * v_avg_amount THEN
        SELECT risk_weight INTO v_rule_weight FROM fraud_rules WHERE rule_name = 'High Value Anomaly' LIMIT 1;
        SET p_risk_score = p_risk_score + IFNULL(v_rule_weight, 0);
    END IF;

    -- 4. Rule 3: Structuring / Smurfing (Under 100k, sum > 100k in 24 hours leading up to this txn)
    IF v_amount < 100000 THEN
        SELECT SUM(amount), COUNT(*) 
        INTO v_structuring_sum, v_structuring_count
        FROM transactions
        WHERE account_id = v_account_id
          AND amount < 100000
          AND txn_date BETWEEN DATE_SUB(v_txn_date, INTERVAL 24 HOUR) AND v_txn_date;
          
        IF v_structuring_sum > 100000 AND v_structuring_count > 1 THEN
            SELECT risk_weight INTO v_rule_weight FROM fraud_rules WHERE rule_name = 'Structuring (Smurfing)' LIMIT 1;
            SET p_risk_score = p_risk_score + IFNULL(v_rule_weight, 0);
        END IF;
    END IF;

    -- (Optional extension) Insert into flagged_transactions if the score is greater than 0
    -- IF p_risk_score > 0 THEN
    --    INSERT INTO flagged_transactions (txn_id, rule_id, risk_score) VALUES ...
    -- END IF;

END //

DELIMITER ;

-- ==========================================
-- Example Usage:
-- ==========================================
-- CALL evaluate_transaction(5, @total_score);
-- SELECT @total_score;
