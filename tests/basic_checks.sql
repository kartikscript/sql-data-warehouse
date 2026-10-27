-- product

--checking if cat id matches or not
SELECT *
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key,1,5),'-','_') NOT IN (
	SELECT cid
	FROM bronze.erp_px_cat_g1v2
)


SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt

--picking a particular product details by prd_key where dates are invalid (eg. prd_key - AC-HE-HL-U509-R, AC-HE-HL-U509)
SELECT *
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')
--there should not be overlapping of dates in every row as prd_cost cant be 11 and 14 same time
-- solution: end date =  start date from next record - 1

SELECT *,
DATEADD(DAY,-1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt))
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R','AC-HE-HL-U509')


-- sales
-- check if prd_key is in sales or not
SELECT *
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)


-- check for ouliers by validating boundaries of date range (like future dates and business start date)
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt >20500101 OR sls_order_dt < 19000101



--cust bdate
SELECT 
cid,
bdate
FROM bronze.erp_cust_az12

SELECT * 
FROM silver.crm_cust_info
WHERE cst_id LIKE 'NAS%'
--we see unneccessary NAS at start in erp cust az12 so remove it



-- joining in gold layer
SELECT DISTINCT 
ci.cst_gndr,
ca.gen,
CASE WHEN ci.cst_gndr = 'n/a' THEN ca.gen
		 ELSE ci.cst_gndr
	END AS gender
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid AND ci.cst_gndr != ca.gen
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid
