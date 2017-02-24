-- SET @@InternalDebug = "DefaultDistributionFromList:on";

-- DROP DATABASE IF EXISTS aloja_bigbench_1GB_d_d;
-- CREATE DATABASE     aloja_bigbench_1GB_d_d;
-- USE DATABASE        aloja_bigbench_1GB_d_d;

-----------------------------------------------------------------------

DROP TABLE income_band;

CREATE TABLE income_band (
  ib_income_band_sk       bigint NOT NULL,
  ib_lower_bound          integer,
  ib_upper_bound          integer
);

CREATE INDEX idx_income_band ON income_band (ib_income_band_sk);

-----------------------------------------------------------------------

DROP TABLE ship_mode;

CREATE TABLE ship_mode (
  sm_ship_mode_sk           bigint NOT NULL,
  sm_ship_mode_id           char(16) NOT NULL,
  sm_type                   char(30),
  sm_code                   char(10),
  sm_carrier                char(20),
  sm_contract               char(20)
);

CREATE INDEX idx_ship_mode ON ship_mode (sm_ship_mode_sk);

-----------------------------------------------------------------------

DROP TABLE warehouse;

CREATE TABLE warehouse (
  w_warehouse_sk            bigint NOT NULL,
  w_warehouse_id            char(16) NOT NULL,
  w_warehouse_name          varchar(20),
  w_warehouse_sq_ft         integer,
  w_street_number           char(10),
  w_street_name             varchar(60),
  w_street_type             char(15),
  w_suite_number            char(10),
  w_city                    varchar(60),
  w_county                  varchar(30),
  w_state                   char(2),
  w_zip                     char(10),
  w_country                 varchar(20),
  w_gmt_offset              decimal(5,2)
);

CREATE INDEX idx_warehouse ON warehouse (w_warehouse_sk);

-----------------------------------------------------------------------

DROP TABLE web_site;

CREATE TABLE web_site (
  web_site_sk               bigint NOT NULL,
  web_site_id               char(16) NOT NULL,
  web_rec_start_date        date,
  web_rec_end_date          date,
  web_name                  varchar(50),
  web_open_date_sk          bigint,
  web_close_date_sk         bigint,
  web_class                 varchar(50),
  web_manager               varchar(40),
  web_mkt_id                integer,
  web_mkt_class             varchar(50),
  web_mkt_desc              varchar(100),
  web_market_manager        varchar(40),
  web_company_id            integer,
  web_company_name          char(50),
  web_street_number         char(10),
  web_street_name           varchar(60),
  web_street_type           char(15),
  web_suite_number          char(10),
  web_city                  varchar(60),
  web_county                varchar(30),
  web_state                 char(2),
  web_zip                   char(10),
  web_country               varchar(20),
  web_gmt_offset            decimal(5,2),
  web_tax_percentage        decimal(5,2)
);

CREATE INDEX idx_web_site ON web_site (web_site_sk);

-----------------------------------------------------------------------

DROP TABLE reason;

CREATE TABLE reason (
  r_reason_sk               bigint NOT NULL,
  r_reason_id               char(16) NOT NULL,
  r_reason_desc             char(100)
);

CREATE INDEX idx_reason ON reason (r_reason_sk);

-----------------------------------------------------------------------

DROP TABLE store;

CREATE TABLE store (
  s_store_sk                bigint NOT NULL,
  s_store_id                char(16) NOT NULL,
  s_rec_start_date          date,
  s_rec_end_date            date,
  s_closed_date_sk          bigint,
  s_store_name              varchar(50),
  s_number_employees        integer,
  s_floor_space             integer,
  s_hours                   char(20),
  s_manager                 varchar(40),
  s_market_id               integer,
  s_geography_class         varchar(100),
  s_market_desc             varchar(100),
  s_market_manager          varchar(40),
  s_division_id             integer,
  s_division_name           varchar(50),
  s_company_id              integer,
  s_company_name            varchar(50),
  s_street_number           varchar(10),
  s_street_name             varchar(60),
  s_street_type             char(15),
  s_suite_number            char(10),
  s_city                    varchar(60),
  s_county                  varchar(30),
  s_state                   char(2),
  s_zip                     char(10),
  s_country                 varchar(20),
  s_gmt_offset              decimal(5,2),
  s_tax_precentage          decimal(5,2)
);

CREATE INDEX idx_store ON store (s_store_sk);

-----------------------------------------------------------------------

DROP TABLE web_page;

CREATE TABLE web_page (
  wp_web_page_sk            bigint NOT NULL,
  wp_web_page_id            char(16) NOT NULL,
  wp_rec_start_date         date,
  wp_rec_end_date           date,
  wp_creation_date_sk       bigint,
  wp_access_date_sk         bigint,
  wp_autogen_flag           char(1),
  wp_customer_sk            bigint,
  wp_url                    varchar(100),
  wp_type                   char(50),
  wp_char_count             integer,
  wp_link_count             integer,
  wp_image_count            integer,
  wp_max_ad_count           integer
);

CREATE INDEX idx_web_page ON web_page (wp_web_page_sk);

-----------------------------------------------------------------------

DROP TABLE household_demographics;

CREATE TABLE household_demographics (
  hd_demo_sk                bigint NOT NULL,
  hd_income_band_sk         bigint,
  hd_buy_potential          char(15),
  hd_dep_count              integer,
  hd_vehicle_count          integer
);

CREATE INDEX idx_household_demographics ON household_demographics (hd_demo_sk);

-----------------------------------------------------------------------

DROP TABLE promotion;

CREATE TABLE promotion (
  p_promo_sk                bigint NOT NULL,
  p_promo_id                char(16) NOT NULL,
  p_start_date_sk           bigint,
  p_end_date_sk             bigint,
  p_item_sk                 bigint,
  p_cost                    decimal(5,2),
  p_response_target         integer,
  p_promo_name              char(50),
  p_channel_dmail           char(1),
  p_channel_email           char(1),
  p_channel_catalog         char(1),
  p_channel_tv              char(1),
  p_channel_radio           char(1),
  p_channel_press           char(1),
  p_channel_event           char(1),
  p_channel_demo            char(1),
  p_channel_details         varchar(100),
  p_purpose                 char(15),
  p_discount_active         char(1)
);

CREATE INDEX idx_promotion ON promotion (p_promo_sk);

-----------------------------------------------------------------------

DROP TABLE time_dim;

CREATE TABLE time_dim (
  t_time_sk                 bigint NOT NULL,
  t_time_id                 char(16) NOT NULL,
  t_time                    integer,
  t_hour                    integer,
  t_minute                  integer,
  t_second                  integer,
  t_am_pm                   char(2),
  t_shift                   char(20),
  t_sub_shift               char(20),
  t_meal_time               char(20)
);

CREATE INDEX idx_time_dim ON time_dim (t_time_sk);

-----------------------------------------------------------------------

DROP TABLE date_dim;

CREATE TABLE date_dim ( 
  d_date_sk                 bigint NOT NULL,
  d_date_id                 char(16) NOT NULL,
  d_date                    date,
  d_month_seq               integer,
  d_week_seq                integer,
  d_quarter_seq             integer,
  d_year                    integer,
  d_dow                     integer,
  d_moy                     integer,
  d_dom                     integer,
  d_qoy                     integer,
  d_fy_year                 integer,
  d_fy_quarter_seq          integer,
  d_fy_week_seq             integer,
  d_day_name                char(9),
  d_quarter_name            char(6),
  d_holiday                 char(1),
  d_weekend                 char(1),
  d_following_holiday       char(1),
  d_first_dom               integer,
  d_last_dom                integer,
  d_same_day_ly             integer,
  d_same_day_lq             integer,
  d_current_day             char(1),
  d_current_week            char(1),
  d_current_month           char(1),
  d_current_quarter         char(1),
  d_current_year            char(1)
);

CREATE INDEX idx_date_dim ON date_dim (d_date_sk);

-----------------------------------------------------------------------

DROP TABLE customer_demographics;

CREATE TABLE customer_demographics (
  cd_demo_sk                bigint NOT NULL,
  cd_gender                 char(1),
  cd_marital_status         char(1),
  cd_education_status       char(20),
  cd_purchase_estimate      integer,
  cd_credit_rating          char(10),
  cd_dep_count              integer,
  cd_dep_employed_count     integer,
  cd_dep_college_count      integer
);

CREATE INDEX idx_customer_demographics ON customer_demographics (cd_demo_sk);

-----------------------------------------------------------------------

DROP TABLE item_marketprices;

CREATE TABLE item_marketprices (
  imp_sk                  bigint NOT NULL,
  imp_item_sk             bigint NOT NULL,
  imp_competitor          varchar(20),
  imp_competitor_price    decimal(7,2),
  imp_start_date          bigint,
  imp_end_date            bigint
);

CREATE INDEX idx_item_marketprices ON item_marketprices (imp_sk);

-----------------------------------------------------------------------

DROP TABLE customer_address;

CREATE TABLE customer_address (
  ca_address_sk             bigint NOT NULL,
  ca_address_id             char(16) NOT NULL,
  ca_street_number          char(10),
  ca_street_name            varchar(60),
  ca_street_type            char(15),
  ca_suite_number           char(10),
  ca_city                   varchar(60),
  ca_county                 varchar(30),
  ca_state                  char(2),
  ca_zip                    char(10),
  ca_country                varchar(20),
  ca_gmt_offset             decimal(5,2),
  ca_location_type          char(20)
);

CREATE INDEX idx_customer_address ON customer_address (ca_address_sk);

-----------------------------------------------------------------------

DROP TABLE item;

CREATE TABLE item (
  i_item_sk                 bigint NOT NULL,
  i_item_id                 char(16) NOT NULL,
  i_rec_start_date          date,
  i_rec_end_date            date,
  i_item_desc               varchar(200),
  i_current_price           decimal(7,2),
  i_wholesale_cost          decimal(7,2),
  i_brand_id                integer,
  i_brand                   char(50),
  i_class_id                integer,
  i_class                   char(50),
  i_category_id             integer,
  i_category                char(50),
  i_manufact_id             char(50),
  i_manufact                char(50),
  i_size                    char(20),
  i_formulation             char(20),
  i_color                   char(20),
  i_units                   char(10),
  i_container               char(10),
  i_manager_id              integer,
  i_product_name            char(50)
);

CREATE INDEX idx_item ON item (i_item_sk);

-----------------------------------------------------------------------

DROP TABLE customer;

CREATE TABLE customer (
  c_customer_sk             bigint NOT NULL,
  c_customer_id             char(16) NOT NULL,
  c_current_cdemo_sk        bigint,
  c_current_hdemo_sk        bigint,
  c_current_addr_sk         bigint,
  c_first_shipto_date_sk    bigint,
  c_first_sales_date_sk     bigint,
  c_salutation              char(10),
  c_first_name              char(20),
  c_last_name               char(30),
  c_preferred_cust_flag     char(1),
  c_birth_day               integer,
  c_birth_month             integer,
  c_birth_year              integer,
  c_birth_country           varchar(20),
  c_login                   char(13),
  c_email_address           char(50),
  c_last_review_date        char(10)
);

CREATE INDEX idx_customer ON customer (c_customer_sk);

-----------------------------------------------------------------------

DROP TABLE product_reviews;

CREATE TABLE product_reviews (
  pr_review_sk            bigint NOT NULL,
  pr_review_date          date,
  pr_review_time          char(8),
  pr_review_rating        integer NOT NULL,
  pr_item_sk              bigint NOT NULL,
  pr_user_sk              bigint,
  pr_order_sk             bigint,
  pr_review_content       clob NOT NULL
);

CREATE INDEX idx_product_reviews ON product_reviews (pr_review_sk);

-----------------------------------------------------------------------

DROP TABLE store_returns;

CREATE TABLE store_returns (
  sr_returned_date_sk       bigint,
  sr_return_time_sk         bigint,
  sr_item_sk                bigint NOT NULL,
  sr_customer_sk            bigint,
  sr_cdemo_sk               bigint,
  sr_hdemo_sk               bigint,
  sr_addr_sk                bigint,
  sr_store_sk               bigint,
  sr_reason_sk              bigint,
  sr_ticket_number          bigint NOT NULL,
  sr_return_quantity        integer,
  sr_return_amt             decimal(7,2),
  sr_return_tax             decimal(7,2),
  sr_return_amt_inc_tax     decimal(7,2),
  sr_fee                    decimal(7,2),
  sr_return_ship_cost       decimal(7,2),
  sr_refunded_cash          decimal(7,2),
  sr_reversed_charge        decimal(7,2),
  sr_store_credit           decimal(7,2),
  sr_net_loss               decimal(7,2)
);

CREATE INDEX idx_store_returns ON store_returns (sr_returned_date_sk);

-----------------------------------------------------------------------

DROP TABLE web_returns;

CREATE TABLE web_returns (
  wr_returned_date_sk       bigint,
  wr_returned_time_sk       bigint,
  wr_item_sk                bigint NOT NULL,
  wr_refunded_customer_sk   bigint,
  wr_refunded_cdemo_sk      bigint,
  wr_refunded_hdemo_sk      bigint,
  wr_refunded_addr_sk       bigint,
  wr_returning_customer_sk  bigint,
  wr_returning_cdemo_sk     bigint,
  wr_returning_hdemo_sk     bigint,
  wr_returning_addr_sk      bigint,
  wr_web_page_sk            bigint,
  wr_reason_sk              bigint,
  wr_order_number           bigint,
  wr_return_quantity        integer,
  wr_return_amt             decimal(7,2),
  wr_return_tax             decimal(7,2),
  wr_return_amt_inc_tax     decimal(7,2),
  wr_fee                    decimal(7,2),
  wr_return_ship_cost       decimal(7,2),
  wr_refunded_cash          decimal(7,2),
  wr_reversed_charge        decimal(7,2),
  wr_account_credit         decimal(7,2),
  wr_net_loss               decimal(7,2)
);

CREATE INDEX idx_web_returns ON web_returns (wr_returned_date_sk);

-----------------------------------------------------------------------

DROP TABLE inventory;

CREATE TABLE inventory (
  inv_date_sk               bigint NOT NULL,
  inv_item_sk               bigint NOT NULL,
  inv_warehouse_sk          bigint NOT NULL,
  inv_quantity_on_hand      integer
);

CREATE INDEX idx_inventory ON inventory (inv_date_sk);

-----------------------------------------------------------------------

DROP TABLE store_sales;

CREATE TABLE store_sales (
  ss_sold_date_sk           bigint,
  ss_sold_time_sk           bigint,
  ss_item_sk                bigint NOT NULL,
  ss_customer_sk            bigint,
  ss_cdemo_sk               bigint,
  ss_hdemo_sk               bigint,
  ss_addr_sk                bigint,
  ss_store_sk               bigint,
  ss_promo_sk               bigint,
  ss_ticket_number          bigint NOT NULL,
  ss_quantity               integer,
  ss_wholesale_cost         decimal(7,2),
  ss_list_price             decimal(7,2),
  ss_sales_price            decimal(7,2),
  ss_ext_discount_amt       decimal(7,2),
  ss_ext_sales_price        decimal(7,2),
  ss_ext_wholesale_cost     decimal(7,2),
  ss_ext_list_price         decimal(7,2),
  ss_ext_tax                decimal(7,2),
  ss_coupon_amt             decimal(7,2),
  ss_net_paid               decimal(7,2),
  ss_net_paid_inc_tax       decimal(7,2),
  ss_net_profit             decimal(7,2)
);

CREATE INDEX idx_store_sales ON store_sales (ss_sold_date_sk);

-----------------------------------------------------------------------

DROP TABLE web_sales;

CREATE TABLE web_sales (
  ws_sold_date_sk           bigint,
  ws_sold_time_sk           bigint,
  ws_ship_date_sk           bigint,
  ws_item_sk                bigint NOT NULL,
  ws_bill_customer_sk       bigint,
  ws_bill_cdemo_sk          bigint,
  ws_bill_hdemo_sk          bigint,
  ws_bill_addr_sk           bigint,
  ws_ship_customer_sk       bigint,
  ws_ship_cdemo_sk          bigint,
  ws_ship_hdemo_sk          bigint,
  ws_ship_addr_sk           bigint,
  ws_web_page_sk            bigint,
  ws_web_site_sk            bigint,
  ws_ship_mode_sk           bigint,
  ws_warehouse_sk           bigint,
  ws_promo_sk               bigint,
  ws_order_number           bigint NOT NULL,
  ws_quantity               integer,
  ws_wholesale_cost         decimal(7,2),
  ws_list_price             decimal(7,2),
  ws_sales_price            decimal(7,2),
  ws_ext_discount_amt       decimal(7,2),
  ws_ext_sales_price        decimal(7,2),
  ws_ext_wholesale_cost     decimal(7,2),
  ws_ext_list_price         decimal(7,2),
  ws_ext_tax                decimal(7,2),
  ws_coupon_amt             decimal(7,2),
  ws_ext_ship_cost          decimal(7,2),
  ws_net_paid               decimal(7,2),
  ws_net_paid_inc_tax       decimal(7,2),
  ws_net_paid_inc_ship      decimal(7,2),
  ws_net_paid_inc_ship_tax  decimal(7,2),
  ws_net_profit             decimal(7,2)
  
);

CREATE INDEX idx_web_sales ON web_sales (ws_sold_date_sk);

-----------------------------------------------------------------------

DROP TABLE web_clickstreams;

CREATE TABLE web_clickstreams (
  wcs_click_date_sk       bigint,
  wcs_click_time_sk       bigint,
  wcs_sales_sk            bigint,
  wcs_item_sk             bigint,
  wcs_web_page_sk         bigint,
  wcs_user_sk             bigint
);

CREATE INDEX idx_web_clickstreams ON web_clickstreams (wcs_click_date_sk);

-----------------------------------------------------------------------






