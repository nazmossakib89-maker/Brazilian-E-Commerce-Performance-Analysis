-- ============================================================
-- Brazilian E-Commerce Performance Analysis — SQL Queries
-- Dataset: Olist Brazilian E-Commerce (8 relational tables, ~99,000 orders)
-- Tool: MySQL Workbench
-- ============================================================


-- ============================================================
-- SETUP: Database and Table Creation
-- ============================================================

CREATE SCHEMA IF NOT EXISTS olist_ecommerce;

USE olist_ecommerce;

SET GLOBAL local_infile = 1;


-- ------------------------------------------------------------
-- Table: orders
-- ------------------------------------------------------------
CREATE TABLE olise_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/olist_orders_dataset.csv'
INTO TABLE olise_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- ------------------------------------------------------------
-- Table: customers
-- ------------------------------------------------------------
CREATE TABLE olise_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/olist_customers_dataset.csv'
INTO TABLE olise_customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);


-- ------------------------------------------------------------
-- Table: order_items
-- ------------------------------------------------------------
CREATE TABLE olise_order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/olist_order_items_dataset.csv'
INTO TABLE olise_order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(order_id, order_item_id, product_id, seller_id, @shipping_limit_date, price, freight_value)
SET
    shipping_limit_date = NULLIF(@shipping_limit_date, '');


-- ------------------------------------------------------------
-- Table: order_payments
-- ------------------------------------------------------------
CREATE TABLE olise_order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/olist_order_payments_dataset.csv'
INTO TABLE olise_order_payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(order_id, payment_sequential, payment_type, @payment_installments, @payment_value)
SET
    payment_installments = NULLIF(@payment_installments, ''),
    payment_value = NULLIF(@payment_value, '');


-- ------------------------------------------------------------
-- Table: order_reviews
-- NOTE: source CSV was pre-cleaned in Python to (1) remove embedded
-- newlines inside multi-line review text and (2) fully quote every
-- field, since MySQL's LOAD DATA INFILE silently mis-parsed rows
-- with mixed/partial quoting.
-- ------------------------------------------------------------
CREATE TABLE olise_order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/olist_order_reviews_dataset_cleaned.csv'
INTO TABLE olise_order_reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(review_id, order_id, @review_score, @review_comment_title, @review_comment_message,
 @review_creation_date, @review_answer_timestamp)
SET
    review_score = NULLIF(@review_score, ''),
    review_comment_title = NULLIF(@review_comment_title, ''),
    review_comment_message = NULLIF(@review_comment_message, ''),
    review_creation_date = NULLIF(@review_creation_date, ''),
    review_answer_timestamp = NULLIF(@review_answer_timestamp, '');


-- ------------------------------------------------------------
-- Table: products
-- ------------------------------------------------------------
CREATE TABLE olise_product (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/olist_products_dataset.csv'
INTO TABLE olise_product
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(product_id, @product_category_name, @product_name_lenght, @product_description_lenght,
 @product_photos_qty, @product_weight_g, @product_length_cm, @product_height_cm, @product_width_cm)
SET
    product_category_name = NULLIF(@product_category_name, ''),
    product_name_lenght = NULLIF(@product_name_lenght, ''),
    product_description_lenght = NULLIF(@product_description_lenght, ''),
    product_photos_qty = NULLIF(@product_photos_qty, ''),
    product_weight_g = NULLIF(@product_weight_g, ''),
    product_length_cm = NULLIF(@product_length_cm, ''),
    product_height_cm = NULLIF(@product_height_cm, ''),
    product_width_cm = NULLIF(@product_width_cm, '');


-- ------------------------------------------------------------
-- Table: sellers
-- ------------------------------------------------------------
CREATE TABLE olise_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/olist_sellers_dataset.csv'
INTO TABLE olise_sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(seller_id, seller_zip_code_prefix, seller_city, seller_state);


-- ------------------------------------------------------------
-- Table: category_translation
-- ------------------------------------------------------------
CREATE TABLE olise_category_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.7/Uploads/product_category_name_translation.csv'
INTO TABLE olise_category_translation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(product_category_name, product_category_name_english);


-- ------------------------------------------------------------
-- Verification: row counts across all tables
-- ------------------------------------------------------------
SELECT 'olise_orders' AS table_name, COUNT(*) AS row_count FROM olise_orders
UNION ALL
SELECT 'olise_order_items', COUNT(*) FROM olise_order_items
UNION ALL
SELECT 'olise_order_payments', COUNT(*) FROM olise_order_payments
UNION ALL
SELECT 'olise_order_reviews', COUNT(*) FROM olise_order_reviews
UNION ALL
SELECT 'olise_product', COUNT(*) FROM olise_product
UNION ALL
SELECT 'olise_customers', COUNT(*) FROM olise_customers
UNION ALL
SELECT 'olise_sellers', COUNT(*) FROM olise_sellers
UNION ALL
SELECT 'olise_category_translation', COUNT(*) FROM olise_category_translation;


-- ============================================================
-- BUSINESS QUESTIONS
-- ============================================================


-- ------------------------------------------------------------
-- Q1: Which product categories generate the highest revenue,
--     and which sell in high volume but underperform in revenue?
-- ------------------------------------------------------------
SELECT 
    ct.product_category_name_english,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM olise_order_items oi
JOIN olise_product p ON oi.product_id = p.product_id
JOIN olise_category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Q2: Does delivery time (purchase -> delivered) impact
--     customer review scores?
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN 'No Data'
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time or Early'
    END AS delivery_status,
    COUNT(r.review_id) AS review_count,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olise_orders o
JOIN olise_order_reviews r ON o.order_id = r.order_id
GROUP BY delivery_status
ORDER BY avg_review_score DESC;


-- ------------------------------------------------------------
-- Q3: Which states/cities have the highest customer concentration,
--     and what is the average order value there?
-- ------------------------------------------------------------
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM olise_customers c
JOIN olise_orders o ON c.customer_id = o.customer_id
JOIN olise_order_payments p ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Q4: How does payment type relate to average order value
--     and installment behavior?
-- ------------------------------------------------------------
SELECT
    payment_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(payment_value), 2) AS total_value,
    ROUND(AVG(payment_value), 2) AS avg_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM olise_order_payments
GROUP BY payment_type
ORDER BY total_value DESC;


-- ------------------------------------------------------------
-- Q5: Which sellers generate the most revenue, and how does
--     their delivery performance compare?
-- ------------------------------------------------------------
SELECT
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN oi.order_id END) * 100.0 
        / COUNT(DISTINCT oi.order_id), 2
    ) AS late_delivery_pct
FROM olise_order_items oi
JOIN olise_sellers s ON oi.seller_id = s.seller_id
JOIN olise_orders o ON oi.order_id = o.order_id
GROUP BY oi.seller_id, s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Q6: What percentage of orders are delivered late vs.
--     on-time/early?
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'No Data'
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'Late'
        ELSE 'On Time or Early'
    END AS delivery_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olise_orders), 2) AS percentage
FROM olise_orders
GROUP BY delivery_status
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- Q7: Which product categories receive the most negative
--     (1-2 star) reviews?
-- ------------------------------------------------------------
SELECT
    ct.product_category_name_english,
    COUNT(r.review_id) AS total_reviews,
    SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2) AS negative_pct
FROM olise_order_items oi
JOIN olise_product p ON oi.product_id = p.product_id
JOIN olise_category_translation ct ON p.product_category_name = ct.product_category_name
JOIN olise_order_reviews r ON oi.order_id = r.order_id
GROUP BY ct.product_category_name_english
HAVING total_reviews >= 30
ORDER BY negative_pct DESC
LIMIT 10;


-- ------------------------------------------------------------
-- Q8: How does freight (shipping) cost compare to product
--     price across categories?
-- ------------------------------------------------------------
SELECT
    ct.product_category_name_english,
    ROUND(AVG(oi.price), 2) AS avg_price,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(AVG(oi.freight_value) / AVG(oi.price) * 100, 2) AS freight_to_price_pct
FROM olise_order_items oi
JOIN olise_product p ON oi.product_id = p.product_id
JOIN olise_category_translation ct ON p.product_category_name = ct.product_category_name
GROUP BY ct.product_category_name_english
ORDER BY freight_to_price_pct DESC
LIMIT 10;