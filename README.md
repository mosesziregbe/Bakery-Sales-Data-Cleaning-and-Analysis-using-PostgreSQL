# Bakery Sales Data Cleaning and Analysis using PostgreSQL

## Project Overview
This project involves the analysis of a bakery's sales data in South Korea using SQL. The goal is to gain insights into sales patterns, product popularity, customer behavior, and overall business performance. The analysis is conducted through a series of SQL queries, ranging from basic data exploration to more complex analytical questions.


## Tools Used
PostgreSQL 
pgAdmin 
SQL for data querying and analysis


## Dataset Description
The dataset is downloaded from kaggle and contains 2 csv files (bakery_sales and bakery_prices). 

The original dataset (bakery_sales) contains information about bakery orders, including:

- Date and time of order
- Day of the week
- Total order amount
- Customer's location
- Quantities of various products ordered (e.g., angbutter, plain bread, jam, americano, etc.)

The dataset contains 27 columns.

`datetime` : order time
`day of week:` day of the week.
`total`: Total Amount.
`place`: customer's place
`angbutter`: It's a pain's name. Pretzel filled with red beans and gourmet butter.
`plain bread`: plain bread.
`jam`: peach jam.
`americano`: americano
`croissant`: croissnat.
`caffe latte`: caffe laffe.
`tiramisu croissant`: Croissants filled with tiramisu cream and fruit.
`cacao deep`: Croissant covered in Valrhona chocolate
`pain au chocolate`: Pain au chocolate.
`almond croissant`: Croissant filled with almond cream.
`croque monsieur`:
`mad garlic`:
`milk tea`: Mariage Frères milk tea.
`gateau chocolat`: piece of chocolate cake.
`pandoro`: pandoro: Italian pain.
`cheese cake`: Cheese cake.
`lemon ade`: Lemon ade
`orange pound`: Orange pound cake.
`wiener`: sausage bread.
`vanila latte`: Brewed with Madagascar vanilla bean.
berry ade: berry ade.
`tiramisu`: tiramisu cake.
`merinque cookies`: cookies.


## Data Cleaning

The data cleaning process involved several steps:

1. Handling missing values, particularly in the 'place' column
2. Translating the 'place' column from korean to english
3. Ensuring consistency in data types
4. Removing duplicate entries
5. Dealing with potential data entry errors


## Data Normalization
We normalized the data into three main tables:

### Orders Table
- order_id (Primary Key)
- order_date
- order_time
- day_of_week
- total
- place

### Products Table
- product_id (Primary Key)
- name
- price
- category

### Sales Table
- order_id (Foreign Key referencing Orders)
- product_id (Foreign Key referencing Products)
- quantity

The normalization process involved:
1. Creating a temporary table with assigned order IDs
2. Unpivoting the product quantities from wide to long format
3. Separating product information into a dedicated table
4. Creating a sales table to link orders with products and quantities

The dataset is stored in a PostgreSQL database named bakery_db with the schema bakery_schema, with the three main tables: orders, products, and sales.


## Database Schema


## Project Structure

The project is organized into several SQL files, each focusing on different aspects of the analysis:

***I - Data Cleaning, transformation and table normalization***
- Initial data cleaning steps
- Database normalization processes

***II - Exploratory Data Analysis (Part A)***
- Basic exploratory queries
- Summary statistics
- Initial insights into sales patterns

***III - Exploratory Data Analysis (Part B)***
- More advanced analytical queries
- Deeper insights into product performance and customer/location behavior

***IV - String Manipulation Questions (Part C)***
- Queries involving string manipulation and analysis


***V - More Business Analytic Questions (Part D)***
- Complex analytical queries addressing specific business questions



## Key Analyses

The project covers various aspects of the bakery's operations, including:

- Sales trends over time
- Popular products and their contribution to revenue
- Location-based sales analysis
- Order value analysis
- Product combination analysis


## Insights 

1. Seasonal and Monthly Trends: Sales show distinct monthly patterns with peaks in early 2020 (February and March) and fluctuations in late 2019.

2. Product Popularity: "Angbutter" consistently leads pastry sales, while "Americano" dominates beverage sales. New products like "Plain Bread" show growing popularity.

3. Timing Patterns: Weekends (especially Sundays) and Fridays have higher sales. Peak hours are 11:00 and 12:00, suggesting a strong lunch-time rush.

4. Product Pairing: "Angbutter" is frequently bought with other items, particularly "plain bread".

5. Location Impact: The bakery's location (Dongmyeon) and nearby areas (Hoopyeong) account for a significant portion of orders, indicating a strong local customer base.


## Recommendations:

1. Product Focus: Continue to promote and innovate around top-selling items like "Angbutter" and "Americano". Explore ways to enhance the popularity of "Plain Bread" and other rising products.

2. Time-Based Promotions: Implement strategies to increase weekday sales, particularly on Tuesdays. Consider extending hours or offering special promotions during peak times (11:00-12:00) to maximize revenue.

3. Bundle Offerings: Create bundle deals featuring "Angbutter" paired with other popular items to increase average order value and promote less popular products.

4. Expansion Strategy: Focus on maintaining strong sales in the local area (Dongmyeon and Hoopyeong) while developing strategies to increase market share in other locations. This could include targeted advertising or considering new branch locations in high-potential areas.

5. Menu Optimization: Given that only 35.87% of orders include beverages, consider strategies to increase beverage sales, such as combo deals or upselling techniques.


## Future Work
- Incorporate more advanced statistical analysis
- Develop predictive models for sales forecasting


