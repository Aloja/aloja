
DROP VIEW TEMP_TABLE1;
DROP VIEW TEMP_TABLE2;

CREATE VIEW TEMP_TABLE1 AS
SELECT ss_customer_sk AS customer_sk,
     sum( CASE WHEN (d_year = 2001) THEN (((ss_ext_list_price-ss_ext_wholesale_cost-ss_ext_discount_amt)+ss_ext_sales_price)/2) ELSE 0 END) first_year_total, 
     sum( CASE WHEN (d_year = 2002) THEN (((ss_ext_list_price-ss_ext_wholesale_cost-ss_ext_discount_amt)+ss_ext_sales_price)/2) ELSE 0 END) second_year_total
FROM  store_sales, date_dim
WHERE ss_sold_date_sk = d_date_sk AND d_year BETWEEN 2001 AND 2001 + 1 
GROUP BY ss_customer_sk
HAVING sum( CASE WHEN (d_year = 2001) THEN (((ss_ext_list_price-ss_ext_wholesale_cost-ss_ext_discount_amt)+ss_ext_sales_price)/2)  ELSE 0 END) > 0 ;


CREATE VIEW TEMP_TABLE2 AS
SELECT ws_bill_customer_sk AS customer_sk,
       sum( CASE WHEN (d_year = 2001) THEN (((ws_ext_list_price-ws_ext_wholesale_cost-ws_ext_discount_amt)+ws_ext_sales_price)/2) ELSE 0 END) first_year_total,
       sum( CASE WHEN (d_year = 2001 + 1) THEN (((ws_ext_list_price-ws_ext_wholesale_cost-ws_ext_discount_amt)+ws_ext_sales_price)/2) ELSE 0 END) second_year_total
FROM  web_sales, date_dim
WHERE ws_sold_date_sk = d_date_sk AND d_year BETWEEN 2001 AND 2001 + 1
GROUP BY ws_bill_customer_sk
HAVING sum( case when (d_year = 2001)   THEN (((ws_ext_list_price-ws_ext_wholesale_cost-ws_ext_discount_amt)+ws_ext_sales_price)/2)   ELSE 0 END) > 0 ;         

SELECT (web.second_year_total / web.first_year_total) AS web_sales_increase_ratio, 
       c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_country, c_login, c_email_address
FROM TEMP_TABLE1 store, TEMP_TABLE2 web, customer c
WHERE store.customer_sk = web.customer_sk AND web.customer_sk = c_customer_sk AND
      (web.second_year_total / web.first_year_total)  >  (store.second_year_total / store.first_year_total)
ORDER BY web_sales_increase_ratio DESC, c_customer_sk, c_first_name, c_last_name, c_preferred_cust_flag, c_birth_country, c_login
FETCH FIRST 100 ROWS ONLY;

DROP VIEW TEMP_TABLE1;
DROP VIEW TEMP_TABLE2;

