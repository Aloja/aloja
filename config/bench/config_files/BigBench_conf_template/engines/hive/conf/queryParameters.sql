-- !echo ============================;
-- !echo <Query Parameters>;
-- !echo ============================;
--new (dates all Mondays, dateranges complete weeks):
--store: 2000-01-03, 2004-01-05 (1463 days, 209 weeks)
--item: 2000-01-03, 2004-01-05 (1463 days, 209 weeks)
--web_page: 2000-01-03, 2004-01-05 (1463 days, 209 weeks)
--store_sales: 2001-01-01, 2006-01-02 (1827 days, 261 weeks)
--web_sales: 2001-01-01, 2006-01-02 (1827 days, 261 weeks)
--inventory: 2001-01-01, 2006-01-02 (1820 days, 261 weeks)

-------- Q01 -----------
--category_ids:
--1 Home & Kitchen
--2 Music
--3 Books
--4 Clothing & Accessories
--5 Electronics
--6 Tools & Home Improvement
--7 Toys & Games
--8 Movies & TV
--9 Sports & Outdoors
set q01_i_category_id_IN=1, 2 ,3;
-- sf1 -> 11 stores, 90k sales in 820k lines
set q01_ss_store_sk_IN=10, 20, 33, 40, 50;
set q01_viewed_together_count=50;
set q01_limit=100;

-------- Q02 -----------
-- q02_pid1_IN=<pid>, <pid>, ..
--pid == item_sk
--sf 1 item count: 17999c
set q02_item_sk=10001;
set q02_MAX_ITEMS_PER_BASKET=5000000;
set q02_limit=30;
set q02_session_timeout_inSec=3600;


-------- Q03 -----------
set q03_days_in_sec_before_purchase=864000;
set q03_views_before_purchase=5;
set q03_purchased_item_IN=10001;
--see q1 for categories
set q03_purchased_item_category_IN=2,3;
set q03_limit=30;

-------- Q04 -----------
set q04_session_timeout_inSec=3600;

-------- Q05 -----------
set q05_i_category='Books';
set q05_cd_education_status_IN='Advanced Degree', 'College', '4 yr Degree', '2 yr Degree';
set q05_cd_gender='M';


-------- Q06 -----------
SET q06_LIMIT=100;
--web_sales and store_sales date
SET q06_YEAR=2001;


-------- Q07 -----------
SET q07_HIGHER_PRICE_RATIO=1.2;
--store_sales date
SET q07_YEAR=2004;
SET q07_MONTH=7;
SET q07_HAVING_COUNT_GE=10;
SET q07_LIMIT=10;

-------- Q08 -----------
-- web_clickstreams date range
set q08_startDate=2001-09-02;
-- + 1year
set q08_endDate=2002-09-02;
-- 3 days in sec = 3*24*60*60
set q08_seconds_before_purchase=259200;


-------- Q09 -----------
--store_sales date
set q09_year=2001;

set q09_part1_ca_country=United States;
set q09_part1_ca_state_IN='KY', 'GA', 'NM';
set q09_part1_net_profit_min=0;
set q09_part1_net_profit_max=2000;
set q09_part1_education_status=4 yr Degree;
set q09_part1_marital_status=M;
set q09_part1_sales_price_min=100;
set q09_part1_sales_price_max=150;

set q09_part2_ca_country=United States;
set q09_part2_ca_state_IN='MT', 'OR', 'IN';
set q09_part2_net_profit_min=150;
set q09_part2_net_profit_max=3000;
set q09_part2_education_status=4 yr Degree;
set q09_part2_marital_status=M;
set q09_part2_sales_price_min=50;
set q09_part2_sales_price_max=200;

set q09_part3_ca_country=United States;
set q09_part3_ca_state_IN='WI', 'MO', 'WV';
set q09_part3_net_profit_min=50;
set q09_part3_net_profit_max=25000;
set q09_part3_education_status=4 yr Degree;
set q09_part3_marital_status=M;
set q09_part3_sales_price_min=150;
set q09_part3_sales_price_max=200;

-------- Q10 -----------
--no params

-------- Q11 -----------
--web_sales date range
set q11_startDate=2003-01-02;
-- +30days
set q11_endDate=2003-02-02;


-------- Q12 -----------
--web_clickstreams start_date - endDate1
--store_sales      start_date - endDate2
set q12_startDate=2001-09-02;
set q12_endDate1=2001-10-02;
set q12_endDate2=2001-12-02;
set q12_i_category_IN='Books', 'Electronics';

-------- Q13 -----------
--store_sales date
set q13_Year=2001;

set q13_limit=100;

-------- Q14 -----------
set q14_dependents=5;
set q14_morning_startHour=7;
set q14_morning_endHour=8;
set q14_evening_startHour=19;
set q14_evening_endHour=20;
set q14_content_len_min=5000;
set q14_content_len_max=6000;

-------- Q15 -----------
--store_sales date range
set q15_startDate=2001-09-02;
--+1year
set q15_endDate=2002-09-02;
set q15_store_sk=10;


-------- Q16 -----------
-- web_sales/returns date
set q16_date=2001-03-16;

-------- Q17 -----------
set q17_gmt_offset=-5;
--store_sales date
set q17_year=2001;
set q17_month=12;
set q17_i_category_IN='Books', 'Music';

-------- Q18 -----------
-- store_sales date range
set q18_startDate=2001-05-02;
--+90days
set q18_endDate=2001-09-02;

-------- Q19 -----------
set q19_storeReturns_date_IN='2004-03-8' ,'2004-08-02' ,'2004-11-15', '2004-12-20';
set q19_webReturns_date_IN='2004-03-8' ,'2004-08-02' ,'2004-11-15', '2004-12-20';
set q19_store_return_limit=100;

-------- Q20 -----------
--no params

-------- Q21 -----------
--store_sales/returns web_sales/returns date
-- ss_date_sk range at SF 1
--36890   2001-01-01
--38697   2005-12-13
set q21_year=2003;
set q21_month=1;
set q21_limit=100;

-------- Q22 -----------
--inventory date
set q22_date=2001-05-08;
set q22_i_current_price_min=0.98;
set q22_i_current_price_max=1.5;

-------- Q23 -----------
--inventory date
set q23_year=2001;
set q23_month=1;
set q23_coefficient=1.3;

-------- Q24 -----------
set q24_i_item_sk=10000;

-------- Q25 -----------
-- store_sales and web_sales date
set q25_date=2002-01-02;

-------- Q26 -----------
set q26_i_category_IN='Books';
set q26_count_ss_item_sk=5;

-------- Q27 -----------
set q27_pr_item_sk=10002;

-------- Q28 -----------
--no params

-------- Q29 -----------
set q29_limit=100;
set q29_session_timeout_inSec=3600;


-------- Q30 -----------
set q30_limit=100;
set q30_session_timeout_inSec=3600;


-- !echo ============================;
-- !echo </Query Parameters.sql>;
-- !echo ============================;

