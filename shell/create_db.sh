echo "Checking if to create tables"

$MYSQL "
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
  \`zabbix_link\` varchar(255) DEFAULT NULL,
  \`valid\` BOOLEAN DEFAULT TRUE,
  PRIMARY KEY (\`id_exec\`),
  UNIQUE KEY \`exec_UNIQUE\` (\`exec\`)
) ENGINE=InnoDB;

create table if not exists hosts (
  id_host int(11) NOT NULL AUTO_INCREMENT,
  host_name varchar(128) NOT NULL,
  id_cluster int(11) NOT NULL,
  role varchar(45) DEFAULT NULL,
  PRIMARY KEY (id_host)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
insert ignore into hosts set id_host=1, id_cluster=1, host_name='minerva-1001', role='master';
insert ignore into hosts set id_host=2, id_cluster=1, host_name='minerva-1002', role='slave';
insert ignore into hosts set id_host=3, id_cluster=1, host_name='minerva-1003', role='slave';
insert ignore into hosts set id_host=4, id_cluster=1, host_name='minerva-1004', role='slave';
insert ignore into hosts set id_host=5, id_cluster=2, host_name='al-1001', role='master';
insert ignore into hosts set id_host=6, id_cluster=2, host_name='al-1002', role='slave';
insert ignore into hosts set id_host=7, id_cluster=2, host_name='al-1003', role='slave';
insert ignore into hosts set id_host=8, id_cluster=2, host_name='al-1004', role='slave';

insert ignore into hosts set id_host=1006, id_cluster=10, host_name='minerva-6', role='master';
insert ignore into hosts set id_host=1007, id_cluster=10, host_name='minerva-7', role='slave';
insert ignore into hosts set id_host=1008, id_cluster=10, host_name='minerva-8', role='slave';
insert ignore into hosts set id_host=1009, id_cluster=10, host_name='minerva-9', role='slave';
insert ignore into hosts set id_host=1010, id_cluster=10, host_name='minerva-10', role='slave';
insert ignore into hosts set id_host=1011, id_cluster=10, host_name='minerva-11', role='slave';
insert ignore into hosts set id_host=1012, id_cluster=10, host_name='minerva-12', role='slave';
insert ignore into hosts set id_host=1013, id_cluster=10, host_name='minerva-13', role='slave';
insert ignore into hosts set id_host=1014, id_cluster=10, host_name='minerva-14', role='slave';
insert ignore into hosts set id_host=1015, id_cluster=10, host_name='minerva-15', role='slave';
insert ignore into hosts set id_host=1016, id_cluster=10, host_name='minerva-16', role='slave';
insert ignore into hosts set id_host=1017, id_cluster=10, host_name='minerva-17', role='slave';
insert ignore into hosts set id_host=1018, id_cluster=10, host_name='minerva-18', role='slave';
insert ignore into hosts set id_host=1019, id_cluster=10, host_name='minerva-19', role='slave';
insert ignore into hosts set id_host=1020, id_cluster=10, host_name='minerva-20', role='slave';

insert ignore into hosts set id_host=1001, id_cluster=12, host_name='minerva-1', role='master';
insert ignore into hosts set id_host=1002, id_cluster=12, host_name='minerva-2', role='slave';
insert ignore into hosts set id_host=1003, id_cluster=12, host_name='minerva-3', role='slave';
insert ignore into hosts set id_host=1004, id_cluster=12, host_name='minerva-4', role='slave';

insert ignore into hosts set id_host=1005, id_cluster=13, host_name='minerva-5', role='master';
insert ignore into hosts set id_host=1006, id_cluster=13, host_name='minerva-6', role='slave';
insert ignore into hosts set id_host=1007, id_cluster=13, host_name='minerva-7', role='slave';
insert ignore into hosts set id_host=1008, id_cluster=13, host_name='minerva-8', role='slave';

create table if not exists clusters (id_cluster int, name varchar(127), cost_hour decimal(10,3), \`type\` varchar(127), link varchar(255), primary key (id_cluster)) engine InnoDB;
insert ignore into clusters set name='Local 1',     id_cluster=1, cost_hour=12, type='Colocated', link='http://hadoop.bsc.es/?page_id=51';
insert ignore into clusters set name='Azure Linux', id_cluster=2, cost_hour=7, type='IaaS Cloud', link='http://www.windowsazure.com/en-us/pricing/calculator/';
insert ignore into clusters set name='minerva',     id_cluster=10, cost_hour=12, type='Colocated', link='http://hadoop.bsc.es/?page_id=51';
insert ignore into clusters set name='minerva1_4',  id_cluster=12, cost_hour=12, type='Colocated', link='http://hadoop.bsc.es/?page_id=51';
insert ignore into clusters set name='minerva5_8',  id_cluster=13, cost_hour=12, type='Colocated', link='http://hadoop.bsc.es/?page_id=51';

#TODO move this to end of execution
update execs SET disk='RR1' where disk='R1';
update execs SET disk='RR2' where disk='R2';
update execs SET disk='RR3' where disk='R3';
"

$MYSQL "
CREATE TABLE IF NOT EXISTS \`SAR_cpu\` (
  \`id_SAR_cpu\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) DEFAULT NULL,
  \`host\` varchar(128) DEFAULT NULL,
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
  \`host\` varchar(128) DEFAULT NULL,
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
  \`host\` varchar(128) DEFAULT NULL,
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
  \`host\` varchar(128) DEFAULT NULL,
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
  \`JOBNAME\` varchar(128) DEFAULT NULL,
  \`SUBMIT_TIME\` datetime DEFAULT NULL,
  \`LAUNCH_TIME\` datetime DEFAULT NULL,
  \`FINISH_TIME\` datetime DEFAULT NULL,
  \`JOB_PRIORITY\` varchar(255) DEFAULT NULL,
  \`USER\` varchar(128) DEFAULT NULL,
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
  \`TASKID\` varchar(128) DEFAULT NULL,
  \`TASK_TYPE\` varchar(128) DEFAULT NULL,
  \`TASK_STATUS\` varchar(128) DEFAULT NULL,
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

"
