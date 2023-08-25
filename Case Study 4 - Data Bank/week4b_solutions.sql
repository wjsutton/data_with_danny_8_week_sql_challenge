-- B. Customer Transactions

-- 1. What is the unique count and total amount for each transaction type?
SELECT 
txn_type,
SUM(txn_amount) as total_amount,
COUNT(*) as transcation_count
FROM customer_transactions
GROUP BY txn_type;


-- 2. What is the average total historical deposit counts and amounts for all customers
WITH CTE AS (
SELECT 
customer_id,
AVG(txn_amount) as avg_deposit,
COUNT(*) as transaction_count
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)
SELECT 
ROUND(AVG(avg_deposit),2) as avg_deposit_amount,
ROUND(AVG(transaction_count),0) as avg_transactions
FROM CTE;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH CTE AS (
SELECT 
DATE_TRUNC('month',txn_date) as month,
customer_id,
SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) as deposits,
SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) as purchase_or_withdrawal
FROM customer_transactions
GROUP BY DATE_TRUNC('month',txn_date),
customer_id
HAVING SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) > 1
AND SUM(CASE WHEN txn_type <> 'deposit' THEN 1 ELSE 0 END) = 1
)
SELECT 
month,
COUNT(customer_id) as customers
FROM CTE
GROUP BY month;


-- 4. What is the closing balance for each customer at the end of the month?
WITH CTE AS (
SELECT 
DATE_TRUNC('month',txn_date) as txn_month,
txn_date,
customer_id,
SUM((CASE WHEN txn_type ='deposit' THEN txn_amount ELSE 0 END) - (CASE WHEN txn_type <>'deposit' THEN txn_amount ELSE 0 END)) as balance
FROM customer_transactions
GROUP BY DATE_TRUNC('month',txn_date),
txn_date,
customer_id
)
, BALANCES AS (
SELECT 
*
,SUM(balance) OVER (PARTITION BY customer_id ORDER BY txn_date) as running_sum
,ROW_NUMBER() OVER (PARTITION BY customer_id, txn_month ORDER BY txn_date DESC) as rn
FROM CTE
ORDER BY txn_date
)
SELECT 
customer_id,
DATEADD('day',-1,DATEADD('month',1,txn_month)) as end_of_month,
running_sum as closing_balance
FROM BALANCES 
WHERE rn = 1;


-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH CTE AS (
SELECT 
DATE_TRUNC('month',txn_date) as txn_month,
txn_date,
customer_id,
SUM((CASE WHEN txn_type ='deposit' THEN txn_amount ELSE 0 END) - (CASE WHEN txn_type <>'deposit' THEN txn_amount ELSE 0 END)) as balance
FROM customer_transactions
GROUP BY DATE_TRUNC('month',txn_date),
txn_date,
customer_id
)
, BALANCES AS (
SELECT 
*
,SUM(balance) OVER (PARTITION BY customer_id ORDER BY txn_date) as running_sum
,ROW_NUMBER() OVER (PARTITION BY customer_id, txn_month ORDER BY txn_date DESC) as rn
FROM CTE
ORDER BY txn_date
)
,CLOSING_BALANCES AS (
SELECT 
customer_id,
DATEADD('day',-1,DATEADD('month',1,txn_month)) as end_of_month,
DATEADD('day',-1,txn_month) as previous_end_of_month,
running_sum as closing_balance
FROM BALANCES 
WHERE rn = 1
ORDER BY end_of_month
)
,PERCENT_INCREASE AS (
SELECT 
CB1.customer_id,
CB1.end_of_month,
CB1.closing_balance,
CB2.closing_balance as next_month_closing_balance,
(CB2.closing_balance / CB1.closing_balance) -1 as percentage_increase,
CASE WHEN (CB2.closing_balance > CB1.closing_balance AND 
(CB2.closing_balance / CB1.closing_balance) -1 > 0.05) THEN 1 ELSE 0 END as percentage_increase_flag
FROM CLOSING_BALANCES as CB1
INNER JOIN CLOSING_BALANCES as CB2 on CB1.end_of_month = CB2.previous_end_of_month 
AND CB1.customer_id = CB2.customer_id
WHERE CB1.closing_balance <> 0
)

SELECT 
SUM(percentage_increase_flag) / COUNT(percentage_increase_flag) as percentage_of_customers_increasing_balance
FROM PERCENT_INCREASE;
