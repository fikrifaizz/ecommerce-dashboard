SELECT
    'Orders' as table_name,
    COUNT(*)
FROM
    olist_orders
UNION ALL
SELECT
    'Reviews',
    COUNT(*)
FROM
    olist_order_reviews -- Harus ~99k
UNION ALL
SELECT
    'Items',
    COUNT(*)
FROM
    olist_order_items;