-- based on tpc-ds q21

-- For all items whose price was changed on a given date,
-- compute the percentage change in inventory between the 30-day period BEFORE
-- the price change and the 30-day period AFTER the change. Group this
-- information by warehouse.

-- Resources


SELECT w_warehouse_name, i_item_id, inv_after, inv_before --the order of inv_after and inv_before is inverted in the Intel results
FROM (

SELECT w_warehouse_name,
           i_item_id,
           SUM(CASE
                   WHEN {fn TIMESTAMPDIFF( SQL_TSI_DAY, CAST(d_date AS TIMESTAMP), CAST('2001-05-08 00:00:00' AS TIMESTAMP))} < 0
                   THEN inv_quantity_on_hand
                   ELSE 0
               END) AS inv_before,
           SUM(CASE
                   WHEN {fn TIMESTAMPDIFF( SQL_TSI_DAY, CAST(d_date AS TIMESTAMP), CAST('2001-05-08 00:00:00' AS TIMESTAMP))} >= 0
                   THEN inv_quantity_on_hand
                   ELSE 0
               END) AS inv_after
FROM inventory inv,
     item i,
     warehouse w,
     date_dim d
WHERE i_current_price BETWEEN 0.98 AND 1.5
  AND i_item_sk = inv_item_sk
  AND inv_warehouse_sk = w_warehouse_sk
  AND inv_date_sk = d_date_sk
  AND {fn TIMESTAMPDIFF( SQL_TSI_DAY, CAST(d_date AS TIMESTAMP), CAST('2001-05-08 00:00:00' AS TIMESTAMP))} >= -30
  AND {fn TIMESTAMPDIFF( SQL_TSI_DAY, CAST(d_date AS TIMESTAMP), CAST('2001-05-08 00:00:00' AS TIMESTAMP))} <= 30
GROUP BY w_warehouse_name,
         i_item_id
ORDER BY w_warehouse_name,
         i_item_id 
) temp
WHERE temp.inv_before > 0.0
       AND ((temp.inv_after*1.0) / temp.inv_before) >= (2.0/3.0)
       AND ((temp.inv_after*1.0) / temp.inv_before) <= (3.0/2.0)
FETCH FIRST 100 ROWS ONLY;




