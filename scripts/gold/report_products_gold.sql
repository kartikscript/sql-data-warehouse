--***********************************
--Product Report
--***********************************
--Purpose : this report consolidates key product metrices and behaviors

--Highlights:
--	1.projects essentitial fields such as product name, category, subcategory and cost.
--	2.segments products by revenue to identify high-performers, mid-range, or low-performers.
--	3.aggregates product level metrices:
--		-total orders
--		-total sales
--		-total quantity sold
--		-total customers(unique)
--		-lifespan(in months)
--	4.calculates valuable KPIs:
--		-recency (how many months since last sale)
--		-average order revenue (total sales/ total no. of orders)
--		-average monthly revenue (total sales / no. of months {lifespan of customer})
-- ================================================================================
CREATE VIEW gold.report_products AS
WITH base_query AS(
--base query : retrieves core columns from tables
SELECT
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
WHERE order_date IS NOT NULL
),
product_aggregation AS(
-- this cte summarizes key metrices at customer level
SELECT
product_key,
product_name,
category,
subcategory,
cost,
MAX(order_date) AS last_sale_date,
COUNT(DISTINCT order_number) AS total_orders,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity_sold,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
ROUND(AVG(CAST(sales_amount AS FLOAT)/ NULLIF(quantity,0)),1) AS avg_selling_price
FROM base_query
GROUP BY product_key,
		product_name,
		category,
		subcategory,
		cost

)
SELECT
product_key,
product_name,
category,
subcategory,
cost,
DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency,
CASE WHEN total_sales > 50000 THEN 'High-Performer'
	 WHEN total_sales >= 10000 THEN 'Mid_Range'
	 ELSE 'Low-Performer'
END AS product_segment,
total_orders,
last_sale_date,
total_sales,
total_quantity_sold,
total_customers,
avg_selling_price,
lifespan,
CASE WHEN total_orders = 0 THEN 0
	 ELSE total_sales/total_orders 
END AS avg_order_revenue,
CASE WHEN lifespan = 0 THEN total_sales -- lifespan=0 means cust exist for 1 month so total_sales/1
	 ELSE total_sales/lifespan 
END AS avg_monthly_revenue
FROM product_aggregation


--SELECT * FROM gold.report_customers
