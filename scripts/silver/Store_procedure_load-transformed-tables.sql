CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME
	DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME

	BEGIN TRY

		SET @batch_start_time = GETDATE();

		------------------------------------------------------------------
		-- TABLE 1: silver.crm_cust_info
		------------------------------------------------------------------
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;

		PRINT '>> Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_material_status,
			cst_gndr,
			cst_create_date
		)
		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,

		CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'SINGLE'
			 WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'MARRIED'
			 ELSE 'N/A'
		END AS cst_material_status,

		CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
			 WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
			 ELSE 'N/A'
		END AS cst_gndr,

		cst_create_date
		FROM
			(SELECT
			*,
			ROW_NUMBER () OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info)t
		WHERE flag_last = 1;

		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		------------------------------------------------------------------
		-- TABLE 2: silver.crm_prd_info
		------------------------------------------------------------------
		SET @start_time = GETDATE();

		IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
			DROP TABLE silver.crm_prd_info;
		CREATE TABLE silver.crm_prd_info(
			prd_id INT,
			cat_id NVARCHAR(50),
			prd_key NVARCHAR(50),
			prd_nm NVARCHAR(50),
			prd_cost INT,
			prd_line NVARCHAR(50),
			prd_start_dt DATE,
			prd_end_dt DATE,
			dwh_create_date DATETIME2 DEFAULT GETDATE()
		);

		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT '>> Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-','_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			prd_nm,
			ISNULL (prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,
			CAST(prd_start_dt AS DATE) AS prd_start_dt,
			CAST(LEAD(prd_end_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		  FROM bronze.crm_prd_info;

		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		------------------------------------------------------------------
		-- TABLE 3: silver.crm_sales_details
		------------------------------------------------------------------
		SET @start_time = GETDATE();

		IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
			DROP TABLE silver.crm_sales_details;
		CREATE TABLE silver.crm_sales_details (
			sls_ord_num NVARCHAR(50),
			sls_prd_key NVARCHAR(50),
			sls_cust_id INT,
			sls_order_dt DATE,
			sls_ship_dt DATE,
			sls_due_dt DATE,
			sls_sales INT,
			sls_quantity INT,
			sls_price INT,
			dwh_create_date DATETIME2 DEFAULT GETDATE()
		);

		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;

		PRINT '>> Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE WHEN sls_order_dt <=0 OR LEN(sls_order_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,
	
			CASE WHEN sls_ship_dt <0 OR LEN(sls_ship_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END sls_ship_dt,

			CASE WHEN sls_due_dt <0 OR LEN(sls_due_dt) != 8 THEN NULL
				 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END sls_due_dt,
			CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
				 THEN sls_quantity * ABS(sls_price)
				 ELSE sls_sales
			END AS sls_sales, --RECALCULATE SALES IF ORIGINAL VALUE IS MISSING OR INCORRECT

			sls_quantity,

			CASE WHEN sls_price IS NULL OR sls_price <= 0 
				 THEN sls_sales / ISNULL(sls_quantity,0)
				 ELSE sls_price
			END AS sls_price --DERIVE PRICE IF ORIGINAL VALUE IS INVALID
		FROM bronze.crm_sales_details;

		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		------------------------------------------------------------------
		-- TABLE 4: silver.erp_cust_az12
		------------------------------------------------------------------
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;

		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)
		SELECT 
			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4,LEN(cid))
				 ELSE cid
			END AS cid,

			CASE WHEN bdate > GETDATE() THEN NULL
				 ELSE bdate
			END AS bdate,

			CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				 ELSE 'n/a'
			END AS gen
		FROM bronze.erp_cust_az12;

		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		------------------------------------------------------------------
		-- TABLE 5: silver.erp_loc_a101
		------------------------------------------------------------------
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;

		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
		)
		SELECT 
			REPLACE(cid, '-', '') AS cid,

			CASE WHEN UPPER(TRIM(cntry)) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
				 WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
				 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
				 ELSE TRIM(cntry)
			END AS cntry
		FROM bronze.erp_loc_a101;

		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		------------------------------------------------------------------
		-- TABLE 6: silver.erp_px_cat_g1v2
		------------------------------------------------------------------
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;

		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';


		------------------------------------------------------------------
		-- BATCH END
		------------------------------------------------------------------
		SET @batch_end_time = GETDATE();
		PRINT '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
		PRINT '>> BATCH LOADING DURATION: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';

	END TRY

	BEGIN CATCH
		PRINT '===========================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '===========================================';
	END CATCH

END

EXEC silver.load_silver
