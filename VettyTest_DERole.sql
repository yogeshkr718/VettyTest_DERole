CREATE TABLE transactions (
    buyer_id VARCHAR(10),
    purchase_time DATETIME,
    refund_time DATETIME,
    refund_item VARCHAR(10),
    store_id VARCHAR(10),
    item_id VARCHAR(10),
    gross_transaction_value INT
);
INSERT INTO transactions 
(buyer_id, purchase_time, refund_time, refund_item, store_id, item_id, gross_transaction_value) VALUES
('3', '2019-09-19 21:19:06.544', NULL, NULL, 'a', 'a1', 58),
('12', '2019-12-10 20:10:14.324', '2019-12-15 23:19:06.544', 'b2', 'b', 'b2', 475),
('3', '2020-02-01 23:59:46.561', '2020-09-02 21:22:06.331', 'c2', 'f', 'f2', 31),
('12', '2020-04-30 20:01:19.222', NULL, NULL, 'd', 'd3', 2500),
('3', '2020-08-22 22:20:08.656', NULL, NULL, 'f', 'f7', 91),
('8', '2020-04-06 21:10:22.214', NULL, NULL, 'e', 'e7', 24),
('5', '2019-09-23 12:09:35.542', '2019-09-27 02:55:02.114', 'g6', 'g', 'g6', 61);

CREATE TABLE items (
    store_id VARCHAR(10),
    item_id VARCHAR(10),
    item_category VARCHAR(50),
    item_name VARCHAR(50)
);

INSERT INTO items 
(store_id, item_id, item_category, item_name)
VALUES
('a', 'a1', 'pants', 'denim pants'),
('a', 'a2', 'tops', 'blouse'),
('f', 'f1', 'table', 'coffee table'),
('f', 'f2', 'chair', 'lounge chair'),
('d', 'd3', 'chair', 'armchair'),
('f', 'f6', 'jewelry', 'bracelet'),
('b', 'b4', 'earphone', 'airpods');

SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS purchase_month,
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_time IS NULL      -- exclude refunded purchases
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m')
ORDER BY purchase_month;

SELECT 
    COUNT(*) AS stores_with_5plus_orders
FROM (
    SELECT 
        store_id,
        COUNT(*) AS order_count
    FROM transactions
    WHERE purchase_time >= '2020-10-01'
      AND purchase_time <  '2020-11-01'
    GROUP BY store_id
    HAVING COUNT(*) >= 5
) AS t;

SELECT
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_time)) AS shortest_refund_interval_min
FROM transactions
WHERE refund_time IS NOT NULL          
GROUP BY store_id;

WITH first_orders AS (
    SELECT
        store_id,
        gross_transaction_value,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
)
SELECT 
    store_id,
    gross_transaction_value AS first_order_gross_value
FROM first_orders
WHERE rn = 1;

WITH first_purchase AS (
    SELECT
        buyer_id,
        item_id,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
)
SELECT 
    i.item_name,
    COUNT(*) AS times_ordered
FROM first_purchase fp
JOIN items i USING (item_id)
WHERE fp.rn = 1                
GROUP BY i.item_name
ORDER BY times_ordered DESC
LIMIT 1;  

SELECT
    *,
    CASE 
        WHEN refund_time IS NOT NULL
             AND TIMESTAMPDIFF(HOUR, purchase_time, refund_time) <= 72
        THEN 1
        ELSE 0
    END AS refund_process_flag
FROM transactions;

WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS purchase_rank
    FROM transactions
    WHERE refund_time IS NULL   -- ignore refunded purchases
)
SELECT *
FROM ranked
WHERE purchase_rank = 2;

WITH ranked AS (
    SELECT
        buyer_id,
        purchase_time,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS rn
    FROM transactions
)
SELECT
    buyer_id,
    purchase_time AS second_transaction_time
FROM ranked
WHERE rn = 2;



                     












