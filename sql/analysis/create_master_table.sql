DROP TABLE IF EXISTS olist_master_dataset;

CREATE TABLE olist_master_dataset AS
SELECT
    -- 1. Order Info
    o.order_id,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    -- Hitung Delivery Time (Actual vs Estimated) dalam hari
    -- Menggunakan DATE_PART/EXTRACT untuk PostgreSQL
    EXTRACT(
        DAY
        FROM
            (
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )
    )::INT as delivery_days_actual,
    EXTRACT(
        DAY
        FROM
            (
                o.order_estimated_delivery_date - o.order_delivered_customer_date
            )
    )::INT as delivery_days_diff,
    -- 2. Product Info
    i.product_id,
    -- Mengambil Nama Kategori Inggris (jika null, pakai nama asli)
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) as product_category,
    i.price as sales_amount,
    i.freight_value,
    (i.price + i.freight_value) as total_order_value,
    -- 3. Customer Info (Geographic)
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    -- 4. Seller Info
    s.seller_id,
    s.seller_city,
    s.seller_state,
    -- 5. Review Info (Ambil rata-rata skor per order jika ada >1 review)
    r.review_score
FROM
    olist_order_items i
    JOIN olist_orders o ON i.order_id = o.order_id
    -- Join ke Products lalu ke Translation
    LEFT JOIN olist_products p ON i.product_id = p.product_id
    LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
    -- Join ke Customers
    LEFT JOIN olist_customers c ON o.customer_id = c.customer_id
    -- Join ke Sellers
    LEFT JOIN olist_sellers s ON i.seller_id = s.seller_id
    -- Join ke Reviews (Gunakan Left Join agar order tanpa review tetap masuk)
    LEFT JOIN (
        SELECT
            order_id,
            AVG(review_score)::INT as review_score
        FROM
            olist_order_reviews
        GROUP BY
            order_id
    ) r ON o.order_id = r.order_id
WHERE
    o.order_status = 'delivered';

-- Validasi hasil
SELECT
    count(*)
FROM
    olist_master_dataset;

SELECT
    *
FROM
    olist_master_dataset;