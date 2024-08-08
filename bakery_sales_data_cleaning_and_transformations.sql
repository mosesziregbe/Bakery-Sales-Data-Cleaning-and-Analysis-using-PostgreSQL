
-- DATA CLEANING AND TRANSFORMATION


-- create the schema

CREATE SCHEMA bakery_schema;


SET search_path TO bakery_schema;


SHOW search_path;



-- DATA CLEANING AND TRANSFORMATION


-- create table for bakery_sales

CREATE TABLE bakery_sales (
    datetime TIMESTAMP,
    day_of_week VARCHAR(10),
    total INTEGER,
    place VARCHAR(100),
    angbutter INTEGER,
    plain_bread INTEGER,
    jam INTEGER,
    americano INTEGER,
    croissant INTEGER,
    caffe_latte INTEGER,
    tiramisu_croissant INTEGER,
    cacao_deep INTEGER,
    pain_au_chocolat INTEGER,
    almond_croissant INTEGER,
    croque_monsieur INTEGER,
    mad_garlic INTEGER,
    milk_tea INTEGER,
    gateau_chocolat INTEGER,
    pandoro INTEGER,
    cheese_cake INTEGER,
    lemon_ade INTEGER,
    orange_pound INTEGER,
    wiener INTEGER,
    vanila_latte INTEGER,
    berry_ade INTEGER,
    tiramisu INTEGER,
    merinque_cookies INTEGER
);


-- import the csv file for bakery_sales using the pgAdmin import tool



-- create table for bakery_price

CREATE TABLE bakery_prices (
    name VARCHAR(50),
    price INTEGER
);


-- import the csv file for bakery_prices using the pgAdmin import tool


-- Inspect the imported datasets

SELECT * FROM bakery_sales;

SELECT * FROM bakery_prices;


-- data cleaning and transformation

-- I noticed that each row for the bakery_sales contains a seperate record
-- or unique sale made during a particular day and time by a particular customer
-- and the bakery_sales table contains columns of all products sold by the bakery store.

-- For a particular order, the product columns contains the quantity of the items
-- ordered or sold. 

-- This mean there will be a lot of NULL values for products that
-- the customer did not order. 

-- Also this is a wide dataset, so I decided to normalized the tables

-- I will normalize the 2 tables (bakery_sales, bakery_prices) into
-- 3 tables (orders, products, sales)


-- create new table for orders

DROP TABLE orders;

CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  order_date DATE NOT NULL,
  order_time TIME NOT NULL,
  day_of_week TEXT NOT NULL,
  total NUMERIC NOT NULL,
  place TEXT NULL
);


-- Insert the needed data to orders table
-- add some where condition to filter NULL values and unuseful rows 
-- from the data

INSERT INTO orders (order_date, order_time, day_of_week, place, total)
SELECT CAST(datetime AS DATE) AS order_date,
	   CAST(datetime AS TIME) AS order_time,
	   day_of_week,
	   CASE WHEN place IS NULL OR place = '' THEN 'NA' ELSE place END AS place,
	   total
FROM bakery_sales
WHERE datetime IS NOT NULL
AND total IS NOT NULL;



-- we have 2420 rows of data in the orders table

SELECT * FROM orders;



-- next, I will create products table from bakery_prices

SELECT * FROM bakery_prices


-- create table for products

DROP TABLE products;

CREATE TABLE products
(product_id SERIAL PRIMARY KEY,
 name VARCHAR(50),
 price NUMERIC NOT NULL,
 category TEXT NOT NULL
);


-- according to the dataset description, the following products are 
-- beverages (americano, caffe latte, ice coffe, ice coffe latter, 
-- ice milk tea, valina latte, berry ade, lemon ade)
-- while the rest are pastry


-- Inserting the data into products table
-- I will also categorize the products into pastry and beverage

INSERT INTO products (name, price, category)
SELECT name, price, 'pastry' AS category 
FROM bakery_prices
WHERE name NOT IN ('americano', 'caffe latte', 'ice coffe', 'ice coffe latter', 'ice milk tea', 'valina latte', 'berry ade', 'lemon ade')
UNION ALL
SELECT name, price, 'beverage' AS category 
FROM bakery_prices
WHERE name IN ('americano', 'caffe latte', 'ice coffe', 'ice coffe latter', 'ice milk tea', 'valina latte', 'berry ade', 'lemon ade')


-- Inspecting the products table
SELECT * FROM products;

SELECT DISTINCT name FROM products;


-- Inspecting the data, I notice we have some product_names not in the
-- products table, but they are showing as columns in the bakery_sales table


-- Also, I need to ensure the name in the products table matches with the 
-- main table (bakery_sales) column names 
-- (this will be handled when normalizing the final table sales)

SELECT angbutter, plain_bread, jam, americano, croissant, caffe_latte,
	   tiramisu_croissant, cacao_deep, pain_au_chocolat, almond_croissant, 
	   croque_monsieur, mad_garlic, milk_tea, gateau_chocolat, pandoro, 
	   cheese_cake, lemon_ade, orange_pound, wiener, vanila_latte,
	   berry_ade, tiramisu, merinque_cookies
FROM bakery_sales;



-- Next, I need to find the prices for missing products 
-- (americano, croque_monsieur, mad_garlic)


-- Inspecting the datasets, I notice there are no sales for croque_mosieur 
-- and mad_garlic so I will leave them out of the products table


-- count shows 0 records, therefore no sales for these 2 products

SELECT COUNT(croque_monsieur)
FROM bakery_sales
WHERE croque_monsieur IS NOT NULL;

SELECT COUNT(mad_garlic)
FROM bakery_sales
WHERE mad_garlic IS NOT NULL;


-- count shows that are 412 records, so there are sales for americano product

SELECT COUNT(americano)
FROM bakery_sales
WHERE americano IS NOT NULL;



-- from the arrangement of the columns matching the dataset dictionary/description,
-- I find out that americano is ice coffe


SELECT * FROM products;



-- update some of the product names to the appropriate names to match with 
-- the columns of the bakery_sales table


-- Also, from the dataset, I notice there are 2 types of 'tiramisu' products
-- (croissant and cake), I will distinguish the product as one of them is
-- showing as 'tiramisu', this will become 'tiramisu cake'


UPDATE products
SET name = CASE WHEN name = 'ice coffe' THEN 'americano'
				WHEN name = 'ice milk tea' THEN 'milk tea'
				WHEN name = 'valina latte' THEN 'vanila latte'
				WHEN name = 'ice coffe latter' THEN 'caffe latte'
				WHEN name = 'tiramisu' THEN 'tiramisu cake'
				ELSE name END;


-- Inspecting the products table

SELECT * FROM products;


-- note: we have 23 products columns in the bakery_sales table, but 21 in the products table,
-- 2 of these products (mad_garlic, croque_monsieur) do not have any sales and 
-- so they are not included in our products table.



-- now, let's handle the bakery_sales table

-- After inspecting the bakery_sales table, I see that this is a wide dataset
-- of 27 columns, the columns are majorly the product names

-- The wide dataset contains a lot of NULL values in each record
-- and some redundant data. This may affect our analysis.

-- we need to normalize this table and also melt it into a long dataset.
-- This will help make our analysis better and also retrieve 
-- fields and records faster


-- create sales table

DROP TABLE sales;

CREATE TABLE sales (
order_id INTEGER REFERENCES orders(order_id),
product_id INTEGER REFERENCES products(product_id),
quantity INTEGER NOT NULL
);




-- next, create temporary table with row_number windows function as the
-- order_id, and also add a WHERE condition to remove unuseful rows


CREATE TEMPORARY TABLE bakery_sales_temp AS
SELECT ROW_NUMBER() OVER() AS order_id, *
FROM bakery_sales
WHERE datetime IS NOT NULL
AND total IS NOT NULL;


-- we also have 2420 rows 

SELECT * FROM bakery_sales_temp;



-- create a temporary table sales_temp

-- I will retrieve the order_id, datetime, place, product_name, and quantity from the 
-- temporary table bakery_sales_temp

-- Next, insert the values from sales_temp into sales, by joining on the 
-- products table so we can retrieve the product_id for each product

-- Also, remember to account for our 'tiramisu' column to make the 
-- product_name 'tiramisu cake' in the sales_temp table


DROP TABLE sales_temp;

CREATE TEMPORARY TABLE sales_temp AS
SELECT 
    order_id,
    datetime,
    place,
    'angbutter' as product_name, 
    angbutter as quantity 
FROM bakery_sales_temp
WHERE angbutter > 0
UNION ALL
SELECT 
    order_id,
    datetime,
    place,
    'plain bread' as product_name, 
    plain_bread as quantity 
FROM bakery_sales_temp
WHERE plain_bread > 0
UNION ALL
SELECT order_id, datetime, place, 'jam' as product_name, jam as quantity FROM bakery_sales_temp WHERE jam > 0
    UNION ALL
    SELECT order_id, datetime, place, 'americano' as product_name, americano as quantity FROM bakery_sales_temp WHERE americano > 0
    UNION ALL
    SELECT order_id, datetime, place, 'croissant' as product_name, croissant as quantity FROM bakery_sales_temp WHERE croissant > 0
    UNION ALL
    SELECT order_id, datetime, place, 'caffe latte' as product_name, caffe_latte as quantity FROM bakery_sales_temp WHERE caffe_latte > 0
    UNION ALL
    SELECT order_id, datetime, place, 'tiramisu croissant' as product_name, tiramisu_croissant as quantity FROM bakery_sales_temp WHERE tiramisu_croissant > 0
    UNION ALL
    SELECT order_id, datetime, place, 'cacao deep' as product_name, cacao_deep as quantity FROM bakery_sales_temp WHERE cacao_deep > 0
    UNION ALL
    SELECT order_id, datetime, place, 'pain au chocolat' as product_name, pain_au_chocolat as quantity FROM bakery_sales_temp WHERE pain_au_chocolat > 0
    UNION ALL
    SELECT order_id, datetime, place, 'almond croissant' as product_name, almond_croissant as quantity FROM bakery_sales_temp WHERE almond_croissant > 0
    UNION ALL
    SELECT order_id, datetime, place, 'croque monsieur' as product_name, croque_monsieur as quantity FROM bakery_sales_temp WHERE croque_monsieur > 0
    UNION ALL
    SELECT order_id, datetime, place, 'mad garlic' as product_name, mad_garlic as quantity FROM bakery_sales_temp WHERE mad_garlic > 0
    UNION ALL
    SELECT order_id, datetime, place, 'milk tea' as product_name, milk_tea as quantity FROM bakery_sales_temp WHERE milk_tea > 0
    UNION ALL
    SELECT order_id, datetime, place, 'gateau chocolat' as product_name, gateau_chocolat as quantity FROM bakery_sales_temp WHERE gateau_chocolat > 0
    UNION ALL
    SELECT order_id, datetime, place, 'pandoro' as product_name, pandoro as quantity FROM bakery_sales_temp WHERE pandoro > 0
    UNION ALL
    SELECT order_id, datetime, place, 'cheese cake' as product_name, cheese_cake as quantity FROM bakery_sales_temp WHERE cheese_cake > 0
    UNION ALL
    SELECT order_id, datetime, place, 'lemon ade' as product_name, lemon_ade as quantity FROM bakery_sales_temp WHERE lemon_ade > 0
    UNION ALL
    SELECT order_id, datetime, place, 'orange pound' as product_name, orange_pound as quantity FROM bakery_sales_temp WHERE orange_pound > 0
    UNION ALL
    SELECT order_id, datetime, place, 'wiener' as product_name, wiener as quantity FROM bakery_sales_temp WHERE wiener > 0
    UNION ALL
    SELECT order_id, datetime, place, 'vanila latte' as product_name, vanila_latte as quantity FROM bakery_sales_temp WHERE vanila_latte > 0
    UNION ALL
    SELECT order_id, datetime, place, 'berry ade' as product_name, berry_ade as quantity FROM bakery_sales_temp WHERE berry_ade > 0
    UNION ALL
    SELECT order_id, datetime, place, 'tiramisu cake' as product_name, tiramisu as quantity FROM bakery_sales_temp WHERE tiramisu > 0
    UNION ALL
    SELECT order_id, datetime, place, 'merinque cookies' as product_name, merinque_cookies as quantity_temp FROM bakery_sales_temp WHERE merinque_cookies > 0;



-- Insert the values from the sales_temp (temporary table) into the sales table

INSERT INTO sales (order_id, product_id, quantity)
SELECT 
    t.order_id, 
    p.product_id, 
    t.quantity
FROM sales_temp t
JOIN products p ON p.name = t.product_name
ORDER BY t.order_id;



-- Inspecting our sales table shows that we now have 3 columns 
-- (order_id, product_id, quantity) and 8285 rows of data

SELECT * FROM sales;



-- more data cleaning

-- now, I will update the place column in the orders table to show 
-- the appropriate translations in english


UPDATE orders
SET place = CASE WHEN place = '소양동' THEN 'Soyang-dong'
				 WHEN place = '효자 3동' THEN 'Hyoja3-dong' 
				 WHEN place = '후평 1동' THEN 'Hoopyeong1-dong'
				 WHEN place = '후평 2동' THEN 'Hoopyeong2-dong' 
				 WHEN place = '석사동' THEN 'Seoksa-dong'
				 WHEN place = '퇴계동' THEN 'Toegye-dong'
				 WHEN place = '동면' THEN 'Dongmyeon'
				 WHEN place = '후평 3동' THEN 'Hoopyeong3-dong'
				 WHEN place = '신사우동' THEN 'Sinsawoo-dong'
				 WHEN place = '강남동' THEN 'Gangnam-dong'
				 WHEN place = '효자 1동' THEN 'Hyoja1-dong' 
				 WHEN place = '조운동' THEN 'Jowoon-dong'
				 WHEN place = '교동' THEN 'Gyo-dong'
				 WHEN place = '효자 2동' THEN 'Hyoja2-dong'
				 WHEN place = '약사명동' THEN 'Yaksamyeong-dong'
				 WHEN place = '근화동' THEN 'Geunhwa-dong' 
				 WHEN place = '동내면' THEN 'Dongnae-myeon' 
				 WHEN place = '신동면' THEN 'Sindong-myeon' 
				 WHEN place = '교동 ' THEN 'Gyo-dong'
				 ELSE place END;

				
				
-- Inspecting the 3 new tables


SELECT * FROM orders;

SELECT * FROM products;

SELECT * FROM sales;





--
