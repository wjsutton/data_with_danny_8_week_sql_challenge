-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions 
-- table, write a brief description about each customer’s onboarding journey.

-- Try to keep it as short as possible - you may also want to run 
-- some sort of join to make your explanations a bit easier!

SELECT 
customer_id,
plan_name,
price,
start_date
FROM subscriptions as S
INNER JOIN plans as P ON S.plan_id = P.plan_id
WHERE customer_id <= 8;


-- B. Data Analysis Questions
-- 1. How many customers has Foodie-Fi ever had?
SELECT 
COUNT(DISTINCT customer_id) as customer_count
FROM subscriptions;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
DATE_TRUNC('month',start_date) as month,
COUNT(customer_id) as trial_starts
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATE_TRUNC('month',start_date);


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
plan_name,
COUNT(*) as count_of_events
FROM subscriptions as S
INNER JOIN plans as P on S.plan_id = P.plan_id
WHERE DATE_PART('year',start_date) > 2020
GROUP BY plan_name;


-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) as customer_count,
ROUND((COUNT(DISTINCT customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions))*100,1) as churned_customers_percent
FROM subscriptions 
WHERE plan_id = 4;


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH CTE AS (
SELECT 
customer_id,
plan_name,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date ASC) as rn
FROM subscriptions as S
INNER JOIN plans as P on S.plan_id = P.plan_id
)
SELECT 
COUNT(DISTINCT customer_id) as churned_afer_trial_customers,
ROUND((COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions))*100,0) as percent_churn_after_trial
FROM CTE
WHERE rn = 2
AND plan_name = 'churn';


-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH CTE AS (
SELECT
customer_id,
plan_name,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date ASC) as rn
FROM subscriptions as S
INNER JOIN plans as P on P.plan_id = S.plan_id
)
SELECT 
plan_name,
COUNT(customer_id) as customer_count,
ROUND((COUNT(customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM CTE))*100,1) as customer_percent
FROM CTE
WHERE rn = 2
GROUP BY plan_name;


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE AS (
SELECT *
,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) as rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
)
SELECT 
plan_name,
COUNT(customer_id) as customer_count,
ROUND((COUNT(customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM CTE))*100,1) as percent_of_customers
FROM CTE
INNER JOIN plans as P on CTE.plan_id = P.plan_id
WHERE rn = 1
GROUP BY plan_name;


-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(customer_id) as annual_upgrade_customers
FROM subscriptions as S
INNER JOIN plans as P on P.plan_id = S.plan_id
WHERE DATE_PART('year',start_date) = 2020
AND plan_name = 'pro annual';


-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH TRIAL AS (
SELECT 
customer_id,
start_date as trial_start
FROM subscriptions
WHERE plan_id = 0
)
, ANNUAL AS (
SELECT 
customer_id,
start_date as annual_start
FROM subscriptions
WHERE plan_id = 3
)
SELECT 
ROUND(AVG(DATEDIFF('days',trial_start,annual_start)),0) as average_days_from_trial_to_annual
FROM TRIAL as T
INNER JOIN ANNUAL as A on T.customer_id = A.customer_id;


-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH TRIAL AS (
SELECT 
customer_id,
start_date as trial_start
FROM subscriptions
WHERE plan_id = 0
)
, ANNUAL AS (
SELECT 
customer_id,
start_date as annual_start
FROM subscriptions
WHERE plan_id = 3
)
SELECT 
CASE
WHEN DATEDIFF('days',trial_start,annual_start)<=30  THEN '0-30'
WHEN DATEDIFF('days',trial_start,annual_start)<=60  THEN '31-60'
WHEN DATEDIFF('days',trial_start,annual_start)<=90  THEN '61-90'
WHEN DATEDIFF('days',trial_start,annual_start)<=120  THEN '91-120'
WHEN DATEDIFF('days',trial_start,annual_start)<=150  THEN '121-150'
WHEN DATEDIFF('days',trial_start,annual_start)<=180  THEN '151-180'
WHEN DATEDIFF('days',trial_start,annual_start)<=210  THEN '181-210'
WHEN DATEDIFF('days',trial_start,annual_start)<=240  THEN '211-240'
WHEN DATEDIFF('days',trial_start,annual_start)<=270  THEN '241-270'
WHEN DATEDIFF('days',trial_start,annual_start)<=300  THEN '271-300'
WHEN DATEDIFF('days',trial_start,annual_start)<=330  THEN '301-330'
WHEN DATEDIFF('days',trial_start,annual_start)<=360  THEN '331-360'
END as bin,
COUNT(T.customer_id) as customer_count
FROM TRIAL as T
INNER JOIN ANNUAL as A on T.customer_id = A.customer_id
GROUP BY 1;


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH PRO_MON AS (
SELECT 
customer_id,
start_date as pro_monthly_start
FROM subscriptions
WHERE plan_id = 2
)
,BASIC_MON AS (
SELECT 
customer_id,
start_date as basic_monthly_start
FROM subscriptions
WHERE plan_id = 1
)
SELECT 
P.customer_id,
pro_monthly_start,
basic_monthly_start
FROM PRO_MON as P
INNER JOIN BASIC_MON as B on P.customer_id = B.customer_id
WHERE pro_monthly_start < basic_monthly_start
AND DATE_PART('year',basic_monthly_start) = 2020;

