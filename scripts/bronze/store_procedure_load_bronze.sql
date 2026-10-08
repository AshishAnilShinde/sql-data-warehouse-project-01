EXEC bronze.load_bronze;

--DATA INGESTION IN TABLES 
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '===============================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '===============================';


		PRINT '********************************';
		PRINT 'LOADING CRM TABLES';
		PRINT '********************************';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info
		BULK INSERT bronze.crm_cust_info
		FROM 'E:\DA Projects\SQL Projects\Main Project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		--SELECT COUNT(*) FROM bronze.crm_cust_info;

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_prd_info
		BULK INSERT bronze.crm_prd_info
		FROM 'E:\DA Projects\SQL Projects\Main Project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		--SELECT COUNT(*) FROM bronze.crm_prd_info;

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_sales_details
		BULK INSERT bronze.crm_sales_details
		FROM 'E:\DA Projects\SQL Projects\Main Project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		--SELECT COUNT(*) FROM bronze.crm_sales_details;


		PRINT '################################';
		PRINT 'LOADING ERP TABLES';
		PRINT '################################';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_cust_az12
		BULK INSERT bronze.erp_cust_az12
		FROM 'E:\DA Projects\SQL Projects\Main Project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		--SELECT COUNT(*) FROM bronze.erp_cust_az12;

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_loc_a101
		BULK INSERT bronze.erp_loc_a101 
		FROM 'E:\DA Projects\SQL Projects\Main Project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		--SELECT COUNT(*) FROM bronze.erp_loc_a101

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_px_cat_g1v2
		BULK INSERT bronze.erp_px_cat_g1v2 
		FROM 'E:\DA Projects\SQL Projects\Main Project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> LOADING DURATION: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
		--SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2
		SET @batch_end_time = GETDATE();
		PRINT '>> BATCH LOADING DURATION: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
	END TRY

	BEGIN CATCH
		PRINT '===========================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '===========================================';
	END CATCH

END;
