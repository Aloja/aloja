SELECT DISTINCT wcs_user_sk
FROM
  (SELECT wcs_user_sk,
          wcs_click_date_sk
   FROM web_clickstreams,
        item
   WHERE wcs_click_date_sk BETWEEN 37134 AND (37134 + 30)
     AND i_category IN ('Books',
                        'Electronics')
     AND wcs_item_sk = i_item_sk
     AND wcs_user_sk IS NOT NULL
     AND wcs_sales_sk IS NULL ) webInRange,

  (SELECT ss_customer_sk,
          ss_sold_date_sk
   FROM store_sales,
        item
   WHERE ss_sold_date_sk BETWEEN 37134 AND (37134 + 90)
     AND i_category IN ('Books',
                        'Electronics')
     AND ss_item_sk = i_item_sk
     AND ss_customer_sk IS NOT NULL) storeInRange
WHERE wcs_user_sk = ss_customer_sk
  AND wcs_click_date_sk < ss_sold_date_sk
ORDER BY wcs_user_sk;
