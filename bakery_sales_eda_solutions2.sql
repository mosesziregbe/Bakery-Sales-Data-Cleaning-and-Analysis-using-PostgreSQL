
-- PART B (Exploratory Data Analysis)


SET search_path TO bakery_schema;

SHOW search_path;



-- 1. How does the average order value vary by month? 
-- Is there any noticeable seasonality?


-- calculate average order value by month

SELECT TO_CHAR(order_date, 'Mon YYYY') AS month, 
	   ROUND(SUM(total) / COUNT(order_id), 2) AS average_order_amount
FROM orders
GROUP BY TO_CHAR(order_date, 'Mon YYYY')
ORDER BY MIN(order_date);


-- Output:
-- "month"	"average_order_amount"
-- "Jul 2019"	30196.30
-- "Aug 2019"	20750.00
-- "Sep 2019"	20831.91
-- "Oct 2019"	19995.45
-- "Nov 2019"	20191.11
-- "Dec 2019"	20530.74
-- "Jan 2020"	21117.51
-- "Feb 2020"	20924.10
-- "Mar 2020"	20525.80
-- "Apr 2020"	20736.02
-- "May 2020"	20560.00


-- Output:
-- The data shows the average order amount for each month 
-- from July 2019 to May 2020.

-- Initial Anomaly: July 2019 shows an exceptionally high average 
-- order value (30,196.30), significantly higher than all other months.

-- Consistent Performance: From August 2019 onwards, average order 
-- values stabilize, consistently ranging between about 
-- 19,995 and 21,118, with no clear seasonal patterns.

-- Recent Stability: The most recent months (March to May 2020) 
-- exhibit particularly stable average order amounts, all within approximately 
-- 200 of each other, suggesting a steady business performance in this period.




-- 2. How does the average order value differ across different 
-- locations (places)?


SELECT place AS location, 
	   ROUND(SUM(total) / COUNT(order_id), 2) AS average_order_amount
FROM orders
GROUP BY place
ORDER BY average_order_amount DESC;


-- Output:
-- "location"	"average_order_amount"
-- "Sindong-myeon"	26100.00
-- "NA"	25690.16
-- "Dongnae-myeon"	23735.48
-- "Seoksa-dong"	23391.12
-- "Sinsawoo-dong"	23251.65
-- "Toegye-dong"	22362.33
-- "Yaksamyeong-dong"	22221.74
-- "Jowoon-dong"	22062.16
-- "Gangnam-dong"	21080.77
-- "Hyoja1-dong"	21002.00
-- "Hoopyeong1-dong"	20816.84
-- "Dongmyeon"	20511.78
-- "Geunhwa-dong"	20313.79
-- "Hyoja2-dong"	19995.10
-- "Soyang-dong"	19953.03
-- "Hoopyeong2-dong"	19384.25
-- "Hoopyeong3-dong"	19268.27
-- "Gyo-dong"	18620.90
-- "Hyoja3-dong"	18481.25



-- The query shows the average order amount for different locations, 
-- including "NA" (Not Available) for orders before July 12 when 
-- the bakery started recording location data.

-- Key Insights:
-- Location Variability: There's significant variation in average order 
-- amounts across different locations, ranging from 18,481.25 to 26,100.00.

-- Top Performers: Sindong-myeon has the highest average order amount (26,100.00), 
-- followed by "NA" (25,690.16) and Dongnae-myeon (23,735.48).

-- Pre-Delivery Data: The high average for "NA" suggests that orders before July 12 
-- (when delivery and location tracking started) had higher values on average 
-- than most locations after delivery was introduced.

-- These insights indicate that order values vary significantly by location, 
-- which could be due to factors such as local income levels, product preferences, 
-- or marketing strategies. The high "NA" value also suggests a potential shift 
-- in ordering patterns after the introduction of delivery services. 

-- Further analysis might be needed to understand these differences and 
-- their implications for the bakery's business strategy.





-- 3. Calculate the average order value for each day of the week. 
-- Which day has the highest average order value?


SELECT TO_CHAR(order_date, 'Day') AS day_of_week,
	   ROUND(SUM(total) / COUNT(order_id), 2) AS average_order_amount
FROM orders
GROUP BY TO_CHAR(order_date, 'Day')
ORDER BY average_order_amount DESC;



-- Output:
-- "day_of_week"	"average_order_amount"
-- "Friday   "	24484.13
-- "Thursday "	21144.68
-- "Wednesday"	21085.00
-- "Monday   "	20806.65
-- "Sunday   "	20337.84
-- "Saturday "	20128.32
-- "Tuesday  "	18666.67


-- The output shows that Friday has the highest average order amount 
-- at 24,484.13, followed by Thursday at 21,144.68, while Tuesday has the 
-- lowest at 18,666.67. 

-- This indicates that customers tend to spend more on Fridays, 
-- possibly due to end-of-week celebrations or payday effects, 
-- while midweek (Tuesday) sees the lowest average spending. 

-- The data suggests a pattern where spending generally increases 
-- towards the end of the week, with a slight dip on the weekend.





-- 4. Is there a correlation between the total order value 
-- and the number of items in the order? 


-- To determine if there is a correlation between the total order value 
-- and the number of items in the order,
-- calculate the total value and the total quantity of items for each order
-- Then use CORR() to find the correlation between the two variables


SELECT ROUND(CORR(total_order_value, total_items)::DECIMAL(5,2), 2) AS correlation
FROM
(
SELECT o.order_id, 
       o.total AS total_order_value, 
       SUM(s.quantity) AS total_items
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
GROUP BY o.order_id, o.total
ORDER BY o.order_id
) AS total_value_per_order


-- Output:
-- "correlation"
-- 0.53



-- The output shows a correlation coefficient of 0.53, indicating a 
-- moderate positive correlation between the total order value and the 
-- number of items in an order. 

-- This suggests that as the number of items in an order increases, there 
-- is a tendency for the total order value to increase as well, although the 
-- relationship is not extremely strong.





-- 5. For each product, calculate its percentage contribution to total sales. 
-- Then categorize products as 'High Impact' (>5%), 'Medium Impact' (1-5%), or 
-- 'Low Impact' (<1%). Output the product name, percentage_contribution, and impact.
-- Which products contribute the most to the total revenue?



WITH cte_product_sales AS
(
SELECT p.name AS product_name, SUM(s.quantity * p.price) AS product_sales
FROM products p
JOIN sales s
ON p.product_id = s.product_id
GROUP BY p.name
)
, pct_cte AS (
SELECT product_name, ROUND(100.0 * product_sales / 
						   (SELECT SUM(product_sales) FROM cte_product_sales), 2) AS pct_contribution
FROM cte_product_sales
)
SELECT product_name, pct_contribution, 
	  CASE WHEN pct_contribution > 5 THEN 'High Impact'
	  	   WHEN pct_contribution BETWEEN 1 AND 5 THEN 'Medium Impact'
		   WHEN pct_contribution < 1 THEN 'Low Impact' END AS impact
FROM pct_cte
ORDER BY pct_contribution DESC;




-- Output:
-- "product_name"	"pct_contribution"	"impact"
-- "angbutter"	34.53	"High Impact"
-- "tiramisu croissant"	10.10	"High Impact"
-- "croissant"	8.18	"High Impact"
-- "plain bread"	8.02	"High Impact"
-- "orange pound"	5.67	"High Impact"
-- "pain au chocolat"	5.66	"High Impact"
-- "americano"	4.57	"Medium Impact"
-- "pandoro"	3.95	"Medium Impact"
-- "cacao deep"	3.24	"Medium Impact"
-- "wiener"	2.65	"Medium Impact"
-- "vanila latte"	2.42	"Medium Impact"
-- "caffe latte"	2.15	"Medium Impact"
-- "almond croissant"	2.09	"Medium Impact"
-- "gateau chocolat"	1.87	"Medium Impact"
-- "milk tea"	1.60	"Medium Impact"
-- "cheese cake"	1.02	"Medium Impact"
-- "jam"	0.83	"Low Impact"
-- "berry ade"	0.55	"Low Impact"
-- "merinque cookies"	0.44	"Low Impact"
-- "lemon ade"	0.38	"Low Impact"
-- "tiramisu cake"	0.07	"Low Impact"


-- Impact Distribution: 
-- High Impact: 6 products
-- Medium Impact: 10 products
-- Low Impact: 5 products

-- Summary:
-- Just two products (Angbutter and Tiramisu croissant) account 
-- for nearly 45% of total revenue.
-- The top 6 "High Impact" products contribute over 72% of total revenue.
-- There's a significant drop-off between high and medium impact products, 
-- suggesting a heavy reliance on a few key items.
-- Low impact products collectively contribute less than 3% to total revenue.





-- 6. What is the sales growth rate month-over-month? 
-- Are there any periods with exceptionally high or low growth rates?


-- to calculate growth rate month_over_month
-- Growth rate (%) = 
-- 100 * (current month sale - previous month sale)/(previous month sale) 


SELECT month, total_sales,
	   ROUND(COALESCE(100.0 * 
					  (total_sales - prev_month_sales)/(prev_month_sales), 0),2) || '%' AS sales_growth_rate
FROM
(SELECT TO_CHAR(order_date, 'Mon YYYY') AS month, 
	   SUM(total) AS total_sales,
  	   LAG(SUM(total)) OVER(ORDER BY MIN(order_date)) AS prev_month_sales
FROM orders
GROUP BY TO_CHAR(order_date, 'Mon YYYY')
ORDER BY MIN(order_date)
) monthly_sales



-- Output:
-- "month"	"total_sales"	"sales_growth_rate"
-- "Jul 2019"	4076500	"0.00%"
-- "Aug 2019"	6100500	"49.65%"
-- "Sep 2019"	4895500	"-19.75%"
-- "Oct 2019"	3959100	"-19.13%"
-- "Nov 2019"	4543000	"14.75%"
-- "Dec 2019"	5009500	"10.27%"
-- "Jan 2020"	4582500	"-8.52%"
-- "Feb 2020"	6423700	"40.18%"
-- "Mar 2020"	6445100	"0.33%"
-- "Apr 2020"	4893700	"-24.07%"
-- "May 2020"	308400	"-93.70%"



-- Summary:
-- COVID-19 Impact: The sharp increase in February 2020 (40.18% growth) 
-- coincides with the large-scale spread beginning on February 18th. 
-- This suggests that the pandemic had a significant impact on consumer behavior.

-- Shift to Delivery: The sales spike in February and March indicates a 
-- rapid shift to delivery services as customers likely avoided in-store 
-- visits due to health concerns.

-- Adaptation Period: The high growth in February might also reflect the 
-- bakery's successful adaptation to the new circumstances, quickly scaling 
-- up their delivery capabilities.

-- Peak and Decline: The sales plateau in March (0.33% growth) and subsequent 
-- decline in April (-24.07%) align with the easing of the initial spread 
-- and possibly a normalization of consumer behavior.

-- Resilience: Despite the challenging circumstances, the bakery managed 
-- to maintain and even increase sales during the early stages of the pandemic, 
-- demonstrating business resilience and adaptability.

-- Pre-Pandemic Growth and Stabilization: The significant growth in August 2019 
-- (49.65%) likely reflects the first full month of delivery service implementation, 
-- which started on July 11th. The subsequent declines in September (-19.75%) 
-- and October (-19.13%) suggest an initial surge of interest in the new delivery service, 
-- followed by a stabilization period as the novelty wore off. 
-- This pattern is common when introducing new services, often referred to as the 
-- "novelty effect" followed by a "normalization phase.

-- Future Strategy: The success of delivery services during the pandemic 
-- peak might inform future business strategies, potentially maintaining 
-- a strong delivery option even as in-store sales recover.





-- 7. What is the total revenue generated from our signature product 'angbutter'?
-- How many orders included at least one 'croissant'? 


-- finding the total revenue generated from angbutter


SELECT p.name, SUM(p.price * s.quantity) AS total_revenue
FROM products p
JOIN sales s
ON p.product_id = s.product_id
WHERE p.name = 'angbutter'
GROUP BY p.name



-- Output:
-- "name"	"total_revenue"
-- "angbutter"	15499200



-- finding orders that included at least 1 croissant

-- croissants in our products table include angbutter(the signature product)
-- and other pastries that contain croissant in the product name
-- like (almond croissant, tiramisu croissant etc.)


SELECT ROUND(100.0 * croissant_orders / (SELECT COUNT(order_id) FROM orders), 2) || '%'
	   AS pct_of_orders_w_croissant
FROM
(
SELECT COUNT(DISTINCT s.order_id) AS croissant_orders
FROM sales s
JOIN products p
ON s.product_id = p.product_id
WHERE p.name IN (SELECT name FROM products WHERE name LIKE '%croissant%' OR name LIKE '%angbutter%')
) AS croissant_count


-- Output
-- "pct_of_orders_w_croissant"
-- 95.66%



-- Summary:
-- Revenue from 'angbutter':
-- The signature product 'angbutter' generated a total revenue of 15,499,200 (Korean won).

-- Orders including croissants:
-- 95.66% of all orders included at least one croissant product 
-- (including 'angbutter' and other croissant variations).

-- Key insights:
-- 'Angbutter' is a significant revenue generator, confirming its status 
-- as a signature product.
-- Croissant products, including 'angbutter', are extremely popular, appearing 
-- in nearly all orders (95.66%).
-- The high percentage of orders containing croissants suggests 
-- they are a key driver of the bakery's business.
-- This data highlights the importance of maintaining consistent quality 
-- and availability of croissant products, especially 'angbutter'.






-- 8. Calculate the percentage of orders that include 'coffee' 
-- (either americano or caffe latte).


-- finding orders that includes coffee


SELECT ROUND(100.0 * coffee_orders / (SELECT COUNT(order_id) FROM orders), 2) || '%'
	   AS pct_of_orders_w_coffee
FROM
(
SELECT COUNT(DISTINCT s.order_id) AS coffee_orders
FROM sales s
JOIN products p
ON s.product_id = p.product_id
WHERE p.name IN (SELECT name FROM products WHERE name IN ('americano', 'caffe latte'))
) AS coffee_count


-- Output:
-- "pct_of_orders_w_coffee"
-- "23.35%"


-- Summary:
-- The analysis shows that 23.35% of all orders include coffee, specifically 
-- either americano or caffe latte. This indicates that while coffee is a 
-- significant part of the bakery's sales, it's not as dominant as the croissant products, 
-- suggesting there might be potential to increase coffee sales or to explore why customers 
-- are more likely to purchase baked goods without coffee.






-- 9. What is the distribution of order sizes (number of items per order)? 
-- Are most orders for single items or multiple items? 


-- finding out the number of items in a particular order
-- for example an order with a single product (e.g., 1 croissant).
-- an order with multiple products (e.g., 2 croissants, 1 coffee).


SELECT num_of_items_ordered, COUNT(order_id) AS orders_count
FROM
(
SELECT order_id, COUNT(product_id) AS num_of_items_ordered
FROM sales
GROUP BY order_id
ORDER BY order_id
) AS orders_distribution
GROUP BY num_of_items_ordered
ORDER BY num_of_items_ordered;


-- Output:
-- "num_of_items_ordered"	"orders_count"
-- 1	96
-- 2	336
-- 3	942
-- 4	694
-- 5	235
-- 6	81
-- 7	29
-- 8	3
-- 9	3




-- Summary of the output:
-- Order Size Range: The number of items per order ranges from 1 to 9, 
-- indicating a wide variety in order sizes.

-- Most Common Order Sizes: The most frequent order sizes are 3 items 
-- (942 orders) and 4 items (694 orders), suggesting that customers 
-- typically prefer to purchase multiple items together.

-- Single-Item Orders: There are relatively few single-item orders (96), 
-- while orders with 5 or more items are less common but still significant, 
-- tapering off as the number of items increases.

-- These insights suggest that customers generally prefer to buy multiple items 
-- in a single order, with a sweet spot around 3-4 items. 

-- This information could be valuable for pricing strategies, product bundling, 
-- and understanding customer purchasing behavior.





-- 10. For each place, what is the most frequently ordered item?
-- Also, find the percentage of their orders that include this product.


-- finding the most frequently ordered item for each place
-- in terms of quantity


SELECT place, product_name, quantity_ordered
FROM
(
SELECT o.place AS place, p.name AS product_name, 
	   SUM(s.quantity) AS quantity_ordered,
	   RANK() OVER(PARTITION BY o.place ORDER BY SUM(s.quantity) DESC) AS rank
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.place, p.name
) ranked_orders
WHERE rank = 1;


-- Output:
-- "place"	"product_name"	"quantity_ordered"
-- "Dongmyeon"	"angbutter"	523
-- "Hoopyeong3-dong"	"angbutter"	281
-- "Hoopyeong1-dong"	"angbutter"	272
-- "Hoopyeong2-dong"	"angbutter"	257
-- "Seoksa-dong"	"angbutter"	244
-- "Toegye-dong"	"angbutter"	231
-- "Hyoja2-dong"	"angbutter"	213
-- "Soyang-dong"	"angbutter"	164
-- "Sinsawoo-dong"	"angbutter"	127
-- "Gyo-dong"	"angbutter"	106
-- "Hyoja3-dong"	"angbutter"	98
-- "Jowoon-dong"	"angbutter"	77
-- "Gangnam-dong"	"croissant"	63
-- "Hyoja1-dong"	"angbutter"	63
-- "Dongnae-myeon"	"angbutter"	53
-- "Geunhwa-dong"	"angbutter"	52
-- "Yaksamyeong-dong"	"angbutter"	39
-- "Sindong-myeon"	"wiener"	2
-- "Sindong-myeon"	"angbutter"	2



-- Summary:
-- The data reveals that 'angbutter' is overwhelmingly the most popular item 
-- across nearly all locations, being the top-ordered product in 17 out of 19 areas. 
-- There are only two exceptions: Gangnam-dong, where 'croissant' takes the lead, 
-- and Sindong-myeon, which shows a tie between 'wiener' and 'angbutter'. 

-- The order quantities vary significantly between locations, with Dongmyeon 
-- showing the highest demand for the top item (523 'angbutter' orders) and 
-- Sindong-myeon the lowest (2 orders each for 'wiener' and 'angbutter'), 
-- potentially reflecting differences in local population or customer base size.




-- finding the percentage of orders for each place that include this 
-- frequently ordered product

-- solution

-- CTE to rank products by their total quantity ordered for each place
WITH ranked_orders AS (
    SELECT o.place AS place, 
           p.name AS fave_product,
           SUM(s.quantity) AS quantity_ordered,
           RANK() OVER (PARTITION BY o.place ORDER BY SUM(s.quantity) DESC) AS rank
    FROM orders o
    JOIN sales s ON o.order_id = s.order_id
    JOIN products p ON s.product_id = p.product_id
    WHERE o.place != 'NA'
    GROUP BY o.place, p.name
),
-- CTE to count the total number of distinct orders for each place
product_cte AS (
    SELECT o.place AS place, 
           COUNT(DISTINCT o.order_id) AS num_orders
    FROM orders o
    JOIN sales s ON o.order_id = s.order_id
    JOIN products p ON s.product_id = p.product_id
    WHERE o.place != 'NA' 
    GROUP BY o.place
),
-- CTE to count the number of orders that include the most frequently 
-- ordered product for each place
fave_orders_cte AS (
    SELECT o.place, 
           COUNT(DISTINCT o.order_id) AS fave_orders
    FROM orders o
    JOIN sales s ON o.order_id = s.order_id
    JOIN products p ON s.product_id = p.product_id
    JOIN ranked_orders r ON p.name = r.fave_product AND o.place = r.place
    WHERE o.place != 'NA' AND r.rank = 1
    GROUP BY o.place
)
-- Final query to get the place, favorite product, total number of orders, 
-- number of orders with the favorite product, and the percentage of orders 
-- that include the favorite product
SELECT r.place, 
       r.fave_product, 
       p.num_orders, 
       f.fave_orders, 
       ROUND((f.fave_orders::NUMERIC / p.num_orders) * 100, 2) AS percentage
FROM ranked_orders r
JOIN product_cte p ON r.place = p.place
JOIN fave_orders_cte f ON r.place = f.place
WHERE r.rank = 1
ORDER BY percentage DESC;



-- Output:
-- "place"	"fave_product"	"num_orders"	"fave_orders"	"percentage"
-- "Sindong-myeon"	"angbutter"	1	1	100.00
-- "Sindong-myeon"	"wiener"	1	1	100.00
-- "Geunhwa-dong"	"angbutter"	29	29	100.00
-- "Hyoja2-dong"	"angbutter"	143	129	90.21
-- "Gyo-dong"	"angbutter"	67	58	86.57
-- "Jowoon-dong"	"angbutter"	37	32	86.49
-- "Hyoja3-dong"	"angbutter"	80	68	85.00
-- "Seoksa-dong"	"angbutter"	169	143	84.62
-- "Dongnae-myeon"	"angbutter"	31	26	83.87
-- "Yaksamyeong-dong"	"angbutter"	23	19	82.61
-- "Hoopyeong3-dong"	"angbutter"	249	203	81.53
-- "Sinsawoo-dong"	"angbutter"	91	74	81.32
-- "Toegye-dong"	"angbutter"	146	118	80.82
-- "Hoopyeong1-dong"	"angbutter"	196	156	79.59
-- "Dongmyeon"	"angbutter"	415	328	79.04
-- "Soyang-dong"	"angbutter"	132	102	77.27
-- "Hoopyeong2-dong"	"angbutter"	254	186	73.23
-- "Hyoja1-dong"	"angbutter"	50	36	72.00
-- "Gangnam-dong"	"croissant"	52	30	57.69




-- Summary:
-- Again, the data shows that 'angbutter' is the most frequently ordered 
-- item in 18 out of 19 locations, with only Gangnam-dong having 'croissant' 
-- as its top item. 

-- The percentage of orders including the most popular item varies 
-- significantly across locations, ranging from 57.69% in Gangnam-dong 
-- to 100% in Sindong-myeon and Geunhwa-dong. Most locations have their 
-- top item included in over 70% of orders, indicating a strong preference 
-- for these products, particularly 'angbutter', across different areas.



-- Breakdown of the query:

-- First CTE (ranked_orders):
-- Calculates the total quantity ordered for each product in each place.
-- Uses RANK() to identify the most frequently ordered product for each place.

-- Second CTE (product_cte):
-- Counts the total number of distinct orders for each place.

-- Third CTE (fave_orders_cte):
-- Counts the number of orders that include the most frequently ordered product for each place.
-- Uses a JOIN with ranked_orders to focus only on the top-ranked product.

-- Final SELECT statement:
-- Combines information from all CTEs.
-- Calculates the percentage of orders that include the favorite product.
-- Filters for only the top-ranked product (WHERE r.rank = 1).
-- Orders the results by percentage in descending order.






--
