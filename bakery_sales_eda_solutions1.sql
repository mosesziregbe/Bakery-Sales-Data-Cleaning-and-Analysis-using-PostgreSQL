
-- PART A (Exploratory Data Analysis)


SET search_path TO bakery_schema;

SHOW search_path;


-- Questions
-- Output
-- (Summary)
-- (Breakdown of Query / Notes)


-- 1. What are the top 5 best-selling products by quantity? 
-- How does this change if you consider total revenue instead?


SELECT p.name, SUM(s.quantity) AS total_quantity
FROM sales s
JOIN products p
ON s.product_id = p.product_id
GROUP BY p.name
ORDER BY total_quantity DESC
LIMIT 5;


-- Output:
-- "name"	"total_quantity"
-- "angbutter"	3229
-- "croissant"	1049
-- "plain bread"	1028
-- "tiramisu croissant"	945
-- "pain au chocolat"	726

-- top 5 best selling products by quantity:
-- angbutter, croissant, plain bread, tiramisu croissant, pain au chocolat



-- top 5 best_selling products by total revenue

SELECT p.name, SUM(s.quantity * p.price) AS amount
FROM sales s
JOIN products p
ON s.product_id = p.product_id
GROUP BY p.name
ORDER BY amount DESC
LIMIT 5;


-- Ouptput:
-- "name"	"amount"
-- "angbutter"	15499200
-- "tiramisu croissant"	4536000
-- "croissant"	3671500
-- "plain bread"	3598000
-- "orange pound"	2547000


-- top 5 products by revenue: 
-- angbutter, tiramisu croissant, croissant, plain bread, orange pound




-- 2. Calculate the total sales for each month. Ensure that the output includes the 
-- month and year, along with the corresponding total sales amount. 
-- How do the monthly sales trends look over the past year? 
-- Are there any noticeable peaks or troughs?
-- Additionally, order the results chronologically, 
-- starting from the earliest month in to the most recent month.


SELECT 
  TO_CHAR(order_date, 'Mon, YYYY') AS month,
  SUM(total) AS total_sales
FROM orders
GROUP BY TO_CHAR(order_date, 'Mon, YYYY')
ORDER BY MIN(order_date);


-- Ouput:
-- "month"	"total_sales"
-- "Jul, 2019"	4076500
-- "Aug, 2019"	6100500
-- "Sep, 2019"	4895500
-- "Oct, 2019"	3959100
-- "Nov, 2019"	4543000
-- "Dec, 2019"	5009500
-- "Jan, 2020"	4582500
-- "Feb, 2020"	6423700
-- "Mar, 2020"	6445100
-- "Apr, 2020"	4893700
-- "May, 2020"	308400


-- Summary:
-- The total sales for each month over the past year show distinct trends with 
-- notable peaks and troughs. The highest sales occurred in March 2020, 
-- reaching 6,445,100, followed by a peak in February 2020 at 6,423,700, 
-- indicating strong performance in early 2020. 
-- Conversely, October 2019 and April 2020 had lower sales, with 
-- 3,959,100 and 4,893,700 respectively, showing some variability. 
-- The data for May 2020 is incomplete, resulting in an unusually 
-- low total of 308,400, which does not reflect the actual sales performance. 
-- Overall, the trends suggest strong sales in early 2020, with some fluctuations 
-- in the latter half of 2019 and incomplete data affecting May 2020's results.


-- Breakdown of Query:
-- The GROUP BY clause groups the results by the month and year 
-- string created using TO_CHAR(order_date, 'Mon, YYYY'). 

-- This means that for each unique month and year combination, all the 
-- corresponding orders are grouped together.

-- Inside each group, there are multiple order_date values. 
-- The MIN(order_date) function finds the minimum (earliest) 
-- order_date value within each group.

-- The ORDER BY clause then uses the minimum order_date for each group 
-- to sort the results chronologically. 

-- This ensures that the output is ordered from the earliest month 
-- to the most recent month, even though the grouping is done based 
-- on the month and year string.





-- 3. Calculate the total sales for each pastry product on a monthly basis. 
-- From the results, identify and return the top 3 selling pastry products 
-- for each month, including the month and year, the product name, 
-- and the corresponding total sales amount. 
-- Ensure that the output is ordered chronologically by month.
-- Do the same for beverage products

-- FOR PASTRY PRODUCTS
	

WITH pastry_cte AS (
    SELECT 
        o.order_date,
        TO_CHAR(o.order_date, 'Mon YYYY') AS month,
        p.name AS product_name,
        (s.quantity * p.price) AS amount
    FROM 
        orders o
    JOIN 
        sales s ON o.order_id = s.order_id
    JOIN 
        products p ON s.product_id = p.product_id
    WHERE 
        p.category = 'pastry'
),
monthly_sales AS (
    SELECT 
        TO_DATE(TO_CHAR(order_date, 'YYYY-MM-01'), 'YYYY-MM-DD') AS month_date,
        product_name,
        SUM(amount) AS total_sales
    FROM 
        pastry_cte
    GROUP BY 
        month_date, product_name
)
, ranked_sales AS (
    SELECT 
        month_date,
        product_name,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY month_date ORDER BY total_sales DESC) AS rank
    FROM 
        monthly_sales
)
SELECT 
    TO_CHAR(month_date, 'Mon YYYY') AS month,
    product_name,
    total_sales
FROM 
    ranked_sales
WHERE 
    rank <= 3
ORDER BY 
    month_date ASC;


-- Output:
-- "month"	"product_name"	"total_sales"
-- "Jul 2019"	"angbutter"	897600
-- "Jul 2019"	"tiramisu croissant"	312000
-- "Jul 2019"	"croissant"	280000
-- "Aug 2019"	"angbutter"	2064000
-- "Aug 2019"	"croissant"	528500
-- "Aug 2019"	"tiramisu croissant"	369600
-- "Sep 2019"	"angbutter"	1617600
-- "Sep 2019"	"croissant"	395500
-- "Sep 2019"	"tiramisu croissant"	364800
-- "Oct 2019"	"angbutter"	1195200
-- "Oct 2019"	"tiramisu croissant"	326400
-- "Oct 2019"	"croissant"	322000
-- "Nov 2019"	"angbutter"	1382400
-- "Nov 2019"	"plain bread"	406000
-- "Nov 2019"	"tiramisu croissant"	374400
-- "Dec 2019"	"angbutter"	1507200
-- "Dec 2019"	"tiramisu croissant"	561600
-- "Dec 2019"	"plain bread"	353500
-- "Jan 2020"	"angbutter"	1440000
-- "Jan 2020"	"tiramisu croissant"	475200
-- "Jan 2020"	"plain bread"	339500
-- "Feb 2020"	"angbutter"	1876800
-- "Feb 2020"	"tiramisu croissant"	532800
-- "Feb 2020"	"plain bread"	479500
-- "Mar 2020"	"angbutter"	1934400
-- "Mar 2020"	"tiramisu croissant"	633600
-- "Mar 2020"	"plain bread"	602000
-- "Apr 2020"	"angbutter"	1492800
-- "Apr 2020"	"tiramisu croissant"	542400
-- "Apr 2020"	"plain bread"	367500
-- "May 2020"	"angbutter"	91200
-- "May 2020"	"tiramisu croissant"	43200
-- "May 2020"	"croissant"	21000



-- Insights and Summary for Pastry Products:
-- Dominance of Angbutter: "Angbutter" consistently leads in sales every month, 
-- with its highest sales reaching 2,064,000 in August 2019. This product is evidently 
-- a customer favorite, maintaining the top spot throughout the observed period.

-- Strong Performers: "Tiramisu Croissant" and "Croissant" are also strong performers. 
-- "Tiramisu Croissant" frequently secures the second or third spot, with notable sales 
-- peaks such as 633,600 in March 2020. "Croissant" also shows solid sales, especially 
-- in months like August 2019 with 528,500.

-- Introduction of Plain Bread: In November 2019, "Plain Bread" makes its first 
-- appearance in the top three and continues to perform well in subsequent months. 
-- This indicates a growing popularity and a possible shift in customer preferences 
-- or introduction of new products.

-- Seasonal Trends: The data reveals seasonal sales patterns, with significant 
-- increases during certain months. For instance, "Angbutter" sees a spike in sales 
-- in February 2020, suggesting higher demand during this period.

-- Overall, "Angbutter" is the dominant pastry product, with "Tiramisu Croissant" 
-- and "Croissant" also showing strong and consistent sales. The introduction 
-- and rising popularity of "Plain Bread" highlight evolving customer preferences 
-- and potential areas for product focus and marketing.



-- Breakdown of Query:
-- Convert order_date to a month string:
-- TO_CHAR(o.order_date, 'Mon YYYY') AS month converts the order date 
-- to a month string for display.

-- Convert order_date to the first day of the month:
-- TO_DATE(TO_CHAR(order_date, 'YYYY-MM-01'), 'YYYY-MM-DD') AS month_date 
-- ensures proper date format for sorting.

-- Group by and aggregate sales:
-- The monthly_sales CTE groups by month_date and product_name, 
-- and sums the amount.

-- Rank products by sales within each month:
-- The ranked_sales CTE ranks products by total_sales within each month_date.

-- Final select and order by:
-- The final query converts month_date back to a string for display 
-- and sorts the results by month_date to ensure chronological order.




-- FOR BEVERAGE PRODUCTS


WITH beverage_cte AS (
    SELECT 
        o.order_date,
        TO_CHAR(o.order_date, 'Mon YYYY') AS month,
        p.name AS product_name,
        (s.quantity * p.price) AS amount
    FROM 
        orders o
    JOIN 
        sales s ON o.order_id = s.order_id
    JOIN 
        products p ON s.product_id = p.product_id
    WHERE 
        p.category = 'beverage'
),
monthly_sales AS (
    SELECT 
        TO_DATE(TO_CHAR(order_date, 'YYYY-MM-01'), 'YYYY-MM-DD') AS month_date,
        product_name,
        SUM(amount) AS total_sales
    FROM 
        beverage_cte
    GROUP BY 
        month_date, product_name
)
, ranked_sales AS (
    SELECT 
        month_date,
        product_name,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY month_date ORDER BY total_sales DESC) AS rank
    FROM 
        monthly_sales
)
SELECT 
    TO_CHAR(month_date, 'Mon YYYY') AS month,
    product_name,
    total_sales
FROM 
    ranked_sales
WHERE 
    rank <= 3
ORDER BY 
    month_date ASC;
	
	
-- Ouput:
-- "month"	"product_name"	"total_sales"
-- "Jul 2019"	"americano"	104000
-- "Jul 2019"	"vanila latte"	81000
-- "Jul 2019"	"milk tea"	45000
-- "Aug 2019"	"americano"	184000
-- "Aug 2019"	"caffe latte"	121500
-- "Aug 2019"	"vanila latte"	103500
-- "Sep 2019"	"americano"	176000
-- "Sep 2019"	"vanila latte"	90000
-- "Sep 2019"	"milk tea"	76500
-- "Oct 2019"	"americano"	172000
-- "Oct 2019"	"vanila latte"	121500
-- "Oct 2019"	"caffe latte"	76500
-- "Nov 2019"	"americano"	160000
-- "Nov 2019"	"caffe latte"	130500
-- "Nov 2019"	"vanila latte"	117000
-- "Dec 2019"	"americano"	260000
-- "Dec 2019"	"caffe latte"	117000
-- "Dec 2019"	"milk tea"	99000
-- "Jan 2020"	"americano"	176000
-- "Jan 2020"	"milk tea"	81000
-- "Jan 2020"	"vanila latte"	76500
-- "Feb 2020"	"americano"	344000
-- "Feb 2020"	"vanila latte"	189000
-- "Feb 2020"	"milk tea"	121500
-- "Mar 2020"	"americano"	268000
-- "Mar 2020"	"caffe latte"	171000
-- "Mar 2020"	"vanila latte"	153000
-- "Apr 2020"	"americano"	188000
-- "Apr 2020"	"caffe latte"	81000
-- "Apr 2020"	"vanila latte"	76500
-- "May 2020"	"americano"	20000
-- "May 2020"	"caffe latte"	9000
-- "May 2020"	"berry ade"	4500


-- Insights and Summary for Beverage products:
-- Consistent Top Seller: "Americano" consistently ranks as the top-selling 
-- beverage each month, with its highest sales in February 2020 at 344,000. 
-- This suggests a strong and steady demand for this product.

-- Stable Performance: "Vanila Latte" frequently appears in the top three, 
-- maintaining a steady performance with notable peaks, such as in February 2020 
-- with sales of 189,000. This indicates it is a popular choice among customers.

-- Variation in the Third Spot: The third highest-selling product varies 
-- more compared to the top two. While "Milk Tea" often holds this position, 
-- other beverages like "Caffe Latte" and "Berry Ade" occasionally appear, 
-- suggesting more variability and opportunities for different beverages 
-- to gain popularity.

-- Seasonal Trends: The data reveals seasonal trends, with December 2019 seeing 
-- a significant spike in sales for beverages like "Americano" and "Caffe Latte." 
-- This might indicate higher consumption during the holiday season.

-- Incomplete Data for May 2020: The sales figures for May 2020 are noticeably lower, 
-- likely due to incomplete data, as seen with "Americano" at 20,000 and "Caffe Latte" 
-- at 9,000. This indicates a data recording issue rather than a sudden drop in sales.

-- Overall, "Americano" is the clear favorite among customers, with "Vanila Latte" 
-- also showing strong and consistent sales. The variability in the third spot highlights 
-- different customer preferences and potential areas for marketing different beverages.





-- 4. What is the total sales distribution across different 
-- product categories?


WITH category_cte AS
(
SELECT p.category AS category, SUM(s.quantity * p.price) AS total_sales
FROM sales s
JOIN products p
ON s.product_id = p.product_id
GROUP BY p.category
)
SELECT category, 
	   ROUND(CAST(100.0 * total_sales / 
				  (SELECT SUM(total_sales) FROM category_cte) AS DECIMAL(5,2)), 2) AS sales_distribution
FROM category_cte;

-- output
-- "category"	"sales_distribution"
-- "pastry"	88.33
-- "beverage"	11.67

-- pastry category make up 88.33% of the total sales,
-- while beverage accounts for a contribution of 11.67% of the total sales.




-- 5. How do sales vary across different days of the week? 
-- Are weekends busier than weekdays?


-- From Docs, converting date to day_of_week with TO_CHAR
-- select To_Char("Date", 'DAY'), * from "MyTable"; -- TUESDAY
-- select To_Char("Date", 'Day'), * from "MyTable"; -- Tuesday
-- select To_Char("Date", 'day'), * from "MyTable"; -- tuesday
-- select To_Char("Date", 'dy'), * from "MyTable";  -- tue
-- select To_Char("Date", 'Dy'), * from "MyTable";  -- Tue
-- select To_Char("Date", 'DY'), * from "MyTable";  -- TUE
-- select To_Char("Date", 'D'), * from "MyTable";   -- 3     
-- day of the week, Sunday (1) to Saturday (7)

-- finding the sales for different days of the week

SELECT TO_CHAR(order_date, 'Day') AS day_of_week, 
	   SUM(total) AS total_sales
FROM orders
GROUP BY TO_CHAR(order_date, 'D'), TO_CHAR(order_date, 'Day')
ORDER BY total_sales DESC;


-- Output:
-- "day_of_week"	"total_sales"
-- "Sunday   "	11287500
-- "Saturday "	9098000
-- "Friday   "	8177700
-- "Thursday "	8140700
-- "Wednesday"	7590600
-- "Monday   "	6887000
-- "Tuesday  "	56000


-- Summary of output:
-- Weekends are Busier: The results show that Sundays and Saturdays have the 
-- highest total sales, indicating that weekends are busier compared to weekdays.

-- Friday as a Peak Day: Fridays also have relatively high sales, 
-- suggesting that sales start to pick up towards the end of the week.

-- Mid-Week Steadiness: Wednesday and Thursday have moderate sales, 
-- which are higher than Monday and Tuesday but lower than the weekend.

-- Low Sales on Tuesday: Tuesday has the lowest total sales by a 
-- significant margin, indicating it might be the least busy day of the week.





-- 6. Which hours of the day are the busiest in terms of number of orders? 
-- Determine the distribution of orders throughout the day by calculating 
-- the number of orders placed in each hour of the day. 
-- Output the hour and the number of orders.
-- Does this pattern differ on weekends versus weekdays?



-- each row represent a unique order in the orders table
-- finding the busiest hours of the day in terms of number of orders


SELECT TO_CHAR(order_time, 'HH12:00') AS hour_of_day, 
	   COUNT(order_id) AS num_of_orders
FROM orders
GROUP BY TO_CHAR(order_time, 'HH12:00')
ORDER BY num_of_orders DESC;

-- Output
-- "hour_of_day"	"num_of_orders"
-- "11:00"	707
-- "12:00"	552
-- "01:00"	446
-- "02:00"	343
-- "03:00"	219
-- "04:00"	125
-- "05:00"	27
-- "10:00"	1


-- finding the busiest hours of weekday and weekend

SELECT hour_of_day, SUM(CASE WHEN day_of_week = 'weekday' THEN 1 ELSE 0 END) AS weekday_orders,
					SUM(CASE WHEN day_of_week = 'weekend' THEN 1 ELSE 0 END) AS weekend_orders
FROM
(
SELECT CASE WHEN TO_CHAR(order_date, 'D') IN ('2', '3', '4', '5', '6') THEN 'weekday'
			WHEN TO_CHAR(order_date, 'D') IN ('1', '7') THEN 'weekend' END AS day_of_week,
			TO_CHAR(order_time, 'HH12:00') AS hour_of_day  
FROM orders) AS weekly_orders
GROUP BY hour_of_day
ORDER BY weekday_orders DESC, weekend_orders DESC;


-- Output:
-- "hour_of_day"	"weekday_orders"	"weekend_orders"
-- "11:00"	385	322
-- "12:00"	309	243
-- "01:00"	268	178
-- "02:00"	198	145
-- "03:00"	149	70
-- "04:00"	83	42
-- "05:00"	20	7
-- "10:00"	1	0



-- Busiest Hours:
-- Peak hours: 11:00 and 12:00 are the busiest times, suggesting a lunch-time rush.
-- 11:00: The busiest hour with 385 weekday orders and 322 weekend orders.
-- 12:00: The next busiest hour with 309 weekday orders and 243 weekend orders.
-- 01:00: Another busy hour with 268 weekday orders and 178 weekend orders.

-- Order Distribution:
-- Weekdays vs. Weekends:
-- Generally, the pattern shows higher order volumes on weekdays 
-- compared to weekends across most hours.
-- The peak hours on both weekdays and weekends are similar, 
-- mainly around late morning to early afternoon.






-- 7. Are there any products that are frequently bought together? 
-- What are the top 5 product pairs?


WITH multiple_ordered_items AS
(
SELECT order_id, COUNT(product_id) 
FROM sales
GROUP BY order_id
HAVING COUNT(product_id) > 1
)
, product_pairs AS (
SELECT s1.product_id AS product1_id, s2.product_id AS product2_id
FROM sales s1
JOIN sales s2 -- create a self-join to return all unique product pairs
ON s1.order_id = s2.order_id AND s1.product_id < s2.product_id -- ensures that each pair is unique 
WHERE s1.order_id IN (SELECT order_id FROM multiple_ordered_items)
)
, pair_counts AS (
SELECT p1.name AS product1, p2.name AS product2, COUNT(*) AS pair_count
FROM product_pairs pp 
JOIN products p1 ON p1.product_id = pp.product1_id
JOIN products p2 ON p2.product_id = pp.product2_id -- join with the products table again to retrieve the product2 names
GROUP BY p1.name, p2.name
)
SELECT product1, product2, pair_count
FROM pair_counts
ORDER BY pair_count DESC
LIMIT 5;


-- output:
-- "product1"	"product2"	"pair_count"
-- "angbutter"	"plain bread"	648
-- "angbutter"	"tiramisu croissant"	601
-- "angbutter"	"croissant"	558
-- "angbutter"	"pain au chocolat"	440
-- "angbutter"	"orange pound"	406


-- The top 5 product pairs that are frequently bought together all 
-- include "angbutter" as one of the products. 
-- "Angbutter" and "plain bread" is the most frequently bought pair, 
-- with 648 occurrences, followed by pairs with "tiramisu croissant," 
-- "croissant," "pain au chocolat," and "orange pound."


-- Breakdown of Query:
-- Create a CTE (multiple_product_orders) that selects order_ids 
-- from the sales table where the count of product_ids is greater than one

-- Create a second CTE (product_pairs) that performs a self-join on 
-- the sales table using the order_id to generate all possible 
-- unique product pairs within each order. 
-- Ensure each pair is unique by joining where product_id in 
-- s1 is less than product_id in s2.

-- Create a third CTE (pair_counts) that joins the product_pairs with 
-- the products table to get the product names. 
-- Group by the product names and count the occurrences of each product pair.

-- Query the pair_counts CTE to select the top 5 product pairs 
-- based on their count in descending order.


-- 8. Is there a correlation between the day of the week and total daily sales? 
-- Which day tends to have the highest sales?


-- finding the correlation between day of the week and total daily sales

SELECT ROUND(CORR(day_of_week, total_sales)::DECIMAL(5,2), 2) AS correlation
FROM 
(
SELECT 
  TO_CHAR(order_date, 'D')::INTEGER AS day_of_week,
  SUM(total) AS total_sales
FROM orders
GROUP BY TO_CHAR(order_date, 'D')
	) dow_sales;


-- Output
-- "correlation"
-- 0.09


-- The correlation coefficient of approximately 0.09 indicates a very 
-- weak positive relationship between the day of the week and total daily sales. 
-- This suggests that there is minimal to no linear association between 
-- the specific days of the week and the amount of sales generated.



-- finding day of the week with the highest sales

SELECT 
  TO_CHAR(order_date, 'Day') AS day_of_week,
  SUM(total) AS total_sales
FROM orders
GROUP BY TO_CHAR(order_date, 'Day')
ORDER BY total_sales DESC;



-- Output
-- "day_of_week"	"total_sales"
-- "Sunday   "	11287500
-- "Saturday "	9098000
-- "Friday   "	8177700
-- "Thursday "	8140700
-- "Wednesday"	7590600
-- "Monday   "	6887000
-- "Tuesday  "	56000

-- Based on the total sales figures, Sunday tends to have the 
-- highest sales, with a total of 11,287,500.





-- 9. What percentage of orders include at least one beverage item 
-- (like americano, latte, etc.)?

-- percentage of orders with at least 1 beverage item

SELECT ROUND(100.0 * beverage_orders / (SELECT COUNT(order_id) FROM orders), 2) 
	   AS pct_of_orders_w_beverages
FROM
(
SELECT COUNT(DISTINCT s.order_id) AS beverage_orders
FROM sales s
JOIN products p
ON s.product_id = p.product_id
WHERE p.name IN (SELECT name FROM products WHERE category = 'beverage')
) AS beverage_count


-- Output
-- "pct_of_orders_w_beverages"
-- 35.87

-- 35.87% of all orders include at least one beverage item.




-- 10. Find the volume of orders by place. Additionally, determine the 
-- percentage of the total orders for each place relative to the 
-- overall order volume. 


WITH filtered_data AS (
SELECT o.place AS place, COUNT(DISTINCT o.order_id) AS num_of_orders
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.place
)
SELECT place, 
	   num_of_orders, 
	   ROUND(100.0 * num_of_orders / (SELECT SUM(num_of_orders) FROM filtered_data) , 2) AS pct_total_orders
FROM filtered_data
ORDER BY num_of_orders DESC;


-- Output:

-- "place"	"num_of_orders"	"pct_total_orders"
-- "Dongmyeon"	415	19.17
-- "Hoopyeong2-dong"	254	11.73
-- "Hoopyeong3-dong"	249	11.50
-- "Hoopyeong1-dong"	196	9.05
-- "Seoksa-dong"	169	7.81
-- "Toegye-dong"	146	6.74
-- "Hyoja2-dong"	143	6.61
-- "Soyang-dong"	132	6.10
-- "Sinsawoo-dong"	91	4.20
-- "Hyoja3-dong"	80	3.70
-- "Gyo-dong"	67	3.09
-- "Gangnam-dong"	52	2.40
-- "Hyoja1-dong"	50	2.31
-- "Jowoon-dong"	37	1.71
-- "Dongnae-myeon"	31	1.43
-- "Geunhwa-dong"	29	1.34
-- "Yaksamyeong-dong"	23	1.06
-- "Sindong-myeon"	1	0.05



-- Output:
-- The query shows the distribution of orders across different places, 
-- with Dongmyeon leading at 19.17% of total orders, 
-- which is significant as it's where the bakery is located.

-- The next three highest order volumes come from areas in Hoopyeong 
-- (Hoopyeong2-dong, Hoopyeong3-dong, and Hoopyeong1-dong), 
-- collectively accounting for about 32.28% of orders, which is 
-- notable given that Hoopyeong-dong is nearby.

-- There's a considerable drop-off in order volume after the top 8 places, 
-- with the remaining locations each contributing less than 5% of total orders, 
-- indicating a concentration of business in a few key areas.








--