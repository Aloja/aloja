SELECT promotions,
           total,
           promotions / total * 100
FROM
  (SELECT SUM(ss_ext_sales_price) promotions
   FROM store_sales ss
   JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE ca_gmt_offset = -5
     AND s_gmt_offset = -5
     AND i_category IN ('Books',
                        'Music')
     AND d_year = 2001
     AND d_moy = 12
     AND (p_channel_dmail = 'Y'
          OR p_channel_email = 'Y'
          OR p_channel_tv = 'Y')) promotional_sales,
  (SELECT SUM(ss_ext_sales_price) total
   FROM store_sales ss
   JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE ca_gmt_offset = -5
     AND s_gmt_offset = -5
     AND i_category IN ('Books',
                        'Music')
     AND d_year = 2001
     AND d_moy = 12) all_sales
ORDER BY promotions,
         total 
FETCH FIRST 100 ROWS ONLY;


         
         