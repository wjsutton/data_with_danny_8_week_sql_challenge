-- A. Customer Nodes Exploration

-- 1. How many unique nodes are there on the Data Bank system?
SELECT 
COUNT(DISTINCT node_id) as unique_nodes
FROM customer_nodes;


-- 2. What is the number of nodes per region?
SELECT 
region_name,
COUNT(DISTINCT node_id) as nodes
FROM customer_nodes as C
INNER JOIN regions as R on C.region_id = R.REGION_ID
GROUP BY region_name;


-- 3. How many customers are allocated to each region?
SELECT 
region_name,
COUNT(DISTINCT customer_id) as unique_customers
FROM customer_nodes as C
INNER JOIN regions as R on C.REGION_ID = R.REGION_ID
GROUP BY region_name;


-- 4. How many days on average are customers reallocated to a different node?
WITH DAYS_IN_NODE AS (
    SELECT 
    customer_id,
    node_id,
    SUM(DATEDIFF('days',start_date,end_date)) as days_in_node
    FROM customer_nodes
    WHERE end_date <> '9999-12-31'
    GROUP BY customer_id,
    node_id
)
SELECT 
ROUND(AVG(days_in_node),0) as average_days_in_node
FROM DAYS_IN_NODE;


-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
WITH DAYS_IN_NODE AS (
    SELECT 
    region_name,
    customer_id,
    node_id,
    SUM(DATEDIFF('days',start_date,end_date)) as days_in_node
    FROM customer_nodes as C
    INNER JOIN regions as R on R.REGION_ID = C.region_id
    WHERE end_date <> '9999-12-31'
    GROUP BY region_name,
    customer_id,
    node_id
)
,ORDERED AS (
SELECT 
region_name,
days_in_node,
ROW_NUMBER() OVER(PARTITION BY region_name ORDER BY days_in_node) as rn
FROM DAYS_IN_NODE
)
,MAX_ROWS as (
SELECT 
region_name,
MAX(rn) as max_rn
FROM ORDERED
GROUP BY region_name
)

SELECT O.region_name
,CASE 
WHEN rn = ROUND(M.max_rn /2,0) THEN 'Median'
WHEN rn = ROUND(M.max_rn * 0.8,0) THEN '80th Percentile'
WHEN rn = ROUND(M.max_rn * 0.95,0) THEN '95th Percentile'
END as metric,
days_in_node as value
FROM ORDERED as O
INNER JOIN MAX_ROWS as M on M.region_name = O.region_name
WHERE rn IN (
    ROUND(M.max_rn /2,0),
    ROUND(M.max_rn * 0.8,0),
     ROUND(M.max_rn * 0.95,0)
) ;





















