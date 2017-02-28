
DROP TABLE TEMP_TABLE;

CREATE TABLE TEMP_TABLE(inv_warehouse_sk bigint,
                        inv_item_sk bigint,
                        d_moy integer,
                        cov decimal(15,5));

INSERT INTO TEMP_TABLE
SELECT inv_warehouse_sk,
       inv_item_sk,
       d_moy,
       cast((stdev / mean) AS decimal(15,5)) cov
FROM
  (SELECT inv_warehouse_sk,
          inv_item_sk,
          d_moy,
          stddev_samp(inv_quantity_on_hand) stdev,
          avg(inv_quantity_on_hand) mean
   FROM inventory inv
   JOIN date_dim d ON (inv.inv_date_sk = d.d_date_sk
                       AND d.d_year = 2001
                       AND d_moy BETWEEN 1 AND (1 + 1))
   GROUP BY inv_warehouse_sk,
            inv_item_sk,
            d_moy) q23_tmp_inv_part
WHERE mean > 0
  AND stdev/mean >= 1.3 ;


SELECT inv1.inv_warehouse_sk,
       inv1.inv_item_sk,
       inv1.d_moy,
       inv1.cov,
       inv2.d_moy,
       inv2.cov
FROM TEMP_TABLE inv1
JOIN TEMP_TABLE inv2 ON(inv1.inv_warehouse_sk=inv2.inv_warehouse_sk
                        AND inv1.inv_item_sk = inv2.inv_item_sk
                        AND inv1.d_moy = 1
                        AND inv2.d_moy = 1 + 1)
ORDER BY inv1.inv_warehouse_sk,
         inv1.inv_item_sk ;


DROP TABLE TEMP_TABLE;

