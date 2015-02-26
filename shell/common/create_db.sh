#file must be sourced

logger "INFO: Creating DB and tables for $DB (if necessary)"

$MYSQL "

CREATE DATABASE IF NOT EXISTS \`$DB\`;

CREATE TABLE IF NOT EXISTS \`execs\` (
  \`id_exec\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_cluster\` int(11) DEFAULT NULL,
  \`exec\` varchar(255) DEFAULT NULL,
  \`bench\` varchar(255) DEFAULT NULL,
  \`exe_time\` decimal(20,3) DEFAULT NULL,
  \`start_time\` datetime DEFAULT NULL,
  \`end_time\` datetime DEFAULT NULL,
  \`net\` varchar(255) DEFAULT NULL,
  \`disk\` varchar(255) DEFAULT NULL,
  \`bench_type\` varchar(255) DEFAULT NULL,
  \`maps\` int(11) DEFAULT NULL,
  \`iosf\` int(11) DEFAULT NULL,
  \`replication\` int(11) DEFAULT NULL,
  \`iofilebuf\` int(11) DEFAULT NULL,
  \`comp\` int(11) DEFAULT NULL,
  \`blk_size\` int(11) DEFAULT NULL,
  hadoop_version varchar(127) default NULL,
  \`zabbix_link\` varchar(255) DEFAULT NULL,
  \`valid\` int DEFAULT 1,
  \`filter\` int DEFAULT 0,
  \`outlier\` int DEFAULT 0,
  PRIMARY KEY (\`id_exec\`),
  UNIQUE KEY \`exec_UNIQUE\` (\`exec\`),
  KEY \`idx_bench\` (\`bench\`),
  KEY \`idx_exe_time\` (\`exe_time\`),
  KEY \`idx_bench_type\` (\`bench_type\`)
) ENGINE=InnoDB;


create table if not exists hosts (
  id_host int(11) NOT NULL AUTO_INCREMENT,
  host_name varchar(127) NOT NULL,
  id_cluster int(11) NOT NULL,
  role varchar(45) DEFAULT NULL,
 cost_remote int(11) DEFAULT NULL,
 cost_SSD int(11) DEFAULT NULL,
 cost_IB int(11) DEFAULT NULL,
  PRIMARY KEY (id_host)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

create table if not exists clusters (
id_cluster int,
name varchar(127),
cost_hour decimal(10,3),
\`type\` varchar(127),
provider varchar(127),
datanodes int DEFAULT NULL,
headnodes int DEFAULT NULL,
vm_size varchar(127) default null,
vm_OS varchar(127) default null,
vm_cores int default null,
vm_RAM decimal(10,3) default null,
cost_remote int default 0,
cost_SSD int default 0,
cost_IB int default 0,
description varchar(256) default null,
link varchar(255),
primary key (id_cluster)) engine InnoDB;
"

$MYSQL "
CREATE TABLE IF NOT EXISTS \`SAR_cpu\` (
  \`id_SAR_cpu\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(127) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`CPU\` varchar(255) DEFAULT NULL,
  \`%user\` decimal(20,3) DEFAULT NULL,
  \`%nice\` decimal(20,3) DEFAULT NULL,
  \`%system\` decimal(20,3) DEFAULT NULL,
  \`%iowait\` decimal(20,3) DEFAULT NULL,
  \`%steal\` decimal(20,3) DEFAULT NULL,
  \`%idle\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_cpu\`),
  UNIQUE KEY \`avoid_duplicates\` (\`id_exec\`,\`host\`,\`date\`)
  #KEY \`index1\` (\`id_exec\`),
  #KEY \`index2\` (\`date\`),
  #KEY \`index3\` (\`host\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_block_devices\` (
  \`id_SAR_block_devices\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(127) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`DEV\` varchar(255) DEFAULT NULL,
  \`tps\` decimal(20,3) DEFAULT NULL,
  \`rd_sec/s\` decimal(20,3) DEFAULT NULL,
  \`wr_sec/s\` decimal(20,3) DEFAULT NULL,
  \`avgrq-sz\` decimal(20,3) DEFAULT NULL,
  \`avgqu-sz\` decimal(20,3) DEFAULT NULL,
  \`await\` decimal(20,3) DEFAULT NULL,
  \`svctm\` decimal(20,3) DEFAULT NULL,
  \`%util\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_block_devices\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`,\`DEV\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_interrupts\` (
  \`id_SAR_interrupts\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`INTR\` varchar(255) DEFAULT NULL,
  \`intr/s\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_interrupts\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_io_paging\` (
  \`id_SAR_io_paging\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`pgpgin/s\` decimal(20,3) DEFAULT NULL,
  \`pgpgout/s\` decimal(20,3) DEFAULT NULL,
  \`fault/s\` decimal(20,3) DEFAULT NULL,
  \`majflt/s\` decimal(20,3) DEFAULT NULL,
  \`pgfree/s\` decimal(20,3) DEFAULT NULL,
  \`pgscank/s\` decimal(20,3) DEFAULT NULL,
  \`pgscand/s\` decimal(20,3) DEFAULT NULL,
  \`pgsteal/s\` decimal(20,3) DEFAULT NULL,
  \`%vmeff\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_io_paging\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_io_rate\` (
  \`id_SAR_io_rate\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(127) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`tps\` decimal(20,3) DEFAULT NULL,
  \`rtps\` decimal(20,3) DEFAULT NULL,
  \`wtps\` decimal(20,3) DEFAULT NULL,
  \`bread/s\` decimal(20,3) DEFAULT NULL,
  \`bwrtn/s\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_io_rate\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_load\` (
  \`id_SAR_load\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`runq-sz\` decimal(20,3) DEFAULT NULL,
  \`plist-sz\` decimal(20,3) DEFAULT NULL,
  \`ldavg-1\` decimal(20,3) DEFAULT NULL,
  \`ldavg-5\` decimal(20,3) DEFAULT NULL,
  \`ldavg-15\` decimal(20,3) DEFAULT NULL,
  \`blocked\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_load\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_memory\` (
  \`id_SAR_memory\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`frmpg/s\` decimal(20,3) DEFAULT NULL,
  \`bufpg/s\` decimal(20,3) DEFAULT NULL,
  \`campg/s\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_memory\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_memory_util\` (
  \`id_SAR_memory_util\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`kbmemfree\` decimal(20,3) DEFAULT NULL,
  \`kbmemused\` decimal(20,3) DEFAULT NULL,
  \`%memused\` decimal(20,3) DEFAULT NULL,
  \`kbbuffers\` decimal(20,3) DEFAULT NULL,
  \`kbcached\` decimal(20,3) DEFAULT NULL,
  \`kbcommit\` decimal(20,3) DEFAULT NULL,
  \`%commit\` decimal(20,3) DEFAULT NULL,
  \`kbactive\` decimal(20,3) DEFAULT NULL,
  \`kbinact\` decimal(20,3) DEFAULT NULL,
  #\`kbdirty\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_memory_util\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_net_devices\` (
  \`id_SAR_net_devices\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(127) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`IFACE\` varchar(255) DEFAULT NULL,
  \`rxpck/s\` decimal(20,3) DEFAULT NULL,
  \`txpck/s\` decimal(20,3) DEFAULT NULL,
  \`rxkB/s\` decimal(20,3) DEFAULT NULL,
  \`txkB/s\` decimal(20,3) DEFAULT NULL,
  \`rxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`txcmp/s\` decimal(20,3) DEFAULT NULL,
  \`rxmcst/s\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_net_devices\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`,\`IFACE\`)
) ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS \`SAR_net_errors\` (
  \`id_SAR_net_errors\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`IFACE\` varchar(255) DEFAULT NULL,
  \`rxerr/s\` varchar(255) DEFAULT NULL,
  \`txerr/s\` varchar(255) DEFAULT NULL,
  \`coll/s\` varchar(255) DEFAULT NULL,
  \`rxdrop/s\` varchar(255) DEFAULT NULL,
  \`txdrop/s\` varchar(255) DEFAULT NULL,
  \`txcarr/s\` varchar(255) DEFAULT NULL,
  \`rxfram/s\` varchar(255) DEFAULT NULL,
  \`rxfifo/s\` varchar(255) DEFAULT NULL,
  \`txfifo/s\` varchar(255) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_net_errors\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`,\`IFACE\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_net_sockets\` (
  \`id_SAR_net_sockets\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` varchar(255) DEFAULT NULL,
  \`date\` varchar(255) DEFAULT NULL,
  \`totsck\` varchar(255) DEFAULT NULL,
  \`tcpsck\` varchar(255) DEFAULT NULL,
  \`udpsck\` varchar(255) DEFAULT NULL,
  \`rawsck\` varchar(255) DEFAULT NULL,
  \`ip-frag\` varchar(255) DEFAULT NULL,
  \`tcp-tw\` varchar(255) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_net_sockets\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_swap\` (
  \`id_SAR_swap\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`kbswpfree\` decimal(20,3) DEFAULT NULL,
  \`kbswpused\` decimal(20,3) DEFAULT NULL,
  \`%swpused\` decimal(20,3) DEFAULT NULL,
  \`kbswpcad\` decimal(20,3) DEFAULT NULL,
  \`%swpcad\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_swap\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_swap_util\` (
  \`id_SAR_swap_util\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`pswpin/s\` decimal(20,3) DEFAULT NULL,
  \`pswpout/s\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_swap_util\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`SAR_switches\` (
  \`id_SAR_switches\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`interval\` decimal(20,3) DEFAULT NULL,
  \`date\` datetime DEFAULT NULL,
  \`proc/s\` decimal(20,3) DEFAULT NULL,
  \`cswch/s\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_SAR_switches\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`date\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`BWM\` (
  \`id_BWM\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`unix_timestamp\` int(11) DEFAULT NULL,
  \`iface_name\` varchar(23) DEFAULT NULL,
  \`bytes_out\` decimal(20,3) DEFAULT NULL,
  \`bytes_in\` decimal(20,3) DEFAULT NULL,
  \`bytes_total\` decimal(20,3) DEFAULT NULL,
  \`packets_out\` decimal(20,3) DEFAULT NULL,
  \`packets_in\` decimal(20,3) DEFAULT NULL,
  \`packets_total\` decimal(20,3) DEFAULT NULL,
  \`errors_out\` decimal(20,3) DEFAULT NULL,
  \`errors_in\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_BWM\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`unix_timestamp\`,\`iface_name\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`BWM2\` (
  \`id_BWM\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`unix_timestamp\` int(11) DEFAULT NULL,
  \`iface_name\` varchar(23) DEFAULT NULL,
  \`bytes_out/s\` decimal(20,3) DEFAULT NULL,
  \`bytes_in/s\` decimal(20,3) DEFAULT NULL,
  \`bytes_total/s\` decimal(20,3) DEFAULT NULL,
  \`bytes_in\` decimal(20,3) DEFAULT NULL,
  \`bytes_out\` decimal(20,3) DEFAULT NULL,
  # \`bytes_total\` decimal(20,3) DEFAULT NULL,
  \`packets_out/s\` decimal(20,3) DEFAULT NULL,
  \`packets_in/s\` decimal(20,3) DEFAULT NULL,
  \`packets_total/s\` decimal(20,3) DEFAULT NULL,
  \`packets_in\` decimal(20,3) DEFAULT NULL,
  \`packets_out\` decimal(20,3) DEFAULT NULL,
  \`errors_out/s\` decimal(20,3) DEFAULT NULL,
  \`errors_in/s\` decimal(20,3) DEFAULT NULL,
  \`errors_in\` decimal(20,3) DEFAULT NULL,
  \`errors_out\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_BWM\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`unix_timestamp\`,\`iface_name\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`VMSTATS\` (
  \`id_VMSTATS\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`host\` varchar(255) DEFAULT NULL,
  \`time\` int(11) DEFAULT NULL,
  \`r\` decimal(20,3) DEFAULT NULL,
  \`b\` decimal(20,3) DEFAULT NULL,
  \`swpd\` decimal(20,3) DEFAULT NULL,
  \`free\` decimal(20,3) DEFAULT NULL,
  \`buff\` decimal(20,3) DEFAULT NULL,
  \`cache\` decimal(20,3) DEFAULT NULL,
  \`si\` decimal(20,3) DEFAULT NULL,
  \`so\` decimal(20,3) DEFAULT NULL,
  \`bi\` decimal(20,3) DEFAULT NULL,
  \`bo\` decimal(20,3) DEFAULT NULL,
  \`in\` decimal(20,3) DEFAULT NULL,
  \`cs\` decimal(20,3) DEFAULT NULL,
  \`us\` decimal(20,3) DEFAULT NULL,
  \`sy\` decimal(20,3) DEFAULT NULL,
  \`id\` decimal(20,3) DEFAULT NULL,
  \`wa\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_VMSTATS\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`host\`,\`time\`)
) ENGINE=InnoDB;


#CREATE TABLE IF NOT EXISTS \`JOB_COUNTERS\` (
#  \`id_JOB_COUNTERS\` int(11) NOT NULL AUTO_INCREMENT,
#  \`id_exec\` int(11) NOT NULL,
#  \`job_name\` varchar(255) DEFAULT NULL,
#  \`BYTES_READ\` bigint DEFAULT NULL,
#  \`SLOTS_MILLIS_MAPS\` bigint DEFAULT NULL,
#  \`FALLOW_SLOTS_MILLIS_REDUCES\` bigint DEFAULT NULL,
#  \`FALLOW_SLOTS_MILLIS_MAPS\` bigint DEFAULT NULL,
#  \`TOTAL_LAUNCHED_MAPS\` bigint DEFAULT NULL,
#  \`SLOTS_MILLIS_REDUCES\` bigint DEFAULT NULL,
#  \`BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`HDFS_BYTES_READ\` bigint DEFAULT NULL,
#  \`FILE_BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`HDFS_BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`MAP_INPUT_RECORDS\` bigint DEFAULT NULL,
#  \`PHYSICAL_MEMORY_BYTES\` bigint DEFAULT NULL,
#  \`SPILLED_RECORDS\` bigint DEFAULT NULL,
#  \`COMMITTED_HEAP_BYTES\` bigint DEFAULT NULL,
#  \`CPU_MILLISECONDS\` bigint DEFAULT NULL,
#  \`MAP_INPUT_BYTES\` bigint DEFAULT NULL,
#  \`VIRTUAL_MEMORY_BYTES\` bigint DEFAULT NULL,
#  \`SPLIT_RAW_BYTES\` bigint DEFAULT NULL,
#  \`MAP_OUTPUT_RECORDS\` bigint DEFAULT NULL,
#  PRIMARY KEY (\`id_JOB_COUNTERS\`),
#  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`),
#  KEY \`index2\` (\`id_exec\`),
#  KEY \`index_job_name\` (\`job_name\`)
#) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`JOB_details\` (
  \`id_JOB_details\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`job_name\` varchar(255) DEFAULT NULL,
  \`JOBID\` varchar(255) NOT NULL,
  \`JOBNAME\` varchar(127) DEFAULT NULL,
  \`SUBMIT_TIME\` datetime DEFAULT NULL,
  \`LAUNCH_TIME\` datetime DEFAULT NULL,
  \`FINISH_TIME\` datetime DEFAULT NULL,
  \`JOB_PRIORITY\` varchar(255) DEFAULT NULL,
  \`USER\` varchar(127) DEFAULT NULL,
  \`TOTAL_MAPS\` int(11) DEFAULT NULL,
  \`FAILED_MAPS\` int(11) DEFAULT NULL,
  \`FINISHED_MAPS\` int(11) DEFAULT NULL,
  \`TOTAL_REDUCES\` int(11) DEFAULT NULL,
  \`FAILED_REDUCES\` int(11) DEFAULT NULL,
  \`Launched map tasks\` bigint DEFAULT NULL,  #Job Counters
  \`Rack-local map tasks\` bigint DEFAULT NULL,
  \`Launched reduce tasks\` bigint DEFAULT NULL,
  \`SLOTS_MILLIS_MAPS\` bigint DEFAULT NULL,
  \`SLOTS_MILLIS_REDUCES\` bigint DEFAULT NULL,
  \`Data-local map tasks\` bigint DEFAULT NULL,
  \`FILE_BYTES_WRITTEN\` bigint DEFAULT NULL, #FileSystem
  \`FILE_BYTES_READ\` bigint DEFAULT NULL,
  \`HDFS_BYTES_WRITTEN\` bigint DEFAULT NULL,
  \`HDFS_BYTES_READ\` bigint DEFAULT NULL,
  \`Bytes Read\` bigint DEFAULT NULL,
  \`Bytes Written\` bigint DEFAULT NULL, #File Input/Output Format
  \`Spilled Records\` bigint DEFAULT NULL,  #MR framework
  \`SPLIT_RAW_BYTES\` bigint DEFAULT NULL,
  \`Map input records\` bigint DEFAULT NULL,
  \`Map output records\` bigint DEFAULT NULL,
  \`Map input bytes\` bigint DEFAULT NULL,
  \`Map output bytes\` bigint DEFAULT NULL,
  \`Map output materialized bytes\` bigint DEFAULT NULL,
  \`Reduce input groups\` bigint DEFAULT NULL,
  \`Reduce input records\` bigint DEFAULT NULL,
  \`Reduce output records\` bigint DEFAULT NULL,
  \`Reduce shuffle bytes\` bigint DEFAULT NULL,
  \`Combine input records\` bigint DEFAULT NULL,
  \`Combine output records\` bigint DEFAULT NULL,
  PRIMARY KEY (\`id_JOB_details\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`),
  KEY \`index2\` (\`id_exec\`),
  KEY \`index_job_name\` (\`job_name\`),
  KEY \`index_JOBNAME\` (\`JOBNAME\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`JOB_status\` (
  \`id_JOB_job_status\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`job_name\` varchar(255) NOT NULL,
  \`JOBID\` varchar(255) NOT NULL,
  \`date\` datetime DEFAULT NULL,
  \`maps\` int(11) DEFAULT NULL,
  \`shuffle\` int(11) DEFAULT NULL,
  \`merge\` int(11) DEFAULT NULL,
  \`reduce\` int(11) DEFAULT NULL,
  \`waste\` int(11) DEFAULT NULL,
  PRIMARY KEY (\`id_JOB_job_status\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`,\`date\`),
  KEY \`index2\` (\`id_exec\`),
  KEY \`index_job_name\` (\`job_name\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`JOB_tasks\` (
  \`id_JOB_job_tasks\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`job_name\` varchar(255) NOT NULL,
  \`JOBID\` varchar(255) NOT NULL,
  \`TASKID\` varchar(127) DEFAULT NULL,
  \`TASK_TYPE\` varchar(127) DEFAULT NULL,
  \`TASK_STATUS\` varchar(127) DEFAULT NULL,
  \`START_TIME\` datetime DEFAULT NULL,
  \`FINISH_TIME\` datetime DEFAULT NULL,
  \`SHUFFLE_TIME\` datetime DEFAULT NULL,
  \`SORT_TIME\` datetime DEFAULT NULL,
  \`Bytes Read\` bigint DEFAULT NULL,
  \`Bytes Written\` bigint DEFAULT NULL,
  \`FILE_BYTES_WRITTEN\` bigint DEFAULT NULL,
  \`FILE_BYTES_READ\` bigint DEFAULT NULL,
  \`HDFS_BYTES_WRITTEN\` bigint DEFAULT NULL,
  \`HDFS_BYTES_READ\` bigint DEFAULT NULL,
  \`Spilled Records\` bigint DEFAULT NULL,
  \`SPLIT_RAW_BYTES\` bigint DEFAULT NULL,
  \`Map input records\` bigint DEFAULT NULL,
  \`Map output records\` bigint DEFAULT NULL,
  \`Map input bytes\` bigint DEFAULT NULL,
  \`Map output bytes\` bigint DEFAULT NULL,
  \`Map output materialized bytes\` bigint DEFAULT NULL,
  \`Reduce input groups\` bigint DEFAULT NULL,
  \`Reduce input records\` bigint DEFAULT NULL,
  \`Reduce output records\` bigint DEFAULT NULL,
  \`Reduce shuffle bytes\` bigint DEFAULT NULL,
  \`Combine input records\` bigint DEFAULT NULL,
  \`Combine output records\` bigint DEFAULT NULL,
  PRIMARY KEY (\`id_JOB_job_tasks\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`, \`TASKID\`),
  KEY \`index2\` (\`id_exec\`),
  KEY \`index_job_name\` (\`job_name\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`execs_conf_parameters\` (
  \`id_execs_conf_parameters\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`job_name\` varchar(255) NOT NULL,
  \`parameter_name\` varchar(255) NOT NULL,
  \`parameter_value\` varchar(255) NOT NULL,
  PRIMARY KEY (\`id_execs_conf_parameters\`),
  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`,\`parameter_name\`),
  KEY \`index2\` (\`id_exec\`),
  KEY \`index_job_name\` (\`job_name\`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS \`HDI_JOB_details\` (
  \`hdi_job_details_id\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`JOB_ID\` varchar(255) NOT NULL,
  \`BYTES_READ\` bigint(20) NOT NULL,
  \`BYTES_WRITTEN\` bigint(20) NOT NULL,
  \`COMMITTED_HEAP_BYTES\` bigint(20) NOT NULL,
  \`CPU_MILLISECONDS\` bigint(20) NOT NULL,
  \`FAILED_MAPS\` bigint(20) NOT NULL,
  \`FAILED_REDUCES\` bigint(20) NOT NULL,
  \`FAILED_SHUFFLE\` bigint(20) NOT NULL,
  \`FILE_BYTES_READ\` bigint(20) NOT NULL,
  \`FILE_BYTES_WRITTEN\` bigint(20) NOT NULL,
  \`FILE_LARGE_READ_OPS\` bigint(20) NOT NULL,
  \`FILE_READ_OPS\` bigint(20) NOT NULL,
  \`FILE_WRITE_OPS\` bigint(20) NOT NULL,
  \`FINISHED_MAPS\` bigint(20) NOT NULL,
  \`FINISH_TIME\` bigint(20) NOT NULL,
  \`GC_TIME_MILLIS\` bigint(20) NOT NULL,
  \`JOB_PRIORITY\` varchar(255) NOT NULL,
  \`LAUNCH_TIME\` bigint(20) NOT NULL,
  \`MAP_INPUT_RECORDS\` bigint(20) NOT NULL,
  \`MAP_OUTPUT_RECORDS\` bigint(20) NOT NULL,
  \`MB_MILLIS_MAPS\` bigint(20) NOT NULL,
  \`MERGED_MAP_OUTPUTS\` bigint(20) NOT NULL,
  \`MILLIS_MAPS\` bigint(20) NOT NULL,
  \`OTHER_LOCAL_MAPS\` bigint(20) NOT NULL,
  \`PHYSICAL_MEMORY_BYTES\` bigint(20) NOT NULL,
  \`SLOTS_MILLIS_MAPS\` bigint(20) NOT NULL,
  \`SPILLED_RECORDS\` bigint(20) NOT NULL,
  \`SPLIT_RAW_BYTES\` bigint(20) NOT NULL,
  \`SUBMIT_TIME\` bigint(20) NOT NULL,
  \`TOTAL_LAUNCHED_MAPS\` bigint(20) NOT NULL,
  \`TOTAL_MAPS\` bigint(20) NOT NULL,
  \`TOTAL_REDUCES\` bigint(20) NOT NULL,
  \`USER\` varchar(255) NOT NULL,
  \`VCORES_MILLIS_MAPS\` bigint(20) NOT NULL,
  \`VIRTUAL_MEMORY_BYTES\` bigint(20) NOT NULL,
  \`WASB_BYTES_READ\` bigint(20) NOT NULL,
  \`WASB_BYTES_WRITTEN\` bigint(20) NOT NULL,
  \`WASB_LARGE_READ_OPS\` bigint(20) NOT NULL,
  \`WASB_READ_OPS\` bigint(20) NOT NULL,
  \`WASB_WRITE_OPS\` bigint(20) NOT NULL,
  \`job_name\` varchar(255) DEFAULT NULL,
  \`RECORDS_WRITTEN\` bigint(20) DEFAULT NULL,
  \`BAD_ID\` varchar(255) DEFAULT NULL,
  \`COMBINE_INPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`COMBINE_OUTPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`CONNECTION\` bigint(20) DEFAULT NULL,
  \`IO_ERROR\` varchar(255) DEFAULT NULL,
  \`MAP_OUTPUT_BYTES\` bigint(20) DEFAULT NULL,
  \`MAP_OUTPUT_MATERIALIZED_BYTES\` bigint(20) DEFAULT NULL,
  \`MB_MILLIS_REDUCES\` bigint(20) DEFAULT NULL,
  \`MILLIS_REDUCES\` bigint(20) DEFAULT NULL,
  \`RACK_LOCAL_MAPS\` bigint(20) DEFAULT NULL,
  \`REDUCE_INPUT_GROUPS\` bigint(20) DEFAULT NULL,
  \`REDUCE_INPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`REDUCE_OUTPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`REDUCE_SHUFFLE_BYTES\` bigint(20) DEFAULT NULL,
  \`WRONG_LENGTH\` bigint(20) DEFAULT NULL,
  \`WRONG_MAP\` bigint(20) DEFAULT NULL,
  \`WRONG_REDUCE\` bigint(20) DEFAULT NULL,
  \`TOTAL_LAUNCHED_REDUCES\` bigint(20) DEFAULT NULL,
  \`SHUFFLED_MAPS\` bigint(20) DEFAULT NULL,
  \`SLOTS_MILLIS_REDUCES\` bigint(20) DEFAULT NULL,
  \`VCORES_MILLIS_REDUCES\` bigint(20) DEFAULT NULL,
  \`CHECKSUM\` varchar(255) DEFAULT NULL,
  \`NUM_FAILED_MAPS\` varchar(255) DEFAULT NULL,
  PRIMARY KEY (\`hdi_job_details_id\`),
  UNIQUE KEY \`job_id_uq\` (\`JOB_ID\`),
  KEY \`id_exec\` (\`id_exec\`),
  CONSTRAINT \`HDI_JOB_details_ibfk_1\` FOREIGN KEY (\`id_exec\`) REFERENCES \`execs\` (\`id_exec\`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`HDI_JOB_tasks\` (
\`hdi_job_task_id\` int(11) NOT NULL AUTO_INCREMENT,
  \`JOB_ID\` varchar(255) NOT NULL,
  \`TASK_ID\` varchar(255) NOT NULL,
  \`BYTES_READ\` bigint(20) DEFAULT '0',
  \`BYTES_WRITTEN\` bigint(20) DEFAULT '0',
  \`COMMITTED_HEAP_BYTES\` bigint(20) DEFAULT '0',
  \`CPU_MILLISECONDS\` bigint(20) DEFAULT '0',
  \`FAILED_SHUFFLE\` bigint(20) DEFAULT '0',
  \`FILE_BYTES_READ\` bigint(20) DEFAULT '0',
  \`FILE_BYTES_WRITTEN\` bigint(20) DEFAULT '0',
  \`FILE_READ_OPS\` bigint(20) DEFAULT '0',
  \`FILE_WRITE_OPS\` bigint(20) DEFAULT '0',
  \`GC_TIME_MILLIS\` bigint(20) DEFAULT '0',
  \`MAP_INPUT_RECORDS\` bigint(20) DEFAULT '0',
  \`MAP_OUTPUT_RECORDS\` bigint(20) DEFAULT '0',
  \`MERGED_MAP_OUTPUTS\` bigint(20) DEFAULT '0',
  \`PHYSICAL_MEMORY_BYTES\` bigint(20) DEFAULT '0',
  \`SPILLED_RECORDS\` bigint(20) DEFAULT '0',
  \`SPLIT_RAW_BYTES\` bigint(20) DEFAULT '0',
  \`TASK_ERROR\` varchar(255) NOT NULL,
  \`TASK_FINISH_TIME\` bigint(20) DEFAULT '0',
  \`TASK_START_TIME\` bigint(20) DEFAULT '0',
  \`TASK_STATUS\` varchar(255) NOT NULL,
  \`TASK_TYPE\` varchar(255) NOT NULL,
  \`VIRTUAL_MEMORY_BYTES\` bigint(20) DEFAULT '0',
  \`WASB_BYTES_READ\` bigint(20) DEFAULT '0',
  \`WASB_BYTES_WRITTEN\` bigint(20) DEFAULT '0',
  \`WASB_LARGE_READ_OPS\` bigint(20) DEFAULT '0',
  \`WASB_READ_OPS\` bigint(20) DEFAULT '0',
  \`WASB_WRITE_OPS\` bigint(20) DEFAULT '0',
  \`FILE_LARGE_READ_OPS\` bigint(20) DEFAULT NULL,
  \`RECORDS_WRITTEN\` bigint(20) DEFAULT NULL,
  \`MAP_OUTPUT_BYTES\` bigint(20) DEFAULT NULL,
  \`MAP_OUTPUT_MATERIALIZED_BYTES\` bigint(20) DEFAULT NULL,
  \`COMBINE_INPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`COMBINE_OUTPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`id_exec\` int(11) DEFAULT NULL,
  \`REDUCE_INPUT_GROUPS\` bigint(20) DEFAULT NULL,
  \`REDUCE_OUTPUT_GROUPS\` bigint(20) DEFAULT NULL,
  \`REDUCE_SHUFFLE_BYTES\` bigint(20) DEFAULT NULL,
  \`REDUCE_INPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`REDUCE_OUTPUT_RECORDS\` bigint(20) DEFAULT NULL,
  \`SHUFFLED_MAPS\` bigint(20) DEFAULT NULL,
  \`BAD_ID\` bigint(20) DEFAULT NULL,
  \`IO_ERROR\` bigint(20) DEFAULT NULL,
  \`WRONG_LENGTH\` bigint(20) DEFAULT NULL,
  \`CONNECTION\` bigint(20) DEFAULT NULL,
  \`WRONG_MAP\` bigint(20) DEFAULT NULL,
  \`WRONG_REDUCE\` bigint(20) DEFAULT NULL,
  \`CHECKSUM\` varchar(255) DEFAULT NULL,
  \`NUM_FAILED_MAPS\` varchar(255) DEFAULT NULL,
  PRIMARY KEY (\`hdi_job_task_id\`),
  UNIQUE KEY \`UQ_TASKID\` (\`TASK_ID\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`JOB_dbscan\` (
  \`id\` int(11) NOT NULL AUTO_INCREMENT,
  \`bench\` varchar(255) NOT NULL,
  \`job_offset\` varchar(255) NOT NULL,
  \`metric_x\` int(11) NOT NULL,
  \`metric_y\` int(11) NOT NULL,
  \`TASK_TYPE\` varchar(127) DEFAULT NULL,
  \`id_exec\` int(11) NOT NULL,
  \`centroid_x\` decimal(20,3) NOT NULL,
  \`centroid_y\` decimal(20,3) NOT NULL,
  PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

"




####################################################
logger "INFO: Executing alter tables"

$MYSQL "alter ignore table execs
  add KEY \`idx_bench\` (\`bench\`),
  add KEY \`idx_exe_time\` (\`exe_time\`),
  add KEY \`idx_bench_type\` (\`bench_type\`);"

$MYSQL "alter ignore table execs
  DROP COLUMN \`valid\`,
  ADD  \`valid\` int DEFAULT '1',
  ADD \`filter\` int DEFAULT '0',
  ADD \`outlier\` int DEFAULT '0';"


$MYSQL "alter ignore table execs add hadoop_version varchar(127) default NULL;"

$MYSQL "alter ignore table clusters add datanodes int DEFAULT NULL;"
$MYSQL "alter ignore table clusters add provider varchar(127);"

$MYSQL "alter ignore table clusters
  add headnodes int DEFAULT NULL,
  add vm_size varchar(127) default null,
  add vm_OS varchar(127) default null,
  add vm_cores int default null,
  add vm_RAM decimal(10,3) default null,
  add description varchar(256) default null;"

$MYSQL "alter ignore table HDI_JOB_details ADD COLUMN NUM_FAILED_MAPS varchar(255) DEFAULT NULL;"
$MYSQL "alter ignore table clusters add column cost_remote int DEFAULT 0"
$MYSQL "alter ignore table clusters add column cost_SSD int DEFAULT 0"
$MYSQL "alter ignore table clusters add column cost_IB int DEFAULT 0"


############################################33
logger "INFO: Updating records"

$MYSQL "
update ignore execs SET disk='RR1' where disk='R1';
update ignore execs SET disk='RR2' where disk='R2';
update ignore execs SET disk='RR3' where disk='R3';
update ignore execs SET bench_type='HiBench' where bench_type='b';
update ignore execs SET bench_type='HiBench' where bench_type='';
update ignore execs SET bench_type='HiBench-min' where bench_type='-min';
update ignore execs SET bench_type='HiBench-min' where exec like '%_b_min_%';

update ignore execs SET bench_type='HiBench-10' where bench_type='-10';
update ignore execs SET bench_type='HiBench-1TB' where bench IN ('prep_terasort', 'terasort') and start_time between '2014-12-02' AND '2014-12-17 12:00';
update ignore execs SET hadoop_version='1.03' where hadoop_version='';
update ignore clusters SET headnodes='1' where headnodes='' and provider != 'hdinsight';

update ignore clusters SET headnodes='2' where headnodes='1' and provider = 'hdinsight';
update ignore clusters SET vm_OS='windows' where vm_OS = 'linux' and provider = 'hdinsight';

#temporary
update execs set id_cluster = 05 where substring(exec, (locate('/', exec) -3), 3 ) = '-05' and id_cluster =1;
update execs set id_cluster = 19 where substring(exec, (locate('/', exec) -3), 3 ) = '-19' and id_cluster =1;
update execs set id_cluster = 03 where substring(exec, (locate('/', exec) -3), 3 ) = '-03' and id_cluster =1;
update execs set id_cluster = 15 where substring(exec, (locate('/', exec) -3), 3 ) = '-15' and id_cluster =1;
update execs set id_cluster = 14 where substring(exec, (locate('/', exec) -3), 3 ) = '-14' and id_cluster =1;
update execs set id_cluster = 22 where substring(exec, (locate('/', exec) -3), 3 ) = '-22' and id_cluster =1;
update execs set id_cluster = 06 where substring(exec, (locate('/', exec) -3), 3 ) = '-06' and id_cluster =1;
update execs set id_cluster = 04 where substring(exec, (locate('/', exec) -3), 3 ) = '-04' and id_cluster =1;
update execs set id_cluster = 08 where substring(exec, (locate('/', exec) -3), 3 ) = '-08' and id_cluster =1;
update execs set id_cluster = 16 where substring(exec, (locate('/', exec) -3), 3 ) = '-16' and id_cluster =1;
update execs set id_cluster = 10 where substring(exec, (locate('/', exec) -3), 3 ) = '-10' and id_cluster =1;
update execs set id_cluster = 12 where substring(exec, (locate('/', exec) -3), 3 ) = '_12' and id_cluster =1;

"

echo "
update ignore execs SET valid = 0;
update ignore execs SET filter = 0;
update ignore execs SET filter = 1 where id_exec NOT IN(select distinct (id_exec) from JOB_status where id_exec is not null);

update ignore execs SET valid = 1 where bench_type = 'HiBench' and bench = 'terasort' and id_exec IN (
  select distinct(id_exec) from
    (select b.id_exec from execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'terasort' and HDFS_BYTES_WRITTEN = '100000000000')
    tmp_table
);

update ignore execs SET valid = 1 where bench_type = 'HiBench' and bench = 'sort' and id_exec IN (
  select distinct(id_exec) from
    (select b.id_exec from execs b join JOB_details using (id_exec) where bench_type = 'HiBench' and bench = 'sort' and HDFS_BYTES_WRITTEN between '73910080224' and '73910985034')
    tmp_table
);


"

#$MYSQL "
#
##insert ignore into clusters set name='m1000-01',     id_cluster=1, cost_hour=12, type='on-premise', link='http://hadoop.bsc.es/?page_id=51';
##insert ignore into clusters set name='al-02', id_cluster=2, cost_hour=7, type='IaaS', link='http://www.windowsazure.com/en-us/pricing/calculator/';
##INSERT ignore INTO clusters(id_cluster,name,cost_hour,type,link,datanodes) values(20,'HDInsight','0.32','PaaS','http://azure.microsoft.com/en-gb/pricing/details/hdinsight/',4);
#
##insert ignore into hosts set id_host=1, id_cluster=1, host_name='minerva-1001', role='master';
##insert ignore into hosts set id_host=2, id_cluster=1, host_name='minerva-1002', role='slave';
##insert ignore into hosts set id_host=3, id_cluster=1, host_name='minerva-1003', role='slave';
##insert ignore into hosts set id_host=4, id_cluster=1, host_name='minerva-1004', role='slave';
##insert ignore into hosts set id_host=5, id_cluster=2, host_name='al-1001', role='master';
##insert ignore into hosts set id_host=6, id_cluster=2, host_name='al-1002', role='slave';
##insert ignore into hosts set id_host=7, id_cluster=2, host_name='al-1003', role='slave';
##insert ignore into hosts set id_host=8, id_cluster=2, host_name='al-1004', role='slave';
#"



#CREATE TABLE IF NOT EXISTS \`JOB_job_history\` (
#  \`id_JOB_job_history\` int(11) NOT NULL AUTO_INCREMENT,
#  \`id_exec\` int(11) NOT NULL,
#  \`job_name\` varchar(255) DEFAULT NULL,
#  \`time\` int(11) DEFAULT NULL,
#  \`maps\` decimal(20,3) DEFAULT NULL,
#  \`shuffle\` decimal(20,3) DEFAULT NULL,
#  \`merge\` decimal(20,3) DEFAULT NULL,
#  \`reduce\` decimal(20,3) DEFAULT NULL,
#  \`waste\` decimal(20,3) DEFAULT NULL,
#  PRIMARY KEY (\`id_JOB_job_history\`),
#  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`,\`time\`),
#  KEY \`index2\` (\`id_exec\`),
#  KEY \`index_job_name\` (\`job_name\`)
#) ENGINE=InnoDB;

#CREATE TABLE IF NOT EXISTS \`JOB_MAP_COUNTERS\` (
#  \`id_JOB_MAP_COUNTERS\` int(11) NOT NULL AUTO_INCREMENT,
#  \`id_exec\` int(11) NOT NULL,
#  \`job_name\` varchar(255) DEFAULT NULL,
#  \`BYTES_READ\` bigint DEFAULT NULL,
#  \`BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`HDFS_BYTES_READ\` bigint DEFAULT NULL,
#  \`FILE_BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`HDFS_BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`MAP_INPUT_RECORDS\` bigint DEFAULT NULL,
#  \`PHYSICAL_MEMORY_BYTES\` bigint DEFAULT NULL,
#  \`SPILLED_RECORDS\` bigint DEFAULT NULL,
#  \`COMMITTED_HEAP_BYTES\` bigint DEFAULT NULL,
#  \`CPU_MILLISECONDS\` bigint DEFAULT NULL,
#  \`MAP_INPUT_BYTES\` bigint DEFAULT NULL,
#  \`VIRTUAL_MEMORY_BYTES\` bigint DEFAULT NULL,
#  \`SPLIT_RAW_BYTES\` bigint DEFAULT NULL,
#  \`MAP_OUTPUT_RECORDS\` bigint DEFAULT NULL,
#  PRIMARY KEY (\`id_JOB_MAP_COUNTERS\`),
#  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`),
#  KEY \`index1\` (\`job_name\`),
#  KEY \`index2\` (\`id_exec\`)
#) ENGINE=InnoDB ;

#CREATE TABLE IF NOT EXISTS \`JOB_REDUCE_COUNTERS\` (
#  \`id_JOB_REDUCE_COUNTERS\` int(11) NOT NULL AUTO_INCREMENT,
#  \`id_exec\` int(11) NOT NULL,
#  \`job_name\` varchar(255) DEFAULT NULL,
#  \`BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`FILE_BYTES_READ\` bigint DEFAULT NULL,
#  \`FILE_BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`HDFS_BYTES_WRITTEN\` bigint DEFAULT NULL,
#  \`REDUCE_INPUT_GROUPS\` bigint DEFAULT NULL,
#  \`COMBINE_OUTPUT_RECORDS\` bigint DEFAULT NULL,
#  \`REDUCE_SHUFFLE_BYTES\` bigint DEFAULT NULL,
#  \`PHYSICAL_MEMORY_BYTES\` bigint DEFAULT NULL,
#  \`REDUCE_OUTPUT_RECORDS\` bigint DEFAULT NULL,
#  \`SPILLED_RECORDS\` bigint DEFAULT NULL,
#  \`COMMITTED_HEAP_BYTES\` bigint DEFAULT NULL,
#  \`CPU_MILLISECONDS\` bigint DEFAULT NULL,
#  \`VIRTUAL_MEMORY_BYTES\` bigint DEFAULT NULL,
#  \`COMBINE_INPUT_RECORDS\` bigint DEFAULT NULL,
#  \`REDUCE_INPUT_RECORDS\` bigint DEFAULT NULL,
#  PRIMARY KEY (\`id_JOB_REDUCE_COUNTERS\`),
#  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`),
#  KEY \`index2\` (\`id_exec\`)
#) ENGINE=InnoDB;
#
#CREATE TABLE IF NOT EXISTS \`JOB_SUMMARY\` (
#  \`id_JOB_SUMMARY\` int(11) NOT NULL AUTO_INCREMENT,
#  \`id_exec\` int(11) NOT NULL,
#  \`job_name\` varchar(255) DEFAULT NULL,
#  \`Job JOBID\` varchar(255) DEFAULT NULL,
#  \`FINISH_TIME\` varchar(255) DEFAULT NULL,
#  \`JOB_STATUS\` varchar(255) DEFAULT NULL,
#  \`FINISHED_MAPS\` int DEFAULT NULL,
#  \`FINISHED_REDUCES\` int DEFAULT NULL,
#  \`FAILED_MAPS\` int DEFAULT NULL,
#  \`FAILED_REDUCES\` int DEFAULT NULL,
#  PRIMARY KEY (\`id_JOB_SUMMARY\`),
#  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`,\`job_name\`, \`Job JOBID\`),
#  KEY \`index2\` (\`id_exec\`)
#) ENGINE=InnoDB;

#CREATE TABLE IF NOT EXISTS \`JOB_task_history\` (
#  \`id_JOB_task_history\` int(11) NOT NULL AUTO_INCREMENT,
#  \`id_exec\` int(11) DEFAULT NULL,
#  \`job_name\` varchar(255) DEFAULT NULL,
#  \`task_name\` varchar(255) DEFAULT NULL,
#  \`reduce_output_bytes\` decimal(20,3) DEFAULT NULL,
#  \`shuffle_finish\` decimal(20,3) DEFAULT NULL,
#  \`reduce_finish\` decimal(20,3) DEFAULT NULL,
#  PRIMARY KEY (\`id_JOB_task_history\`),
#  UNIQUE KEY \`avoid_duplicates_UNIQUE\` (\`id_exec\`, \`job_name\`,\`task_name\`)
#) ENGINE=InnoDB;
