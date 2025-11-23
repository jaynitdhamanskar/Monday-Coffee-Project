-- Monday Coffee -- Data Analysis

SELECT * FROM city;

SELECT * FROM products;

SELECT * FROM customers;

SELECT * FROM sales;


-- REPORT & DATA ANALYSIS

-- Q1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
city_name,
population, 
ROUND((population * 0.25)/ 1000000,2) AS coffee_consumer_in_millions
FROM city ORDER BY 3 DESC;

-- Q2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

-- REVENUE CITY WISE

SELECT ci.city_name, 
SUM(s.total) AS total_revenue
FROM city AS ci
JOIN customers AS cu
	ON ci.city_id = cu.city_id
JOIN sales AS s
	ON cu.customer_id = s.customer_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- -- REVENUE CITY WISE IN Q4 FOR YEAR 2023

SELECT ci.city_name, 
SUM(s.total) AS total_revenue
FROM city AS ci
JOIN customers AS cu
	ON ci.city_id = cu.city_id
JOIN sales AS s
	ON cu.customer_id = s.customer_id
WHERE 
EXTRACT(YEAR FROM sale_date) = 2023
AND
EXTRACT(QUARTER FROM sale_date) = 4
GROUP BY ci.city_name
ORDER BY SUM(s.total) DESC
LIMIT 5;

-- Q3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT * FROM products;

SELECT * FROM sales;

SELECT p.product_name, COUNT(s.sale_id) AS unit_sold
FROM products AS p
	LEFT JOIN sales AS s
	ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY 2 DESC
LIMIT 5;

-- Q4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- CITY AND TOTAL SALE
-- NO. OF CUSTOMERS IN EACH CITY

SELECT ci.city_name, 
SUM(s.total) AS total_sale, 
COUNT(DISTINCT cu.customer_id) AS total_customer,
ROUND(SUM(s.total)/COUNT(DISTINCT cu.customer_id),2) AS avg_sales_per_customer
FROM city AS ci
	JOIN customers AS cu
	ON ci.city_id = cu.city_id
	JOIN sales AS s
    ON cu.customer_id = s.customer_id
GROUP BY 1
ORDER BY 4 DESC
LIMIT 5;

-- ALTERNATE WAY
-- Q4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT * FROM city;
SELECT * FROM sales;
SELECT * FROM customers;


SELECT ci.city_name, ROUND(AVG(cs.total_spent),2) AS avg_sales_per_customer FROM customers AS cu
	JOIN city AS ci
    ON cu.city_id = ci.city_id
    JOIN
	(SELECT customer_id, SUM(total) AS total_spent
	FROM sales
	GROUP BY customer_id) AS cs
	ON cs.customer_id = cu.customer_id
GROUP BY ci.city_name
ORDER BY 2 DESC
LIMIT 5;

-- Q5 City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- RETURN CITY NAME, TOTAL CURRENT CUSTOMERS, ESTIMATED COFFEE CONSUMERS

SELECT ci.city_name, 
ci.population, 
ROUND((ci.population * 0.25)/1000000,2) AS estimated_coffee_consumers_in_mn,
COUNT(DISTINCT cu.customer_id) AS unique_customers
FROM city AS ci
LEFT JOIN customers AS cu
	ON ci.city_id = cu.city_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- Q6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * FROM city;
SELECT * FROM sales;
SELECT * FROM products;
SELECT * FROM customers;


SELECT ci.city_name, p.product_name, COUNT(*) AS sales_vol FROM sales AS s
	JOIN customers AS cu
		ON s.customer_id = cu.customer_id
	JOIN products AS p
		ON s.product_id = p.product_id
	JOIN city AS ci
		ON cu.city_id = ci.city_id
GROUP BY 1,2;



WITH city_prod_sales AS(
SELECT ci.city_name, p.product_name, COUNT(*) AS sales_vol FROM sales AS s
	JOIN customers AS cu
		ON s.customer_id = cu.customer_id
	JOIN products AS p
		ON s.product_id = p.product_id
	JOIN city AS ci
		ON cu.city_id = ci.city_id
GROUP BY 1,2)
SELECT 
city_name,
product_name,
sales_vol
FROM(
	SELECT *, 
    ROW_NUMBER() OVER (PARTITION BY city_name ORDER BY sales_vol DESC) AS rn
	FROM city_prod_sales
) AS t
WHERE rn <=3
ORDER BY city_name, sales_vol DESC;

-- ALTERNATE APPROACH

SELECT * FROM
(SELECT ci.city_name, p.product_name, COUNT(*) AS sales_vol, 
DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS rnk
FROM sales AS s
	JOIN products AS P
		ON s.product_id = p.product_id
	JOIN customers AS cu
		ON s.customer_id = cu.customer_id
	JOIN city AS ci
		ON cu.city_id = ci.city_id
GROUP BY 1,2) t1
WHERE rnk <=3;

-- Q7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT ci.city_name, COUNT(DISTINCT s.customer_id) AS unique_customer FROM sales AS s
	JOIN customers AS cu
    ON s.customer_id = cu.customer_id
    JOIN city AS ci
    ON cu.city_id = ci.city_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM sales;

-- Step 1: unique customers per city
SELECT ci.city_id, ci.city_name, COUNT(DISTINCT customer_id) AS unique_customers FROM CITY AS ci
	LEFT JOIN customers AS cu
		ON ci.city_id = cu.city_id
GROUP BY 1,2;

-- Step 2: total sales per city
SELECT
    cu.city_id,
    SUM(s.total) AS total_sales
FROM sales s
JOIN customers cu
    ON s.customer_id = cu.customer_id
GROUP BY 1;

-- Step 3: inspect city rent
SELECT city_id, city_name, population, estimated_rent
FROM city;

-- Step 4: average sale per customer and avg rent per customer
WITH customers_per_city AS (
    SELECT ci.city_id, ci.city_name, ci.estimated_rent, COUNT(DISTINCT cu.customer_id) AS unique_customers
    FROM city ci
    LEFT JOIN customers cu
        ON ci.city_id = cu.city_id
    GROUP BY ci.city_id, ci.city_name, ci.estimated_rent
),
sales_per_city AS (
    SELECT cu.city_id, SUM(s.total) AS total_sales FROM sales s
    JOIN customers cu
        ON s.customer_id = cu.customer_id
    GROUP BY cu.city_id
)
SELECT
    cpc.city_name,
    cpc.unique_customers, 
    ROUND(COALESCE(spc.total_sales, 0) / NULLIF(cpc.unique_customers, 0), 2) AS avg_sale_per_customer,
    ROUND(cpc.estimated_rent / NULLIF(cpc.unique_customers, 0), 2) AS avg_rent_per_customer
FROM customers_per_city AS cpc
LEFT JOIN sales_per_city AS spc
    ON cpc.city_id = spc.city_id
ORDER BY avg_sale_per_customer DESC;

-- Q9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH city_month_sales AS (
    SELECT
        ci.city_name,
        EXTRACT(YEAR FROM s.sale_date) AS yr,
        EXTRACT(MONTH FROM s.sale_date) AS mn,
        SUM(s.total) AS monthly_sales
    FROM sales AS s
    JOIN customers AS cu ON s.customer_id = cu.customer_id
    JOIN city AS ci ON cu.city_id = ci.city_id
    GROUP BY ci.city_name, yr, mn
)
SELECT
    city_name,
    yr,
    mn,
    monthly_sales,
    LAG(monthly_sales) OVER (PARTITION BY city_name ORDER BY yr, mn) AS prev_month_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (PARTITION BY city_name ORDER BY yr, mn)) /
        LAG(monthly_sales) OVER (PARTITION BY city_name ORDER BY yr, mn) * 100,
        2
    ) AS growth_percentage
FROM city_month_sales
ORDER BY city_name, yr, mn;

-- Q10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

SELECT ci.city_name, 
ci.estimated_rent, 
SUM(s.total) AS total_sales, 
COUNT(DISTINCT cu.customer_id) AS total_customers,
ROUND(SUM(s.total)/COUNT(DISTINCT cu.customer_id),2) AS avg_sale_per_customer,
ci.estimated_rent AS total_rent,
ROUND(ci.estimated_rent/COUNT(DISTINCT cu.customer_id),2) AS avg_rent_per_customer,
ROUND(ci.population * 0.25/1000000,2) AS estimated_coffee_consumers_in_mns
FROM city AS ci
JOIN customers AS cu
	ON ci.city_id = cu.city_id
JOIN sales AS s
	ON cu.customer_id = s.customer_id
GROUP BY ci.city_id, ci.city_name, ci.estimated_rent, ci.population
ORDER BY total_sales DESC
LIMIT 10;

/*
-- RECOMMENDATION

1) Pune
Pune stands out as the strongest market with the highest sales (12.58 lakh) and strong customer base (52 customers). 
Rent is moderate and coffee consumption potential is solid.

2) Chennai
Chennai follows with very strong sales (9.44 lakh) supported by 42 customers. 
The rent is slightly higher but acceptable, and coffee consumer potential is also high.

3) Bangalore
Bangalore takes third place with sales of 8.6 lakh and 39 customers. 
It has the highest rent among the top cities and a strong consumer potential.
*/