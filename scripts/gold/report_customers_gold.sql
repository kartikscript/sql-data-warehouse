--***********************************
--Customer Report
--***********************************
--Purpose : this report consolidates key customer metrices and behaviors

--Highlights:
--	1.projects essentitial fields such as names, ages and transaction details,.
--	2.segments customers into categories(VIP, Regular, New) and age groups.
--	3.aggregates customer level metrices:
--		-total orders
--		-total sales
--		-total quantity purchased
--		-total products
--		-lifespan(in months)
--	4.calculates valuable KPIs:
--		-recency (how many months since last order)
--		-average order value (total sales/ total no. of orders)
--		-average monthly spend (total sales / no. of months {lifespan of customer})
-- ================================================================================

CREATE VIEW gold.report_customers AS
WITH base_query AS(
--base query : retrieves core columns from tables
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name,' ',c.last_name) customer_name,
DATEDIFF(YEAR, c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL
),
customer_aggregation AS(
-- this cte summarizes key metrices at customer level
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY customer_key,
		customer_number,
		customer_name,
		age
)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 20 THEN 'Under 20'
	 WHEN age BETWEEN 20 AND 29 THEN '20-29'
	 WHEN age BETWEEN 30 AND 39 THEN '30-39'
	 WHEN age BETWEEN 40 AND 49 THEN '40-49'
	 ELSE '50 and above'
END AS age_group,
CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	 WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	 ELSE 'New'
END AS customer_segment,
total_orders,
last_order_date,
DATEDIFF(MONTH, last_order_date, GETDATE()) AS recency,
total_sales,
total_quantity,
total_products,
lifespan,
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_sales/total_orders 
END AS avg_order_value,
CASE WHEN lifespan = 0 THEN total_sales -- lifespan=0 means cust exist for 1 month so total_sales/1
	 ELSE total_sales/lifespan 
END AS avg_monthly_spend
FROM customer_aggregation


--SELECT * FROM gold.report_customers
