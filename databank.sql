SELECT *
FROM customer_nodes;

SELECT *
FROM customer_transactions;

SELECT *
FROM regions;

-- How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT(node_id)) AS num_of_nodes
FROM customer_nodes;

-- What is the number of nodes per region?
SELECT R.region_name,COUNT(CN.node_id) AS num_of_nodes
FROM customer_nodes AS CN
JOIN regions AS R
ON CN.region_id = R.region_id
GROUP BY R.region_name
ORDER BY COUNT(CN.node_id) DESC;

-- How many customers are allocated to each region?
SELECT R.region_name,
COUNT(DISTINCT CN.customer_id) AS num_of_customers
FROM customer_nodes AS CN
JOIN regions AS R
ON CN.region_id = R.region_id
GROUP BY R.region_name
ORDER BY COUNT(DISTINCT CN.customer_id)DESC;

-- How many days on average are customers reallocated to a different node?
SELECT AVG(DATEDIFF(end_date,start_date)) AS avg_num_days
FROM customer_nodes
WHERE end_date <> '9999-12-31';

ALTER TABLE customer_nodes
DROP COLUMN number_of_day;
    
-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- What is the unique count and total amount for each transaction type? 
SELECT  txn_type,
        COUNT(*) AS unique_count,
        SUM(txn_amount) as tax_amt
FROM customer_transactions
GROUP  BY txn_type
ORDER BY SUM(txn_amount) DESC;

-- What is the average total historical deposit counts and amounts for all customers
WITH deposit_summary AS 
(
           SELECT customer_id,
	       txn_type,
	       COUNT(*) AS deposit_count,
	       SUM(txn_amount) AS deposit_amount
	FROM customer_transactions
	GROUP BY customer_id, txn_type
    )
    SELECT txn_type,
       AVG(deposit_count) AS avg_deposit_count,
       AVG(deposit_amount) AS avg_deposit_amount
FROM deposit_summary
WHERE txn_type = 'deposit'
GROUP BY txn_type;

-- For each month - how many Data Bank customers make more than 1 deposit and 
-- either 1 purchase or 1 withdrawal in a single month?
WITH customer_activity AS
(
	SELECT customer_id,
	       MONTH(txn_date) AS month_id,
           MONTHNAME(txn_date) AS month_name,
	       COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
	       COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
	       COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
FROM customer_transactions
GROUP BY customer_id, MONTH (txn_date), MONTHNAME(txn_date)
)
SELECT month_id,	
       month_name,
       COUNT(DISTINCT customer_id) AS active_customer_count
FROM customer_activity
WHERE deposit_count > 1
      AND (purchase_count > 0 OR withdrawal_count > 0)
GROUP BY month_id, month_name;

-- What is the closing balance for each customer at the end of the month?
WITH balance AS (
    SELECT
        customer_id,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS deposit_amt,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) AS withdrawal_amt
    FROM
        customer_transactions
    GROUP BY
        customer_id
)
SELECT
    customer_id,
    (deposit_amt - withdrawal_amt) AS closing_balance
FROM
    balance
    
ORDER BY closing_balance DESC;
    
-- What is the percentage of customers who increase their closing balance by more than 5%?
WITH balance AS (
    SELECT
        customer_id,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) AS deposit_amt,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN txn_amount ELSE 0 END) AS withdrawal_amt
    FROM
        customer_transactions
    GROUP BY
        customer_id
)
SELECT
    COUNT(*) AS num_customers_with_increase,
    (SELECT COUNT(*) FROM balance) AS total_customers,
    COUNT(*) / (SELECT COUNT(*) FROM balance) * 100 AS percentage_increase
FROM
    balance
WHERE
    (deposit_amt - withdrawal_amt) / withdrawal_amt > 0.05;
    
      
       
      


