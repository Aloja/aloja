--"INTEL CONFIDENTIAL"
--Copyright 2016 Intel Corporation All Rights Reserved.
--
--The source code contained or described herein and all documents related to the source code ("Material") are owned by Intel Corporation or its suppliers or licensors. Title to the Material remains with Intel Corporation or its suppliers and licensors. The Material contains trade secrets and proprietary and confidential information of Intel or its suppliers and licensors. The Material is protected by worldwide copyright and trade secret laws and treaty provisions. No part of the Material may be used, copied, reproduced, modified, published, uploaded, posted, transmitted, distributed, or disclosed in any way without Intel's prior express written permission.
--
--No license under any patent, copyright, trade secret or other intellectual property right is granted to or conferred upon you by disclosure or delivery of the Materials, either expressly, by implication, inducement, estoppel or otherwise. Any license under such intellectual property rights must be express and approved by Intel in writing.

set hdfsDataPath=##HDFS_DATA_ABSOLUTE_PATH##;
set fieldDelimiter=|;
set tableFormat=${hiveconf:bigbench.tableFormat_source};
set temporaryTableSuffix=_temporary;

set customerTableName=customer;
set customerAddressTableName=customer_address;
set customerDemographicsTableName=customer_demographics;
set dateTableName=date_dim;
set householdDemographicsTableName=household_demographics;
set incomeTableName=income_band;
set itemTableName=item;
set promotionTableName=promotion;
set reasonTableName=reason;
set shipModeTableName=ship_mode;
set storeTableName=store;
set timeTableName=time_dim;
set warehouseTableName=warehouse;
set webSiteTableName=web_site;
set webPageTableName=web_page;
set inventoryTableName=inventory;
set storeSalesTableName=store_sales;
set storeReturnsTableName=store_returns;
set webSalesTableName=web_sales;
set webReturnsTableName=web_returns;

set marketPricesTableName=item_marketprices;
set clickstreamsTableName=web_clickstreams;
set reviewsTableName=product_reviews;

-- /Begin HACK create first table differently
-- README! why is the first table not done with CTAS (create table as), like the other tables?
--
-- hack for https://issues.apache.org/jira/browse/HIVE-2419 where CTAS (create table as) is not working for a fresh install where the "warehouse" folder for hive does not exist.
-- The normal create table creates the warehouse folder if its missing.
-- But CTAS does not! create the warehouse folder, thus the "move" operation for data would fail with:
-- "Failed with exception Unable to rename: hdfs://namenode:port/tmp/hive-root/../-ext-000001 hdfs://namenode:port/user/hive/warehouse/<database>/<table>"

DROP TABLE IF EXISTS createDatabaseDummyTable;
CREATE TABLE createDatabaseDummyTable(sk bigint);
DROP TABLE createDatabaseDummyTable;

-- /END HACK create first table differently


-- !echo Create temporary table: ${hiveconf:customerTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:customerTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:customerTableName}${hiveconf:temporaryTableSuffix}
  ( c_customer_sk             bigint              --not null
  , c_customer_id             string              --not null
  , c_current_cdemo_sk        bigint
  , c_current_hdemo_sk        bigint
  , c_current_addr_sk         bigint
  , c_first_shipto_date_sk    bigint
  , c_first_sales_date_sk     bigint
  , c_salutation              string
  , c_first_name              string
  , c_last_name               string
  , c_preferred_cust_flag     string
  , c_birth_day               int
  , c_birth_month             int
  , c_birth_year              int
  , c_birth_country           string
  , c_login                   string
  , c_email_address           string
  , c_last_review_date        string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:customerTableName}'
;


-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:customerTableName};
DROP TABLE IF EXISTS ${hiveconf:customerTableName};
CREATE TABLE ${hiveconf:customerTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:customerTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:customerTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:customerTableName}${hiveconf:temporaryTableSuffix};



-- !echo Create temporary table: ${hiveconf:customerAddressTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:customerAddressTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:customerAddressTableName}${hiveconf:temporaryTableSuffix}
  ( ca_address_sk             bigint              --not null
  , ca_address_id             string              --not null
  , ca_street_number          string
  , ca_street_name            string
  , ca_street_type            string
  , ca_suite_number           string
  , ca_city                   string
  , ca_county                 string
  , ca_state                  string
  , ca_zip                    string
  , ca_country                string
  , ca_gmt_offset             decimal(5,2)
  , ca_location_type          string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:customerAddressTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:customerAddressTableName};
DROP TABLE IF EXISTS ${hiveconf:customerAddressTableName};
CREATE TABLE ${hiveconf:customerAddressTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:customerAddressTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:customerAddressTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:customerAddressTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:customerDemographicsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:customerDemographicsTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:customerDemographicsTableName}${hiveconf:temporaryTableSuffix}
  ( cd_demo_sk                bigint                ----not null
  , cd_gender                 string
  , cd_marital_status         string
  , cd_education_status       string
  , cd_purchase_estimate      int
  , cd_credit_rating          string
  , cd_dep_count              int
  , cd_dep_employed_count     int
  , cd_dep_college_count      int

  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:customerDemographicsTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:customerDemographicsTableName};
DROP TABLE IF EXISTS ${hiveconf:customerDemographicsTableName};
CREATE TABLE ${hiveconf:customerDemographicsTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:customerDemographicsTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:customerDemographicsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:customerDemographicsTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:dateTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:dateTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:dateTableName}${hiveconf:temporaryTableSuffix}
  ( d_date_sk                 bigint              --not null
  , d_date_id                 string              --not null
  , d_date                    string
  , d_month_seq               int
  , d_week_seq                int
  , d_quarter_seq             int
  , d_year                    int
  , d_dow                     int
  , d_moy                     int
  , d_dom                     int
  , d_qoy                     int
  , d_fy_year                 int
  , d_fy_quarter_seq          int
  , d_fy_week_seq             int
  , d_day_name                string
  , d_quarter_name            string
  , d_holiday                 string
  , d_weekend                 string
  , d_following_holiday       string
  , d_first_dom               int
  , d_last_dom                int
  , d_same_day_ly             int
  , d_same_day_lq             int
  , d_current_day             string
  , d_current_week            string
  , d_current_month           string
  , d_current_quarter         string
  , d_current_year            string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:dateTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:dateTableName};
DROP TABLE IF EXISTS ${hiveconf:dateTableName};
CREATE TABLE ${hiveconf:dateTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:dateTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:dateTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:dateTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:householdDemographicsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:householdDemographicsTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:householdDemographicsTableName}${hiveconf:temporaryTableSuffix}
  ( hd_demo_sk                bigint                --not null
  , hd_income_band_sk         bigint
  , hd_buy_potential          string
  , hd_dep_count              int
  , hd_vehicle_count          int
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:householdDemographicsTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:householdDemographicsTableName};
DROP TABLE IF EXISTS ${hiveconf:householdDemographicsTableName};
CREATE TABLE ${hiveconf:householdDemographicsTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:householdDemographicsTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:householdDemographicsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:householdDemographicsTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:incomeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:incomeTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:incomeTableName}${hiveconf:temporaryTableSuffix}
  ( ib_income_band_sk         bigint              --not null
  , ib_lower_bound            int
  , ib_upper_bound            int
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:incomeTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:incomeTableName};
DROP TABLE IF EXISTS ${hiveconf:incomeTableName};
CREATE TABLE ${hiveconf:incomeTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:incomeTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:incomeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:incomeTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:itemTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:itemTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:itemTableName}${hiveconf:temporaryTableSuffix}
  ( i_item_sk                 bigint              --not null
  , i_item_id                 string              --not null
  , i_rec_start_date          string
  , i_rec_end_date            string
  , i_item_desc               string
  , i_current_price           decimal(7,2)
  , i_wholesale_cost          decimal(7,2)
  , i_brand_id                int
  , i_brand                   string
  , i_class_id                int
  , i_class                   string
  , i_category_id             int
  , i_category                string
  , i_manufact_id             int
  , i_manufact                string
  , i_size                    string
  , i_formulation             string
  , i_color                   string
  , i_units                   string
  , i_container               string
  , i_manager_id              int
  , i_product_name            string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:itemTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:itemTableName};
DROP TABLE IF EXISTS ${hiveconf:itemTableName};
CREATE TABLE ${hiveconf:itemTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:itemTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:itemTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:itemTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:promotionTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:promotionTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:promotionTableName}${hiveconf:temporaryTableSuffix}
  ( p_promo_sk                bigint              --not null
  , p_promo_id                string              --not null
  , p_start_date_sk           bigint
  , p_end_date_sk             bigint
  , p_item_sk                 bigint
  , p_cost                    decimal(15,2)
  , p_response_target         int
  , p_promo_name              string
  , p_channel_dmail           string
  , p_channel_email           string
  , p_channel_catalog         string
  , p_channel_tv              string
  , p_channel_radio           string
  , p_channel_press           string
  , p_channel_event           string
  , p_channel_demo            string
  , p_channel_details         string
  , p_purpose                 string
  , p_discount_active         string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:promotionTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:promotionTableName};
DROP TABLE IF EXISTS ${hiveconf:promotionTableName};
CREATE TABLE ${hiveconf:promotionTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:promotionTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:promotionTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:promotionTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:reasonTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:reasonTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:reasonTableName}${hiveconf:temporaryTableSuffix}
  ( r_reason_sk               bigint              --not null
  , r_reason_id               string              --not null
  , r_reason_desc             string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:reasonTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:reasonTableName};
DROP TABLE IF EXISTS ${hiveconf:reasonTableName};
CREATE TABLE ${hiveconf:reasonTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:reasonTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:reasonTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:reasonTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:shipModeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:shipModeTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:shipModeTableName}${hiveconf:temporaryTableSuffix}
  ( sm_ship_mode_sk           bigint              --not null
  , sm_ship_mode_id           string              --not null
  , sm_type                   string
  , sm_code                   string
  , sm_carrier                string
  , sm_contract               string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:shipModeTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:shipModeTableName};
DROP TABLE IF EXISTS ${hiveconf:shipModeTableName};
CREATE TABLE ${hiveconf:shipModeTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:shipModeTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:shipModeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:shipModeTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:storeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:storeTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:storeTableName}${hiveconf:temporaryTableSuffix}
  ( s_store_sk                bigint              --not null
  , s_store_id                string              --not null
  , s_rec_start_date          string
  , s_rec_end_date            string
  , s_closed_date_sk          bigint
  , s_store_name              string
  , s_number_employees        int
  , s_floor_space             int
  , s_hours                   string
  , s_manager                 string
  , s_market_id               int
  , s_geography_class         string
  , s_market_desc             string
  , s_market_manager          string
  , s_division_id             int
  , s_division_name           string
  , s_company_id              int
  , s_company_name            string
  , s_street_number           string
  , s_street_name             string
  , s_street_type             string
  , s_suite_number            string
  , s_city                    string
  , s_county                  string
  , s_state                   string
  , s_zip                     string
  , s_country                 string
  , s_gmt_offset              decimal(5,2)
  , s_tax_precentage          decimal(5,2)
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:storeTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:storeTableName};
DROP TABLE IF EXISTS ${hiveconf:storeTableName};
CREATE TABLE ${hiveconf:storeTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:storeTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:storeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:storeTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:timeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:timeTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:timeTableName}${hiveconf:temporaryTableSuffix}
  ( t_time_sk                 bigint              --not null
  , t_time_id                 string              --not null
  , t_time                    int
  , t_hour                    int
  , t_minute                  int
  , t_second                  int
  , t_am_pm                   string
  , t_shift                   string
  , t_sub_shift               string
  , t_meal_time               string
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:timeTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:timeTableName};
DROP TABLE IF EXISTS ${hiveconf:timeTableName};
CREATE TABLE ${hiveconf:timeTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:timeTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:timeTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:timeTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:warehouseTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:warehouseTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:warehouseTableName}${hiveconf:temporaryTableSuffix}
  ( w_warehouse_sk            bigint              --not null
  , w_warehouse_id            string              --not null
  , w_warehouse_name          string
  , w_warehouse_sq_ft         int
  , w_street_number           string
  , w_street_name             string
  , w_street_type             string
  , w_suite_number            string
  , w_city                    string
  , w_county                  string
  , w_state                   string
  , w_zip                     string
  , w_country                 string
  , w_gmt_offset              decimal(5,2)
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:warehouseTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:warehouseTableName};
DROP TABLE IF EXISTS ${hiveconf:warehouseTableName};
CREATE TABLE ${hiveconf:warehouseTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:warehouseTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:warehouseTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:warehouseTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:webSiteTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:webSiteTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:webSiteTableName}${hiveconf:temporaryTableSuffix}
  ( web_site_sk               bigint              --not null
  , web_site_id               string              --not null
  , web_rec_start_date        string
  , web_rec_end_date          string
  , web_name                  string
  , web_open_date_sk          bigint
  , web_close_date_sk         bigint
  , web_class                 string
  , web_manager               string
  , web_mkt_id                int
  , web_mkt_class             string
  , web_mkt_desc              string
  , web_market_manager        string
  , web_company_id            int
  , web_company_name          string
  , web_street_number         string
  , web_street_name           string
  , web_street_type           string
  , web_suite_number          string
  , web_city                  string
  , web_county                string
  , web_state                 string
  , web_zip                   string
  , web_country               string
  , web_gmt_offset            decimal(5,2)
  , web_tax_percentage        decimal(5,2)
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:webSiteTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:webSiteTableName};
DROP TABLE IF EXISTS ${hiveconf:webSiteTableName};
CREATE TABLE ${hiveconf:webSiteTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:webSiteTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:webSiteTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:webSiteTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:webPageTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:webPageTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:webPageTableName}${hiveconf:temporaryTableSuffix}
  ( wp_web_page_sk            bigint              --not null
  , wp_web_page_id            string              --not null
  , wp_rec_start_date         string
  , wp_rec_end_date           string
  , wp_creation_date_sk       bigint
  , wp_access_date_sk         bigint
  , wp_autogen_flag           string
  , wp_customer_sk            bigint
  , wp_url                    string
  , wp_type                   string
  , wp_char_count             int
  , wp_link_count             int
  , wp_image_count            int
  , wp_max_ad_count           int
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:webPageTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:webPageTableName};
DROP TABLE IF EXISTS ${hiveconf:webPageTableName};
CREATE TABLE ${hiveconf:webPageTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:webPageTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:webPageTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:webPageTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:inventoryTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:inventoryTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:inventoryTableName}${hiveconf:temporaryTableSuffix}
  ( inv_date_sk               bigint                --not null
  , inv_item_sk               bigint                --not null
  , inv_warehouse_sk          bigint                --not null
  , inv_quantity_on_hand      int
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:inventoryTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:inventoryTableName};
DROP TABLE IF EXISTS ${hiveconf:inventoryTableName};
CREATE TABLE ${hiveconf:inventoryTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:inventoryTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:inventoryTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:inventoryTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:storeSalesTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:storeSalesTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:storeSalesTableName}${hiveconf:temporaryTableSuffix}
  ( ss_sold_date_sk           bigint
  , ss_sold_time_sk           bigint
  , ss_item_sk                bigint                --not null
  , ss_customer_sk            bigint
  , ss_cdemo_sk               bigint
  , ss_hdemo_sk               bigint
  , ss_addr_sk                bigint
  , ss_store_sk               bigint
  , ss_promo_sk               bigint
  , ss_ticket_number          bigint                --not null
  , ss_quantity               int
  , ss_wholesale_cost         decimal(7,2)
  , ss_list_price             decimal(7,2)
  , ss_sales_price            decimal(7,2)
  , ss_ext_discount_amt       decimal(7,2)
  , ss_ext_sales_price        decimal(7,2)
  , ss_ext_wholesale_cost     decimal(7,2)
  , ss_ext_list_price         decimal(7,2)
  , ss_ext_tax                decimal(7,2)
  , ss_coupon_amt             decimal(7,2)
  , ss_net_paid               decimal(7,2)
  , ss_net_paid_inc_tax       decimal(7,2)
  , ss_net_profit             decimal(7,2)
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:storeSalesTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:storeSalesTableName};
DROP TABLE IF EXISTS ${hiveconf:storeSalesTableName};
CREATE TABLE ${hiveconf:storeSalesTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:storeSalesTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:storeSalesTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:storeSalesTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:storeReturnsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:storeReturnsTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:storeReturnsTableName}${hiveconf:temporaryTableSuffix}
  ( sr_returned_date_sk       bigint
  , sr_return_time_sk         bigint
  , sr_item_sk                bigint                --not null
  , sr_customer_sk            bigint
  , sr_cdemo_sk               bigint
  , sr_hdemo_sk               bigint
  , sr_addr_sk                bigint
  , sr_store_sk               bigint
  , sr_reason_sk              bigint
  , sr_ticket_number          bigint                --not null
  , sr_return_quantity        int
  , sr_return_amt             decimal(7,2)
  , sr_return_tax             decimal(7,2)
  , sr_return_amt_inc_tax     decimal(7,2)
  , sr_fee                    decimal(7,2)
  , sr_return_ship_cost       decimal(7,2)
  , sr_refunded_cash          decimal(7,2)
  , sr_reversed_charge        decimal(7,2)
  , sr_store_credit           decimal(7,2)
  , sr_net_loss               decimal(7,2)
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:storeReturnsTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:storeReturnsTableName};
DROP TABLE IF EXISTS ${hiveconf:storeReturnsTableName};
CREATE TABLE ${hiveconf:storeReturnsTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:storeReturnsTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:storeReturnsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:storeReturnsTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:webSalesTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:webSalesTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:webSalesTableName}${hiveconf:temporaryTableSuffix}
  ( ws_sold_date_sk           bigint
  , ws_sold_time_sk           bigint
  , ws_ship_date_sk           bigint
  , ws_item_sk                bigint                --not null
  , ws_bill_customer_sk       bigint
  , ws_bill_cdemo_sk          bigint
  , ws_bill_hdemo_sk          bigint
  , ws_bill_addr_sk           bigint
  , ws_ship_customer_sk       bigint
  , ws_ship_cdemo_sk          bigint
  , ws_ship_hdemo_sk          bigint
  , ws_ship_addr_sk           bigint
  , ws_web_page_sk            bigint
  , ws_web_site_sk            bigint
  , ws_ship_mode_sk           bigint
  , ws_warehouse_sk           bigint
  , ws_promo_sk               bigint
  , ws_order_number           bigint                --not null
  , ws_quantity               int
  , ws_wholesale_cost         decimal(7,2)
  , ws_list_price             decimal(7,2)
  , ws_sales_price            decimal(7,2)
  , ws_ext_discount_amt       decimal(7,2)
  , ws_ext_sales_price        decimal(7,2)
  , ws_ext_wholesale_cost     decimal(7,2)
  , ws_ext_list_price         decimal(7,2)
  , ws_ext_tax                decimal(7,2)
  , ws_coupon_amt             decimal(7,2)
  , ws_ext_ship_cost          decimal(7,2)
  , ws_net_paid               decimal(7,2)
  , ws_net_paid_inc_tax       decimal(7,2)
  , ws_net_paid_inc_ship      decimal(7,2)
  , ws_net_paid_inc_ship_tax  decimal(7,2)
  , ws_net_profit             decimal(7,2)
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:webSalesTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:webSalesTableName};
DROP TABLE IF EXISTS ${hiveconf:webSalesTableName};
CREATE TABLE ${hiveconf:webSalesTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:webSalesTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:webSalesTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:webSalesTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:webReturnsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:webReturnsTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:webReturnsTableName}${hiveconf:temporaryTableSuffix}
  ( wr_returned_date_sk       bigint
  , wr_returned_time_sk       bigint
  , wr_item_sk                bigint                --not null
  , wr_refunded_customer_sk   bigint
  , wr_refunded_cdemo_sk      bigint
  , wr_refunded_hdemo_sk      bigint
  , wr_refunded_addr_sk       bigint
  , wr_returning_customer_sk  bigint
  , wr_returning_cdemo_sk     bigint
  , wr_returning_hdemo_sk     bigint
  , wr_returning_addr_sk      bigint
  , wr_web_page_sk            bigint
  , wr_reason_sk              bigint
  , wr_order_number           bigint                --not null
  , wr_return_quantity        int
  , wr_return_amt             decimal(7,2)
  , wr_return_tax             decimal(7,2)
  , wr_return_amt_inc_tax     decimal(7,2)
  , wr_fee                    decimal(7,2)
  , wr_return_ship_cost       decimal(7,2)
  , wr_refunded_cash          decimal(7,2)
  , wr_reversed_charge        decimal(7,2)
  , wr_account_credit         decimal(7,2)
  , wr_net_loss               decimal(7,2)
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:webReturnsTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:webReturnsTableName};
DROP TABLE IF EXISTS ${hiveconf:webReturnsTableName};
CREATE TABLE ${hiveconf:webReturnsTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:webReturnsTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:webReturnsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:webReturnsTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:marketPricesTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:marketPricesTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:marketPricesTableName}${hiveconf:temporaryTableSuffix}
  ( imp_sk                  bigint                --not null
  , imp_item_sk             bigint                --not null
  , imp_competitor          string
  , imp_competitor_price    decimal(7,2)
  , imp_start_date          bigint
  , imp_end_date            bigint

  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:marketPricesTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:marketPricesTableName};
DROP TABLE IF EXISTS ${hiveconf:marketPricesTableName};
CREATE TABLE ${hiveconf:marketPricesTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:marketPricesTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:marketPricesTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:marketPricesTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:clickstreamsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:clickstreamsTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:clickstreamsTableName}${hiveconf:temporaryTableSuffix}
(   wcs_click_date_sk       bigint
  , wcs_click_time_sk       bigint
  , wcs_sales_sk            bigint
  , wcs_item_sk             bigint
  , wcs_web_page_sk         bigint
  , wcs_user_sk             bigint
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:clickstreamsTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:clickstreamsTableName};
DROP TABLE IF EXISTS ${hiveconf:clickstreamsTableName};
CREATE TABLE ${hiveconf:clickstreamsTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:clickstreamsTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:clickstreamsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:clickstreamsTableName}${hiveconf:temporaryTableSuffix};


-- !echo Create temporary table: ${hiveconf:reviewsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE IF EXISTS ${hiveconf:reviewsTableName}${hiveconf:temporaryTableSuffix};
CREATE EXTERNAL TABLE ${hiveconf:reviewsTableName}${hiveconf:temporaryTableSuffix}
(   pr_review_sk            bigint              --not null
  , pr_review_date          string
  , pr_review_time          string
  , pr_review_rating        int                 --not null
  , pr_item_sk              bigint              --not null
  , pr_user_sk              bigint
  , pr_order_sk             bigint
  , pr_review_content       string --not null
  )
  ROW FORMAT DELIMITED FIELDS TERMINATED BY '${hiveconf:fieldDelimiter}'
  STORED AS TEXTFILE LOCATION '${hiveconf:hdfsDataPath}/${hiveconf:reviewsTableName}'
;

-- !echo Load text data into ${hiveconf:tableFormat} table: ${hiveconf:reviewsTableName};
DROP TABLE IF EXISTS ${hiveconf:reviewsTableName};
CREATE TABLE ${hiveconf:reviewsTableName}
STORED AS ${hiveconf:tableFormat}
AS
SELECT * FROM ${hiveconf:reviewsTableName}${hiveconf:temporaryTableSuffix}
;

-- !echo Drop temporary table: ${hiveconf:reviewsTableName}${hiveconf:temporaryTableSuffix};
DROP TABLE ${hiveconf:reviewsTableName}${hiveconf:temporaryTableSuffix};
