-- ***************
-- Advance Analysis
-- ***************

-- sales over time
-- Change-over-time trends  ----- analyse how a measure evolves over time -- aggregated[Measure] By [Date Dimension]
-- we dont aggregate data on day level but on month/year level so change from date dimension to year dimension using date fn
SELECT 
DATETRUNC(MONTH, order_date) AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date)



--comulative analysis -- aggregate the data progressively over time -- helps understand whether business growing or declining
--normal aggregation -> SUM(), comulative aggregation -> SUM() OVER()
--total sales per month and the running total of sales per time
SELECT
order_date,
total_sales,
SUM(total_sales) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_total_sales,
avg_sales,
AVG(avg_sales) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_average_sales
FROM(
	SELECT 
	DATETRUNC(MONTH, order_date) AS order_date, -- watching out for all sales in each month
	SUM(sales_amount) AS total_sales,
	AVG(sales_amount) AS avg_sales
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
)t


--performance analysis ---- process of comparing current value to a target value -- current[measure] - target[measure]

--yearly performance of prods by comparing their sales to both the avg sales performance and the prev year's sales of prod
SELECT 
order_date,
product_name,
total_sales,
AVG(total_sales) OVER(PARTITION BY product_name) AS avg_sales,
total_sales - AVG(total_sales) OVER(PARTITION BY product_name) AS diff_sales_and_avg,
CASE WHEN total_sales - AVG(total_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above AVG'
	 WHEN total_sales - AVG(total_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below AVG'
	 ELSE 'AVG'
END AS avg_indicator,
-- year-over-year analysis
LAG(total_sales) OVER(PARTITION BY product_name ORDER BY product_name, order_date) AS prev_year_sales,
total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY product_name, order_date) AS diff_sales_and_prev_year_sales,
CASE WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY product_name, order_date) > 0 THEN 'Sales Increased'
	 WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY product_name, order_date) < 0 THEN 'Sales Decreased'
	 ELSE 'Sales Unchanged'
END AS prev_year_indicator
FROM(
	SELECT 
	YEAR(f.order_date) AS order_date,
	p.product_name,
	SUM(f.sales_amount) AS total_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON f.product_key = p.product_key
	WHERE f.order_date IS NOT NULL
	GROUP BY YEAR(f.order_date), p.product_name
)t 
ORDER BY product_name, order_date


--part to whole / Proportional analysis -- analysis of an individual part performing compared to overall -- allows us to understand which cat has greatest impact on business
-- ([Measure] / Total[Measure]) * 100 By [Dimension] >>eg (sales/ total sales)*100 By cat(or country)

--categories that contribute the most to overall sales 
WITH category_CTE AS(
SELECT 
p.category,
SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
GROUP BY category
)
SELECT
category,
total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND(CAST(total_sales AS FLOAT)/SUM(total_sales) OVER()*100, 2), '%') AS salest_by_overall_sales_percent
FROM category_CTE
ORDER BY salest_by_overall_sales_percent DESC


-- Data Segmentation --- group data based on specific range (categorize) -- helps understand corr b/w two measures
-- [Measure] By [Measure] - eg. Total Prods by sales range, Total custs by Age

-- segment prods into cost ranges and count how many prods fall into each segment
WITH product_segments AS (
SELECT
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
-- here we converted our measure into new dimension by segmenting
END AS cost_range
FROM gold.dim_products
)
SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;


--group custs into 3 segments based on their spending behavior: 
--1.VIP : at least 12 mnths of history and spending more than 5000, 2.Regular : same as vip but spending 5000 or less 3.New:lifespan less then 12 mnths
--Also find total num of custs by each group
WITH spending_segments AS(
	SELECT 
	f.customer_key,
	--c.first_name,
	--c.last_name,
	--MIN(order_date) AS first_order_date,
	--MAX(order_date) AS last_order_date,
	--DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS customer_timespan,
	--SUM(sales_amount) AS total_spendings,
	CASE WHEN DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) >= 12 AND SUM(sales_amount) > 5000 THEN 'VIP'
		 WHEN DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) >= 12 AND SUM(sales_amount) <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS customer_category
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
		ON f.customer_key = c.customer_key 
	GROUP BY f.customer_key,c.first_name,c.last_name
)
SELECT 
customer_category,
COUNT(customer_key) AS total_customers
FROM spending_segments
GROUP BY customer_category
ORDER BY total_customers DESC

