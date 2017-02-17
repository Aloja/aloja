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



-- !echo ============================;
-- !echo Hive Settings;
-- !echo ============================;

-- set hive.log.dir=##LOG_DIR##;
-- set hive.exec.local.scratchdir=##TMP_DIR##;
-- set hive.metastore.uris=thrift://localhost:##PORT_PREFIX##9083;

-- set ambari.hive.db.schema.name=hive;

set fs.file.impl.disable.cache=true;
set fs.hdfs.impl.disable.cache=true;
set hive.auto.convert.sortmerge.join=true;
set hive.compactor.abortedtxn.threshold=1000;
set hive.compactor.check.interval=300;
set hive.compactor.delta.num.threshold=10;
set hive.compactor.delta.pct.threshold=0.1f;
set hive.compactor.initiator.on=false;
set hive.compactor.worker.threads=0;
set hive.compactor.worker.timeout=86400;
set hive.compute.query.using.stats=true;
set hive.enforce.bucketing=true;
set hive.enforce.sorting=true;
set hive.enforce.sortmergebucketmapjoin=true;
set hive.limit.pushdown.memory.usage=0.04;
set hive.map.aggr=true;
set hive.mapjoin.bucket.cache.size=10000;
set hive.mapred.reduce.tasks.speculative.execution=false;
set hive.metastore.cache.pinobjtypes=Table,Database,Type,FieldSchema,Order;
set hive.metastore.client.socket.timeout=60;
set hive.metastore.execute.setugi=true;
set hive.metastore.warehouse.dir=/apps/hive/warehouse;
set hive.optimize.bucketmapjoin.sortedmerge=false;
set hive.optimize.bucketmapjoin=true;
set hive.optimize.index.filter=true;
-- set hive.optimize.mapjoin.mapreduce=true;
set hive.optimize.reducededuplication.min.reducer=4;
set hive.optimize.reducededuplication=true;
set hive.orc.splits.include.file.footer=false;
set hive.security.authorization.enabled=false;
set hive.security.metastore.authorization.manager=org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider;
-- set hive.semantic.analyzer.factory.impl=org.apache.hivealog.cli.HCatSemanticAnalyzerFactory;
set hive.server2.enable.doAs=false;

set hive.stats.autogather=true;
set hive.txn.manager=org.apache.hadoop.hive.ql.lockmgr.DummyTxnManager;
set hive.txn.max.open.batch=1000;
set hive.txn.timeout=300;

set hive.vectorized.execution.enabled=true;
set hive.vectorized.execution.reduce.enabled = true;
set hive.vectorized.groupby.checkinterval=1024;
set hive.vectorized.groupby.flush.percent=1;
set hive.vectorized.groupby.maxentries=1024;

set hive.cbo.enable=true;
set hive.stats.fetch.column.stats=true;
set hive.stats.fetch.partition.stats=true;

set hive.support.sql11.reserved.keywords=false;

-- ###########################
-- Number of mappers.
-- ###########################

set mapred.max.split.size=67108864;
set mapred.min.split.size=1;

-- ###########################
-- optimizations for joins.
-- ###########################

set hive.auto.convert.join=##HIVE_JOINS##;
set hive.auto.convert.join.noconditionaltask=##HIVE_JOINS##;
set hive.auto.convert.join.noconditionaltask.size=10000000;
set hive.mapjoin.localtask.max.memory.usage = 0.999;
set hive.exec.submit.local.task.via.child=true;


set hive.auto.convert.sortmerge.join=true;
set hive.auto.convert.sortmerge.join.to.mapjoin=false;
set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.exec.max.created.files=100000;
set hive.exec.max.dynamic.partitions=5000;
set hive.exec.max.dynamic.partitions.pernode=2000;
set hive.map.aggr=true;
set hive.map.aggr.hash.force.flush.memory.threshold=0.9;
set hive.stats.autogather=true;

-- ###########################
-- Tez settings
-- ###########################

set hive.execution.engine=##HIVE_ENGINE##;
set hive.tez.container.size=##MAPS_MB##;
set hive.tez.cpu.vcores=-1;
set hive.tez.java.opts=-Xms##CONTAINER_80##m -Xmx##CONTAINER_80##m -Djava.net.preferIPv4Stack=true -XX:NewRatio=8 -XX:+UseNUMA -XX:+UseParallelGC;
set tez.runtime.unordered.output.buffer.size-mb=##CONTAINER_10##;
set hive.tez.input.format=org.apache.hadoop.hive.ql.io.HiveInputFormat;
set hive.server2.tez.default.queues=default;
set hive.server2.tez.initialize.default.sessions=false;
set hive.server2.tez.sessions.per.default.queue=1;
set hive.tez.auto.reducer.parallelism=false;

set hive.tez.exec.print.summary=true;


set hive.tez.dynamic.partition.pruning=true;
set hive.tez.dynamic.partition.pruning.max.data.size=104857600;
set hive.tez.dynamic.partition.pruning.max.event.size=1048576;
-- set tez.grouping.min-size=67108864;
-- set tez.grouping.max-size=1073741824;
set hive.tez.max.partition.factor=3f;
set hive.tez.min.partition.factor=1f;
set hive.convert.join.bucket.mapjoin.tez=false;

-- Print Settings

set hive.exec.parallel;
set hive.exec.parallel.thread.number;
set hive.exec.compress.intermediate;
set mapred.map.output.compression.codec;
set hive.exec.compress.output;
set mapred.output.compression.codec;
set hive.default.fileformat;
set mapred.max.split.size;
set mapred.min.split.size;
set hive.exec.reducers.bytes.per.reducer;
set hive.exec.reducers.max;
set hive.auto.convert.sortmerge.join;
set hive.auto.convert.sortmerge.join.noconditionaltask;
set hive.optimize.bucketmapjoin;
set hive.optimize.bucketmapjoin.sortedmerge;
set hive.optimize.ppd;
set hive.optimize.index.filter;
set hive.auto.convert.join.noconditionaltask.size;
set hive.auto.convert.join;
set hive.auto.convert.join.noconditionaltask;
set hive.optimize.mapjoin.mapreduce;
set hive.mapred.local.mem;
set hive.mapjoin.smalltable.filesize;
set hive.mapjoin.localtask.max.memory.usage;
set hive.optimize.skewjoin;
set hive.optimize.skewjoin.compiletime;
set hive.groupby.skewindata;

set hive.tez.container.size;
set hive.tez.java.opts;
set tez.runtime.unordered.output.buffer.size-mb;
set hive.tez.dynamic.partition.pruning.max.data.size;
set hive.tez.dynamic.partition.pruning.max.event.size;

-- !echo ============================;
-- !echo </settings from hiveSettings.sql>;
-- !echo ============================;

-- Database - DO NOT DELETE OR CHANGE
CREATE DATABASE IF NOT EXISTS bigbench;
use bigbench;



-- NEEDED FOR BB
set bigbench.hive.optimize.sampling.orderby=true;
set bigbench.hive.optimize.sampling.orderby.number=20000;
set bigbench.hive.optimize.sampling.orderby.percent=0.1;
set bigbench.resources.dir=##BIG_BENCH_RESOURCES_DIR##;
set bigbench.tableFormat_source=##HIVE_FILEFORMAT##;
set bigbench.tableFormat=TEXTFILE;

