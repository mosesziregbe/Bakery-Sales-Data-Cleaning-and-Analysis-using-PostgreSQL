
-- PART D (Business Analytics Questions)


SET search_path TO bakery_db, bakery_schema;

SHOW search_path;




-- /*************************/

-- 1. Identify orders where the total amount is more than twice 
-- the average order amount. Output the order ID and total amount.


-- Average order amount = Sum of total sales/ number of orders


SELECT order_id, total 
FROM orders
WHERE total > (SELECT ROUND(SUM(total) / COUNT(order_id), 2) * 2 AS average_order_amount FROM orders)
ORDER BY total DESC;



-- Output:
-- "order_id"	"total"
-- 90	1293000
-- 1445	116500
-- 1327	91300
-- 1496	77100
-- 88	73200
-- 562	71800
-- 977	70700
-- 715	68100
-- 1677	67000
-- 267	65600
-- 2325	64000
-- 1309	58900
-- 1497	58700
-- 3	58000
-- 33	58000
-- 278	58000
-- 547	57900
-- 352	57700
-- 1120	57700
-- 1675	57500
-- 860	55800
-- 1661	55200
-- 807	54700
-- 1047	54100
-- 331	54000
-- 1328	53900
-- 403	53800
-- 1659	53600
-- 1227	52800
-- 772	51900
-- 1234	51200
-- 1835	51100
-- 1591	50000
-- 618	49700
-- 191	49300
-- 803	47600
-- 1982	47000
-- 1341	46900
-- 233	46200
-- 1261	46000
-- 1577	45500
-- 1423	45400
-- 1214	45400
-- 2199	44500
-- 1422	44100
-- 2118	43200
-- 1348	43100
-- 1334	42900
-- 1531	42900
-- 2042	42400


-- Summary:
-- The query shows that multiple orders have totals significantly higher 
-- than twice the average order amount, with the highest being 
-- order ID 90 at 1,293,000. Other notable high-value orders range 
-- from 116,500 to 42,400.

-- Further Analysis:
-- Further analysis can focus on identifying the delivery locations for 
-- these high-value orders to understand geographic demand patterns. 
-- Investigate the specific products in these orders to determine if 
-- certain items drive higher sales. 
-- Analyze the timing of these orders to identify trends, such as 
-- peak times or seasons for large purchases. 
-- Use these insights to optimize inventory and supply chain management 
-- to better meet demand in high-order areas.

-- /*************************/








-- /*************************/

-- 2. Identify "high-value hours" for each day of the week. A high-value hour 
-- is one where the average order value is at least 25% higher than the 
-- overall average order value for that day of the week. 
-- Output the day of the week, high value hour, average order value
-- and overall average order value.



-- AOV = Total Revenue / Number of Orders

	   
WITH day_aov_cte AS (
SELECT TO_CHAR(order_date, 'Day') AS day_of_week, ROUND(SUM(total) / COUNT(order_id), 2) AS overall_aov
FROM orders
GROUP BY TO_CHAR(order_date, 'Day')
)
, hour_aov_cte AS (
SELECT TO_CHAR(order_date, 'Day') AS day_of_week,
	   TO_CHAR(order_time, 'HH24') AS hour,
	   ROUND(SUM(total) / COUNT(order_id), 2) AS aov
FROM orders
GROUP BY TO_CHAR(order_date, 'Day'), TO_CHAR(order_time, 'HH24')
)
SELECT d.day_of_week AS day_of_week,
	   h.hour AS high_value_hour,
	   h.aov AS aov,
	   d.overall_aov AS overall_aov
FROM day_aov_cte d
JOIN hour_aov_cte h
ON d.day_of_week = h.day_of_week
WHERE h.aov >= (1.25 * d.overall_aov);
	


-- Output:

-- "day_of_week"	"high_value_hour"	"aov"	"overall_aov"
-- "Sunday   "	"23"	35600.00	20337.84
-- "Friday   "	"11"	34845.74	24484.13



-- Querying our data to get more insights about our earlier result:

SELECT order_id, order_time, EXTRACT(HOUR FROM order_time), total 
FROM orders
WHERE EXTRACT(HOUR FROM order_time) > '17'

-- output:

-- "order_id"	"order_time"	"extract"	"total"
-- 838	"23:02:00"	23	35600
-- 1722	"22:13:00"	22	15800




-- Summary:

-- Based on the new query results, here's a summary of our 
-- findings:

-- High-value hours:
-- Sunday at 23:00 (11 PM): Average Order Value (AOV) of $35,600.00
-- Friday at 11:00 (11 AM): AOV of $34,845.74

-- These hours have an AOV at least 25% higher than the overall average 
-- for their respective days.

-- Evening/Night orders (after 5 PM):
-- There are only two orders placed after 5 PM:

-- Order ID 838: placed at 23:02 (11:02 PM) with a total of $35,600
-- Order ID 1722: placed at 22:13 (10:13 PM) with a total of $15,800


-- The extremely high AOV for Sunday at 11 PM is due to a single large order 
-- (Order ID 838) of $35,600.

-- The bakery appears to have limited operations in the evening and night hours. 
-- Only two orders were placed after 5 PM, both occurring after 10 PM.

-- The Friday 11 AM high-value hour remains unchanged and seems more representative 
-- of normal business operations during regular hours.

-- These findings suggest that while the bakery has some extremely high-value 
-- orders occurring late at night, these are rare occurrences. 

-- The more reliable high-value period is Friday morning. The late-night orders, 
-- especially the Sunday 11 PM order, appear to be outliers that significantly 
-- skew the average order value for those hours. 

-- The bakery's primary operating hours seem to be before 6 PM, with only 
-- exceptional orders occurring in the late evening or night.
	
-- /*************************/
	
	
	
	



-- /*************************/

-- 3. Calculate the 'order diversity index' for each place. 
-- The order diversity index is defined as the number of unique products 
-- ordered divided by the total quantity of items ordered. 
-- Categorize places into 'Relatively Diverse' (index > 0.10), 'Moderate' (0.05 - 0.10), 
-- and 'Focused' (< 0.05) based on this index."


WITH quantity_cte AS
(
SELECT o.place AS place,
		SUM(s.quantity) AS total_items_sold
FROM orders o
JOIN sales s ON o.order_id = s.order_id
JOIN products p ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.place
) 
, products_cte AS (
SELECT o.place, COUNT(DISTINCT p.name) AS unique_items_ordered
FROM orders o
JOIN sales s ON o.order_id = s.order_id
JOIN products p ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.place
)
, diversity_cte AS (
SELECT p.place, 
	   CAST(1.0 * (p.unique_items_ordered) / (q.total_items_sold) AS DECIMAL(5,2)) AS diversity_index
FROM products_cte p
JOIN quantity_cte q
ON p.place = q.place
)
SELECT place, diversity_index,
	   CASE WHEN diversity_index > 0.10 THEN 'Relatively Diverse'
	        WHEN diversity_index BETWEEN 0.05 AND 0.10 THEN 'Moderate'
			ELSE 'Focused' END AS diversity_category
FROM diversity_cte;



-- Output:

-- "place"	"diversity_index"	"diversity_category"
-- "Dongmyeon"	0.01	"Focused"
-- "Dongnae-myeon"	0.11	"Relatively Diverse"
-- "Gangnam-dong"	0.08	"Moderate"
-- "Geunhwa-dong"	0.11	"Relatively Diverse"
-- "Gyo-dong"	0.07	"Moderate"
-- "Hoopyeong1-dong"	0.02	"Focused"
-- "Hoopyeong2-dong"	0.02	"Focused"
-- "Hoopyeong3-dong"	0.02	"Focused"
-- "Hyoja1-dong"	0.08	"Moderate"
-- "Hyoja2-dong"	0.03	"Focused"
-- "Hyoja3-dong"	0.06	"Moderate"
-- "Jowoon-dong"	0.10	"Moderate"
-- "Seoksa-dong"	0.02	"Focused"
-- "Sindong-myeon"	0.71	"Relatively Diverse"
-- "Sinsawoo-dong"	0.04	"Focused"
-- "Soyang-dong"	0.03	"Focused"
-- "Toegye-dong"	0.03	"Focused"
-- "Yaksamyeong-dong"	0.16	"Relatively Diverse"



-- Brief summary:
-- Diversity Distribution:

-- 4 places are categorized as "Relatively Diverse" (22%)
-- 5 places are "Moderate" (28%)
-- 9 places are "Focused" (50%)

-- Business Implication: The majority of locations have a focused ordering pattern, 
-- suggesting that most customers tend to stick to a limited range of products. 
-- This could indicate strong product preferences or limited menu awareness in many areas.

-- Outlier Performance:
-- Sindong-myeon stands out with a significantly higher diversity index (0.71) 
-- compared to other locations. This highest diversity index (0.71) is due to very 
-- low total order count (7 items), skewing the results.

-- Low Overall Diversity:
-- Even among "Relatively Diverse" locations, most have indices below 0.20 
-- (except Sindong-myeon).

-- Business Implication: There is a general trend of low product diversity across 
-- orders. This could suggest opportunities for menu expansion, better promotion 
-- of less-popular items, or the need for targeted marketing to encourage customers 
-- to try a wider range of products.


-- Recommendations:
-- Implementing targeted marketing or bundling strategies to promote less-ordered items.
-- Considering staff training to improve upselling and cross-selling techniques, 
-- particularly in locations with low diversity indices.

-- /*************************/








-- /*************************/

-- 4. Create a report showing month-over-month growth in total sales, 
-- number of orders, and average order value. Identify any months with 
-- significant changes (e.g., more than 20% growth or decline).


-- to calculate growth rate month_over_month
-- Growth rate (%) = 
-- 100 * (current month sale - previous month sale)/(previous month sale) 

	
WITH mom_sales_data AS (
SELECT TO_CHAR(order_date, 'Mon YYYY') AS month, 
	   SUM(total) AS total_sales,
  	   LAG(SUM(total)) OVER(ORDER BY MIN(order_date)) AS prev_month_sales,
	   COUNT(order_id) AS num_of_orders,
	   LAG(COUNT(order_id)) OVER(ORDER BY MIN(order_date)) AS prev_month_orders,
	   ROUND(SUM(total) / COUNT(order_id), 2) AS month_aov,
	   LAG(ROUND(SUM(total) / COUNT(order_id), 2)) OVER(ORDER BY MIN(order_date)) AS prev_month_aov
FROM orders
GROUP BY TO_CHAR(order_date, 'Mon YYYY')
)
SELECT month,
	   ROUND(COALESCE(100.0 * 
					  (total_sales - prev_month_sales)/(prev_month_sales), 0),2) || '%' AS mom_sales_growth_rate,
	   ROUND(COALESCE(100.0 * 
					  (num_of_orders - prev_month_orders)/(prev_month_orders), 0),2) || '%' AS mom_order_GR,
	   ROUND(COALESCE(100.0 * 
					  (month_aov - prev_month_aov)/(prev_month_aov), 0),2) || '%' AS mom_aov_GR
	FROM mom_sales_data;
	
	
	
-- Output:

-- "month"	"mom_sales_growth_rate"	"mom_order_gr"	"mom_aov_gr"
-- "Jul 2019"	"0.00%"	"0.00%"	"0.00%"
-- "Aug 2019"	"49.65%"	"117.78%"	"-31.28%"
-- "Sep 2019"	"-19.75%"	"-20.07%"	"0.39%"
-- "Oct 2019"	"-19.13%"	"-15.74%"	"-4.02%"
-- "Nov 2019"	"14.75%"	"13.64%"	"0.98%"
-- "Dec 2019"	"10.27%"	"8.44%"	"1.68%"
-- "Jan 2020"	"-8.52%"	"-11.07%"	"2.86%"
-- "Feb 2020"	"40.18%"	"41.47%"	"-0.92%"
-- "Mar 2020"	"0.33%"	"2.28%"	"-1.90%"
-- "Apr 2020"	"-24.07%"	"-24.84%"	"1.02%"
-- "May 2020"	"-93.70%"	"-93.64%"	"-0.85%"
	





-- Identify any months with significant changes


WITH mom_sales_data AS (
    SELECT 
        TO_CHAR(order_date, 'Mon YYYY') AS month, 
        SUM(total) AS total_sales,
        LAG(SUM(total)) OVER(ORDER BY MIN(order_date)) AS prev_month_sales,
        COUNT(order_id) AS num_of_orders,
        LAG(COUNT(order_id)) OVER(ORDER BY MIN(order_date)) AS prev_month_orders,
        ROUND(SUM(total) / COUNT(order_id), 2) AS month_aov,
        LAG(ROUND(SUM(total) / COUNT(order_id), 2)) OVER(ORDER BY MIN(order_date)) AS prev_month_aov
    FROM orders
    GROUP BY TO_CHAR(order_date, 'Mon YYYY')
)
SELECT 
    month,
    ROUND(COALESCE(100.0 * (total_sales - prev_month_sales)/(prev_month_sales), 0),2) AS mom_sales_growth_rate,
    CASE 
        WHEN COALESCE(100.0 * (total_sales - prev_month_sales)/(prev_month_sales), 0) > 20 THEN 'Significant increase'
        WHEN COALESCE(100.0 * (total_sales - prev_month_sales)/(prev_month_sales), 0) < -20 THEN 'Significant decrease'
        ELSE 'No significant change'
    END AS sales_change,
    ROUND(COALESCE(100.0 * (num_of_orders - prev_month_orders)/(prev_month_orders), 0),2) AS mom_order_growth_rate,
    CASE 
        WHEN COALESCE(100.0 * (num_of_orders - prev_month_orders)/(prev_month_orders), 0) > 20 THEN 'Significant increase'
        WHEN COALESCE(100.0 * (num_of_orders - prev_month_orders)/(prev_month_orders), 0) < -20 THEN 'Significant decrease'
        ELSE 'No significant change'
    END AS orders_change,
    ROUND(COALESCE(100.0 * (month_aov - prev_month_aov)/(prev_month_aov), 0),2) AS mom_aov_growth_rate,
    CASE 
        WHEN COALESCE(100.0 * (month_aov - prev_month_aov)/(prev_month_aov), 0) > 20 THEN 'Significant increase'
        WHEN COALESCE(100.0 * (month_aov - prev_month_aov)/(prev_month_aov), 0) < -20 THEN 'Significant decrease'
        ELSE 'No significant change'
    END AS aov_change
FROM mom_sales_data
ORDER BY TO_DATE(month, 'Mon YYYY');



-- Output:

-- "month"	"mom_sales_growth_rate"	"sales_change"	"mom_order_growth_rate"	"orders_change"	"mom_aov_growth_rate"	"aov_change"
-- "Jul 2019"	0.00	"No significant change"	0.00	"No significant change"	0.00	"No significant change"
-- "Aug 2019"	49.65	"Significant increase"	117.78	"Significant increase"	-31.28	"Significant decrease"
-- "Sep 2019"	-19.75	"No significant change"	-20.07	"Significant decrease"	0.39	"No significant change"
-- "Oct 2019"	-19.13	"No significant change"	-15.74	"No significant change"	-4.02	"No significant change"
-- "Nov 2019"	14.75	"No significant change"	13.64	"No significant change"	0.98	"No significant change"
-- "Dec 2019"	10.27	"No significant change"	8.44	"No significant change"	1.68	"No significant change"
-- "Jan 2020"	-8.52	"No significant change"	-11.07	"No significant change"	2.86	"No significant change"
-- "Feb 2020"	40.18	"Significant increase"	41.47	"Significant increase"	-0.92	"No significant change"
-- "Mar 2020"	0.33	"No significant change"	2.28	"No significant change"	-1.90	"No significant change"
-- "Apr 2020"	-24.07	"Significant decrease"	-24.84	"Significant decrease"	1.02	"No significant change"
-- "May 2020"	-93.70	"Significant decrease"	-93.64	"Significant decrease"	-0.85	"No significant change"




-- Brief summary of the output:

-- Significant growth periods:

-- August 2019 saw exceptional growth, with sales increasing 
-- by 49.65% and orders by 117.78% compared to July.

-- February 2020 also showed strong performance, with sales growing 
-- by 40.18% and orders by 41.47% compared to January.


-- Significant decline periods:
-- April 2020 experienced a notable decline, with sales dropping 
-- by 24.07% and orders by 24.84% compared to March.

-- The apparent severe decline in May 2020 (over 93% drop in sales and orders) 
-- is likely due to incomplete data for that month rather than 
-- an actual business downturn.

-- Average Order Value (AOV) stability:
-- Despite fluctuations in overall sales and order numbers, 
-- AOV remained relatively stable throughout most months.
-- The most significant AOV change was in August 2019, with 
-- a 31.28% decrease from July, likely due to the large increase 
-- in order volume.

-- /*************************/







-- /*************************/
-- 5. Monthly Rising Star Product: For each month, identify the 
-- "rising star" product - the product with the highest percentage 
-- increase in sales compared to its average sales in the previous 
-- three months. 

-- Only consider products that have been sold in all 
-- four relevant months (the current month and the previous three). 
-- Present the results as a table with columns for Month, 
-- Rising Star Product, Percentage Increase, and Current Month Sales.



WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        p.product_id,
        p.name AS product_name,
        SUM(s.quantity * p.price) AS total_sales
    FROM 
        orders o
    JOIN 
        sales s ON o.order_id = s.order_id
    JOIN 
        products p ON s.product_id = p.product_id
    GROUP BY 
        DATE_TRUNC('month', o.order_date), p.product_id, p.name
),
average_previous_sales AS (
    SELECT 
        month,
        product_id,
        product_name,
        total_sales AS current_month_sales,
        AVG(total_sales) OVER (PARTITION BY product_id ORDER BY month ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING) AS avg_previous_3_months
    FROM 
        monthly_sales
),
sales_increase AS (
    SELECT 
        month,
        product_id,
        product_name,
        current_month_sales,
        avg_previous_3_months,
        (current_month_sales - avg_previous_3_months) / avg_previous_3_months * 100 AS percentage_increase,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY (current_month_sales - avg_previous_3_months) / avg_previous_3_months DESC) AS rank
    FROM 
        average_previous_sales
    WHERE 
        avg_previous_3_months IS NOT NULL
)
SELECT 
    TO_CHAR(month, 'Mon YYYY') AS month_date,
    product_name AS rising_star_product,
    ROUND(percentage_increase, 2) AS percentage_increase,
    current_month_sales
FROM 
    sales_increase
WHERE 
    rank = 1
    AND month >= (SELECT MIN(month) FROM monthly_sales) + INTERVAL '3 months'
ORDER BY 
    month;
	
	

-- Output:

-- "month_date"	"rising_star_product"	"percentage_increase"	"current_month_sales"
-- "Oct 2019"	"vanila latte"	32.79	121500
-- "Nov 2019"	"cheese cake"	700.00	80000
-- "Dec 2019"	"cheese cake"	77.78	80000
-- "Jan 2020"	"berry ade"	162.50	31500
-- "Feb 2020"	"vanila latte"	113.56	189000
-- "Mar 2020"	"caffe latte"	90.00	171000
-- "Apr 2020"	"merinque cookies"	60.00	32000
-- "May 2020"	"merinque cookies"	-84.21	4000



-- Query breakdown:

-- 1. monthly_sales CTE: 
-- Calculates the total sales for each product in each month.
-- average_previous_sales CTE: Calculates the average sales for each product 
-- over the previous three months using a window function.

-- 2. sales_increase CTE:
-- Calculates the percentage increase in sales compared to the average of 
-- the previous three months.
-- Ranks products within each month based on their percentage increase.
-- Filters out products that don't have sales data for all four relevant months 
-- (current + previous 3).

-- 3. Final SELECT:
-- Selects the top-ranked product (rising star) for each month.
-- Filters out the first three months of data to ensure we always have 
-- three months of history.
-- Rounds the percentage increase to two decimal places.

-- This query will produce a table with the requested columns: 
-- Month, Rising Star Product, Percentage Increase, and Current Month Sales, 
-- showing the product with the highest percentage increase in sales for each month compared 
-- to its average over the previous three months.

-- /*************************/









-- /*************************/

-- 6. Golden Hour Sales Analysis: For each day of the week, 
-- determine the "golden hour" - the one-hour period with the 
-- highest average sales across all products. 

-- Then, for each product, calculate what percentage of its total sales 
-- occur during these seven golden hours. 
-- Present the results as a table with columns for Product, 
-- Total Sales, Golden Hour Sales, and Percentage of Sales in Golden Hours.


-- finding the golden hour for each day of the week
-- (the 1-hour period with the highest average sales)


CREATE VIEW golden_hour_view AS
-- Step 1: Calculate the total sales per hour for each day
WITH hourly_sales AS (
    SELECT
        TO_CHAR(o.order_date, 'Day') AS day_of_week,
        EXTRACT(HOUR FROM o.order_time) AS hour,
        SUM(s.quantity * p.price) AS total_sales
    FROM
        orders o
    JOIN
        sales s ON o.order_id = s.order_id
    JOIN
        products p ON s.product_id = p.product_id
    GROUP BY
        TO_CHAR(o.order_date, 'Day'), EXTRACT(HOUR FROM o.order_time)
),
-- Step 2: Calculate the average sales per hour for each day of the week
average_hourly_sales AS (
    SELECT
        day_of_week,
        hour,
        ROUND(AVG(total_sales), 2) AS avg_sales
    FROM
        hourly_sales
    GROUP BY
        day_of_week, hour
),
-- Step 3: Identify the "golden hour" for each day of the week
golden_hour AS (
    SELECT
        day_of_week,
        hour,
        avg_sales,
        RANK() OVER(PARTITION BY day_of_week ORDER BY avg_sales DESC) AS sales_rank
    FROM
        average_hourly_sales
)
-- Final Step: Select the top-ranked hour for each day of the week
SELECT
    day_of_week,
    hour AS golden_hour,
    avg_sales AS highest_avg_sales
FROM
    golden_hour
WHERE
    sales_rank = 1
ORDER BY
    highest_avg_sales DESC;



-- Output the results from the view:

SELECT * FROM golden_hour_view;


-- Output:

-- "day_of_week"	"golden_hour"	"highest_avg_sales"
-- "Sunday   "	11	3352200.00
-- "Saturday "	11	2768100.00
-- "Wednesday"	11	2222800.00
-- "Thursday "	11	2145600.00
-- "Friday   "	11	1936600.00
-- "Monday   "	12	1509500.00
-- "Tuesday  "	11	33000.00



-- finding the percentage of sales made during these golden hour
-- for each product

-- Step 1: Calculate the total weekly sales per product
WITH total_weekly_sales AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        SUM(s.quantity * p.price) AS total_sales
    FROM
        orders o
    JOIN
        sales s ON o.order_id = s.order_id
    JOIN
        products p ON s.product_id = p.product_id
    GROUP BY
        p.product_id, p.name
),

-- Step 2: Calculate the sales during the golden hours per product
golden_hour_sales AS (
    SELECT
        p.product_id,
        p.name AS product_name,
        SUM(s.quantity * p.price) AS golden_hour_sales
    FROM
        orders o
    JOIN
        sales s ON o.order_id = s.order_id
    JOIN
        products p ON s.product_id = p.product_id
    JOIN
        golden_hour_view ghv ON TO_CHAR(o.order_date, 'Day') = ghv.day_of_week
                      AND EXTRACT(HOUR FROM o.order_time) = ghv.golden_hour
    GROUP BY
        p.product_id, p.name
),
-- Step 3: Calculate the percentage of sales during golden hours
sales_analysis AS (
    SELECT
        t.product_name,
        t.total_sales,
        COALESCE(g.golden_hour_sales, 0) AS golden_hour_sales,
        ROUND(COALESCE(g.golden_hour_sales, 0) * 100.0 / t.total_sales, 2) AS percentage_in_golden_hours
    FROM
        total_weekly_sales t
    LEFT JOIN
        golden_hour_sales g ON t.product_id = g.product_id
)
-- Final Step: Select the results for presentation
SELECT
    product_name,
    total_sales,
    golden_hour_sales,
    percentage_in_golden_hours || '%' AS pct_in_golden_hours
FROM
    sales_analysis
ORDER BY
    percentage_in_golden_hours DESC;



-- Ouput:

-- "product_name"	"total_sales"	"golden_hour_sales"	"pct_in_golden_hours"
-- "pandoro"	1773000	670500	"37.82%"
-- "wiener"	1190000	430000	"36.13%"
-- "almond croissant"	940000	328000	"34.89%"
-- "tiramisu croissant"	4536000	1579200	"34.81%"
-- "pain au chocolat"	2541000	878500	"34.57%"
-- "croissant"	3671500	1221500	"33.27%"
-- "angbutter"	15499200	4833600	"31.19%"
-- "plain bread"	3598000	1074500	"29.86%"
-- "orange pound"	2547000	742500	"29.15%"
-- "cacao deep"	1456000	424000	"29.12%"
-- "tiramisu cake"	31500	9000	"28.57%"
-- "americano"	2052000	568000	"27.68%"
-- "gateau chocolat"	840000	228000	"27.14%"
-- "caffe latte"	963000	256500	"26.64%"
-- "merinque cookies"	196000	52000	"26.53%"
-- "lemon ade"	171000	45000	"26.32%"
-- "jam"	373500	94500	"25.30%"
-- "vanila latte"	1084500	252000	"23.24%"
-- "cheese cake"	460000	105000	"22.83%"
-- "berry ade"	247500	54000	"21.82%"
-- "milk tea"	720000	121500	"16.88%"





-- Query Breakdown:
-- The technique used in joining the golden_hour_view is called a 
-- conditional join. It's joining based on two conditions:

-- The day of the week from the order date matches the day in the golden hour view.
-- The hour extracted from the order time matches the golden hour in the view.

-- This join effectively filters the orders to only those that occurred during 
-- the defined golden hours for each day of the week.

-- Also, we use a LEFT JOIN in the final step between total_weekly_sales 
-- and golden_hour_sales for these reasons:

-- It ensures all products are included in the result, even if they had no sales during golden hours.
-- It prevents products with zero golden hour sales from being excluded from the analysis.
-- It allows for a complete comparison between total sales and golden hour sales for all products.

-- /*************************/








--