--------------------------------------------------------------------------------------------------------------------------------------------
-- 1.  The total amount spent and the country for the Pending delivery status for each country. 
--------------------------------------------------------------------------------------------------------------------------------------------
WITH order_status AS (
    SELECT
        b.order_id,
        CASE 
            WHEN MAX(CASE WHEN s.status = 'PENDING' THEN 1 ELSE 0 END) = 1 
                THEN 'PENDING'
            ELSE 'DELIVERED'
        END AS order_status
    FROM Order_Shipment_Bridge b
    JOIN Fact_Shipping s
        ON b.shipment_id = s.shipment_id
    GROUP BY b.order_id
)

SELECT
    c.country,
    SUM(o.total_amount) AS total_amount
FROM Fact_Order o
JOIN order_status os
    ON o.order_id = os.order_id
JOIN Dim_Customer c
    ON o.customer_sk = c.customer_sk
WHERE os.order_status = 'PENDING'
GROUP BY c.country;


--------------------------------------------------------------------------------------------------------------------------------------------
-- 2. The total number of transactions, total quantity sold, and total amount spent for each customer, along with the product details. 
--------------------------------------------------------------------------------------------------------------------------------------------


SELECT
    c.customer_id,
    p.product_name,
    COUNT(DISTINCT o.order_id) AS total_transactions,
    SUM(ol.quantity) AS total_quantity,
    SUM(ol.amount) AS total_amount
FROM Fact_Order o
JOIN Fact_Product_Order ol
    ON o.order_id = ol.order_id
JOIN Dim_Product p
    ON ol.product_id = p.product_id
JOIN Dim_Customer c
    ON o.customer_sk = c.customer_sk
GROUP BY c.customer_id, p.product_name;


--------------------------------------------------------------------------------------------------------------------------------------------
-- 3. The maximum product purchased for each country: Most purchsed product
--------------------------------------------------------------------------------------------------------------------------------------------


 SELECT
        c.country,
        p.product_name,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM Fact_Order o
    JOIN Fact_Product_Order ol
        ON o.order_id = ol.order_id
    JOIN Dim_Product p
        ON ol.product_id = p.product_id
    JOIN Dim_Customer c
        ON o.customer_sk = c.customer_sk
    GROUP BY c.country, p.product_name
    QUALIFY DENSE_RANK() OVER (PARTITION BY c.country ORDER BY COUNT(DISTINCT o.order_id) DESC) =1

--------------------------------------------------------------------------------------------------------------------------------------------
--4.  The most purchased product based on the age category less than 30 and above 30. 
--------------------------------------------------------------------------------------------------------------------------------------------

SELECT
        CASE 
            WHEN c.age < 30 THEN 'LESS THAN 30'
            ELSE 'GREATER THAN 30'
        END AS age_category,
        p.product_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
      
    FROM Fact_Order o
    JOIN Fact_Product_Order ol
        ON o.order_id = ol.order_id
    JOIN Dim_Product p
        ON ol.product_id = p.product_id
    JOIN Dim_Customer c
        ON o.customer_sk = c.customer_sk
    GROUP BY age_category, p.product_name

    QUALIFY   DENSE_RANK() OVER ( PARTITION BY age_category ORDER BY COUNT(DISTINCT o.order_id) DESC)=1


--------------------------------------------------------------------------------------------------------------------------------------------
--5. The country that had minimum transactions and sales amount. 
--------------------------------------------------------------------------------------------------------------------------------------------


 SELECT
        c.country,
        COUNT(DISTINCT o.order_id) AS total_transactions,
        SUM(o.total_amount) AS total_amount,
       
    FROM Fact_Order o
    JOIN Dim_Customer c
        ON o.customer_sk = c.customer_sk
    GROUP BY c.country
    QUALIFY  DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT o.order_id), SUM(o.total_amount))  =1  

--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
