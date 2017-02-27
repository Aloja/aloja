
DROP TABLE TEMP_TABLE;


CREATE TABLE TEMP_TABLE(i_item_sk bigint,
                        imp_sk bigint,
                        price_change decimal(7,2),
                        imp_start_date bigint,
                        no_days_comp_price bigint);

INSERT INTO TEMP_TABLE
SELECT i_item_sk,
           imp_sk,
           (imp_competitor_price - i_current_price)/i_current_price AS price_change,
           imp_start_date,
           (imp_end_date - imp_start_date) AS no_days_comp_price
FROM item i,
     item_marketprices imp
WHERE i.i_item_sk = imp.imp_item_sk
  AND i.i_item_sk = 10000
ORDER BY i_item_sk,
         imp_sk,
         imp_start_date ;


SELECT ws_item_sk,
       AVG ((current_ss_quant + current_ws_quant - prev_ss_quant - prev_ws_quant) / ((prev_ss_quant + prev_ws_quant) * ws.price_change)) AS cross_price_elasticity
FROM
  (SELECT ws_item_sk,
          imp_sk,
          price_change,
          SUM(CASE
                  WHEN ((ws_sold_date_sk >= c.imp_start_date)
                        AND (ws_sold_date_sk < (c.imp_start_date + c.no_days_comp_price))) THEN ws_quantity
                  ELSE 0
              END) AS current_ws_quant,
          SUM(CASE
                  WHEN ((ws_sold_date_sk >= (c.imp_start_date - c.no_days_comp_price))
                        AND (ws_sold_date_sk < c.imp_start_date)) THEN ws_quantity
                  ELSE 0
              END) AS prev_ws_quant
   FROM web_sales ws
   JOIN TEMP_TABLE c ON ws.ws_item_sk = c.i_item_sk
   GROUP BY ws_item_sk,
            imp_sk,
            price_change) ws
JOIN
  (SELECT ss_item_sk,
          imp_sk,
          price_change,
          SUM(CASE
                  WHEN ((ss_sold_date_sk >= c.imp_start_date)
                        AND (ss_sold_date_sk < (c.imp_start_date + c.no_days_comp_price))) THEN ss_quantity
                  ELSE 0
              END) AS current_ss_quant,
          SUM(CASE
                  WHEN ((ss_sold_date_sk >= (c.imp_start_date - c.no_days_comp_price))
                        AND (ss_sold_date_sk < c.imp_start_date)) THEN ss_quantity
                  ELSE 0
              END) AS prev_ss_quant
   FROM store_sales ss
   JOIN TEMP_TABLE c ON c.i_item_sk = ss.ss_item_sk
   GROUP BY ss_item_sk,
            imp_sk,
            price_change) ss ON (ws.ws_item_sk = ss.ss_item_sk
                                 AND ws.imp_sk = ss.imp_sk)
GROUP BY ws.ws_item_sk ;


DROP TABLE TEMP_TABLE;

