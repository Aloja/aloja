
-- The Intel result is 0.0021533, this query gives as result -0.0010479756250875256
-- for a correlation value between -1 and 1 seems plausible.
-- For some reason, the calculated revenue is not used.
-- To run this query the product_reviews table must be populated, in order
-- to do so in Derby, the generated files need to have the quotes removed.

DROP TABLE dateF;

CREATE TABLE dateF(
	d_date_sk bigint,
	d_date DATE
);

INSERT INTO dateF
SELECT d_date_sk, d_date
FROM date_dim
WHERE d_date >= CAST('2003-01-02' AS DATE)
AND d_date <= CAST('2003-02-02' AS DATE);


DROP TABLE TEMP;

CREATE TABLE TEMP (
	pr_item_sk bigint,	
	reviews_count integer, 
	avg_rating decimal(24,7),
	m_revenue decimal(24,7)
);


DROP TABLE REVIEWS;

CREATE TABLE REVIEWS(
	pr_item_sk bigint,
    r_count integer,
    avg_rating decimal(24,7)
);

INSERT INTO REVIEWS
SELECT
      pr_item_sk,
      count(*) AS r_count,
      avg(pr_review_rating) AS avg_rating
FROM product_reviews
WHERE pr_item_sk IS NOT NULL
--this is GROUP BY 1 in original::same as pr_item_sk here::hive complains anyhow
GROUP BY pr_item_sk;



INSERT INTO TEMP
SELECT
	p.pr_item_sk AS pid,
	p.r_count    AS reviews_count,
    p.avg_rating AS avg_rating,
    s.revenue AS m_revenue
FROM
	REVIEWS p
  	INNER JOIN (
    	SELECT
      		ws.ws_item_sk,
      		SUM(ws.ws_net_paid) AS revenue
    	FROM
    	(
    		SELECT ws1.ws_item_sk, ws1.ws_net_paid
    		FROM
    		web_sales ws1
    		-- Select date range of interest
    		WHERE EXISTS (
      			SELECT d.d_date_sk
      			FROM dateF d
      			WHERE ws1.ws_sold_date_sk = d.d_date_sk
    		)
    	) ws
    	WHERE ws.ws_item_sk IS NOT null
    	--this is GROUP BY 1 in original::same as ws_item_sk here::hive complains anyhow
    	GROUP BY ws.ws_item_sk
  ) s
  ON p.pr_item_sk = s.ws_item_sk
--no sorting required, output is a single line
;

DROP TABLE QUERYSTATS;

CREATE TABLE QUERYSTATS(
	sum1 decimal(24,7),
    sum2 decimal(24,7),
    sum1sq decimal(24,7),
    sum2sq decimal(24,7),
    psum decimal(24,7),
    n integer
);


INSERT INTO QUERYSTATS
SELECT
    SUM(reviews_count) AS sum1,
	SUM(avg_rating) AS sum2,
    SUM(reviews_count * reviews_count) AS sum1sq,
    SUM(avg_rating * avg_rating) AS sum2sq,
    SUM(reviews_count * avg_rating) AS psum,
    COUNT(*) AS n
FROM TEMP;


--Formula used to calculate the correlation coefficient for a sample
--SELECT ((n * psum) - ( sum1 * sum2)) / ( SQRT( (n * sum1sq) - (sum1 * sum1) ) * SQRT( (n * sum2sq) - (sum2 * sum2) ) )
--FROM QUERYSTATS;

--Alternative formula, seems to be equivalent
--SELECT ( psum - ( (sum1 * sum2) / n )) / ( SQRT( (sum1sq - ((sum1 * sum1)/n) ) * (sum2sq - ((sum2 * sum2)/n)) ) )
--FROM QUERYSTATS;

--Formula used to calculate the correlation coefficient for a population
SELECT ( (psum/n) - ((sum1/n) * (sum2/n)) ) / ( SQRT( (sum1sq/n) - (sum1 / n) * (sum1 / n) ) * SQRT( (sum2sq/n) - (sum2 / n) * (sum2 / n) ) )
FROM QUERYSTATS;

DROP TABLE dateF;
DROP TABLE QUERYSTATS;
DROP TABLE TEMP;
DROP TABLE REVIEWS;








