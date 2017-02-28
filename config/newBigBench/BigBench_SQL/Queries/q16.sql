
-- based on tpc-ds q40
-- Compute the impact of an item price change on the
-- store sales by computing the total sales for items in a 30 day period before and
-- after the price change. Group the items by location of warehouse where they
-- were delivered from.

-- Resources

DROP TABLE dateF;

CREATE TABLE dateF(
	d_date_sk bigint,
	d_date DATE
);

INSERT INTO dateF
SELECT d_date_sk, d_date
FROM date_dim
WHERE CAST(d_date AS TIMESTAMP) >= { fn timestampadd(SQL_TSI_DAY, -30, CAST('2001-03-16 00:00:00' AS TIMESTAMP) ) }
AND CAST(d_date AS TIMESTAMP) <= { fn timestampadd(SQL_TSI_DAY, 30, CAST('2001-03-16 00:00:00' AS TIMESTAMP) ) };

SELECT w_state,
           i_item_id,
           SUM(CASE
                   WHEN (CAST(d_date AS DATE) < CAST('2001-03-16' AS DATE))
                   THEN ws_sales_price - COALESCE(wr_refunded_cash,0)
                   ELSE 0.0
               END) AS sales_before,
           SUM(CASE
                   WHEN (CAST(d_date AS DATE) >= CAST('2001-03-16' AS DATE))
                   THEN ws_sales_price - COALESCE(wr_refunded_cash,0)
                   ELSE 0.0
               END) AS sales_after
FROM
  (SELECT ws_sold_date_sk, ws_item_sk, ws_warehouse_sk, ws_sales_price, wr_refunded_cash
   FROM ( 
          SELECT ws_sold_date_sk, ws_item_sk, ws_warehouse_sk, ws_sales_price, ws_order_number
          FROM web_sales, dateF
          WHERE ws_sold_date_sk = d_date_sk
         ) ws
         LEFT OUTER JOIN 
         ( 
          SELECT  wr_order_number, wr_item_sk, wr_refunded_cash
          FROM web_returns, dateF
          WHERE wr_returned_date_sk = d_date_sk
         ) wr
         ON (ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk)) a1
JOIN item i ON a1.ws_item_sk = i.i_item_sk
JOIN warehouse w ON a1.ws_warehouse_sk = w.w_warehouse_sk
JOIN dateF d ON a1.ws_sold_date_sk = d.d_date_sk
GROUP BY w_state,
         i_item_id
ORDER BY w_state,
         i_item_id
FETCH FIRST 100 ROWS ONLY;

DROP TABLE dateF;



    




 