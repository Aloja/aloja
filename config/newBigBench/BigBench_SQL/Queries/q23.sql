
DROP TABLE invF;

CREATE TABLE invF(
	inv_warehouse_sk bigint,
    inv_item_sk bigint,
    d_moy integer,
    inv_quantity_on_hand integer
);

CREATE INDEX idx_invF ON invF (inv_item_sk);

INSERT INTO invF
SELECT inv_warehouse_sk,
       inv_item_sk,
       d_moy,
       inv_quantity_on_hand
FROM inventory inv, date_dim d
WHERE inv.inv_date_sk = d.d_date_sk
      AND d.d_year = 2001
      AND d.d_moy BETWEEN 1 AND (1 + 1)
      AND inv.inv_quantity_on_hand IS NOT NULL;

DROP TABLE invFMN;
      
CREATE TABLE invFMN(
	inv_warehouse_sk bigint,
    inv_item_sk bigint,
    d_moy integer,
    mean double,
    n integer
);

CREATE INDEX idx_invFMN ON invFMN (inv_item_sk);

INSERT INTO invFMN
SELECT inv_warehouse_sk,
       inv_item_sk,
       d_moy,
       AVG(inv_quantity_on_hand) as mean,
       count(*) as n
FROM invF
GROUP BY inv_warehouse_sk, inv_item_sk, d_moy;


DROP TABLE invFS;
      
CREATE TABLE invFS(
	inv_warehouse_sk bigint,
    inv_item_sk bigint,
    d_moy integer,
    sumSQ double
);

CREATE INDEX idx_invFS ON invFS (inv_item_sk);

INSERT INTO invFS
SELECT invF.inv_warehouse_sk,
       invF.inv_item_sk,
       invF.d_moy,
       SUM( ( (invF.inv_quantity_on_hand - 
               (SELECT mean FROM invFMN WHERE invF.inv_warehouse_sk = invFMN.inv_warehouse_sk AND invF.inv_item_sk = invFMN.inv_item_sk AND invF.d_moy = invFMN.d_moy))
               *
               (invF.inv_quantity_on_hand -
               (SELECT mean FROM invFMN WHERE invF.inv_warehouse_sk = invFMN.inv_warehouse_sk AND invF.inv_item_sk = invFMN.inv_item_sk AND invF.d_moy = invFMN.d_moy))
             ) ) as sumSQ
FROM invF
GROUP BY invF.inv_warehouse_sk, invF.inv_item_sk, invF.d_moy;
      

DROP TABLE TEMP_TABLE;

CREATE TABLE TEMP_TABLE(inv_warehouse_sk bigint,
                        inv_item_sk bigint,
                        d_moy integer,
                        cov double);

INSERT INTO TEMP_TABLE
SELECT invFMN.inv_warehouse_sk, invFMN.inv_item_sk, invFMN.d_moy, ( SQRT( (1.0/(invFMN.n-1)) * invFS.sumSQ ) / invFMN.mean ) AS cov
FROM invFMN, invFS
WHERE invFMN.inv_warehouse_sk = invFS.inv_warehouse_sk AND invFMN.inv_item_sk = invFS.inv_item_sk AND invFMN.d_moy = invFS.d_moy
      AND invFMN.mean > 0.0
      AND ( SQRT( (1.0/(invFMN.n-1)) * invFS.sumSQ ) / invFMN.mean ) >= 1.3;


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
                        

DROP TABLE invF;
DROP TABLE invFMN;
DROP TABLE invFS;
DROP TABLE TEMP_TABLE;



