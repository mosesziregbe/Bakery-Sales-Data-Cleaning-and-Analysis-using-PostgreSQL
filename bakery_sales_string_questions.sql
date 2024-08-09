
-- PART C (String Manipulation Questions)


SET search_path TO bakery_schema;

SHOW search_path;


-- 1.  Generate a daily sales summary where the day of the week is represented 
-- by its first three letters, followed by the date and total sales. 
-- For example: "MON 2019-07-01: ₩1234.56". 


SELECT CONCAT(TO_CHAR(date, 'DY'), ' ', date, ':', '  ₩', daily_sales) AS sales_summary
FROM
(
SELECT order_date AS date, SUM(total) AS daily_sales
FROM orders
GROUP BY order_date
ORDER BY MIN(order_date)
) agg_daily_sales



-- Output (first few rows):
-- "sales_summary"
-- "THU 2019-07-11:  ₩39600"
-- "FRI 2019-07-12:  ₩58000"
-- "SAT 2019-07-13:  ₩117400"
-- "SUN 2019-07-14:  ₩212000"
-- "MON 2019-07-15:  ₩30900"
-- "WED 2019-07-17:  ₩74100"




-- 2. For each month, create a summary of the top 3 selling products 
-- along with their total quantities sold. The result should be presented 
-- as a table with the following columns:

-- Month: The month for which the data is summarized (format: YYYY-MM)
-- TopSellersSummary: A string representing the top 3 selling products 
-- for that month, formatted as "Product1 (qty), Product2 (qty), Product3 (qty)". 
-- The products should be ordered by their total quantity sold in descending order. 
-- If there are fewer than 3 products sold in a month, 
-- include only the available products.

-- Example output:
-- Month---|---top_sellers_summary--|
-- 2023-01 | product1 (150), product2 (120) | product3 (95)
-- 2023-02 | product1 (180), product3 (160) | product4 (120)



WITH ranked_product_sales AS (
    SELECT 
        TO_CHAR(o.order_date, 'YYYY - MM') AS month,
        p.name AS product_name,
        SUM(s.quantity) AS qty,
		DENSE_RANK() OVER(PARTITION BY TO_CHAR(o.order_date, 'YYYY - MM') ORDER BY SUM(s.quantity) DESC) AS rank
    FROM 
        orders o
    JOIN 
        sales s ON o.order_id = s.order_id
    JOIN 
        products p ON s.product_id = p.product_id
    WHERE 
        p.category = 'pastry'
	GROUP BY TO_CHAR(o.order_date, 'YYYY - MM'), product_name
	)
	SELECT month, 
		   STRING_AGG(CONCAT(product_name, ' (', qty, ')'), ', ') AS top_sellers_summary
	FROM ranked_product_sales
	WHERE rank <= 3
	GROUP BY month;




-- Output:
-- "month"	"top_sellers_summary"
-- "2019 - 07"	"angbutter (187), croissant (80), tiramisu croissant (65)"
-- "2019 - 08"	"angbutter (430), croissant (151), plain bread (105)"
-- "2019 - 09"	"angbutter (337), croissant (113), pain au chocolat (79), plain bread (79)"
-- "2019 - 10"	"angbutter (249), croissant (92), pain au chocolat (80)"
-- "2019 - 11"	"angbutter (288), plain bread (116), croissant (92)"
-- "2019 - 12"	"angbutter (314), tiramisu croissant (117), plain bread (101)"
-- "2020 - 01"	"angbutter (300), tiramisu croissant (99), plain bread (97)"
-- "2020 - 02"	"angbutter (391), plain bread (137), croissant (128)"
-- "2020 - 03"	"angbutter (403), plain bread (172), tiramisu croissant (132)"
-- "2020 - 04"	"angbutter (311), tiramisu croissant (113), plain bread (105)"
-- "2020 - 05"	"angbutter (19), tiramisu croissant (9), croissant (6)"



-- Summary:
-- The query provides a monthly summary of the top 3 selling pastry products, 
-- including their total quantities sold.
-- The output shows that "angbutter" is consistently the top-selling product 
-- across all months, with the highest quantity of 430 units sold in August 2019.
-- The top 3 products vary across months, with "croissant", "tiramisu croissant", 
-- "plain bread", and "pain au chocolat" also appearing in the top 3 lists.



-- Breakdown of the query:
-- The query uses a Common Table Expression (CTE) called "ranked_product_sales" 
-- to calculate the total quantity sold for each product in each month and rank 
-- them in descending order using DENSE_RANK().


-- The main query then selects the month and generates a comma-separated string 
-- of the top 3 products for each month, along with their quantities, using the 
-- STRING_AGG function.
-- The WHERE clause in the main query ensures that only the top 3 ranked products 
-- for each month are included in the output.



/********* Notes **************/

-- Both RANK() and DENSE_RANK() would work in this case, but there is a 
-- slight difference between the two:

-- RANK():
-- RANK() assigns a unique rank to each row within the partition, with gaps in 
-- the ranking if there are ties.
-- For example, if the top 3 products have quantities of 100, 100, and 80, 
-- the ranks would be 1, 1, and 3.


-- DENSE_RANK():
-- DENSE_RANK() assigns a unique rank to each row within the partition, 
-- but without gaps in the ranking in case of ties.
-- For the same example, if the top 3 products have quantities of 
-- 100, 100, and 80, the ranks would be 1, 1, and 2.

-- In the context of this query, either RANK() or DENSE_RANK() would work, 
-- as the goal is to get the top 3 products for each month. The difference would 
-- only be apparent if there were ties in the quantities sold.

-- Using DENSE_RANK() is a slightly better choice because it ensures that 
-- all 3 products are always displayed, even if there are ties in the quantities. 
-- With RANK(), if there was a tie for the 3rd spot, only 2 products would be 
-- shown for that month.

-- So, while both RANK() and DENSE_RANK() would work, DENSE_RANK() is the 
-- more appropriate choice for this particular use case.

-- For example, 

-- "2019 - 09"    "angbutter (337), croissant (113), pain au chocolat (79), plain bread (79)"

-- Let's examine what would happen in that specific row if we had used 
-- RANK() instead of DENSE_RANK().

-- Even if the query had used RANK() instead of DENSE_RANK(), the final output would 
-- still have included the 4 products for the "2019 - 09" row, 
-- because the WHERE clause in the main query is checking for rank <= 3.

-- So, regardless of whether RANK() or DENSE_RANK() is used in the CTE, 
-- the final output would have been the same:

-- "2019 - 09" "angbutter (337), croissant (113), pain au chocolat (79), plain bread (79)"

-- The WHERE clause WHERE rank <= 3 is the key factor here, and it ensures that all 
-- top 3 (or more in case of ties) products are included in the final output, 
-- regardless of the ranking function used in the CTE.


/********* Notes **************/





-- 3. Generate a report of all orders that include both a pastry and a beverage. 
-- Display the order ID, date, and create a new column that lists pastries, followed 
-- by " with ", then beverages.


-- find orders that contains both pastry and beverage

-- CTE to gather relevant data from orders, sales, and products tables
WITH relevant_data AS (
    SELECT o.order_id, o.order_date, p.name, p.category
    FROM orders o
    JOIN sales s ON o.order_id = s.order_id
    JOIN products p ON s.product_id = p.product_id 
)
-- CTE to find orders that contain both pastry and beverage
, cte_pastry_beverage AS (
    SELECT order_id
    FROM relevant_data 
    WHERE category = 'pastry'
    INTERSECT
    SELECT order_id
    FROM relevant_data
    WHERE category = 'beverage'
)
-- Main query to aggregate pastries and beverages for each qualifying order
SELECT 
    order_id, 
    order_date,
    -- Aggregate pastry names
    CONCAT(STRING_AGG(CASE WHEN category = 'pastry' THEN name END, ', '),
		   ' with ',
    -- Aggregate beverage names
    STRING_AGG(CASE WHEN category = 'beverage' THEN name END, ', ')) AS order_details
FROM relevant_data
WHERE order_id IN (SELECT order_id FROM cte_pastry_beverage)
GROUP BY order_id, order_date
ORDER BY order_date, order_id;


-- Output (first 5 rows):
-- "order_id"	"order_date"	"order_details"
-- 1	"2019-07-11"	"tiramisu croissant, angbutter with vanila latte, americano"
-- 4	"2019-07-13"	"plain bread, angbutter with vanila latte"
-- 6	"2019-07-13"	"angbutter with vanila latte, milk tea"
-- 7	"2019-07-13"	"orange pound, angbutter with vanila latte"
-- 11	"2019-07-14"	"tiramisu croissant, angbutter with vanila latte"



-- Breakdown of Query:
-- Common Table Expressions (CTEs):
-- relevant_data: Joins the orders, sales, and products tables to 
-- gather necessary information.
-- cte_pastry_beverage: Uses INTERSECT to find orders containing 
-- both pastries and beverages.

-- INTERSECT operation:
-- The INTERSECT part is crucial. It finds the intersection of two sets:
-- Orders containing pastries and Orders containing beverages
-- This ensures that only orders with both categories are selected.

-- Main Query:
-- Filters orders using the results from cte_pastry_beverage.
-- Groups results by order_id and order_date.
-- Uses STRING_AGG with CASE WHEN for concatenation:
-- This part does two things:
-- a) Aggregates pastry names:
-- STRING_AGG(CASE WHEN category = 'pastry' THEN name END, ', ')
-- b) Aggregates beverage names:
-- STRING_AGG(CASE WHEN category = 'beverage' THEN name END, ', ')
-- The CASE WHEN ensures only items of the correct category are 
-- included in each aggregation. 

-- STRING_AGG concatenates these names with a comma separator.

-- Finally, CONCAT joins the pastry and beverage lists with " with " in between.






-- 4. Generate a daily product diversity report. For each day, provide a 
-- single column that lists all unique products sold, separated by commas 
-- and ordered alphabetically. Output the date and the product list.



SELECT o.order_date, STRING_AGG(DISTINCT p.name, ', ') AS products_sold
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
GROUP BY o.order_date;




-- Output (first few rows):

-- "order_date"	"products_sold"
-- "2019-07-11"	"americano, angbutter, orange pound, tiramisu croissant, vanila latte"
-- "2019-07-12"	"tiramisu croissant"
-- "2019-07-13"	"angbutter, cacao deep, milk tea, orange pound, plain bread, tiramisu croissant, vanila latte"


-- Query breakdown:
-- The query joins the orders, sales, and products tables to connect order dates 
-- with the products sold on those dates.
-- It then uses GROUP BY to organize the data by date and STRING_AGG with 
-- DISTINCT to create a comma-separated list of unique products sold each day, 
-- ordered alphabetically by default.






-- 5. Create a place ID for each place by taking the first 6 letters
-- of the place name (converted to uppercase) and concatenating it with
-- the last 3 digits of their first order ID. Output as (place-digit)
-- For example, if the place name is "Seoksa-dong" and the
-- first order ID is 12345, the output would be: (SEOKSA-345).
-- If the place name contains a hyphen (-), remove it before taking the first 6 letters.
-- For example, if the place name is "Hyoja1-dong" and the
-- first order ID is 67890, the output would be: (HYOJA1-890).


SELECT place, 
	   CONCAT(place_name, '-', RIGHT(order_id::TEXT, 3)) AS place_id
FROM
(
SELECT order_id, place, 
	   UPPER(LEFT(REPLACE(place, '-', ''), 6)) AS place_name, 
	   ROW_NUMBER() OVER(PARTITION BY place ORDER BY order_id) AS row_num
FROM orders
WHERE place != 'NA'
) row_orders
WHERE row_num = 1


-- Output:

-- "place"	"place_id"
-- "Dongmyeon"	"DONGMY-264"
-- "Dongnae-myeon"	"DONGNA-338"
-- "Gangnam-dong"	"GANGNA-276"
-- "Geunhwa-dong"	"GEUNHW-327"
-- "Gyo-dong"	"GYODON-285"
-- "Hoopyeong1-dong"	"HOOPYE-257"
-- "Hoopyeong2-dong"	"HOOPYE-259"
-- "Hoopyeong3-dong"	"HOOPYE-272"
-- "Hyoja1-dong"	"HYOJA1-280"
-- "Hyoja2-dong"	"HYOJA2-300"
-- "Hyoja3-dong"	"HYOJA3-255"
-- "Jowoon-dong"	"JOWOON-283"
-- "Seoksa-dong"	"SEOKSA-260"
-- "Sindong-myeon"	"SINDON-925"
-- "Sinsawoo-dong"	"SINSAW-275"
-- "Soyang-dong"	"SOYANG-262"
-- "Toegye-dong"	"TOEGYE-263"
-- "Yaksamyeong-dong"	"YAKSAM-301"





-- 6. For each product, create a string that represents its sales trend 
-- over the last 7 days it was sold. The output should include a new column 
-- with a string of 7 characters, each representing whether sales went up, down, 
-- or stayed the same compared to the previous day.
-- Concatenate the quantity sold with the trend.
-- Use 'U' for up (sales increased), 'D' for down (sales decreased), 
-- and 'S' for same. For example: "5S-7U-4D-4S-3D-3S-7U".


WITH ranked_sales AS (
    -- Step 1: Rank the sales dates for each product
    SELECT 
        p.product_id, 
        p.name,
        o.order_date, 
        SUM(s.quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY p.product_id ORDER BY o.order_date DESC) AS rn
    FROM 
        products p
    JOIN 
        sales s ON p.product_id = s.product_id
    JOIN 
        orders o ON s.order_id = o.order_id
    GROUP BY 
        p.product_id, p.name, o.order_date
)
, last_7_sales AS (
    -- Step 2: Filter to keep only the last 7 unique days of sales for each product
    SELECT 
        product_id, 
        name, 
        order_date, 
        total_quantity,
        LAG(total_quantity) OVER (PARTITION BY product_id ORDER BY order_date) AS previous_total_quantity
    FROM 
        ranked_sales
    WHERE 
        rn <= 7
)
, sales_trend AS (
    -- Step 3: Calculate the trend for each product
    SELECT 
        product_id, 
        name,
        order_date,
        CASE 
            WHEN total_quantity > previous_total_quantity THEN CONCAT(total_quantity, 'U')
            WHEN total_quantity < previous_total_quantity THEN CONCAT(total_quantity, 'D')
            ELSE CONCAT(total_quantity, 'S')
        END AS trend
    FROM 
        last_7_sales
)
-- Step 4: Concatenate the trends
SELECT 
    product_id, 
    name, 
    STRING_AGG(trend, ' - ') AS trend
FROM 
    sales_trend
GROUP BY 
    product_id, name
ORDER BY 
    product_id;



-- Output:

-- "product_id"	"name"	"trend"
-- 1	"angbutter"	"18S - 20U - 11D - 7D - 7S - 15U - 4D"
-- 2	"plain bread"	"6S - 6S - 7U - 7S - 3D - 4U - 1D"
-- 3	"jam"	"1S - 1S - 2U - 2S - 1D - 2U - 1D"
-- 4	"croissant"	"6S - 9U - 8D - 2D - 1D - 5U - 1D"
-- 5	"tiramisu croissant"	"6S - 4D - 8U - 4D - 4S - 6U - 3D"
-- 6	"cacao deep"	"3S - 2D - 1D - 6U - 2D - 1D - 1S"
-- 7	"pain au chocolat"	"4S - 3D - 6U - 1D - 2U - 3U - 2D"
-- 8	"almond croissant"	"1S - 1S - 3U - 2D - 1D - 1S - 2U"
-- 9	"gateau chocolat"	"1S - 2U - 1D - 1S - 2U - 2S - 1D"
-- 10	"pandoro"	"3S - 4U - 1D - 8U - 1D - 1S - 1S"
-- 11	"cheese cake"	"1S - 1S - 1S - 1S - 1S - 1S - 2U"
-- 12	"orange pound"	"4S - 2D - 3U - 1D - 2U - 3U - 1D"
-- 13	"wiener"	"1S - 2U - 3U - 7U - 1D - 3U - 1D"
-- 14	"tiramisu cake"	"3S - 1D - 1S - 1S - 1S"
-- 15	"merinque cookies"	"1S - 1S - 2U - 1D - 1S - 1S - 1S"
-- 16	"americano"	"2S - 4U - 3D - 1D - 2U - 4U - 1D"
-- 17	"caffe latte"	"2S - 1D - 1S - 3U - 1D - 1S - 1S"
-- 18	"milk tea"	"1S - 1S - 1S - 1S - 1S - 1S - 1S"
-- 19	"lemon ade"	"1S - 1S - 1S - 1S - 1S - 3U - 1D"
-- 20	"vanila latte"	"1S - 1S - 3U - 1D - 1S - 1S - 1S"
-- 21	"berry ade"	"1S - 1S - 1S - 1S - 1S - 1S - 1S"




-- Summary:
-- 1. The query provides a detailed view of the sales trends for each 
-- product over the last 7 days, displaying the quantity sold and 
-- whether the sales went up, down, or remained the same compared to the previous day.

-- 2. The output reveals that some products, like "angbutter" and "plain bread," 
-- have consistent sales with a mix of increases, decreases, and stable days, 
-- while other products, like "tiramisu cake" and "cheese cake," 
-- have more sporadic sales patterns.

-- 3. The sales trend information can help the bakery identify products 
-- with stable or growing demand, as well as those that may need 
-- further analysis or adjustments to their production and inventory management 
-- to optimize sales and satisfy customer preferences.



-- Breakdown of the Query:

-- Ranked Sales (Step 1):
-- This CTE uses the ROW_NUMBER() OVER (PARTITION BY p.product_id ORDER BY o.order_date DESC) 
-- function to rank the sales dates for each product in descending order.
-- This allows us to identify the most recent 7 days of sales for each product.

-- Last 7 Sales (Step 2):
-- The second CTE, last_7_sales, filters the data from the previous CTE 
-- to keep only the last 7 unique days of sales for each product.
-- It also uses the LAG(total_quantity) OVER (PARTITION BY product_id ORDER BY order_date) 
-- function to get the previous day's total quantity for each product.

-- Sales Trend (Step 3):
-- This CTE calculates the sales trend for each product by comparing 
-- the current day's total quantity to the previous day's total quantity.
-- It uses a CASE statement to determine whether the sales went up 
-- ('U'), down ('D'), or stayed the same ('S'), and concatenates the 
-- quantity with the trend.

-- Final Output (Step 4):
-- The final query aggregates the trend information from the sales_trend 
-- CTE using STRING_AGG() to create a comma-separated string of the 
-- last 7 days' trends for each product.
-- The results are ordered by product_id.





-- 7.Write a query that generates a descriptive string for each order 
-- in the sales table for the last 60 days. The output should include 
-- the order_id, date, a concatenated string of all the products sold in that 
-- order (including the quantity and product name),
-- and the total for that order.
-- The format of the concatenated string should be:
-- "2 x angbutter, 3 x croissant, 1 x lemon ade"
-- The total for each order should be calculated based on the 
-- quantity and price of each product sold.


-- date arithmetic from Docs:
-- select date('08/30/2021') + 180  -- it will give next 180 days date
-- select current_date + 180  -- it will give next 180 days date
-- select current_date - 180  -- it will give before 180 days date


WITH filtered_data AS (
SELECT o.order_id, o.order_date, p.name, s.quantity, p.price, 
       s.quantity * p.price AS product_sum
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
WHERE o.order_date BETWEEN 
	((SELECT MAX(order_date) FROM orders) - 60) AND (SELECT MAX(order_date) FROM orders)
)
SELECT order_id, order_date, 
	   STRING_AGG(CONCAT(quantity, ' x ', name), ', ') AS order_details, 
	   SUM(product_sum) AS total
FROM filtered_data
GROUP BY order_id, order_date;



-- Output (first and last few rows):	

-- "order_id"	"order_date"	"order_details"	"total"
-- 1886	"2020-03-05"	"1 x plain bread, 1 x tiramisu croissant, 1 x angbutter"	13100
-- 1887	"2020-03-05"	"1 x plain bread, 1 x caffe latte, 2 x tiramisu croissant, 3 x angbutter, 1 x pandoro"	36500
-- 1888	"2020-03-05"	"2 x cacao deep, 1 x tiramisu croissant"	12800
-- 1889	"2020-03-05"	"1 x americano, 2 x jam, 1 x vanila latte, 2 x plain bread"	18500
-- ....
-- 2417	"2020-05-02"	"1 x americano, 1 x tiramisu croissant, 1 x berry ade, 1 x angbutter"	18100
-- 2418	"2020-05-02"	"1 x plain bread, 1 x angbutter, 1 x cacao deep"	12300
-- 2419	"2020-05-02"	"1 x croissant, 1 x cheese cake, 1 x tiramisu croissant"	13300
-- 2420	"2020-05-02"	"1 x tiramisu croissant, 1 x pain au chocolat, 2 x angbutter, 1 x orange pound"	22400








-- 8.Assuming that the delivery fee for each order can be calculated 
-- by subtracting the total sales amount from the total price of all 
-- products sold in that order, write a query to calculate the average 
-- delivery fee for each place from the orders table. 
-- The output should include the place and the average delivery fee, 
-- formatted to two decimal places.



WITH total_cte AS (
SELECT o.order_id, 
	   o.place, 
	   SUM(o.total) OVER(PARTITION BY o.order_id) - SUM(s.quantity * p.price) AS delivery_fee
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.order_id, o.place
)
SELECT place, ROUND(AVG(delivery_fee), 2) AS avg_delivery_fee
FROM total_cte
GROUP BY place
ORDER BY avg_delivery_fee;



-- Output:
-- "place"	"avg_delivery_fee"
-- "Sindong-myeon"	0.00
-- "Hyoja1-dong"	1846.00
-- "Hyoja2-dong"	1861.54
-- "Dongmyeon"	1885.78
-- "Jowoon-dong"	1886.49
-- "Dongnae-myeon"	1964.52
-- "Hoopyeong2-dong"	1988.58
-- "Soyang-dong"	1996.97
-- "Hoopyeong1-dong"	2001.53
-- "Gyo-dong"	2013.43
-- "Hoopyeong3-dong"	2055.82
-- "Geunhwa-dong"	2148.28
-- "Hyoja3-dong"	2158.75
-- "Yaksamyeong-dong"	2504.35
-- "Gangnam-dong"	2542.31
-- "Seoksa-dong"	2673.37
-- "Toegye-dong"	2829.45
-- "Sinsawoo-dong"	3403.30



-- Summary:
-- The query calculates the average delivery fee for each place, 
-- with fees ranging from 0.00 to 3403.30 (in the local currency).

-- The average delivery fee for Dongmyeon is 1885.78, which is relatively 
-- low compared to many other areas. This makes sense as it's where the bakery 
-- is located, so delivery distances are likely shorter, resulting in lower fees.

-- The Hoopyeong areas (Hoopyeong1-dong, Hoopyeong2-dong, Hoopyeong3-dong) have 
-- average delivery fees ranging from 1988.58 to 2055.82. These fees are slightly higher 
-- than Dongmyeon but still relatively low, which aligns with their proximity to the bakery. 
-- The small increase might be due to the slightly longer distance compared to Dongmyeon.

-- Sindong-myeon has the lowest average delivery fee at 0.00, 
-- which could indicate either free delivery or potentially an anomaly 
-- in the data for this location.
-- The highest average delivery fees are found in Sinsawoo-dong (3403.30), 
-- Toegye-dong (2829.45), and Seoksa-dong (2673.37), suggesting these areas 
-- might be further from the bakery or have other factors increasing delivery costs.




-- 9.Using the same logic for calculating the delivery fee 
-- (total - (quantity * price)), write a query that categorizes 
-- the delivery fees into ranges: "Low" for fees less than 2000, 
-- "Medium" for fees between 2000 and 2500, and "High" for fees 
-- above 2500. Return the count of orders in each delivery fee category.


WITH total_cte AS (
SELECT o.order_id, 
	   o.place, 
	   SUM(o.total) OVER(PARTITION BY o.order_id) - SUM(s.quantity * p.price) AS delivery_amt
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.order_id, o.place
)
, delivery_cte AS (
SELECT place, ROUND(AVG(delivery_amt), 2) AS delivery_fee
FROM total_cte
GROUP BY place
)
SELECT place, delivery_fee, CASE WHEN delivery_fee < 2000 THEN 'Low'
				 WHEN delivery_fee BETWEEN 2000 AND 2500 THEN 'Medium'
				 WHEN delivery_fee > 2500 THEN 'High'
				 END AS delivery_fee_category
FROM delivery_cte
ORDER BY delivery_fee;




-- Output:

-- "place"	"delivery_fee"	"delivery_fee_category"
-- "Sindong-myeon"	0.00	"Low"
-- "Hyoja1-dong"	1846.00	"Low"
-- "Hyoja2-dong"	1861.54	"Low"
-- "Dongmyeon"	1885.78	"Low"
-- "Jowoon-dong"	1886.49	"Low"
-- "Dongnae-myeon"	1964.52	"Low"
-- "Hoopyeong2-dong"	1988.58	"Low"
-- "Soyang-dong"	1996.97	"Low"
-- "Hoopyeong1-dong"	2001.53	"Medium"
-- "Gyo-dong"	2013.43	"Medium"
-- "Hoopyeong3-dong"	2055.82	"Medium"
-- "Geunhwa-dong"	2148.28	"Medium"
-- "Hyoja3-dong"	2158.75	"Medium"
-- "Yaksamyeong-dong"	2504.35	"High"
-- "Gangnam-dong"	2542.31	"High"
-- "Seoksa-dong"	2673.37	"High"
-- "Toegye-dong"	2829.45	"High"
-- "Sinsawoo-dong"	3403.30	"High"



-- Return the count of orders in each delivery fee category.

WITH total_cte AS (
SELECT o.order_id, 
	   o.place, 
	   SUM(o.total) OVER(PARTITION BY o.order_id) - SUM(s.quantity * p.price) AS delivery_amt
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.order_id, o.place
)
, delivery_cte AS (
SELECT place, ROUND(AVG(delivery_amt), 2) AS delivery_fee
FROM total_cte
GROUP BY place
)
, delivery_category_cte AS (
SELECT place, delivery_fee, CASE WHEN delivery_fee < 2000 THEN 'Low'
				 WHEN delivery_fee BETWEEN 2000 AND 2500 THEN 'Medium'
				 WHEN delivery_fee > 2500 THEN 'High' 
				 END AS delivery_fee_category
FROM delivery_cte d
)
, orders_cte AS (
SELECT o.place AS place, COUNT(DISTINCT o.order_id) AS num_of_orders
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
WHERE o.place != 'NA'
GROUP BY o.place
)
SELECT d.delivery_fee_category AS delivery_category, SUM(oc.num_of_orders) AS orders_distribution
FROM delivery_category_cte d
JOIN orders_cte oc
ON d.place = oc.place
GROUP BY d.delivery_fee_category
ORDER BY orders_distribution DESC;




-- Output:
-- "delivery_category"	"orders_distribution"
-- "Low"	1063
-- "Medium"	621
-- "High"	481


-- Summary:
-- The majority of orders (1063) fall into the "Low" delivery fee category, 
-- which aligns with the earlier observation that the bakery's location 
-- and nearby areas have lower delivery fees. The "Medium" category accounts 
-- for 621 orders, while the "High" category has the least number of orders at 481, 
-- suggesting that most of the bakery's business comes from areas with 
-- more affordable delivery fees.







-- 10. Write a query to find the best-selling pastry and beverage product 
-- for each month based on total quantity sold. The output should include 
-- the month and year, along with the best pastry 
-- (formatted as "[product_name] (qty)") and the best beverage 
-- (formatted as "[product_name] (qty)").
-- If there is no pastry or beverage sold in a particular month, 
-- output "No pastry sold" or "No beverage sold" respectively. 
-- The results should be ordered by month, with the highest sales first.
-- For example, the output for a particular month could look like:
-- Aug, 2019 | Best Pastry: Angbutter (200), Best Beverage: Lemon Ade (150)
-- Sep, 2019 | Best Pastry: Croissant (180), Best Beverage: No beverage sold




WITH relevant_data AS (
  SELECT TO_CHAR(o.order_date, 'Mon, YYYY') AS month,
         p.category,
         p.name,
         SUM(s.quantity) AS qty
  FROM orders o
  JOIN sales s ON o.order_id = s.order_id
  JOIN products p ON s.product_id = p.product_id
  GROUP BY TO_CHAR(o.order_date, 'Mon, YYYY'), p.category, p.name
),
ranked_sales AS (
  SELECT month,
         category,
         name,
         qty,
         RANK() OVER(PARTITION BY month, category ORDER BY qty DESC) AS rank
  FROM relevant_data
)
SELECT 
  TO_CHAR(TO_DATE(month, 'Mon, YYYY'), 'Mon, YYYY') AS month,
  COALESCE(MAX(CASE WHEN rank = 1 AND category = 'pastry' 
			   THEN CONCAT(name, ' (', qty, ')') END), 'No best pastry') AS best_pastry,
  COALESCE(MAX(CASE WHEN rank = 1 AND category = 'beverage' 
			   THEN CONCAT(name, ' (', qty, ')') END), 'No best beverage') AS best_beverage
FROM ranked_sales
GROUP BY month
ORDER BY TO_DATE(month, 'Mon, YYYY');


-- Output:
-- "month"	"best_pastry"	"best_beverage"
-- "Jul, 2019"	"angbutter (187)"	"americano (26)"
-- "Aug, 2019"	"angbutter (430)"	"americano (46)"
-- "Sep, 2019"	"angbutter (337)"	"americano (44)"
-- "Oct, 2019"	"angbutter (249)"	"americano (43)"
-- "Nov, 2019"	"angbutter (288)"	"americano (40)"
-- "Dec, 2019"	"angbutter (314)"	"americano (65)"
-- "Jan, 2020"	"angbutter (300)"	"americano (44)"
-- "Feb, 2020"	"angbutter (391)"	"americano (86)"
-- "Mar, 2020"	"angbutter (403)"	"americano (67)"
-- "Apr, 2020"	"angbutter (311)"	"americano (47)"
-- "May, 2020"	"angbutter (19)"	"americano (5)"



-- Summary:
-- The query identifies the best-selling pastry and beverage products 
-- for each month, with "angbutter" consistently being the top-selling pastry 
-- and "americano" dominating as the best-selling beverage across all months.



-- Explanation of the final SELECT statement and the key components:

-- 1. `TO_CHAR(TO_DATE(month, 'Mon, YYYY'), 'Mon, YYYY') AS month`:
--    - This part converts the `month` column from the original string 
--    format ("Mon, YYYY") to a proper date format using `TO_DATE()`.
--    - It then uses `TO_CHAR()` to format the date back into a string 
--    in the desired format of "Mon, YYYY".
--    - This ensures that the month is displayed in the correct format 
--    ("Jul, 2019", "Aug, 2019", etc.) in the output.

-- 2. `COALESCE(MAX(CASE WHEN rank = 1 AND category = 'pastry' THEN 
-- 			CONCAT(name, ' (', qty, ')') END), 'No best pastry') AS best_pastry`:

--    - This part uses a CASE statement to check if the current row has a 
--    rank of 1 (i.e., the top seller) for the 'pastry' category.
--    - If true, it concatenates the product name and quantity into a single string.
--    - If no pastry product is found with rank 1, it returns the 
-- 	default value 'No best pastry'.
--    - The `COALESCE()` function is used to handle the case where 
--    there are no pastry products at all for a given month.

-- 3. `COALESCE(MAX(CASE WHEN rank = 1 AND category = 'beverage' 
-- 	THEN CONCAT(name, ' (', qty, ')') END), 'No best beverage') AS best_beverage`:
--    - This part is similar to the previous one, but it looks for 
--    the top-selling beverage product.

-- 4. `GROUP BY month`:
--    - This groups the data by the `month` column, allowing the 
--    aggregate functions (e.g., `MAX()`) to work correctly.

-- 5. `ORDER BY TO_DATE(month, 'Mon, YYYY')`:
--    - This part sorts the output by the actual date (converted from the 
--    `month` column), ensuring the results are displayed in chronological order.


-- Notes:
-- 1. Why use `TO_DATE()` to sort the date?
--    - Using `TO_DATE()` to sort the date is necessary because the 
--    `month` column is in a string format ("Mon, YYYY"). 
--    By converting it to a proper date format, the database can sort 
--    the rows in the correct chronological order.

-- 2. Why use `MAX()` inside the `CASE` statement?
--    - The `MAX()` function is used to ensure that only the top-selling 
--    product (with rank 1) is displayed for each month and category.
   
--    Without the `MAX()`, the query would return all products 
--    with a rank of 1, which may result in multiple rows per month 
--    and category, which is not the desired output.





-- 11. Write a SQL query to find the bottom 3 selling pastry and beverage products 
-- for each month based on total quantity sold. The output should include the 
-- month and year, along with the bottom 3 products in seperate columns 
-- (formatted as "[product_name] (qty)).

-- If there are fewer than 3 products sold in a particular category 
-- (pastry or beverage) for a given month, include only the available products. 

-- If there are no pastry or beverage products sold in a particular month, 
-- output "No pastries sold" or "No beverages sold" respectively.

-- The results should be ordered by month in descending order, with the 
-- most recent month first.

-- Do the same for top products.

-- Example output:
-- |---month----|--Bottom 3 Pastries-|--Bottom 3 Beverages--|
-- |  Aug, 2019 | Plain Bread (20).. |  Vanila Latte (25)...|
-- |  Jul, 2019 | No pastries sold.. |  Vanila Latte (15)...|



-- BOTTOM 3 PRODUCTS IN EACH CATEGORY


WITH relevant_data AS (
  SELECT TO_CHAR(o.order_date, 'Mon, YYYY') AS month,
         p.category,
         p.name,
         SUM(s.quantity) AS qty
  FROM orders o
  JOIN sales s ON o.order_id = s.order_id
  JOIN products p ON s.product_id = p.product_id
  GROUP BY TO_CHAR(o.order_date, 'Mon, YYYY'), p.category, p.name
)
, ranked_sales AS (
  SELECT month,
         category,
         name,
         qty,
         RANK() OVER(PARTITION BY month, category ORDER BY qty ASC) AS bottom_rank
  FROM relevant_data
)
SELECT 
  TO_CHAR(TO_DATE(month, 'Mon, YYYY'), 'Mon, YYYY') AS month,
  COALESCE(STRING_AGG(CASE WHEN bottom_rank <= 3 AND category = 'pastry' 
			   THEN CONCAT(name, ' (', qty, ')') END, ', '), 'No pastries sold') AS bottom_three_pastries,
  COALESCE(STRING_AGG(CASE WHEN bottom_rank <= 3 AND category = 'beverage' 
			   THEN CONCAT(name, ' (', qty, ')') END, ', '), 'No beverages sold') AS bottom_three_beverages
FROM ranked_sales
GROUP BY month
ORDER BY TO_DATE(month, 'Mon, YYYY');



-- Output (first few rows):
-- "month"	"bottom_three_pastries"	"bottom_three_beverages"
-- "Jul, 2019"	"tiramisu cake (5), cacao deep (7), jam (9)"	"lemon ade (5), berry ade (6), caffe latte (7)"
-- "Aug, 2019"	"tiramisu cake (2), merinque cookies (9), cacao deep (18)"	"lemon ade (5), berry ade (9), milk tea (16)"
-- "Sep, 2019"	"merinque cookies (8), jam (21), almond croissant (25)"	"lemon ade (1), berry ade (5), caffe latte (16)"
-- "Oct, 2019"	"merinque cookies (2), cheese cake (2), gateau chocolat (12)"	"berry ade (2), lemon ade (4), milk tea (6)"



-- Summary:
-- Consistent Underperformers in Pastries:
-- The bottom-selling pastry products are consistently items like 
-- "tiramisu cake", "merinque cookies", "gateau chocolat", and 
-- "cheese cake" across multiple months.
-- This suggests that these specialty or unique pastry offerings 
-- are not resonating with the bakery's customers, who seem to 
-- prefer more traditional and popular pastry options.


-- Fluctuating Bottom Beverages:
-- The bottom-selling beverage products vary more month-to-month, with 
-- "lemon ade", "berry ade", "caffe latte", "milk tea", and others 
-- appearing in the bottom 3.
-- This indicates that the bakery may need to closely monitor customer 
-- preferences for beverages and adjust its product mix accordingly 
-- to cater to evolving customer tastes.


-- Potential Inventory Optimization Opportunities:
-- While there are no instances of "No pastries sold" or "No beverages sold" 
-- in the output, the consistently low sales of certain products could present 
-- opportunities for the bakery to optimize its inventory and production planning.
-- By identifying and potentially discontinuing or reducing the availability 
-- of these underperforming items, the bakery can free up resources to focus 
-- on its top-selling and more profitable products.



-- TOP 3 PRODUCTS IN EACH CATEGORY


WITH relevant_data AS (
  SELECT TO_CHAR(o.order_date, 'Mon, YYYY') AS month,
         p.category,
         p.name,
         SUM(s.quantity) AS qty
  FROM orders o
  JOIN sales s ON o.order_id = s.order_id
  JOIN products p ON s.product_id = p.product_id
  GROUP BY TO_CHAR(o.order_date, 'Mon, YYYY'), p.category, p.name
)
, ranked_sales AS (
  SELECT month,
         category,
         name,
         qty,
         RANK() OVER(PARTITION BY month, category ORDER BY qty DESC) AS top_rank
  FROM relevant_data
)
SELECT 
  TO_CHAR(TO_DATE(month, 'Mon, YYYY'), 'Mon, YYYY') AS month,
  COALESCE(STRING_AGG(CASE WHEN top_rank <= 3 AND category = 'pastry' 
			   THEN CONCAT(name, ' (', qty, ')') END, ', '), 'No pastries sold') AS top_three_pastries,
  COALESCE(STRING_AGG(CASE WHEN top_rank <= 3 AND category = 'beverage' 
			   THEN CONCAT(name, ' (', qty, ')') END, ', '), 'No beverages sold') AS top_three_beverages
FROM ranked_sales
GROUP BY month
ORDER BY TO_DATE(month, 'Mon, YYYY');



-- Output (first few rows):

-- "month"	"top_three_pastries"	"top_three_beverages"
-- "Jul, 2019"	"angbutter (187), croissant (80), tiramisu croissant (65)"	"americano (26), vanila latte (18), milk tea (10)"
-- "Aug, 2019"	"angbutter (430), croissant (151), plain bread (105)"	"americano (46), caffe latte (27), vanila latte (23)"
-- "Sep, 2019"	"angbutter (337), croissant (113), pain au chocolat (79), plain bread (79)"	"americano (44), vanila latte (20), milk tea (17)"
-- "Oct, 2019"	"angbutter (249), croissant (92), pain au chocolat (80)"	"americano (43), vanila latte (27), caffe latte (17)"
-- "Nov, 2019"	"angbutter (288), plain bread (116), croissant (92)"	"americano (40), caffe latte (29), vanila latte (26)"




-- Summary:
-- Angbutter Dominance: The pastry product "angbutter" consistently ranks as the 
-- top-selling item across all months, indicating it is a signature and 
-- highly popular product for the bakery.

-- Other popular pastry products include "croissant", "tiramisu croissant", 
-- "plain bread", and "pain au chocolat", which frequently appear in the top 3 list.
-- This suggests that the bakery has a core set of signature pastry items 
-- that are highly sought after by customers, indicating a strong brand 
-- identity and customer loyalty.

-- Varied Beverage Preferences: While "americano" remains the most consistently 
-- top-selling beverage, the other top beverage products shift between "caffe latte", 
-- "vanila latte", and "milk tea".

-- This could indicate that customers have more diverse preferences when 
-- it comes to beverages, and the bakery may need to regularly monitor and 
-- adjust its beverage offerings to cater to evolving customer tastes.






-- 12. For each order, create a summary string that includes the order ID, 
-- total amount, and a concatenation of the first letter of each 
-- unique product ordered along with its product ID with * seperating each productname
-- formatted as follows: "Order [order_id]: $[total_amount] 
-- ([first_letter1product_id1*first_letter2product_id2...])".

-- For example, if an order includes products like 
-- "Angbutter" (ID 1), "Plain bread" (ID 2), and "Merinque Cookies" 
-- (ID 15), the output should look like: "Order 1001: $45.50 (A1*P2*M15)".



SELECT CONCAT('Order ', o.order_id, ': ', '₩', o.total, ' (', 
			  STRING_AGG(CONCAT(UPPER(LEFT(p.name, 1)), p.product_id), ' * '), ')') AS order_summary
FROM orders o
JOIN sales s
ON o.order_id = s.order_id
JOIN products p
ON s.product_id = p.product_id
GROUP BY o.order_id, o.total;


-- Output (first few rows):

-- "order_summary"
-- "Order 1: ₩23800 (V20 * T5 * A16 * A1)"
-- "Order 2: ₩15800 (O12 * A1 * T5)"
-- "Order 3: ₩58000 (T5)"
-- "Order 4: ₩14800 (P2 * V20 * A1)"
-- "Order 5: ₩15600 (T5 * A1)"






-- 
