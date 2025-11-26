-- ANALISIS 1: RFM SEGMENTATION
-- Tujuan: Mengidentifikasi "Champion Customers" vs "Churn Risk"
WITH
    rfm_base AS (
        SELECT
            c.customer_unique_id,
            -- Recency: Jumlah hari sejak order terakhir (asumsi 'hari ini' adalah tanggal max di dataset)
            MAX(o.order_purchase_timestamp) as last_order_date,
            (
                SELECT
                    MAX(order_purchase_timestamp)
                FROM
                    olist_orders
            ) - MAX(o.order_purchase_timestamp) as recency_interval,
            -- Frequency: Jumlah order
            COUNT(DISTINCT o.order_id) as frequency,
            -- Monetary: Total belanja (Price + Freight)
            SUM(i.price + i.freight_value) as monetary
        FROM
            olist_orders o
            JOIN olist_order_items i ON o.order_id = i.order_id
            JOIN olist_customers c ON o.customer_id = c.customer_id
        WHERE
            o.order_status = 'delivered'
        GROUP BY
            c.customer_unique_id
    ),
    rfm_scores AS (
        SELECT
            customer_unique_id,
            recency_interval,
            frequency,
            monetary,
            -- NTILE(5) membagi data menjadi 5 bucket (1=Terburuk, 5=Terbaik)
            -- Untuk Recency, makin KECIL angkanya makin BAGUS (dibalik)
            NTILE(5) OVER (
                ORDER BY
                    recency_interval DESC
            ) as r_score,
            NTILE(5) OVER (
                ORDER BY
                    frequency ASC
            ) as f_score,
            NTILE(5) OVER (
                ORDER BY
                    monetary ASC
            ) as m_score
        FROM
            rfm_base
    )
SELECT
    customer_unique_id,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) as rfm_total,
    -- Segmentasi Sederhana
    CASE
        WHEN (r_score + f_score + m_score) >= 14 THEN 'Champion'
        WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal'
        WHEN (r_score + f_score + m_score) >= 6 THEN 'Potential'
        ELSE 'Lost/Low Value'
    END as customer_segment
FROM
    rfm_scores
ORDER BY
    rfm_total DESC;

-- ANALISIS 2: GEOGRAPHIC PERFORMANCE
-- Tujuan: Menemukan kota dengan daya beli (AOV) tertinggi
SELECT
    c.customer_state,
    c.customer_city,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(i.price + i.freight_value) as total_revenue,
    -- Hitung AOV (Rata-rata belanja per order)
    ROUND(
        (
            SUM(i.price + i.freight_value) / COUNT(DISTINCT o.order_id)
        )::numeric,
        2
    ) as avg_order_value
FROM
    olist_orders o
    JOIN olist_order_items i ON o.order_id = i.order_id
    JOIN olist_customers c ON o.customer_id = c.customer_id
WHERE
    o.order_status = 'delivered'
GROUP BY
    c.customer_state,
    c.customer_city
    -- Filter kota yang punya minimal 50 order agar datanya valid
HAVING
    COUNT(DISTINCT o.order_id) > 50
ORDER BY
    avg_order_value DESC
LIMIT
    20;

-- ANALISIS 3: MONTHLY SALES TREND & GROWTH
-- Tujuan: Melihat pertumbuhan bisnis MoM (Month over Month)
WITH
    monthly_sales AS (
        SELECT
            TO_CHAR(order_purchase_timestamp, 'YYYY-MM') as month_year,
            SUM(price + freight_value) as revenue
        FROM
            olist_orders o
            JOIN olist_order_items i ON o.order_id = i.order_id
        WHERE
            o.order_status = 'delivered'
        GROUP BY
            1
    )
SELECT
    month_year,
    revenue,
    -- Ambil revenue bulan sebelumnya
    LAG(revenue) OVER (
        ORDER BY
            month_year
    ) as prev_month_revenue,
    -- Hitung % Pertumbuhan
    ROUND(
        (
            (
                revenue - LAG(revenue) OVER (
                    ORDER BY
                        month_year
                )
            )::NUMERIC / NULLIF(
                LAG(revenue) OVER (
                    ORDER BY
                        month_year
                ),
                0
            ) * 100
        )::NUMERIC,
        2
    ) as growth_percent
FROM
    monthly_sales
ORDER BY
    month_year;