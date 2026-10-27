--customers object 
--check for duplicates
SELECT cst_id, COUNT(*)
FROM(
SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid
)t GROUP BY cst_id
HAVING COUNT(*) > 1


--data integration for gender cols
--check gender in ci and ca for filling n/a values from ca table
SELECT DISTINCT 
ci.cst_gndr,
ca.gen,
CASE WHEN ci.cst_gndr = 'n/a' AND ca.gen IS NOT NULL THEN ca.gen
		 ELSE ci.cst_gndr
	END AS gender
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid AND ci.cst_gndr != ca.gen
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid;


SELECT * FROM gold.dim_customers;


--product object
--check duplicates
SELECT prd_key,COUNT(*)
FROM(
SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pc.cat,
pc.subcat,
pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL
)t GROUP BY prd_key
HAVING COUNT(*) > 1

-- check if all end dates are null (these are current info of the product) {excluding history of products}
SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_start_dt,
pn.prd_end_dt
FROM silver.crm_prd_info pn;

SELECT * FROM gold.dim_products;

SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
WHERE c.customer_key IS NULL OR p.product_key IS NULL;
