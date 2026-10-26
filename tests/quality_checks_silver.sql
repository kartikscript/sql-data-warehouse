-- Quality checks
-- ***************************************************
-- Basic cleaning steps : 
-- 	>>check nulls and duplicates for primary key (eg. cust_id, cust_key). if there are duplicates, then logically choose one row and remove others.
-- 	>>check unwanted spaces
-- 	>>Data standardization and consistency meaning to map coded value to clear,meaningful description (eg. 'M' converted to 'Male')
-- 	>>handle missing data (eg. nulls to 'n/a')

-- Note : Run these checks after loading silver layer
-- ***************************************************

--checking for duplicates and nulls 
SELECT *
FROM bronze.crm_cust_info
WHERE cst_key IS NULL;

SELECT cst_id, COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

--extracting the latest customer details from duplicates
SELECT * 
FROM (
	SELECT *, ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM silver.crm_cust_info
)t WHERE flag_last = 1 AND cst_id IS NOT NULL
;

--checking for unwanted spaces
SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
;

--data standardization
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;


--Product

--checking for duplicates and nulls 
SELECT prd_id, COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;


--checking for unwanted spaces
SELECT *
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- check for nulls or negatives
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost <0 OR prd_cost IS NULL;

--data standardization and consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Checking for invalid date orders -- end date shouldn't be earlier than start date
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

SELECT *
FROM silver.crm_prd_info;



-- sales
--check nulls
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key != TRIM(sls_prd_key);

SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id IS NULL



-- check for invalid dates(negatives and zeroes numbers) and len of date which should be 8 for formatting. eg(20101229 -- YYYYMMDD)
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8
OR sls_order_dt >20500101 
OR sls_order_dt < 19000101;

--check for order date which should be earlier than shipping or due date
SELECT *
FROM silver.crm_sales_details
WHERE (sls_order_dt > sls_ship_dt) OR (sls_order_dt > sls_due_dt)
--no data returned so we have a good data

--check sales, quantity and price logics
SELECT sls_price,sls_quantity,sls_sales
FROM silver.crm_sales_details
WHERE sls_sales != sls_price * sls_quantity
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales

SELECT *
FROM silver.crm_sales_details


-- erp cust az12
--check invalid birth dates
SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE()

--data standardization
SELECT DISTINCT gen
FROM silver.erp_cust_az12

SELECT *
FROM silver.erp_cust_az12


--erp loc a101

SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry

SELECT *
FROM silver.erp_loc_a101


-- erp cat

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2

SELECT *
FROM silver.erp_px_cat_g1v2
