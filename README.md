# VettyTest_DERole

1. Count of purchases per month (excluding refunded purchases)

```sql
SELECT 
    DATE_FORMAT(purchase_time, '%Y-%m') AS purchase_month,
    COUNT(*) AS purchase_count
FROM transactions
WHERE refund_time IS NULL
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m')
ORDER BY purchase_month;
```

**Explanation (in layman terms):**

* I first convert the purchase date into a **Year-Month format** like `2020-08`, `2020-09`, etc.
* I only take those transactions **where there is no refund** (i.e., `refund_time` is empty).
* Then I **group** all these transactions by month and **count** how many happened in each month.
* Finally, I sort the result by month so that the output is in order.

In short:
This query tells me **how many valid (non-refunded) purchases happened in each month.**

**OUTPUT**
<img width="1157" height="732" alt="Q1" src="https://github.com/user-attachments/assets/00908311-c1f1-4455-a332-d6855481aab3" />


![Q1]([assets/image.png](https://github.com/yogeshkr718/VettyTest_DERole/blob/main/Q1.png))

---

2. How many stores receive at least 5 orders in October 2020?

```sql
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
```

**Explanation:**

* First, I look only at transactions that happened **in October 2020**.
* Then I count **how many orders each store received** in that month.
* Using `HAVING COUNT(*) >= 5`, I keep only those stores that got **5 or more orders**.
* That inner result gives me a list of such stores.
* In the outer query, I just count **how many such stores** exist.

In short:
This query tells me **how many stores were “busy” enough to receive at least 5 orders in October 2020.**

---

3. Shortest interval (in minutes) from purchase to refund per store

```sql
SELECT
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_time)) AS shortest_refund_interval_min
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id;
```

**Explanation:**

* I only look at rows where **a refund actually happened** (`refund_time IS NOT NULL`).
* For each refunded transaction, I calculate how many **minutes** passed between the purchase time and the refund time.
* Then for each store, I take the **minimum** of these differences – that represents the **fastest refund** at that store.
* The result shows one row per store with the **shortest refund time in minutes**.

In short:
This query shows **how quickly each store has refunded at least one order**, using the shortest time difference.

---

4. Gross transaction value of every store’s first order

```sql
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
```

**Explanation:**

* For each store, I **order its transactions by purchase_time**, from oldest to newest.
* Using `ROW_NUMBER`, I give a rank (1, 2, 3, …) to each transaction inside each store.
* So, `rn = 1` means **the first ever order** for that store.
* In the outer query, I only select those rows where `rn = 1`, and show their `gross_transaction_value`.

In short:
This query tells me **how much money each store made on its first recorded order.**

---

5. Most popular item name on buyers’ first purchase

```sql
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
```

**Explanation:**

* For each buyer, I sort their transactions by **purchase_time** and rank them (1, 2, 3…).
* `rn = 1` gives me each buyer’s **first purchase ever**.
* From these first purchases, I take the `item_id` and join with the `items` table to get the **item_name**.
* Then I count how many times each item name appears as a **first purchase**.
* I sort the items from most frequent to least and pick the **top 1**.

In short:
This query finds **which item is most commonly bought as the first purchase by buyers.**

---

6. Create a flag whether refund can be processed (within 72 hours)

```sql
SELECT
    *,
    CASE 
        WHEN refund_time IS NOT NULL
             AND TIMESTAMPDIFF(HOUR, purchase_time, refund_time) <= 72
        THEN 1
        ELSE 0
    END AS refund_process_flag
FROM transactions;
```

**Explanation:**

* For every transaction, I check two things:

  * Did a refund happen? (`refund_time IS NOT NULL`)
  * If yes, how many **hours** passed between purchase and refund?
* If the refund happened within **72 hours** of purchase, I set `refund_process_flag` to **1**.
* If there’s no refund or it’s after 72 hours, the flag is **0**.
* The query keeps all original columns and just **adds a new flag column**.

In short:
This query tags each transaction as **eligible (1)** or **not eligible (0)** for refund based on the 72-hour rule.

---

7. Rank by buyer_id and show only second purchase (ignoring refunds)

```sql
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY buyer_id
            ORDER BY purchase_time
        ) AS purchase_rank
    FROM transactions
    WHERE refund_time IS NULL
)
SELECT *
FROM ranked
WHERE purchase_rank = 2;
```

**Explanation:**

* First, I **ignore all refunded transactions** by using `WHERE refund_time IS NULL`.
* For each buyer, I order their valid purchases by time and assign a **row number**:

  * 1 = first purchase
  * 2 = second purchase
  * and so on.
* Then I filter and keep only those rows where `purchase_rank = 2`.
* This gives me **only the second valid (non-refunded) purchase** for each buyer.

In short:
This query shows **the second proper purchase of each buyer**, ignoring any transaction that later got refunded.

---

8. Find the second transaction time per buyer (without MIN/MAX)

```sql
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
```

**Explanation:**

* For each buyer, I sort all their transactions by `purchase_time`.
* I give a **row number** based on this order: first transaction = 1, second = 2, etc.
* I then pick only those rows where `rn = 2`.
* I only select `buyer_id` and the `purchase_time` of that second transaction.

In short:
This query gives me **the timestamp of the second transaction for every buyer**, without using `MIN` or `MAX`, only using ranking.

---

If you want, I can also help you write a **short final answer** in your own voice like:

> “In all the queries, I mainly used filtering, grouping, and window functions like ROW_NUMBER to identify first and second transactions, and to apply the refund logic based on time difference.”
