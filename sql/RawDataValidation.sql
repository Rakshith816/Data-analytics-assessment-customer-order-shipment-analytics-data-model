--Author: Ramrakshith Biradar Patil

USE ASSESSMENT_DB;
USE SCHEMA PUBLIC_RAW;
ALTER SESSION SET ROWS_PER_RESULTSET = 0;
USE SECONDARY ROLES ALL;



--------------------------------------------------------------------------------------------------------------------------------------------
--NULL Check: PASS: There are no NULL values in Primary columns of respective tables
--------------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS
WHERE CUSTOMER_ID IS NULL;

SELECT *
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS
WHERE ORDER_ID IS NULL;

SELECT * 
FROM  ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS;

--Create  table for  parsed shipping value details

CREATE  TABLE SHIPPING_DETAILS_PARSED AS 
SELECT
    JASON_SHIPPING:Customer_ID::VARCHAR        AS CUSTOMER_ID,
    JASON_SHIPPING:Shipping_ID::VARCHAR        AS SHIPPRawING_ID,
    JASON_SHIPPING:Status::VARCHAR         AS STATUS
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS
ORDER BY CUSTOMER_ID
;
SELECT * FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED;

SELECT * 
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED
WHERE SHIPPING_ID IS NULL;

--------------------------------------------------------------------------------------------------------------------------------------------
--PK Deduplication checks: PASS: There are no duplicates in any of the table
--------------------------------------------------------------------------------------------------------------------------------------------

SELECT CUSTOMER_ID, COUNT(*) AS COUNT
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS
GROUP BY CUSTOMER_ID
HAVING COUNT > 1;


SELECT ORDER_ID, COUNT(*) AS COUNT
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS
GROUP BY ORDER_ID
HAVING COUNT > 1;

SELECT SHIPPING_ID, COUNT(*) AS COUNT
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED
GROUP BY SHIPPING_ID
HAVING COUNT > 1;

--------------------------------------------------------------------------------------------------------------------------------------------
--REFFERENTIAL INTEGRITY CHECKS: 3 out of 4 checks passed
--------------------------------------------------------------------------------------------------------------------------------------------

-- 1. There can be no orders without a customer.: PASS
SELECT * 
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS A
LEFT JOIN ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS B
ON A.CUSTOMER_ID = B.CUSTOMER_ID
WHERE B.CUSTOMER_ID IS NULL;
-- 2. Each customer can have one/multiple orders, but each order always belongs to exactly one customer: PASS
SELECT ORDER_ID
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS A
JOIN ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS B
ON A.CUSTOMER_ID = B.CUSTOMER_ID
GROUP BY 1
HAVING COUNT(DISTINCT A.CUSTOMER_ID) > 1;



--3. There can be no shipments without a customer order .: FAIL
SELECT COUNT(DISTINCT A.SHIPPING_ID) AS INVALID_SHIPPING_ID,
COUNT(DISTINCT A.CUSTOMER_ID) AS CUSTOMER_WITHOUT_ORDERS_WITH_SHIPMENT
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED A
LEFT JOIN ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS B
ON A.CUSTOMER_ID = B.CUSTOMER_ID
WHERE B.CUSTOMER_ID IS NULL;

-- A total of 98 shipping records corresponding to 55 customers were identified without matching order records.
-- These represent orphan shipping records where no order transaction data exists.

--4. Each customer order can have one/multiple shipping ID's, but shippment  always belongs to exactly one order: PASS
SELECT SHIPPING_ID
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED A
JOIN ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS B
ON A.CUSTOMER_ID = B.CUSTOMER_ID
GROUP BY 1
HAVING COUNT(DISTINCT A.CUSTOMER_ID) > 1; 

--------------------------------------------------------------------------------------------------------------------------------------------
--DATA TYPE CHECKS: PASS
--------------------------------------------------------------------------------------------------------------------------------------------


SELECT *
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS
WHERE TRY_CAST(AGE AS NUMBER) IS NULL OR 
TRY_CAST(CUSTOMER_ID AS VARCHAR) IS NULL OR
TRY_CAST(FIRST_NAME AS VARCHAR) IS NULL OR
TRY_CAST(LAST_NAME AS VARCHAR) IS NULL OR
TRY_CAST(COUNTRY AS VARCHAR) IS NULL;


SELECT *
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS
WHERE TRY_CAST(ORDER_ID AS VARCHAR) IS NULL OR
TRY_CAST(CUSTOMER_ID AS VARCHAR) IS NULL OR
TRY_CAST(ITEM AS VARCHAR) IS NULL OR
TRY_CAST(AMOUNT AS NUMBER) IS NULL;

SELECT *
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED
WHERE TRY_CAST(CUSTOMER_ID AS VARCHAR) IS NULL OR
TRY_CAST(SHIPPING_ID AS VARCHAR) IS NULL OR
TRY_CAST(STATUS AS VARCHAR) IS NULL ;

--------------------------------------------------------------------------------------------------------------------------------------------
-- RANGE VALIDATION: PASS
--------------------------------------------------------------------------------------------------------------------------------------------

SELECT * 
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS
WHERE AGE < 0 OR AGE > 150;

SELECT DISTINCT COUNTRY
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS;

SELECT *
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS
WHERE LENGTH(FIRST_NAME) = 0 
OR LENGTH(LAST_NAME) = 0;

SELECT *
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS
WHERE AMOUNT<0;

SELECT * 
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS
WHERE ITEM IS NULL OR LENGTH(ITEM) = 0;

SELECT DISTINCT STATUS
FROM SHIPPING_DETAILS_PARSED;

SELECT * 
FROM SHIPPING_DETAILS_PARSED
WHERE UPPER(TRIM(STATUS)) NOT IN ('PENDING','DELIVERED') ;

--------------------------------------------------------------------------------------------------------------------------------------------
--VOLUME CHECKS: PASS
--------------------------------------------------------------------------------------------------------------------------------------------

--1. Customers with no orders + Customer with orders = Total customers from customer table: PASS

SELECT COUNT(DISTINCT A.CUSTOMER_ID) AS TOTAL_CUSTOMERS,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_NO_ORDERS,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NOT NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_ORDERS
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS A
LEFT JOIN ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS B
ON A.CUSTOMER_ID = B.CUSTOMER_ID;

--TOTAL_CUSTOMERS	CUSTOMERS_WITH_NO_ORDERS	CUSTOMERS_WITH_ORDERS
--      250	                   90	                     160

-- 2. Total customers with orders = Customer orders with no shipment + Customer orders with shipment: PASS
SELECT COUNT(DISTINCT A.CUSTOMER_ID) AS TOTAL_CUSTOMERS_WITH_ORDERS,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_NO_SHIPMENT,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NOT NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_SHIPMENT
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS A 
LEFT JOIN ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED B
ON A.CUSTOMER_ID = B.CUSTOMER_ID;

-- TOTAL_CUSTOMERS_WITH_ORDERS	CUSTOMERS_WITH_ORDERS_NO_SHIPMENT	CUSTOMERS_WITH_ORDERS_SHIPMENT
--              160	                          61	                  99


--3. Customers with no shipment + Customer with shipment = Total customers from customer table: PASS
SELECT COUNT(DISTINCT A.CUSTOMER_ID) AS TOTAL_CUSTOMERS,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_NO_SHIPMENT,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NOT NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_SHIPMENT
FROM ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS A 
LEFT JOIN ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED B
ON A.CUSTOMER_ID = B.CUSTOMER_ID;

-- TOTAL_CUSTOMERS	TOTAL_CUSTOMERS_WITH_NO_SHIPMENT	TOTAL_CUSTOMERS_WITH_SHIPMENT
--       250	               96	                        154

--4. To validate if the shipment customers are not part of customer table: PASS 
SELECT COUNT(DISTINCT A.CUSTOMER_ID) AS TOTAL_CUSTOMERS_WITH_SHIPMENT_IDS,
COUNT(DISTINCT A.SHIPPING_ID) AS TOTAL_SHIPPING_IDS,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_SHIPMENT_NOT_IN_CUSTOMER_TABLE,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NOT NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_SHIPMENT_IN_CUSTOMER_TABLE
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED  A 
LEFT JOIN ASSESSMENT_DB.PUBLIC_RAW.CUSTOMER_DETAILS B
ON A.CUSTOMER_ID = B.CUSTOMER_ID;

--5. Total customer with shipment = Customer with shipment no orders + customer with shipment orders: PASS
--Note: Customer with shipment no orders are problmatic one's
SELECT COUNT(DISTINCT A.CUSTOMER_ID) AS TOTAL_CUSTOMERS_WITH_SHIPMENT_IDS,
COUNT(DISTINCT A.SHIPPING_ID) AS TOTAL_SHIPPING_IDS,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_SHIPMENT_WITH_NO_ORDERS,
COUNT(DISTINCT CASE WHEN  B.CUSTOMER_ID IS NOT NULL THEN A.CUSTOMER_ID END) AS CUSTOMERS_WITH_SHIPMENT_ORDERS
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED  A 
LEFT JOIN ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS B
ON A.CUSTOMER_ID = B.CUSTOMER_ID;

--TOTAL_CUSTOMERS_WITH_SHIPMENT_IDS	TOTAL_SHIPPING_IDS	CUSTOMERS_WITH_SHIPMENT_WITH_NO_ORDERS	CUSTOMERS_WITH_SHIPMENT_ORDERS
--                      154             	250	                      55	                                99

--------------------------------------------------------------------------------------------------------------------------------------------
--DATA CONSISTENCY CHECK:
--------------------------------------------------------------------------------------------------------------------------------------------

WITH DELIEVERED AS(
SELECT CUSTOMER_ID,COUNT(DISTINCT SHIPPING_ID) AS CNT
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED
WHERE UPPER(TRIM(STATUS))='DELIVERED'
GROUP BY 1
)

, ORDERS AS (SELECT CUSTOMER_ID,COUNT(DISTINCT order_id) AS CNT
FROM ASSESSMENT_DB.PUBLIC_RAW.ORDER_DETAILS
GROUP BY 1)
SELECT A.CUSTOMER_ID,A.CNT,B.CNT
FROM DELIEVERED A JOIN ORDERS B ON A.CUSTOMER_ID=B.CUSTOMER_ID
WHERE A.CNT>B.CNT;

--There are 6 customers who have more delivered shipments than orders

-- CUSTOMER_ID
-- 40
-- 242
-- 37
-- 232
-- 15
-- 12

--Each shipping ID has one distict status 
SELECT SHIPPING_ID,
COUNT(DISTINCT STATUS) AS STATUS_COUNT
FROM ASSESSMENT_DB.PUBLIC_RAW.SHIPPING_DETAILS_PARSED
GROUP BY 1
ORDER BY STATUS_COUNT DESC;

--------------------------------------------------------------------------------------------------------------------------------------------
--DATA VALIDATION/ QUALITY CHECK CMPLETED:
--------------------------------------------------------------------------------------------------------------------------------------------