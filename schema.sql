-- Create accounts table
CREATE TABLE accounts (
    account_id BIGINT AUTO_INCREMENT,
    customer_id BIGINT NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    opening_date DATE NOT NULL,
    avg_monthly_balance DECIMAL(15, 2) DEFAULT 0.00,
    PRIMARY KEY (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Create transactions table
CREATE TABLE transactions (
    txn_id BIGINT AUTO_INCREMENT,
    account_id BIGINT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    txn_type VARCHAR(50) NOT NULL,
    txn_date DATETIME NOT NULL,
    merchant VARCHAR(255),
    location VARCHAR(255),
    PRIMARY KEY (txn_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE,
    INDEX idx_account_id (account_id),
    INDEX idx_txn_date (txn_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Create fraud_rules table
CREATE TABLE fraud_rules (
    rule_id INT AUTO_INCREMENT,
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    risk_weight DECIMAL(5, 2) NOT NULL,
    PRIMARY KEY (rule_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Create flagged_transactions table
CREATE TABLE flagged_transactions (
    txn_id BIGINT NOT NULL,
    rule_id INT NOT NULL,
    risk_score DECIMAL(5, 2) NOT NULL,
    flagged_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (txn_id, rule_id),
    FOREIGN KEY (txn_id) REFERENCES transactions(txn_id) ON DELETE CASCADE,
    FOREIGN KEY (rule_id) REFERENCES fraud_rules(rule_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
