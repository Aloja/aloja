SELECT CAST(amc AS float) / CAST(pmc AS float) am_pm_ratio
FROM
  (SELECT COUNT(*) amc
   FROM web_sales ws, household_demographics hd, time_dim td, web_page wp 
   WHERE td.t_time_sk = ws.ws_sold_time_sk
         AND hd.hd_demo_sk = ws.ws_ship_hdemo_sk
         AND wp.wp_web_page_sk = ws.ws_web_page_sk
         AND td.t_hour >= 7
         AND td.t_hour <= 8
         AND hd.hd_dep_count = 5
         AND wp.wp_char_count >= 5000
         AND wp.wp_char_count <= 6000
  ) AS atTable,
  (SELECT COUNT(*) pmc
   FROM web_sales ws, household_demographics hd, time_dim td, web_page wp 
   WHERE td.t_time_sk = ws.ws_sold_time_sk
         AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
         AND wp.wp_web_page_sk = ws.ws_web_page_sk
         AND hd.hd_dep_count = 5
         AND td.t_hour >= 19
         AND td.t_hour <= 20
         AND wp.wp_char_count >= 5000
         AND wp.wp_char_count <= 6000
  ) AS ptTable
  ORDER BY am_pm_ratio;
   
   