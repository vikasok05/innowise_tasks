CREATE TABLE IF NOT EXISTS superstore ( --this would be for initial load
    row_id         INTEGER,
    order_id       VARCHAR(50),
    order_date     DATE,
    ship_date      DATE,
    ship_mode      VARCHAR(50),
    customer_id    VARCHAR(50),
    customer_name  VARCHAR(100),
    segment        VARCHAR(50),
    country        VARCHAR(50),
    city           VARCHAR(100),
    statee         VARCHAR(50),
    postal_code    VARCHAR(20),
    region         VARCHAR(50),
    product_id     VARCHAR(50),
    category       VARCHAR(50),
    sub_category   VARCHAR(50),
    product_name   VARCHAR(200),
    sales          NUMERIC(12,3),
    quantity       INTEGER,
    discount       NUMERIC(5,2),
    profit         NUMERIC(12,2)
);

SET datestyle = 'MDY';

--1st load

COPY superstore(row_id, order_id, order_date, ship_date, ship_mode, customer_id, 
    customer_name, segment, country, city, statee, postal_code, region, 
    product_id, category, sub_category, product_name, sales, quantity, 
    discount, profit)
FROM 'D:/Inn/BI task/Sample - Superstore 9000.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
    HEADER true,
    ENCODING 'WIN1252'
);

CREATE TABLE customers
(
	customer_key   SERIAL PRIMARY KEY,
 	customer_id    VARCHAR(50),
    customer_name  VARCHAR(100),
    segment        VARCHAR(50)
);

INSERT INTO customers (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM superstore;

ALTER TABLE customers
ADD COLUMN	valid_from DATE,
ADD COLUMN	valid_to DATE,
ADD COLUMN	is_current BOOLEAN;

UPDATE customers
SET valid_from = CURRENT_DATE,
	is_current = TRUE;

--DROP TABLE customers;

CREATE TABLE products
(
	product_key    SERIAL PRIMARY KEY,
    product_id     VARCHAR(50),
    category       VARCHAR(50),
    sub_category   VARCHAR(50),
    product_name   VARCHAR(200)
);

INSERT INTO products (product_id, category, sub_category, product_name)
SELECT DISTINCT product_id, category, sub_category, product_name
FROM superstore;

ALTER TABLE products
ADD	COLUMN valid_from DATE,
ADD COLUMN valid_to DATE,
ADD COLUMN is_current BOOLEAN;

UPDATE products
SET 
	valid_from = CURRENT_DATE,
	is_current = TRUE;

--DROP TABLE products;

CREATE TABLE locations
(
	location_key   SERIAL PRIMARY KEY,
	country        VARCHAR(50),
    city           VARCHAR(100),
    statee         VARCHAR(50),
    postal_code    VARCHAR(20),
    region         VARCHAR(50)
	--UNIQUE (country, city, statee, postal_code, region)
);

INSERT INTO locations (country, city, statee, postal_code, region)
SELECT DISTINCT country, city, statee, postal_code, region
FROM superstore;

--DROP TABLE locations;

CREATE TABLE orders
(
    order_id       VARCHAR(50),
    order_date     DATE,
    ship_date      DATE,
    ship_mode      VARCHAR(50),
	
	customer_key    INTEGER,
    product_key     INTEGER,
	location_key    INTEGER,
	
	sales          NUMERIC(12,3),
    quantity       INTEGER,
    discount       NUMERIC(5,2),
    profit         NUMERIC(12,2)
);

INSERT INTO orders (
	order_id,
	order_date, 
	ship_date, 
	ship_mode,
	
	customer_key, 
	product_key, 
	location_key, 
	
	sales, 
	quantity, 
	discount, 
	profit
)
SELECT order_id, order_date, ship_date, ship_mode, customer_key, product_key, location_key, sales, quantity, discount, profit
FROM superstore
INNER JOIN customers USING(customer_id)
INNER JOIN products USING(product_id)
INNER JOIN locations ON superstore.country = locations.country
	AND superstore.city = locations.city
	AND superstore.statee = locations.statee
	AND superstore.postal_code = locations.postal_code
	AND superstore.region = locations.region;

DROP TABLE superstore;

CREATE TABLE IF NOT EXISTS superstore_secondary (
    row_id         INTEGER,
    order_id       VARCHAR(50),
    order_date     DATE,
    ship_date      DATE,
    ship_mode      VARCHAR(50),
    customer_id    VARCHAR(50),
    customer_name  VARCHAR(100),
    segment        VARCHAR(50),
    country        VARCHAR(50),
    city           VARCHAR(100),
    statee         VARCHAR(50),
    postal_code    VARCHAR(20),
    region         VARCHAR(50),
    product_id     VARCHAR(50),
    category       VARCHAR(50),
    sub_category   VARCHAR(50),
    product_name   VARCHAR(200),
    sales          NUMERIC(12,3),
    quantity       INTEGER,
    discount       NUMERIC(5,2),
    profit         NUMERIC(12,4)
);

--2nd load
COPY superstore_secondary(row_id, order_id, order_date, ship_date, ship_mode, customer_id, 
    customer_name, segment, country, city, statee, postal_code, region, 
    product_id, category, sub_category, product_name, sales, quantity, 
    discount, profit)
FROM 'D:/Inn/BI task/Sample - Superstore 8990-9994.csv'
WITH (
    FORMAT csv,
    DELIMITER ',',
	HEADER true,
    ENCODING 'WIN1252'
);

UPDATE customers c
SET
    valid_to = CURRENT_DATE - INTERVAL '1 day',
    is_current = FALSE
FROM superstore_secondary s
WHERE
    c.customer_id = s.customer_id
    AND c.is_current = TRUE
	AND (c.customer_name IS DISTINCT FROM s.customer_name
	OR c.segment IS DISTINCT FROM s.segment );

INSERT INTO customers (customer_id, customer_name, segment, valid_from, valid_to, is_current)
SELECT s.customer_id, s.customer_name, s.segment,  CURRENT_DATE, DATE '12-31-9999', TRUE
FROM superstore_secondary s
LEFT JOIN customers c ON c.customer_id = s.customer_id AND c.is_current = TRUE
WHERE c.customer_id IS NULL          
    OR (c.customer_name IS DISTINCT FROM s.customer_name
        OR c.segment IS DISTINCT FROM s.segment);

/*SELECT customer_id, COUNT(*)
FROM customers
WHERE is_current = TRUE
GROUP BY customer_id
HAVING COUNT(*) > 1;*/

UPDATE products
SET 
	valid_to = CURRENT_DATE - INTERVAL '1 day',
	is_current = FALSE
FROM superstore_secondary s
INNER JOIN products p ON p.product_id = s.product_id AND p.is_current = TRUE
WHERE p.product_id = s.product_id
    AND p.is_current = TRUE
    AND (p.category IS DISTINCT FROM s.category
        OR p.sub_category IS DISTINCT FROM s.sub_category
        OR p.product_name IS DISTINCT FROM s.product_name);

INSERT INTO products (product_id, category, sub_category, product_name, valid_from, is_current)
SELECT s.product_id, s.category, s.sub_category, s.product_name, CURRENT_DATE, TRUE
FROM superstore_secondary s
LEFT JOIN products p ON p.product_id = s.product_id AND p.is_current = TRUE
WHERE p.product_id IS NULL
    OR (p.category IS DISTINCT FROM s.category
        OR p.sub_category IS DISTINCT FROM s.sub_category
        OR p.product_name IS DISTINCT FROM s.product_name);

INSERT INTO orders (order_date, ship_date, ship_mode, customer_key, product_key, location_key, sales, quantity, discount, profit)
SELECT order_date, ship_date, ship_mode, customer_key, product_key, location_key, sales, quantity, discount, profit
FROM superstore_secondary s
INNER JOIN products p ON s.product_id = p.product_id AND p.is_current = TRUE
INNER JOIN customers c ON s.customer_id = c.customer_id AND c.is_current = TRUE
INNER JOIN locations ON s.country = locations.country AND
	s.city = locations.city AND
	s.statee = locations.statee AND
	s.postal_code = locations.postal_code AND
	s.region =locations.region
WHERE NOT EXISTS 
(
SELECT 1
FROM orders o
WHERE o.order_id = s.order_id
);
	
DROP TABLE superstore_secondary;

--DROP SCHEMA public CASCADE;
--CREATE SCHEMA public;

SELECT COUNT(*)
FROM orders;

CREATE TABLE mart_sales AS
SELECT o.order_date, c.customer_name, c.segment, p.category, p.sub_category, l.region, o.sales, o.quantity, o.profit
FROM orders o
JOIN customers c ON o.customer_key = c.customer_key
JOIN products p ON o.product_key = p.product_key
JOIN locations l ON o.location_key = l.location_key;

INSERT INTO mart_sales
SELECT o.order_date, c.customer_name, c.segment, p.category, p.sub_category, l.region, o.sales, o.quantity, o.profit
FROM orders o
JOIN customers c ON o.customer_key = c.customer_key
JOIN products p ON o.product_key = p.product_key
JOIN locations l ON o.location_key = l.location_key;
