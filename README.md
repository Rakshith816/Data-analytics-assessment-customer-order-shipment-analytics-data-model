# Customer Order & Shipment Analytics – Data Modeling

## Overview
This project focuses on analyzing raw customer, order, and shipment data to identify data gaps and design a scalable analytical data model.  

The objective is to propose a well-structured dimensional model that supports accurate reporting for:
- Customer transactions
- Product-level analysis
- Shipment and delivery tracking

---

## Objectives
- Evaluate existing datasets and identify data quality and modeling gaps  
- Define requirements for anticipated datasets  
- Design a dimensional data model with correct grain and relationships  
- Enable accurate aggregation and reporting without data duplication  

---

## Key Findings from Data Analysis
- Shipping data is linked at the customer level and not at the order level  
- No direct mapping exists between `order_id` and `shipment_id`  
- Presence of orphan shipping records without corresponding orders  
- Missing attributes such as quantity and shipment timestamps  
- Inconsistent shipment counts compared to order counts  

---

## Proposed Data Model

The model follows a dimensional design approach:

### 🔹 Dimension Tables
- **Dim_Customer (SCD Type 2)** – Tracks historical customer attributes  
- **Dim_Product** – Standardized product information  

### 🔹 Fact Tables
- **Fact_Order** – One row per order  
- **Fact_Product_Order** – One row per order-product  
- **Fact_Shipping** – One row per shipment (tracks shipment lifecycle)  

### 🔹 Bridge Table
- **Order_Shipment_Bridge** – Resolves many-to-many relationship between orders and shipments  

---

## Key Design Decisions
- Separation of order data into header and line tables to maintain correct grain  
- Use of surrogate key (`customer_sk`) for SCD implementation  
- Use of bridge table to avoid duplication in many-to-many relationships  
- Shipment lifecycle tracked using `shipment_date` and `delivery_date`  
 

---

##  Data Relationships
- Customer -> Order  (1:M)  
- Order ->  Product Order Line (1:M)  
- Product -> Product Order Line (1:M)  
- Order -> order Shipment bridge (1:M) 
- Shipment -> order Shipment bridge (1:M)   

---

## Business Questions Addressed
The proposed model supports answering:
1. Total amount for pending deliveries by country  
2. Total transactions, quantity, and amount per customer and product  
3. Most purchased product by country  
4. Most purchased product by age category  
5. Country with minimum transactions and sales  

---

## Repository Structure

- [Detail Ask](docs/DataAnalystTask.pdf): Details of the task
- [Raw Data Validation](sql/RawDataValidation.sql) : Raw data validation checks 
- [Data modelling doc](docs/CustomerOrderAnalytics_DataModeling_RequirementsDocument.pdf): Data modeling document
- [ERD](docs/ERD.png): Entity relationship diagram
- [User story](docs/Data_Modeling_User_story.pdf): Data modeling user story 
- [Business Questions](sql/Business_Questions_Queries.sql) : Queries that answers business requirements  
- [Rough](sql/ROUGH_WORKBOOK.sql) : Understanding the raw data  
- [data](data/)  : data
