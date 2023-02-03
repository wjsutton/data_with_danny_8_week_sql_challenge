-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH runner_signups AS (
  SELECT 
    runner_id, 
    registration_date, 
    DATE_TRUNC('week', registration_date) + 4 AS start_of_week 
  FROM 
    runners
) 
SELECT 
  start_of_week, 
  COUNT(runner_id) AS signups 
FROM 
  runner_signups 
GROUP BY 
  start_of_week 
ORDER BY 
  start_of_week;
  
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT 
  runner_id, 
  AVG(TIMEDIFF(minute, order_time::timestamp_ntz, pickup_time::timestamp_ntz)) as avg_minutes_to_pickup 
FROM 
  runner_orders as ro 
  INNER JOIN customer_orders as co on ro.order_id = co.order_id 
WHERE 
  pickup_time <> 'null' 
GROUP BY 
  runner_id;
  
-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH CTE AS (
  SELECT 
    ro.order_id, 
    COUNT(pizza_id) as number_of_pizzas, 
    MAX(TIMEDIFF(minute, order_time::timestamp_ntz, pickup_time::timestamp_ntz)) as order_prep_time 
  FROM 
    runner_orders as ro 
    INNER JOIN customer_orders as co on ro.order_id = co.order_id 
  WHERE 
    pickup_time <> 'null' 
  GROUP BY 
    ro.order_id
) 
SELECT 
  number_of_pizzas, 
  AVG(order_prep_time) as avg_order_prep_time 
FROM 
  CTE 
GROUP BY 
  number_of_pizzas;
  
-- 4. What was the average distance travelled for each customer?
SELECT 
  customer_id, 
  AVG(REPLACE(distance, 'km', ''):: numeric(3, 1)) as avg_distance_travelled 
FROM 
  runner_orders as ro 
  INNER JOIN customer_orders as co on ro.order_id = co.order_id 
WHERE 
  distance <> 'null' 
GROUP BY 
  customer_id;
  
-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT 
  MAX(REGEXP_REPLACE(duration, '[^0-9]', '')::int) - MIN(REGEXP_REPLACE(duration, '[^0-9]', '')::int) as delivery_time_difference 
FROM 
  runner_orders 
WHERE 
  duration <> 'null' 

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
  runner_id, 
  order_id, 
  REPLACE(distance, 'km', '')::numeric(3, 1) / REGEXP_REPLACE(duration, '[^0-9]', '')::numeric(3, 1) as speed_km_per_minute 
FROM 
  runner_orders 
WHERE 
  duration <> 'null' 
ORDER BY 
  runner_id, 
  order_id 

-- 7. What is the successful delivery percentage for each runner?
SELECT 
  runner_id, 
  COUNT(order_id) as orders, 
  SUM(
    CASE 
        WHEN pickup_time = 'null' 
        THEN 0
        ELSE 1 
    END
  ) / COUNT(order_id) as delivery_percentage 
FROM 
  runner_orders 
GROUP BY 
  runner_id