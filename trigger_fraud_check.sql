-- MySQL AFTER INSERT Trigger for Real-Time Fraud Detection

DELIMITER //

DROP TRIGGER IF EXISTS after_transaction_insert //

CREATE TRIGGER after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_risk_score DECIMAL(5,2) DEFAULT 0;
    
    DECLARE v_velocity_count INT;
    DECLARE v_avg_amount DECIMAL(15,2);
    DECLARE v_structuring_sum DECIMAL(15,2);
    DECLARE v_structuring_count INT;
    
    DECLARE v_rule1_weight DECIMAL(5,2);
    DECLARE v_rule2_weight DECIMAL(5,2);
    DECLARE v_rule3_weight DECIMAL(5,2);

  
    -- 1. Calculate Total Risk Score
    

    -- Rule 1: High Velocity
    SELECT COUNT(*) INTO v_velocity_count
    FROM transactions
    WHERE account_id = NEW.account_id
      AND txn_date BETWEEN DATE_SUB(NEW.txn_date, INTERVAL 2 MINUTE) AND NEW.txn_date;
      
    IF v_velocity_count >= 5 THEN
        SELECT risk_weight INTO v_rule1_weight FROM fraud_rules WHERE rule_name = 'High Velocity' LIMIT 1;
        SET v_risk_score = v_risk_score + IFNULL(v_rule1_weight, 0);
    END IF;

    -- Rule 2: High Value Anomaly
    SELECT AVG(amount) INTO v_avg_amount
    FROM transactions
    WHERE account_id = NEW.account_id AND txn_id != NEW.txn_id;
    
    IF v_avg_amount IS NOT NULL AND NEW.amount >= 10 * v_avg_amount THEN
        SELECT risk_weight INTO v_rule2_weight FROM fraud_rules WHERE rule_name = 'High Value Anomaly' LIMIT 1;
        SET v_risk_score = v_risk_score + IFNULL(v_rule2_weight, 0);
    END IF;

    -- Rule 3: Structuring / Smurfing
    IF NEW.amount < 100000 THEN
        SELECT SUM(amount), COUNT(*) 
        INTO v_structuring_sum, v_structuring_count
        FROM transactions
        WHERE account_id = NEW.account_id
          AND amount < 100000
          AND txn_date BETWEEN DATE_SUB(NEW.txn_date, INTERVAL 24 HOUR) AND NEW.txn_date;
          
        IF v_structuring_sum > 100000 AND v_structuring_count > 1 THEN
            SELECT risk_weight INTO v_rule3_weight FROM fraud_rules WHERE rule_name = 'Structuring (Smurfing)' LIMIT 1;
            SET v_risk_score = v_risk_score + IFNULL(v_rule3_weight, 0);
        END IF;
    END IF;

   
    -- 2. Insert into flagged_transactions if threshold exceeded

    -- NOTE: Threshold is 50 as requested. However, since the weights are (8.5, 7.0, 9.0), 
    -- the maximum score is 24.5. You will need to either lower this threshold (e.g. 15.0) 
    -- or increase the weights in the fraud_rules table for this to trigger.

    IF v_risk_score > 50 THEN
        -- Insert a record for each rule that contributed to the score
        -- to satisfy the (txn_id, rule_id) Primary Key and Foreign Key constraints
        
        IF v_velocity_count >= 5 THEN
            INSERT INTO flagged_transactions (txn_id, rule_id, risk_score)
            SELECT NEW.txn_id, rule_id, v_risk_score FROM fraud_rules WHERE rule_name = 'High Velocity' LIMIT 1;
        END IF;
        
        IF v_avg_amount IS NOT NULL AND NEW.amount >= 10 * v_avg_amount THEN
            INSERT INTO flagged_transactions (txn_id, rule_id, risk_score)
            SELECT NEW.txn_id, rule_id, v_risk_score FROM fraud_rules WHERE rule_name = 'High Value Anomaly' LIMIT 1;
        END IF;
        
        IF NEW.amount < 100000 AND v_structuring_sum > 100000 AND v_structuring_count > 1 THEN
            INSERT INTO flagged_transactions (txn_id, rule_id, risk_score)
            SELECT NEW.txn_id, rule_id, v_risk_score FROM fraud_rules WHERE rule_name = 'Structuring (Smurfing)' LIMIT 1;
        END IF;
        
    END IF;

END //

DELIMITER ;
