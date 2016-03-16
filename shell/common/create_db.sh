#file must be sourced

logger "INFO: Creating DB and tables for $DB (if necessary)"

$MYSQL_CREATE "

CREATE DATABASE IF NOT EXISTS \`$DB\`;

USE \`$DB\`;

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
  \`hadoop_version\` varchar(127) default NULL,
  \`zabbix_link\` varchar(255) DEFAULT NULL,
  \`valid\` int DEFAULT 0,
  \`filter\` int DEFAULT 0,
  \`outlier\` int DEFAULT 0,
  \`perf_details\` int DEFAULT 0,
  \`exec_type\` varchar(255) DEFAULT 'default',
  \`datasize\` int(11) DEFAULT NULL,
  \`scale_factor\` varchar(255) DEFAULT 'N/A',
  PRIMARY KEY (\`id_exec\`),
  UNIQUE KEY \`exec_UNIQUE\` (\`exec\`),
  KEY \`idx_bench\` (\`bench\`),
  KEY \`idx_exe_time\` (\`exe_time\`),
  KEY \`idx_bench_type\` (\`bench_type\`),
  KEY \`idx_id_cluster\` (\`id_cluster\`),
  KEY \`idx_valid\` (\`valid\`),
  KEY \`idx_filter\` (\`filter\`),
  KEY \`idx_perf_details\` (\`perf_details\`)
) ENGINE=InnoDB;

create table if not exists hosts (
  id_host int(11) NOT NULL AUTO_INCREMENT,
  host_name varchar(127) NOT NULL,
  id_cluster int(11) NOT NULL,
  role varchar(45) DEFAULT NULL,
 cost_remote decimal(10,3) default 0,
 cost_SSD decimal(10,3) default 0,
 cost_IB decimal(10,3) default 0,
  PRIMARY KEY (id_host)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;

create table if not exists clusters (
id_cluster int,
name varchar(127),
cost_hour decimal(10,5),
\`type\` varchar(127),
provider varchar(127),
datanodes int DEFAULT NULL,
headnodes int DEFAULT NULL,
vm_size varchar(127) default null,
vm_OS varchar(127) default null,
vm_cores int default null,
vm_RAM decimal(10,3) default null,
cost_remote decimal(10,3) default 0,
cost_SSD decimal(10,3) default 0,
cost_IB decimal(10,3) default 0,
description varchar(256) default null,
link varchar(255),
primary key (id_cluster)) engine InnoDB;
"

$MYSQL "

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
  \`DATA_LOCAL_MAPS\` bigint(20) DEFAULT NULL,
  \`TOTAL_LAUNCHED_MAPS\` bigint(20) NOT NULL,
  \`TOTAL_MAPS\` bigint(20) NOT NULL,
  \`TOTAL_REDUCES\` bigint(20) NOT NULL,
  \`USER\` varchar(255) NOT NULL,
  \`VCORES_MILLIS_MAPS\` bigint(20) NOT NULL,
  \`VIRTUAL_MEMORY_BYTES\` bigint(20) NOT NULL,
  \`HDFS_BYTES_WRITTEN\` bigint DEFAULT NULL,
  \`HDFS_BYTES_READ\` bigint DEFAULT NULL,
  \`HDFS_READ_OPS\` bigint DEFAULT NULL,
  \`HDFS_WRITE_OPS\` bigint DEFAULT NULL,
  \`HDFS_LARGE_READ_OPS\` bigint DEFAULT NULL,
  \`HDFS_LARGE_WRITE_OPS\` bigint DEFAULT NULL,
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


CREATE TABLE IF NOT EXISTS \`precal_cpu_metrics\` (
  \`id_exec\` int(11) NOT NULL,
  \`avg%user\` decimal(20,3) DEFAULT NULL,
  \`max%user\` decimal(20,3) DEFAULT NULL,
  \`min%user\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%user\` decimal(20,3) DEFAULT NULL,
  \`var_pop%user\` decimal(20,3) DEFAULT NULL,
  \`avg%nice\` decimal(20,3) DEFAULT NULL,
  \`max%nice\` decimal(20,3) DEFAULT NULL,
  \`min%nice\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%nice\` decimal(20,3) DEFAULT NULL,
  \`var_pop%nice\` decimal(20,3) DEFAULT NULL,

  \`avg%system\` decimal(20,3) DEFAULT NULL,
  \`max%system\` decimal(20,3) DEFAULT NULL,
  \`min%system\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%system\` decimal(20,3) DEFAULT NULL,
  \`var_pop%system\` decimal(20,3) DEFAULT NULL,

  \`avg%iowait\` decimal(20,3) DEFAULT NULL,
  \`max%iowait\` decimal(20,3) DEFAULT NULL,
  \`min%iowait\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%iowait\` decimal(20,3) DEFAULT NULL,
  \`var_pop%iowait\` decimal(20,3) DEFAULT NULL,

  \`avg%steal\` decimal(20,3) DEFAULT NULL,
  \`max%steal\` decimal(20,3) DEFAULT NULL,
  \`min%steal\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%steal\` decimal(20,3) DEFAULT NULL,
  \`var_pop%steal\` decimal(20,3) DEFAULT NULL,

  \`avg%idle\` decimal(20,3) DEFAULT NULL,
  \`max%idle\` decimal(20,3) DEFAULT NULL,
  \`min%idle\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%idle\` decimal(20,3) DEFAULT NULL,
  \`var_pop%idle\` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (\`id_exec\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`precal_disk_metrics\` (
  \`id_exec\` int(11) NOT NULL,
  \`DEV\` varchar(255) DEFAULT NULL,
  \`avgtps\` decimal(20,3) DEFAULT NULL,
  \`maxtps\` decimal(20,3) DEFAULT NULL,
  \`mintps\` decimal(20,3) DEFAULT NULL,
  \`avgrd_sec/s\` decimal(20,3) DEFAULT NULL,
  \`maxrd_sec/s\` decimal(20,3) DEFAULT NULL,
  \`minrd_sec/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poprd_sec/s\` decimal(20,3) DEFAULT NULL,
  \`var_poprd_sec/s\` decimal(20,3) DEFAULT NULL,
  \`sumrd_sec/s\` decimal(20,3) DEFAULT NULL,
  
  
  \`avgwr_sec/s\` decimal(20,3) DEFAULT NULL,
  \`maxwr_sec/s\` decimal(20,3) DEFAULT NULL,
  \`minwr_sec/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_popwr_sec/s\` decimal(20,3) DEFAULT NULL,
  \`var_popwr_sec/s\` decimal(20,3) DEFAULT NULL,
  \`sumwr_sec/s\` decimal(20,3) DEFAULT NULL,
  
  \`avgrq_sz\` decimal(20,3) DEFAULT NULL,
  \`maxrq_sz\` decimal(20,3) DEFAULT NULL,
  \`minrq_sz\` decimal(20,3) DEFAULT NULL,
  \`stddev_poprq_sz\` decimal(20,3) DEFAULT NULL,
  \`var_poprq_sz\` decimal(20,3) DEFAULT NULL,
  
  \`avgqu_sz\` decimal(20,3) DEFAULT NULL,
  \`maxqu_sz\` decimal(20,3) DEFAULT NULL,
  \`minqu_sz\` decimal(20,3) DEFAULT NULL,
  \`stddev_popqu_sz\` decimal(20,3) DEFAULT NULL,
  \`var_popqu_sz\` decimal(20,3) DEFAULT NULL,
  
  \`avgawait\` decimal(20,3) DEFAULT NULL,
  \`maxawait\` decimal(20,3) DEFAULT NULL,
  \`minawait\` decimal(20,3) DEFAULT NULL,
  \`stddev_popawait\` decimal(20,3) DEFAULT NULL,
  \`var_popawait\` decimal(20,3) DEFAULT NULL,
  
  \`avg%util\` decimal(20,3) DEFAULT NULL,
  \`max%util\` decimal(20,3) DEFAULT NULL,
  \`min%util\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%util\` decimal(20,3) DEFAULT NULL,
  \`var_pop%util\` decimal(20,3) DEFAULT NULL,
  
  \`avgsvctm\` decimal(20,3) DEFAULT NULL,
  \`maxsvctm\` decimal(20,3) DEFAULT NULL,
  \`minsvctm\` decimal(20,3) DEFAULT NULL,
  \`stddev_popsvctm\` decimal(20,3) DEFAULT NULL,
  \`var_popsvctm\` decimal(20,3) DEFAULT NULL,

  PRIMARY KEY (\`id_exec\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`precal_memory_metrics\` (
  \`id_exec\` int(11) NOT NULL,
  \`DEV\` varchar(255) DEFAULT NULL,
  \`avgkbmemfree\` decimal(20,3) DEFAULT NULL,
  \`maxkbmemfree\` decimal(20,3) DEFAULT NULL,
  \`minkbmemfree\` decimal(20,3) DEFAULT NULL,
  \`stddev_popkbmemfree\` decimal(20,3) DEFAULT NULL,
  \`var_popkbmemfree\` decimal(20,3) DEFAULT NULL,
  
  \`avgkbmemused\` decimal(20,3) DEFAULT NULL,
  \`maxkbmemused\` decimal(20,3) DEFAULT NULL,
  \`minkbmemused\` decimal(20,3) DEFAULT NULL,
  \`stddev_popkbmemused\` decimal(20,3) DEFAULT NULL,
  \`var_popkbmemused\` decimal(20,3) DEFAULT NULL,
  
  \`avg%memused\` decimal(20,3) DEFAULT NULL,
  \`max%memused\` decimal(20,3) DEFAULT NULL,
  \`min%memused\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%memused\` decimal(20,3) DEFAULT NULL,
  \`var_pop%memused\` decimal(20,3) DEFAULT NULL,
  
  \`avgkbbuffers\` decimal(20,3) DEFAULT NULL,
  \`maxkbbuffers\` decimal(20,3) DEFAULT NULL,
  \`minkbbuffers\` decimal(20,3) DEFAULT NULL,
  \`stddev_popkbbuffers\` decimal(20,3) DEFAULT NULL,
  \`var_popkbbuffers\` decimal(20,3) DEFAULT NULL,
  
  \`avgkbcached\` decimal(20,3) DEFAULT NULL,
  \`maxkbcached\` decimal(20,3) DEFAULT NULL,
  \`minkbcached\` decimal(20,3) DEFAULT NULL,
  \`stddev_popkbcached\` decimal(20,3) DEFAULT NULL,
  \`var_popkbcached\` decimal(20,3) DEFAULT NULL,
  
  \`avgkbcommit\` decimal(20,3) DEFAULT NULL,
  \`maxkbcommit\` decimal(20,3) DEFAULT NULL,
  \`minkbcommit\` decimal(20,3) DEFAULT NULL,
  \`stddev_popkbcommit\` decimal(20,3) DEFAULT NULL,
  \`var_popkbcommit\` decimal(20,3) DEFAULT NULL,
  
  \`avg%commit\` decimal(20,3) DEFAULT NULL,
  \`max%commit\` decimal(20,3) DEFAULT NULL,
  \`min%commit\` decimal(20,3) DEFAULT NULL,
  \`stddev_pop%commit\` decimal(20,3) DEFAULT NULL,
  \`var_pop%commit\` decimal(20,3) DEFAULT NULL,
  
  \`avgkbactive\` decimal(20,3) DEFAULT NULL,
  \`maxkbactive\` decimal(20,3) DEFAULT NULL,
  \`minkbactive\` decimal(20,3) DEFAULT NULL,
  \`stddev_popkbactive\` decimal(20,3) DEFAULT NULL,
  \`var_popkbactive\` decimal(20,3) DEFAULT NULL,
  
  \`avgkbinact\` decimal(20,3) DEFAULT NULL,
  \`maxkbinact\` decimal(20,3) DEFAULT NULL,
  \`minkbinact\` decimal(20,3) DEFAULT NULL,
  \`stddev_popkbinact\` decimal(20,3) DEFAULT NULL,
  \`var_popkbinact\` decimal(20,3) DEFAULT NULL,

  PRIMARY KEY (\`id_exec\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`precal_network_metrics\` (
  \`id_exec\` int(11) NOT NULL,
  \`IFACE\` varchar(255) DEFAULT NULL,
  \`avgrxpck/s\` decimal(20,3) DEFAULT NULL,
  \`maxrxpck/s\` decimal(20,3) DEFAULT NULL,
  \`minrxpck/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poprxpck/s\` decimal(20,3) DEFAULT NULL,
  \`var_poprxpck/s\` decimal(20,3) DEFAULT NULL,
  \`sumrxpck/s\` decimal(20,3) DEFAULT NULL,
  
  \`avgtxpck/s\` decimal(20,3) DEFAULT NULL,
  \`maxtxpck/s\` decimal(20,3) DEFAULT NULL,
  \`mintxpck/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poptxpck/s\` decimal(20,3) DEFAULT NULL,
  \`var_poptxpck/s\` decimal(20,3) DEFAULT NULL,
  \`sumtxpck/s\` decimal(20,3) DEFAULT NULL,

  \`avgrxkB/s\` decimal(20,3) DEFAULT NULL,
  \`maxrxkB/s\` decimal(20,3) DEFAULT NULL,
  \`minrxkB/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poprxkB/s\` decimal(20,3) DEFAULT NULL,
  \`var_poprxkB/s\` decimal(20,3) DEFAULT NULL,
  \`sumrxkB/s\` decimal(20,3) DEFAULT NULL,

  \`avgtxkB/s\` decimal(20,3) DEFAULT NULL,
  \`maxtxkB/s\` decimal(20,3) DEFAULT NULL,
  \`mintxkB/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poptxkB/s\` decimal(20,3) DEFAULT NULL,
  \`var_poptxkB/s\` decimal(20,3) DEFAULT NULL,
  \`sumtxkB/s\` decimal(20,3) DEFAULT NULL,

  \`avgrxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`maxrxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`minrxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poprxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`var_poprxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`sumrxcmp/s\` decimal(20,3) DEFAULT NULL,

  \`avgtxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`maxtxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`mintxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poptxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`var_poptxcmp/s\` decimal(20,3) DEFAULT NULL,
  \`sumtxcmp/s\` decimal(20,3) DEFAULT NULL,

  \`avgrxmcst/s\` decimal(20,3) DEFAULT NULL,
  \`maxrxmcst/s\` decimal(20,3) DEFAULT NULL,
  \`minrxmcst/s\` decimal(20,3) DEFAULT NULL,
  \`stddev_poprxmcst/s\` decimal(20,3) DEFAULT NULL,
  \`var_poprxmcst/s\` decimal(20,3) DEFAULT NULL,
  \`sumrxmcst/s\` decimal(20,3) DEFAULT NULL,

  PRIMARY KEY (\`id_exec\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
"

####################################################
logger "INFO: Creating DB aloja_logs and tables (if needed)"

$MYSQL_CREATE "CREATE DATABASE IF NOT EXISTS \`aloja_logs\`;"

logger "INFO: Moving logs tables from aloja2 to aloja_logs (if needed)"

#move from aloja2 to aloja_logs
$MYSQL "alter table aloja2.SAR_cpu rename aloja_logs.SAR_cpu";
$MYSQL "alter table aloja2.SAR_block_devices rename aloja_logs.SAR_block_devices";
$MYSQL "alter table aloja2.SAR_interrupts rename aloja_logs.SAR_interrupts";
$MYSQL "alter table aloja2.SAR_io_paging rename aloja_logs.SAR_io_paging";
$MYSQL "alter table aloja2.SAR_io_rate rename aloja_logs.SAR_io_rate";
$MYSQL "alter table aloja2.SAR_load rename aloja_logs.SAR_load";
$MYSQL "alter table aloja2.SAR_memory rename aloja_logs.SAR_memory";
$MYSQL "alter table aloja2.SAR_memory_util rename aloja_logs.SAR_memory_util";
$MYSQL "alter table aloja2.SAR_net_devices rename aloja_logs.SAR_net_devices";
$MYSQL "alter table aloja2.SAR_net_errors rename aloja_logs.SAR_net_errors";
$MYSQL "alter table aloja2.SAR_net_sockets rename aloja_logs.SAR_net_sockets";
$MYSQL "alter table aloja2.SAR_swap rename aloja_logs.SAR_swap";
$MYSQL "alter table aloja2.SAR_swap_util rename aloja_logs.SAR_swap_util";
$MYSQL "alter table aloja2.SAR_switches rename aloja_logs.SAR_switches";
$MYSQL "alter table aloja2.BWM rename aloja_logs.BWM";
$MYSQL "alter table aloja2.BWM2 rename aloja_logs.BWM2";
$MYSQL "alter table aloja2.VMSTATS rename aloja_logs.VMSTATS";
$MYSQL "alter table aloja2.JOB_status rename aloja_logs.JOB_status";
$MYSQL "alter table aloja2.JOB_tasks rename aloja_logs.JOB_tasks";
$MYSQL "alter table aloja2.HDI_JOB_tasks rename aloja_logs.HDI_JOB_tasks";

$MYSQL_CREATE "

USE \`aloja_logs\`;

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
  \`kbdirty\` decimal(20,3) DEFAULT NULL,
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
  \`%ifutil\` decimal(20,3) DEFAULT NULL,
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

CREATE TABLE IF NOT EXISTS VMSTATS (
  id_VMSTATS int(11) NOT NULL AUTO_INCREMENT,
  id_exec int(11) NOT NULL,
  host varchar(255) DEFAULT NULL,
  time int(11) DEFAULT NULL,
  r decimal(20,3) DEFAULT NULL,
  b decimal(20,3) DEFAULT NULL,
  swpd decimal(20,3) DEFAULT NULL,
  free decimal(20,3) DEFAULT NULL,
  buff decimal(20,3) DEFAULT NULL,
  cache decimal(20,3) DEFAULT NULL,
  si decimal(20,3) DEFAULT NULL,
  so decimal(20,3) DEFAULT NULL,
  bi decimal(20,3) DEFAULT NULL,
  bo decimal(20,3) DEFAULT NULL,
  \`in\` decimal(20,3) DEFAULT NULL,
  cs decimal(20,3) DEFAULT NULL,
  us decimal(20,3) DEFAULT NULL,
  sy decimal(20,3) DEFAULT NULL,
  id decimal(20,3) DEFAULT NULL,
  wa decimal(20,3) DEFAULT NULL,
  st decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (id_VMSTATS),
  UNIQUE KEY avoid_duplicates_UNIQUE (id_exec,host,time)
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
  KEY \`index_job_name\` (\`job_name\`),
  KEY \`index_JOBID\` (\`JOBID\`),
  KEY \`index_TASK_TYPE\` (\`TASK_TYPE\`)
) ENGINE=InnoDB;

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
  \`HDFS_BYTES_WRITTEN\` bigint DEFAULT NULL,
  \`HDFS_BYTES_READ\` bigint DEFAULT NULL,
  \`HDFS_LARGE_READ_OPS\` bigint DEFAULT NULL,
  \`HDFS_LARGE_WRITE_OPS\` bigint DEFAULT NULL,
  \`HDFS_READ_OPS\` bigint DEFAULT NULL,
  \`HDFS_WRITE_OPS\` bigint DEFAULT NULL,
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

\`job_name\` varchar(255) DEFAULT NULL,
\`CREATED_FILES\` bigint(20) DEFAULT NULL,
\`DESERIALIZE_ERRORS\` varchar(255) DEFAULT NULL,
\`FAILED_REDUCES\` bigint(20) DEFAULT NULL,
\`FINISHED_MAPS\` bigint(20) DEFAULT NULL,
\`JOB_PRIORITY\` bigint(20) DEFAULT NULL,
\`LAUNCH_TIME\` varchar(255) DEFAULT NULL,
\`MB_MILLIS_MAPS\` bigint(20) DEFAULT NULL,
\`MB_MILLIS_REDUCES\` bigint(20) DEFAULT NULL,
\`MILLIS_MAPS\` bigint(20) DEFAULT NULL,
\`MILLIS_REDUCES\` bigint(20) DEFAULT NULL,
\`NUM_KILLED_MAPS\` bigint(20) DEFAULT NULL,
\`NUM_KILLED_REDUCES\` bigint(20) DEFAULT NULL,
\`OTHER_LOCAL_MAPS\` bigint(20) DEFAULT NULL,
\`RACK_LOCAL_MAPS\` bigint(20) DEFAULT NULL,
\`RECORDS_IN\` bigint(20) DEFAULT NULL,
\`RECORDS_OUT_INTERMEDIATE\` bigint(20) DEFAULT NULL,
\`SKEWJOINFOLLOWUPJOBS\` varchar(255) DEFAULT NULL,
\`SLOTS_MILLIS_MAPS\` bigint(20) DEFAULT NULL,
\`SLOTS_MILLIS_REDUCES\` bigint(20) DEFAULT NULL,
\`SUBMIT_TIME\` varchar(255) DEFAULT NULL,
\`TOTAL_LAUNCHED_MAPS\` bigint(20) DEFAULT NULL,
\`TOTAL_LAUNCHED_REDUCES\` bigint(20) DEFAULT NULL,
\`TOTAL_MAPS\` bigint(20) DEFAULT NULL,
\`TOTAL_REDUCES\` bigint(20) DEFAULT NULL,
\`USER\` varchar(255) DEFAULT NULL,
\`VCORES_MILLIS_MAPS\` bigint(20) DEFAULT NULL,
\`VCORES_MILLIS_REDUCES\` bigint(20) DEFAULT NULL,



  PRIMARY KEY (\`hdi_job_task_id\`),
  UNIQUE KEY \`UQ_TASKID\` (\`TASK_ID\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS AOP4Hadoop (
  id_AOP4Hadoop int(11) NOT NULL AUTO_INCREMENT,
  id_exec int(11) NOT NULL,
  date datetime DEFAULT NULL,
  mili_secs int(11) DEFAULT NULL,
  host_name varchar(127) DEFAULT NULL,
  PID int(11) DEFAULT NULL,
  moment varchar(127) DEFAULT NULL,
  event varchar(127) DEFAULT NULL,
  extra1 varchar(255) DEFAULT NULL,
  PRIMARY KEY (id_AOP4Hadoop),
  UNIQUE KEY avoid_duplicates_UNIQUE (id_exec,date,mili_secs,host_name,event),
  KEY index2 (id_exec)
) ENGINE=InnoDB;
"

####################################################
logger "INFO: Executing alter tables, you can IGNORE warnings"

$MYSQL "alter table execs
  add KEY \`idx_bench\` (\`bench\`),
  add KEY \`idx_exe_time\` (\`exe_time\`),
  add KEY \`idx_bench_type\` (\`bench_type\`);"

$MYSQL "alter table execs
  add KEY \`idx_id_cluster\` (\`id_cluster\`),
  add KEY \`idx_valid\` (\`valid\`),
  add KEY \`idx_filter\` (\`filter\`),
  add KEY \`idx_perf_details\` (\`perf_details\`);"

$MYSQL "alter table execs
 add column  \`valid\` int DEFAULT '1';"

$MYSQL "alter table aloja_logs.VMSTATS
 add column st decimal(20,3) DEFAULT NULL;"

$MYSQL "alter table aloja_logs.SAR_memory_util
 add column \`kbdirty\` decimal(20,3) DEFAULT NULL"

$MYSQL "alter table aloja_logs.SAR_net_devices
 add column \`%ifutil\` decimal(20,3) DEFAULT NULL"

$MYSQL "alter table execs
 modify column  \`valid\` int DEFAULT '1',
  ADD \`filter\` int DEFAULT '0',
  ADD \`outlier\` int DEFAULT '0';"

$MYSQL "alter table aloja2.execs ADD COLUMN  \`perf_details\` int DEFAULT '0';"

$MYSQL "alter table aloja2.execs add hadoop_version varchar(127) default NULL;"

$MYSQL "alter table aloja2.clusters  add datanodes int DEFAULT NULL;"
$MYSQL "alter table aloja2.clusters  add provider varchar(127);"
$MYSQL "alter table aloja2.clusters modify cost_hour decimal(10,5);"

$MYSQL "alter table clusters
  add headnodes int DEFAULT NULL,
  add vm_size varchar(127) default null,
  add vm_OS varchar(127) default null,
  add vm_cores int default null,
  add vm_RAM decimal(10,3) default null,
  add description varchar(256) default null;"

$MYSQL "alter table HDI_JOB_details ADD COLUMN NUM_FAILED_MAPS varchar(255) DEFAULT NULL;"
$MYSQL "alter table HDI_JOB_details ADD COLUMN HDFS_BYTES_READ bigint DEFAULT NULL;"
$MYSQL "alter table HDI_JOB_details ADD COLUMN HDFS_BYTES_WRITTEN bigint DEFAULT NULL;"
$MYSQL "alter table HDI_JOB_details ADD COLUMN HDFS_READ_OPS bigint DEFAULT NULL;"
$MYSQL "alter table HDI_JOB_details ADD COLUMN HDFS_WRITE_OPS bigint DEFAULT NULL;"
$MYSQL "alter table HDI_JOB_details ADD COLUMN HDFS_LARGE_READ_OPS bigint DEFAULT NULL;"
$MYSQL "alter table HDI_JOB_details ADD COLUMN HDFS_LARGE_WRITE_OPS bigint DEFAULT NULL;"
$MYSQL "alter table HDI_JOB_details ADD COLUMN DATA_LOCAL_MAPS bigint DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN HDFS_BYTES_READ bigint DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN HDFS_BYTES_WRITTEN bigint DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN HDFS_LARGE_READ_OPS bigint DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN HDFS_LARGE_WRITE_OPS bigint DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN HDFS_READ_OPS bigint DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN HDFS_WRITE_OPS bigint DEFAULT NULL;"

$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`job_name\` varchar(255) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`CREATED_FILES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`DESERIALIZE_ERRORS\` varchar(255) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`FAILED_REDUCES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`FINISHED_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`JOB_PRIORITY\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`LAUNCH_TIME\` varchar(255) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`MB_MILLIS_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`MB_MILLIS_REDUCES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`MILLIS_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`MILLIS_REDUCES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`NUM_KILLED_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`NUM_KILLED_REDUCES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`OTHER_LOCAL_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`RACK_LOCAL_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`RECORDS_IN\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`RECORDS_OUT_INTERMEDIATE\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`SKEWJOINFOLLOWUPJOBS\` varchar(255) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`SLOTS_MILLIS_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`SLOTS_MILLIS_REDUCES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`SUBMIT_TIME\` varchar(255) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`TOTAL_LAUNCHED_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`TOTAL_LAUNCHED_REDUCES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`TOTAL_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`TOTAL_REDUCES\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`USER\` varchar(255) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`VCORES_MILLIS_MAPS\` bigint(20) DEFAULT NULL;"
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`VCORES_MILLIS_REDUCES\` bigint(20) DEFAULT NULL;"



$MYSQL "alter table aloja2.clusters  add column cost_remote int DEFAULT 0"
$MYSQL "alter table aloja2.clusters  add column cost_SSD int DEFAULT 0"
$MYSQL "alter table aloja2.clusters  add column cost_IB int DEFAULT 0"

$MYSQL "alter table clusters
 modify column cost_remote decimal(10,3) default 0,
  modify column cost_SSD decimal(10,3) default 0,
  modify column cost_IB decimal(10,3) default 0;"

$MYSQL "alter table hosts
	add column cost_remote decimal(10,3) default 0,
	add column cost_SSD decimal(10,3) default 0,
	add column cost_IB decimal(10,3) default 0;"

$MYSQL "alter table execs
    add column exec_type varchar(255) default 'default';"

$MYSQL "alter table execs
    modify column datasize bigint default NULL;"

$MYSQL "alter table execs
    add column scale_factor varchar(255) default NULL;"


############################################33
logger "INFO: Updating records"

$MYSQL "
update ignore aloja2.execs SET disk='RR1' where disk='R1';
update ignore aloja2.execs SET disk='RR2' where disk='R2';
update ignore aloja2.execs SET disk='RR3' where disk='R3';
update ignore aloja2.execs SET bench_type='HiBench' where bench_type='b';
update ignore aloja2.execs SET bench_type='HiBench' where bench_type='';
update ignore aloja2.execs SET bench_type='HiBench-min' where bench_type='-min';

#update ignore aloja2.execs SET bench_type='HiBench-min' where exec like '%_b_min_%';

update ignore aloja2.execs SET bench_type='HiBench-10' where bench_type='-10';
update ignore aloja2.execs SET bench_type='HiBench-1TB' where bench_type='-1TB';
update ignore aloja2.execs SET bench_type='HiBench-1TB' where bench IN ('prep_terasort', 'terasort') and start_time between '2014-12-02' AND '2014-12-17 12:00';
update ignore aloja2.execs SET hadoop_version='1.03' where hadoop_version IS NULL;
update ignore aloja2.execs SET net='IB' where id_cluster = 26;
update ignore aloja2.execs SET disk='HDD' where disk = 'SSD' AND id_cluster = 26;

#azure VMs (this should also be in get_filter_sql)
update ignore aloja2.clusters  SET vm_size='A1' where vm_size IN ('small', 'Small');
update ignore aloja2.clusters  SET vm_size='A2' where vm_size IN ('medium', 'Medium');
update ignore aloja2.clusters  SET vm_size='A3' where vm_size IN ('large', 'Large');
update ignore aloja2.clusters  SET vm_size='A4' where vm_size IN ('extralarge', 'Extralarge');
update ignore aloja2.clusters  SET vm_size='D4' where vm_size IN ('Standard_D4');
update ignore aloja2.clusters  set headnodes=2 where provider = 'hdinsight' and vm_OS = 'windows';

update aloja2.execs JOIN aloja2.clusters using (id_cluster) set valid = 1, filter = 0 where provider = 'hdinsight';
update aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench='wordcount' and exe_time < 700 OR id_cluster =25 AND YEAR(start_time) = '2014';
update aloja2.execs set id_cluster=25 where exec like '%alojahdi32%' AND YEAR(start_time) = '2014';
update aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench='wordcount' and exe_time>5000 AND YEAR(start_time) = '2014';
update aloja2.execs set bench_type = 'HiBench-1TB' where id_cluster IN (20,23,24,25) AND exe_time > 10000 AND bench = 'terasort' AND YEAR(start_time) = '2014';
update aloja2.execs set valid=0 where id_cluster IN (20,23,24,25) AND bench_type = 'HDI' AND bench = 'terasort' AND exe_time > 5000 AND YEAR(start_time) = '2014';
update aloja2.execs set bench_type = 'HiBench' where id_cluster IN (20,23,24,25) AND bench_type = 'HDI' AND YEAR(start_time) = '2014';

update aloja2.execs set filter = 1 where id_cluster = 24 AND bench = 'terasort' AND exe_time > 900 AND YEAR(start_time) = '2014';

update aloja2.execs set filter = 1 where id_cluster = 23 AND bench = 'terasort' AND exe_time > 1100 AND YEAR(start_time) = '2014';

update aloja2.execs set filter = 1 where id_cluster = 20 AND bench = 'terasort' AND exe_time > 2300 AND YEAR(start_time) = '2014';

"
$MYSQL "update aloja2.execs set bench='terasort' where bench='TeraSort' and id_cluster IN (20,23,24,25);
update aloja2.execs set bench='prep_wordcount' where bench='random-text-writer' and id_cluster IN (20,23,24,25);
update aloja2.execs set bench='prep_terasort' where bench='TeraGen' and id_cluster IN (20,23,24,25);"

#azure VMs
$MYSQL "
update ignore aloja2.clusters  SET vm_size='A3' where vm_size IN ('large', 'Large');
update ignore aloja2.clusters  SET vm_size='A2' where vm_size IN ('medium', 'Medium');
update ignore aloja2.clusters  SET vm_size='A4' where vm_size IN ('extralarge', 'Extralarge');
update ignore aloja2.clusters  SET vm_size='D4' where vm_size IN ('Standard_D4');"


#Change bench suite names
$MYSQL "
update ignore aloja2.execs set bench_type = 'HiBench' where bench_type LIKE 'HiBench-%';
update ignore aloja2.execs JOIN clusters c USING (id_cluster) set bench_type = 'HiBench3' where bench_type LIKE 'HiBench3-%' OR (bench_type = 'HiBench3HDI' AND vm_OS = 'linux');
update ignore aloja2.execs JOIN clusters c USING (id_cluster) set bench_type = 'MapReduce-Examples' where bench_type = 'HiBench3HDI' AND vm_OS = 'windows';
"

##Datasize and scale factor
$MYSQL "
update ignore aloja2.execs set datasize = NULL where datasize < 1;
update ignore aloja2.execs set scale_factor = 'N/A' where datasize < 1;

update ignore aloja2.execs e JOIN JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.HDFS_BYTES_READ where c.type != 'PaaS' and bench != 'terasort';
update ignore aloja2.execs e JOIN HDI_JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.WASB_BYTES_READ where c.type = 'PaaS' and bench != 'terasort';

update ignore aloja2.execs e JOIN JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.HDFS_BYTES_WRITTEN where c.type != 'PaaS' and bench = 'terasort';
update ignore aloja2.execs e JOIN HDI_JOB_details d USING (id_exec) JOIN clusters c USING (id_cluster) set e.datasize = d.WASB_BYTES_WRITTEN where c.type = 'PaaS' and bench = 'terasort';

update ignore aloja2.execs e set e.scale_factor = '32GB/Dn' where e.bench='wordcount' and e.bench_type LIKE 'HiBench%';

update ignore aloja2.execs e set e.scale_factor='24GB/Dn' where e.bench='sort' and e.bench_type LIKE 'HiBench%';
"

##HDInsight filters
$MYSQL "
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set exec_type = 'experimental' where exec_type = 'default' and vm_OS = 'linux' and comp != 0 and provider = 'hdinsight' and start_time < '2015-05-22';
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set exec_type = 'default' where exec_type != 'default' and vm_OS = 'linux' and comp = 0 and provider = 'hdinsight' and start_time < '2015-05-22';
update ignore aloja2.execs JOIN aloja2.clusters using (id_cluster) set disk = 'RR1' where disk != 'RR1' and provider = 'hdinsight' and start_time < '2015-05-22';
"

#Rackspace cloud
#$MYSQL "
#
#insert ignore into execs(id_cluster,exec,bench,exe_time,net,disk,bench_type,maps,valid,hadoop_version,perf_details) values(38,'terasort_r16_1428333140','terasort',4134,'ETH','RR1','HiBench',32,1,1,0);
#insert ignore into execs(id_cluster,exec,bench,exe_time,net,disk,bench_type,maps,valid,hadoop_version,perf_details) values(38,'terasort_r16_1428327683','terasort',4148,'ETH','RR1','HiBench',32,1,1,0);
#"
#insert ignore into execs(id_cluster,exec,bench,exe_time,net,disk,bench_type,maps,valid,hadoop_version,perf_details) values(42,'2014_alojahdil4_1428309325/job_1428289975913_0002','terasort',4148,'ETH','RR1','HiBench',32,1,1,0);
#insert ignore into execs(id_cluster,exec,bench,exe_time,net,disk,bench_type,maps,valid,hadoop_version,perf_details) values(38,'terasort_1427396874','terasort',25340,'ETH','RR1','HiBench',32,1,1,0);
#insert ignore into execs(id_cluster,exec,bench,exe_time,net,disk,bench_type,maps,valid,hadoop_version,perf_details) values(38,'terasort_1427432130','terasort',32974,'ETH','RR1','HiBench',32,1,1,0);
#insert ignore into execs(id_cluster,exec,bench,exe_time,net,disk,bench_type,maps,valid,hadoop_version,perf_details) values(38,'terasort_1427439529','terasort',8720,'ETH','RR1','HiBench',32,1,1,0);

#Azure DW (SaaS)

$MYSQL "
#File 100GB_1000DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query1','query 1',17859,'2016-02-01',DATE_ADD(start_time,INTERVAL 17859 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query1','query 1',14356,'2016-02-01',DATE_ADD(start_time,INTERVAL 14356 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query1','query 1',13142,'2016-02-01',DATE_ADD(start_time,INTERVAL 13142 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query2','query 2',16818,'2016-02-01',DATE_ADD(start_time,INTERVAL 16818 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query2','query 2',19572,'2016-02-01',DATE_ADD(start_time,INTERVAL 19572 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query2','query 2',19596,'2016-02-01',DATE_ADD(start_time,INTERVAL 19596 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query3','query 3',39445,'2016-02-01',DATE_ADD(start_time,INTERVAL 39445 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query3','query 3',39331,'2016-02-01',DATE_ADD(start_time,INTERVAL 39331 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query3','query 3',37977,'2016-02-01',DATE_ADD(start_time,INTERVAL 37977 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query4','query 4',84140,'2016-02-01',DATE_ADD(start_time,INTERVAL 84140 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query4','query 4',81363,'2016-02-01',DATE_ADD(start_time,INTERVAL 81363 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query4','query 4',81667,'2016-02-01',DATE_ADD(start_time,INTERVAL 81667 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query5','query 5',48621,'2016-02-01',DATE_ADD(start_time,INTERVAL 48621 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query5','query 5',43207,'2016-02-01',DATE_ADD(start_time,INTERVAL 43207 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query5','query 5',96239,'2016-02-01',DATE_ADD(start_time,INTERVAL 96239 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query6','query 6',13289,'2016-02-01',DATE_ADD(start_time,INTERVAL 13289 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query6','query 6',5256,'2016-02-01',DATE_ADD(start_time,INTERVAL 5256 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query6','query 6',14769,'2016-02-01',DATE_ADD(start_time,INTERVAL 14769 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query7','query 7',50289,'2016-02-01',DATE_ADD(start_time,INTERVAL 50289 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query7','query 7',50567,'2016-02-01',DATE_ADD(start_time,INTERVAL 50567 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query7','query 7',50798,'2016-02-01',DATE_ADD(start_time,INTERVAL 50798 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query8','query 8',59526,'2016-02-01',DATE_ADD(start_time,INTERVAL 59526 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query8','query 8',60543,'2016-02-01',DATE_ADD(start_time,INTERVAL 60543 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query8','query 8',52122,'2016-02-01',DATE_ADD(start_time,INTERVAL 52122 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query9','query 9',207418,'2016-02-01',DATE_ADD(start_time,INTERVAL 207418 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query9','query 9',199668,'2016-02-01',DATE_ADD(start_time,INTERVAL 199668 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query9','query 9',269693,'2016-02-01',DATE_ADD(start_time,INTERVAL 269693 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query10','query 10',98827,'2016-02-01',DATE_ADD(start_time,INTERVAL 98827 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query10','query 10',121275,'2016-02-01',DATE_ADD(start_time,INTERVAL 121275 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query10','query 10',107303,'2016-02-01',DATE_ADD(start_time,INTERVAL 107303 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query11','query 11',13501,'2016-02-01',DATE_ADD(start_time,INTERVAL 13501 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query11','query 11',9523,'2016-02-01',DATE_ADD(start_time,INTERVAL 9523 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query11','query 11',8971,'2016-02-01',DATE_ADD(start_time,INTERVAL 8971 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query12','query 12',13280,'2016-02-01',DATE_ADD(start_time,INTERVAL 13280 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query12','query 12',13690,'2016-02-01',DATE_ADD(start_time,INTERVAL 13690 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query12','query 12',21712,'2016-02-01',DATE_ADD(start_time,INTERVAL 21712 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query13','query 13',25960,'2016-02-01',DATE_ADD(start_time,INTERVAL 25960 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query13','query 13',19933,'2016-02-01',DATE_ADD(start_time,INTERVAL 19933 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query13','query 13',20668,'2016-02-01',DATE_ADD(start_time,INTERVAL 20668 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query14','query 14',12774,'2016-02-01',DATE_ADD(start_time,INTERVAL 12774 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query14','query 14',13308,'2016-02-01',DATE_ADD(start_time,INTERVAL 13308 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query14','query 14',11298,'2016-02-01',DATE_ADD(start_time,INTERVAL 11298 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query15','query 15',18148,'2016-02-01',DATE_ADD(start_time,INTERVAL 18148 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query15','query 15',17028,'2016-02-01',DATE_ADD(start_time,INTERVAL 17028 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query15','query 15',15439,'2016-02-01',DATE_ADD(start_time,INTERVAL 15439 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query16','query 16',69154,'2016-02-01',DATE_ADD(start_time,INTERVAL 69154 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query16','query 16',72058,'2016-02-01',DATE_ADD(start_time,INTERVAL 72058 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query16','query 16',71779,'2016-02-01',DATE_ADD(start_time,INTERVAL 71779 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query17','query 17',51954,'2016-02-01',DATE_ADD(start_time,INTERVAL 51954 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query17','query 17',52304,'2016-02-01',DATE_ADD(start_time,INTERVAL 52304 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query17','query 17',53378,'2016-02-01',DATE_ADD(start_time,INTERVAL 53378 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query18','query 18',58503,'2016-02-01',DATE_ADD(start_time,INTERVAL 58503 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query18','query 18',59899,'2016-02-01',DATE_ADD(start_time,INTERVAL 59899 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query18','query 18',56651,'2016-02-01',DATE_ADD(start_time,INTERVAL 56651 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query19','query 19',14840,'2016-02-01',DATE_ADD(start_time,INTERVAL 14840 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query19','query 19',11291,'2016-02-01',DATE_ADD(start_time,INTERVAL 11291 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query19','query 19',35229,'2016-02-01',DATE_ADD(start_time,INTERVAL 35229 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query20','query 20',21131,'2016-02-01',DATE_ADD(start_time,INTERVAL 21131 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query20','query 20',21190,'2016-02-01',DATE_ADD(start_time,INTERVAL 21190 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query20','query 20',21418,'2016-02-01',DATE_ADD(start_time,INTERVAL 21418 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query21','query 21',147001,'2016-02-01',DATE_ADD(start_time,INTERVAL 147001 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query21','query 21',149203,'2016-02-01',DATE_ADD(start_time,INTERVAL 149203 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query21','query 21',145206,'2016-02-01',DATE_ADD(start_time,INTERVAL 145206 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/query22','query 22',15004,'2016-02-01',DATE_ADD(start_time,INTERVAL 15004 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/query22','query 22',17709,'2016-02-01',DATE_ADD(start_time,INTERVAL 17709 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/query22','query 22',17447,'2016-02-01',DATE_ADD(start_time,INTERVAL 17447 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
"
$MYSQL "
#File 100GB_100DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query1','query 1',88618,'2016-02-01',DATE_ADD(start_time,INTERVAL 88618 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query1','query 1',81600,'2016-02-01',DATE_ADD(start_time,INTERVAL 81600 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query1','query 1',79013,'2016-02-01',DATE_ADD(start_time,INTERVAL 79013 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query2','query 2',65255,'2016-02-01',DATE_ADD(start_time,INTERVAL 65255 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query2','query 2',92999,'2016-02-01',DATE_ADD(start_time,INTERVAL 92999 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query2','query 2',110779,'2016-02-01',DATE_ADD(start_time,INTERVAL 110779 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query3','query 3',592464,'2016-02-01',DATE_ADD(start_time,INTERVAL 592464 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query3','query 3',497825,'2016-02-01',DATE_ADD(start_time,INTERVAL 497825 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query3','query 3',592419,'2016-02-01',DATE_ADD(start_time,INTERVAL 592419 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query4','query 4',461810,'2016-02-01',DATE_ADD(start_time,INTERVAL 461810 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query4','query 4',411771,'2016-02-01',DATE_ADD(start_time,INTERVAL 411771 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query4','query 4',414059,'2016-02-01',DATE_ADD(start_time,INTERVAL 414059 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query5','query 5',68526,'2016-02-01',DATE_ADD(start_time,INTERVAL 68526 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query5','query 5',259219,'2016-02-01',DATE_ADD(start_time,INTERVAL 259219 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query5','query 5',41467,'2016-02-01',DATE_ADD(start_time,INTERVAL 41467 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query6','query 6',42274,'2016-02-01',DATE_ADD(start_time,INTERVAL 42274 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query6','query 6',21451,'2016-02-01',DATE_ADD(start_time,INTERVAL 21451 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query6','query 6',58270,'2016-02-01',DATE_ADD(start_time,INTERVAL 58270 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query7','query 7',538240,'2016-02-01',DATE_ADD(start_time,INTERVAL 538240 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query7','query 7',481383,'2016-02-01',DATE_ADD(start_time,INTERVAL 481383 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query7','query 7',458810,'2016-02-01',DATE_ADD(start_time,INTERVAL 458810 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query8','query 8',67930,'2016-02-01',DATE_ADD(start_time,INTERVAL 67930 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query8','query 8',69705,'2016-02-01',DATE_ADD(start_time,INTERVAL 69705 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query8','query 8',73116,'2016-02-01',DATE_ADD(start_time,INTERVAL 73116 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query9','query 9',1544772,'2016-02-01',DATE_ADD(start_time,INTERVAL 1544772 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query9','query 9',1611538,'2016-02-01',DATE_ADD(start_time,INTERVAL 1611538 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query9','query 9',1400310,'2016-02-01',DATE_ADD(start_time,INTERVAL 1400310 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query10','query 10',695284,'2016-02-01',DATE_ADD(start_time,INTERVAL 695284 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query10','query 10',594699,'2016-02-01',DATE_ADD(start_time,INTERVAL 594699 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query10','query 10',623035,'2016-02-01',DATE_ADD(start_time,INTERVAL 623035 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query11','query 11',102058,'2016-02-01',DATE_ADD(start_time,INTERVAL 102058 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query11','query 11',109175,'2016-02-01',DATE_ADD(start_time,INTERVAL 109175 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query11','query 11',69367,'2016-02-01',DATE_ADD(start_time,INTERVAL 69367 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query12','query 12',108486,'2016-02-01',DATE_ADD(start_time,INTERVAL 108486 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query12','query 12',91525,'2016-02-01',DATE_ADD(start_time,INTERVAL 91525 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query12','query 12',87851,'2016-02-01',DATE_ADD(start_time,INTERVAL 87851 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query13','query 13',165979,'2016-02-01',DATE_ADD(start_time,INTERVAL 165979 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query13','query 13',170789,'2016-02-01',DATE_ADD(start_time,INTERVAL 170789 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query13','query 13',164480,'2016-02-01',DATE_ADD(start_time,INTERVAL 164480 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query14','query 14',305592,'2016-02-01',DATE_ADD(start_time,INTERVAL 305592 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query14','query 14',233434,'2016-02-01',DATE_ADD(start_time,INTERVAL 233434 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query14','query 14',248070,'2016-02-01',DATE_ADD(start_time,INTERVAL 248070 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query15','query 15',81986,'2016-02-01',DATE_ADD(start_time,INTERVAL 81986 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query15','query 15',88401,'2016-02-01',DATE_ADD(start_time,INTERVAL 88401 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query15','query 15',110333,'2016-02-01',DATE_ADD(start_time,INTERVAL 110333 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query16','query 16',340996,'2016-02-01',DATE_ADD(start_time,INTERVAL 340996 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query16','query 16',329449,'2016-02-01',DATE_ADD(start_time,INTERVAL 329449 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query16','query 16',322029,'2016-02-01',DATE_ADD(start_time,INTERVAL 322029 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query17','query 17',457149,'2016-02-01',DATE_ADD(start_time,INTERVAL 457149 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query17','query 17',454525,'2016-02-01',DATE_ADD(start_time,INTERVAL 454525 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query17','query 17',543346,'2016-02-01',DATE_ADD(start_time,INTERVAL 543346 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query18','query 18',564327,'2016-02-01',DATE_ADD(start_time,INTERVAL 564327 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query18','query 18',450255,'2016-02-01',DATE_ADD(start_time,INTERVAL 450255 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query18','query 18',484357,'2016-02-01',DATE_ADD(start_time,INTERVAL 484357 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query19','query 19',53329,'2016-02-01',DATE_ADD(start_time,INTERVAL 53329 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query19','query 19',140206,'2016-02-01',DATE_ADD(start_time,INTERVAL 140206 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query19','query 19',160149,'2016-02-01',DATE_ADD(start_time,INTERVAL 160149 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query20','query 20',113678,'2016-02-01',DATE_ADD(start_time,INTERVAL 113678 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query20','query 20',68116,'2016-02-01',DATE_ADD(start_time,INTERVAL 68116 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query20','query 20',76506,'2016-02-01',DATE_ADD(start_time,INTERVAL 76506 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query21','query 21',1289642,'2016-02-01',DATE_ADD(start_time,INTERVAL 1289642 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query21','query 21',1433387,'2016-02-01',DATE_ADD(start_time,INTERVAL 1433387 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query21','query 21',1220220,'2016-02-01',DATE_ADD(start_time,INTERVAL 1220220 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/query22','query 22',157270,'2016-02-01',DATE_ADD(start_time,INTERVAL 157270 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/query22','query 22',150508,'2016-02-01',DATE_ADD(start_time,INTERVAL 150508 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/query22','query 22',524996,'2016-02-01',DATE_ADD(start_time,INTERVAL 524996 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
"
$MYSQL "
#File 100GB_400DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query1','query 1',205495,'2016-02-01',DATE_ADD(start_time,INTERVAL 205495 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query1','query 1',30074,'2016-02-01',DATE_ADD(start_time,INTERVAL 30074 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query1','query 1',97531,'2016-02-01',DATE_ADD(start_time,INTERVAL 97531 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query2','query 2',46121,'2016-02-01',DATE_ADD(start_time,INTERVAL 46121 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query2','query 2',27526,'2016-02-01',DATE_ADD(start_time,INTERVAL 27526 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query2','query 2',25759,'2016-02-01',DATE_ADD(start_time,INTERVAL 25759 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query3','query 3',103370,'2016-02-01',DATE_ADD(start_time,INTERVAL 103370 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query3','query 3',82642,'2016-02-01',DATE_ADD(start_time,INTERVAL 82642 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query3','query 3',81726,'2016-02-01',DATE_ADD(start_time,INTERVAL 81726 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query4','query 4',132173,'2016-02-01',DATE_ADD(start_time,INTERVAL 132173 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query4','query 4',144634,'2016-02-01',DATE_ADD(start_time,INTERVAL 144634 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query4','query 4',153815,'2016-02-01',DATE_ADD(start_time,INTERVAL 153815 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query5','query 5',102010,'2016-02-01',DATE_ADD(start_time,INTERVAL 102010 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query5','query 5',87536,'2016-02-01',DATE_ADD(start_time,INTERVAL 87536 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query5','query 5',70443,'2016-02-01',DATE_ADD(start_time,INTERVAL 70443 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query6','query 6',13382,'2016-02-01',DATE_ADD(start_time,INTERVAL 13382 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query6','query 6',66427,'2016-02-01',DATE_ADD(start_time,INTERVAL 66427 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query6','query 6',11047,'2016-02-01',DATE_ADD(start_time,INTERVAL 11047 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query7','query 7',113207,'2016-02-01',DATE_ADD(start_time,INTERVAL 113207 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query7','query 7',113584,'2016-02-01',DATE_ADD(start_time,INTERVAL 113584 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query7','query 7',115691,'2016-02-01',DATE_ADD(start_time,INTERVAL 115691 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query8','query 8',77138,'2016-02-01',DATE_ADD(start_time,INTERVAL 77138 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query8','query 8',79172,'2016-02-01',DATE_ADD(start_time,INTERVAL 79172 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query8','query 8',68669,'2016-02-01',DATE_ADD(start_time,INTERVAL 68669 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query9','query 9',397938,'2016-02-01',DATE_ADD(start_time,INTERVAL 397938 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query9','query 9',389601,'2016-02-01',DATE_ADD(start_time,INTERVAL 389601 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query9','query 9',377670,'2016-02-01',DATE_ADD(start_time,INTERVAL 377670 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query10','query 10',317238,'2016-02-01',DATE_ADD(start_time,INTERVAL 317238 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query10','query 10',214333,'2016-02-01',DATE_ADD(start_time,INTERVAL 214333 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query10','query 10',173140,'2016-02-01',DATE_ADD(start_time,INTERVAL 173140 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query11','query 11',12519,'2016-02-01',DATE_ADD(start_time,INTERVAL 12519 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query11','query 11',11268,'2016-02-01',DATE_ADD(start_time,INTERVAL 11268 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query11','query 11',12118,'2016-02-01',DATE_ADD(start_time,INTERVAL 12118 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query12','query 12',190848,'2016-02-01',DATE_ADD(start_time,INTERVAL 190848 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query12','query 12',36268,'2016-02-01',DATE_ADD(start_time,INTERVAL 36268 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query12','query 12',41967,'2016-02-01',DATE_ADD(start_time,INTERVAL 41967 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query13','query 13',62407,'2016-02-01',DATE_ADD(start_time,INTERVAL 62407 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query13','query 13',45653,'2016-02-01',DATE_ADD(start_time,INTERVAL 45653 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query13','query 13',46855,'2016-02-01',DATE_ADD(start_time,INTERVAL 46855 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query14','query 14',43282,'2016-02-01',DATE_ADD(start_time,INTERVAL 43282 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query14','query 14',24261,'2016-02-01',DATE_ADD(start_time,INTERVAL 24261 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query14','query 14',25271,'2016-02-01',DATE_ADD(start_time,INTERVAL 25271 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query15','query 15',35205,'2016-02-01',DATE_ADD(start_time,INTERVAL 35205 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query15','query 15',24747,'2016-02-01',DATE_ADD(start_time,INTERVAL 24747 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query15','query 15',22600,'2016-02-01',DATE_ADD(start_time,INTERVAL 22600 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query16','query 16',108878,'2016-02-01',DATE_ADD(start_time,INTERVAL 108878 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query16','query 16',107323,'2016-02-01',DATE_ADD(start_time,INTERVAL 107323 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query16','query 16',105523,'2016-02-01',DATE_ADD(start_time,INTERVAL 105523 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query17','query 17',139582,'2016-02-01',DATE_ADD(start_time,INTERVAL 139582 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query17','query 17',148222,'2016-02-01',DATE_ADD(start_time,INTERVAL 148222 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query17','query 17',150971,'2016-02-01',DATE_ADD(start_time,INTERVAL 150971 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query18','query 18',129949,'2016-02-01',DATE_ADD(start_time,INTERVAL 129949 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query18','query 18',157498,'2016-02-01',DATE_ADD(start_time,INTERVAL 157498 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query18','query 18',148398,'2016-02-01',DATE_ADD(start_time,INTERVAL 148398 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query19','query 19',17990,'2016-02-01',DATE_ADD(start_time,INTERVAL 17990 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query19','query 19',30632,'2016-02-01',DATE_ADD(start_time,INTERVAL 30632 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query19','query 19',20813,'2016-02-01',DATE_ADD(start_time,INTERVAL 20813 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query20','query 20',25603,'2016-02-01',DATE_ADD(start_time,INTERVAL 25603 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query20','query 20',30697,'2016-02-01',DATE_ADD(start_time,INTERVAL 30697 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query20','query 20',27322,'2016-02-01',DATE_ADD(start_time,INTERVAL 27322 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query21','query 21',523235,'2016-02-01',DATE_ADD(start_time,INTERVAL 523235 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query21','query 21',452837,'2016-02-01',DATE_ADD(start_time,INTERVAL 452837 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query21','query 21',482312,'2016-02-01',DATE_ADD(start_time,INTERVAL 482312 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/query22','query 22',30297,'2016-02-01',DATE_ADD(start_time,INTERVAL 30297 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/query22','query 22',29359,'2016-02-01',DATE_ADD(start_time,INTERVAL 29359 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/query22','query 22',29006,'2016-02-01',DATE_ADD(start_time,INTERVAL 29006 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
"
$MYSQL "
#File 100GB_500DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query1','query 1',45543,'2016-02-01',DATE_ADD(start_time,INTERVAL 45543 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query1','query 1',32960,'2016-02-01',DATE_ADD(start_time,INTERVAL 32960 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query1','query 1',43077,'2016-02-01',DATE_ADD(start_time,INTERVAL 43077 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query2','query 2',25683,'2016-02-01',DATE_ADD(start_time,INTERVAL 25683 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query2','query 2',30911,'2016-02-01',DATE_ADD(start_time,INTERVAL 30911 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query2','query 2',26521,'2016-02-01',DATE_ADD(start_time,INTERVAL 26521 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query3','query 3',70280,'2016-02-01',DATE_ADD(start_time,INTERVAL 70280 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query3','query 3',67546,'2016-02-01',DATE_ADD(start_time,INTERVAL 67546 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query3','query 3',75509,'2016-02-01',DATE_ADD(start_time,INTERVAL 75509 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query4','query 4',159898,'2016-02-01',DATE_ADD(start_time,INTERVAL 159898 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query4','query 4',208108,'2016-02-01',DATE_ADD(start_time,INTERVAL 208108 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query4','query 4',139013,'2016-02-01',DATE_ADD(start_time,INTERVAL 139013 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query5','query 5',69235,'2016-02-01',DATE_ADD(start_time,INTERVAL 69235 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query5','query 5',65161,'2016-02-01',DATE_ADD(start_time,INTERVAL 65161 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query5','query 5',120934,'2016-02-01',DATE_ADD(start_time,INTERVAL 120934 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query6','query 6',12155,'2016-02-01',DATE_ADD(start_time,INTERVAL 12155 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query6','query 6',11430,'2016-02-01',DATE_ADD(start_time,INTERVAL 11430 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query6','query 6',12441,'2016-02-01',DATE_ADD(start_time,INTERVAL 12441 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query7','query 7',94683,'2016-02-01',DATE_ADD(start_time,INTERVAL 94683 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query7','query 7',93897,'2016-02-01',DATE_ADD(start_time,INTERVAL 93897 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query7','query 7',102831,'2016-02-01',DATE_ADD(start_time,INTERVAL 102831 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query8','query 8',74724,'2016-02-01',DATE_ADD(start_time,INTERVAL 74724 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query8','query 8',67145,'2016-02-01',DATE_ADD(start_time,INTERVAL 67145 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query8','query 8',72131,'2016-02-01',DATE_ADD(start_time,INTERVAL 72131 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query9','query 9',344452,'2016-02-01',DATE_ADD(start_time,INTERVAL 344452 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query9','query 9',331509,'2016-02-01',DATE_ADD(start_time,INTERVAL 331509 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query9','query 9',348105,'2016-02-01',DATE_ADD(start_time,INTERVAL 348105 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query10','query 10',340648,'2016-02-01',DATE_ADD(start_time,INTERVAL 340648 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query10','query 10',303236,'2016-02-01',DATE_ADD(start_time,INTERVAL 303236 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query10','query 10',207074,'2016-02-01',DATE_ADD(start_time,INTERVAL 207074 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query11','query 11',18418,'2016-02-01',DATE_ADD(start_time,INTERVAL 18418 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query11','query 11',18911,'2016-02-01',DATE_ADD(start_time,INTERVAL 18911 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query11','query 11',13168,'2016-02-01',DATE_ADD(start_time,INTERVAL 13168 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query12','query 12',30235,'2016-02-01',DATE_ADD(start_time,INTERVAL 30235 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query12','query 12',35295,'2016-02-01',DATE_ADD(start_time,INTERVAL 35295 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query12','query 12',26337,'2016-02-01',DATE_ADD(start_time,INTERVAL 26337 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query13','query 13',47116,'2016-02-01',DATE_ADD(start_time,INTERVAL 47116 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query13','query 13',39305,'2016-02-01',DATE_ADD(start_time,INTERVAL 39305 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query13','query 13',40874,'2016-02-01',DATE_ADD(start_time,INTERVAL 40874 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query14','query 14',24804,'2016-02-01',DATE_ADD(start_time,INTERVAL 24804 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query14','query 14',21337,'2016-02-01',DATE_ADD(start_time,INTERVAL 21337 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query14','query 14',25147,'2016-02-01',DATE_ADD(start_time,INTERVAL 25147 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query15','query 15',27500,'2016-02-01',DATE_ADD(start_time,INTERVAL 27500 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query15','query 15',25883,'2016-02-01',DATE_ADD(start_time,INTERVAL 25883 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query15','query 15',37575,'2016-02-01',DATE_ADD(start_time,INTERVAL 37575 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query16','query 16',102268,'2016-02-01',DATE_ADD(start_time,INTERVAL 102268 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query16','query 16',101930,'2016-02-01',DATE_ADD(start_time,INTERVAL 101930 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query16','query 16',103204,'2016-02-01',DATE_ADD(start_time,INTERVAL 103204 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query17','query 17',122257,'2016-02-01',DATE_ADD(start_time,INTERVAL 122257 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query17','query 17',127837,'2016-02-01',DATE_ADD(start_time,INTERVAL 127837 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query17','query 17',118711,'2016-02-01',DATE_ADD(start_time,INTERVAL 118711 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query18','query 18',142167,'2016-02-01',DATE_ADD(start_time,INTERVAL 142167 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query18','query 18',137554,'2016-02-01',DATE_ADD(start_time,INTERVAL 137554 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query18','query 18',161395,'2016-02-01',DATE_ADD(start_time,INTERVAL 161395 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query19','query 19',29912,'2016-02-01',DATE_ADD(start_time,INTERVAL 29912 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query19','query 19',17615,'2016-02-01',DATE_ADD(start_time,INTERVAL 17615 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query19','query 19',19458,'2016-02-01',DATE_ADD(start_time,INTERVAL 19458 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query20','query 20',33532,'2016-02-01',DATE_ADD(start_time,INTERVAL 33532 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query20','query 20',29566,'2016-02-01',DATE_ADD(start_time,INTERVAL 29566 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query20','query 20',23665,'2016-02-01',DATE_ADD(start_time,INTERVAL 23665 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query21','query 21',355728,'2016-02-01',DATE_ADD(start_time,INTERVAL 355728 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query21','query 21',459323,'2016-02-01',DATE_ADD(start_time,INTERVAL 459323 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query21','query 21',348333,'2016-02-01',DATE_ADD(start_time,INTERVAL 348333 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/query22','query 22',34709,'2016-02-01',DATE_ADD(start_time,INTERVAL 34709 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/query22','query 22',30422,'2016-02-01',DATE_ADD(start_time,INTERVAL 30422 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/query22','query 22',31715,'2016-02-01',DATE_ADD(start_time,INTERVAL 31715 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
"
$MYSQL "
#File 10GB_1000DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query1','query 1',8027,'2016-02-01',DATE_ADD(start_time,INTERVAL 8027 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query1','query 1',14470,'2016-02-01',DATE_ADD(start_time,INTERVAL 14470 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query1','query 1',3752,'2016-02-01',DATE_ADD(start_time,INTERVAL 3752 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query2','query 2',5467,'2016-02-01',DATE_ADD(start_time,INTERVAL 5467 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query2','query 2',3548,'2016-02-01',DATE_ADD(start_time,INTERVAL 3548 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query2','query 2',13821,'2016-02-01',DATE_ADD(start_time,INTERVAL 13821 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query3','query 3',5521,'2016-02-01',DATE_ADD(start_time,INTERVAL 5521 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query3','query 3',4093,'2016-02-01',DATE_ADD(start_time,INTERVAL 4093 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query3','query 3',4210,'2016-02-01',DATE_ADD(start_time,INTERVAL 4210 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query4','query 4',4250,'2016-02-01',DATE_ADD(start_time,INTERVAL 4250 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query4','query 4',4533,'2016-02-01',DATE_ADD(start_time,INTERVAL 4533 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query4','query 4',4515,'2016-02-01',DATE_ADD(start_time,INTERVAL 4515 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query5','query 5',5689,'2016-02-01',DATE_ADD(start_time,INTERVAL 5689 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query5','query 5',4990,'2016-02-01',DATE_ADD(start_time,INTERVAL 4990 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query5','query 5',5799,'2016-02-01',DATE_ADD(start_time,INTERVAL 5799 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query6','query 6',3369,'2016-02-01',DATE_ADD(start_time,INTERVAL 3369 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query6','query 6',2381,'2016-02-01',DATE_ADD(start_time,INTERVAL 2381 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query6','query 6',2205,'2016-02-01',DATE_ADD(start_time,INTERVAL 2205 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query7','query 7',6176,'2016-02-01',DATE_ADD(start_time,INTERVAL 6176 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query7','query 7',4234,'2016-02-01',DATE_ADD(start_time,INTERVAL 4234 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query7','query 7',6358,'2016-02-01',DATE_ADD(start_time,INTERVAL 6358 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query8','query 8',12218,'2016-02-01',DATE_ADD(start_time,INTERVAL 12218 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query8','query 8',6233,'2016-02-01',DATE_ADD(start_time,INTERVAL 6233 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query8','query 8',8242,'2016-02-01',DATE_ADD(start_time,INTERVAL 8242 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query9','query 9',7628,'2016-02-01',DATE_ADD(start_time,INTERVAL 7628 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query9','query 9',7316,'2016-02-01',DATE_ADD(start_time,INTERVAL 7316 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query9','query 9',8271,'2016-02-01',DATE_ADD(start_time,INTERVAL 8271 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query10','query 10',6160,'2016-02-01',DATE_ADD(start_time,INTERVAL 6160 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query10','query 10',5497,'2016-02-01',DATE_ADD(start_time,INTERVAL 5497 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query10','query 10',6619,'2016-02-01',DATE_ADD(start_time,INTERVAL 6619 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query11','query 11',3519,'2016-02-01',DATE_ADD(start_time,INTERVAL 3519 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query11','query 11',3205,'2016-02-01',DATE_ADD(start_time,INTERVAL 3205 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query11','query 11',3400,'2016-02-01',DATE_ADD(start_time,INTERVAL 3400 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query12','query 12',4118,'2016-02-01',DATE_ADD(start_time,INTERVAL 4118 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query12','query 12',3115,'2016-02-01',DATE_ADD(start_time,INTERVAL 3115 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query12','query 12',4280,'2016-02-01',DATE_ADD(start_time,INTERVAL 4280 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query13','query 13',4139,'2016-02-01',DATE_ADD(start_time,INTERVAL 4139 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query13','query 13',3582,'2016-02-01',DATE_ADD(start_time,INTERVAL 3582 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query13','query 13',5017,'2016-02-01',DATE_ADD(start_time,INTERVAL 5017 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query14','query 14',21943,'2016-02-01',DATE_ADD(start_time,INTERVAL 21943 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query14','query 14',9633,'2016-02-01',DATE_ADD(start_time,INTERVAL 9633 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query14','query 14',3047,'2016-02-01',DATE_ADD(start_time,INTERVAL 3047 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query15','query 15',8474,'2016-02-01',DATE_ADD(start_time,INTERVAL 8474 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query15','query 15',10582,'2016-02-01',DATE_ADD(start_time,INTERVAL 10582 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query15','query 15',7383,'2016-02-01',DATE_ADD(start_time,INTERVAL 7383 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query16','query 16',7985,'2016-02-01',DATE_ADD(start_time,INTERVAL 7985 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query16','query 16',7794,'2016-02-01',DATE_ADD(start_time,INTERVAL 7794 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query16','query 16',7430,'2016-02-01',DATE_ADD(start_time,INTERVAL 7430 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query17','query 17',5272,'2016-02-01',DATE_ADD(start_time,INTERVAL 5272 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query17','query 17',4274,'2016-02-01',DATE_ADD(start_time,INTERVAL 4274 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query17','query 17',3665,'2016-02-01',DATE_ADD(start_time,INTERVAL 3665 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query18','query 18',5760,'2016-02-01',DATE_ADD(start_time,INTERVAL 5760 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query18','query 18',11634,'2016-02-01',DATE_ADD(start_time,INTERVAL 11634 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query18','query 18',5311,'2016-02-01',DATE_ADD(start_time,INTERVAL 5311 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query19','query 19',10964,'2016-02-01',DATE_ADD(start_time,INTERVAL 10964 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query19','query 19',3554,'2016-02-01',DATE_ADD(start_time,INTERVAL 3554 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query19','query 19',4020,'2016-02-01',DATE_ADD(start_time,INTERVAL 4020 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query20','query 20',3338,'2016-02-01',DATE_ADD(start_time,INTERVAL 3338 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query20','query 20',3141,'2016-02-01',DATE_ADD(start_time,INTERVAL 3141 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query20','query 20',5928,'2016-02-01',DATE_ADD(start_time,INTERVAL 5928 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query21','query 21',7358,'2016-02-01',DATE_ADD(start_time,INTERVAL 7358 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query21','query 21',7229,'2016-02-01',DATE_ADD(start_time,INTERVAL 7229 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query21','query 21',10807,'2016-02-01',DATE_ADD(start_time,INTERVAL 10807 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/query22','query 22',5273,'2016-02-01',DATE_ADD(start_time,INTERVAL 5273 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/query22','query 22',14092,'2016-02-01',DATE_ADD(start_time,INTERVAL 14092 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/query22','query 22',4408,'2016-02-01',DATE_ADD(start_time,INTERVAL 4408 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
"
$MYSQL "
#File 10GB_100DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query1','query 1',18022,'2016-02-01',DATE_ADD(start_time,INTERVAL 18022 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query1','query 1',19280,'2016-02-01',DATE_ADD(start_time,INTERVAL 19280 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query1','query 1',15166,'2016-02-01',DATE_ADD(start_time,INTERVAL 15166 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query2','query 2',21728,'2016-02-01',DATE_ADD(start_time,INTERVAL 21728 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query2','query 2',15384,'2016-02-01',DATE_ADD(start_time,INTERVAL 15384 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query2','query 2',14955,'2016-02-01',DATE_ADD(start_time,INTERVAL 14955 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query3','query 3',54663,'2016-02-01',DATE_ADD(start_time,INTERVAL 54663 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query3','query 3',58209,'2016-02-01',DATE_ADD(start_time,INTERVAL 58209 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query3','query 3',57448,'2016-02-01',DATE_ADD(start_time,INTERVAL 57448 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query4','query 4',46012,'2016-02-01',DATE_ADD(start_time,INTERVAL 46012 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query4','query 4',44746,'2016-02-01',DATE_ADD(start_time,INTERVAL 44746 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query4','query 4',44562,'2016-02-01',DATE_ADD(start_time,INTERVAL 44562 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query5','query 5',36454,'2016-02-01',DATE_ADD(start_time,INTERVAL 36454 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query5','query 5',31196,'2016-02-01',DATE_ADD(start_time,INTERVAL 31196 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query5','query 5',32575,'2016-02-01',DATE_ADD(start_time,INTERVAL 32575 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query6','query 6',7803,'2016-02-01',DATE_ADD(start_time,INTERVAL 7803 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query6','query 6',6112,'2016-02-01',DATE_ADD(start_time,INTERVAL 6112 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query6','query 6',6033,'2016-02-01',DATE_ADD(start_time,INTERVAL 6033 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query7','query 7',82017,'2016-02-01',DATE_ADD(start_time,INTERVAL 82017 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query7','query 7',89752,'2016-02-01',DATE_ADD(start_time,INTERVAL 89752 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query7','query 7',95251,'2016-02-01',DATE_ADD(start_time,INTERVAL 95251 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query8','query 8',31230,'2016-02-01',DATE_ADD(start_time,INTERVAL 31230 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query8','query 8',29078,'2016-02-01',DATE_ADD(start_time,INTERVAL 29078 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query8','query 8',23957,'2016-02-01',DATE_ADD(start_time,INTERVAL 23957 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query9','query 9',180853,'2016-02-01',DATE_ADD(start_time,INTERVAL 180853 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query9','query 9',168364,'2016-02-01',DATE_ADD(start_time,INTERVAL 168364 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query9','query 9',169502,'2016-02-01',DATE_ADD(start_time,INTERVAL 169502 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query10','query 10',58639,'2016-02-01',DATE_ADD(start_time,INTERVAL 58639 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query10','query 10',54765,'2016-02-01',DATE_ADD(start_time,INTERVAL 54765 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query10','query 10',53706,'2016-02-01',DATE_ADD(start_time,INTERVAL 53706 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query11','query 11',11677,'2016-02-01',DATE_ADD(start_time,INTERVAL 11677 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query11','query 11',10884,'2016-02-01',DATE_ADD(start_time,INTERVAL 10884 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query11','query 11',12207,'2016-02-01',DATE_ADD(start_time,INTERVAL 12207 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query12','query 12',23010,'2016-02-01',DATE_ADD(start_time,INTERVAL 23010 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query12','query 12',15783,'2016-02-01',DATE_ADD(start_time,INTERVAL 15783 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query12','query 12',15521,'2016-02-01',DATE_ADD(start_time,INTERVAL 15521 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query13','query 13',39245,'2016-02-01',DATE_ADD(start_time,INTERVAL 39245 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query13','query 13',30216,'2016-02-01',DATE_ADD(start_time,INTERVAL 30216 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query13','query 13',30733,'2016-02-01',DATE_ADD(start_time,INTERVAL 30733 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query14','query 14',13077,'2016-02-01',DATE_ADD(start_time,INTERVAL 13077 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query14','query 14',15215,'2016-02-01',DATE_ADD(start_time,INTERVAL 15215 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query14','query 14',13396,'2016-02-01',DATE_ADD(start_time,INTERVAL 13396 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query15','query 15',19373,'2016-02-01',DATE_ADD(start_time,INTERVAL 19373 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query15','query 15',16549,'2016-02-01',DATE_ADD(start_time,INTERVAL 16549 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query15','query 15',20410,'2016-02-01',DATE_ADD(start_time,INTERVAL 20410 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query16','query 16',47336,'2016-02-01',DATE_ADD(start_time,INTERVAL 47336 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query16','query 16',49716,'2016-02-01',DATE_ADD(start_time,INTERVAL 49716 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query16','query 16',53537,'2016-02-01',DATE_ADD(start_time,INTERVAL 53537 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query17','query 17',92769,'2016-02-01',DATE_ADD(start_time,INTERVAL 92769 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query17','query 17',81069,'2016-02-01',DATE_ADD(start_time,INTERVAL 81069 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query17','query 17',95772,'2016-02-01',DATE_ADD(start_time,INTERVAL 95772 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query18','query 18',101799,'2016-02-01',DATE_ADD(start_time,INTERVAL 101799 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query18','query 18',92585,'2016-02-01',DATE_ADD(start_time,INTERVAL 92585 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query18','query 18',117880,'2016-02-01',DATE_ADD(start_time,INTERVAL 117880 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query19','query 19',20796,'2016-02-01',DATE_ADD(start_time,INTERVAL 20796 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query19','query 19',14235,'2016-02-01',DATE_ADD(start_time,INTERVAL 14235 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query19','query 19',16486,'2016-02-01',DATE_ADD(start_time,INTERVAL 16486 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query20','query 20',20960,'2016-02-01',DATE_ADD(start_time,INTERVAL 20960 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query20','query 20',11095,'2016-02-01',DATE_ADD(start_time,INTERVAL 11095 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query20','query 20',25299,'2016-02-01',DATE_ADD(start_time,INTERVAL 25299 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query21','query 21',176191,'2016-02-01',DATE_ADD(start_time,INTERVAL 176191 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query21','query 21',172135,'2016-02-01',DATE_ADD(start_time,INTERVAL 172135 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query21','query 21',192416,'2016-02-01',DATE_ADD(start_time,INTERVAL 192416 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/query22','query 22',26605,'2016-02-01',DATE_ADD(start_time,INTERVAL 26605 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/query22','query 22',24372,'2016-02-01',DATE_ADD(start_time,INTERVAL 24372 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/query22','query 22',22452,'2016-02-01',DATE_ADD(start_time,INTERVAL 22452 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
"
$MYSQL "
#File 10GB_400DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query1','query 1',9468,'2016-02-01',DATE_ADD(start_time,INTERVAL 9468 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query1','query 1',5880,'2016-02-01',DATE_ADD(start_time,INTERVAL 5880 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query1','query 1',7748,'2016-02-01',DATE_ADD(start_time,INTERVAL 7748 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query2','query 2',57536,'2016-02-01',DATE_ADD(start_time,INTERVAL 57536 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query2','query 2',6338,'2016-02-01',DATE_ADD(start_time,INTERVAL 6338 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query2','query 2',7062,'2016-02-01',DATE_ADD(start_time,INTERVAL 7062 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query3','query 3',20707,'2016-02-01',DATE_ADD(start_time,INTERVAL 20707 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query3','query 3',19382,'2016-02-01',DATE_ADD(start_time,INTERVAL 19382 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query3','query 3',17473,'2016-02-01',DATE_ADD(start_time,INTERVAL 17473 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query4','query 4',16606,'2016-02-01',DATE_ADD(start_time,INTERVAL 16606 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query4','query 4',17211,'2016-02-01',DATE_ADD(start_time,INTERVAL 17211 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query4','query 4',17193,'2016-02-01',DATE_ADD(start_time,INTERVAL 17193 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query5','query 5',10562,'2016-02-01',DATE_ADD(start_time,INTERVAL 10562 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query5','query 5',12787,'2016-02-01',DATE_ADD(start_time,INTERVAL 12787 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query5','query 5',9959,'2016-02-01',DATE_ADD(start_time,INTERVAL 9959 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query6','query 6',3843,'2016-02-01',DATE_ADD(start_time,INTERVAL 3843 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query6','query 6',2333,'2016-02-01',DATE_ADD(start_time,INTERVAL 2333 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query6','query 6',3148,'2016-02-01',DATE_ADD(start_time,INTERVAL 3148 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query7','query 7',30283,'2016-02-01',DATE_ADD(start_time,INTERVAL 30283 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query7','query 7',26491,'2016-02-01',DATE_ADD(start_time,INTERVAL 26491 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query7','query 7',28276,'2016-02-01',DATE_ADD(start_time,INTERVAL 28276 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query8','query 8',14442,'2016-02-01',DATE_ADD(start_time,INTERVAL 14442 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query8','query 8',11767,'2016-02-01',DATE_ADD(start_time,INTERVAL 11767 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query8','query 8',13305,'2016-02-01',DATE_ADD(start_time,INTERVAL 13305 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query9','query 9',49698,'2016-02-01',DATE_ADD(start_time,INTERVAL 49698 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query9','query 9',49897,'2016-02-01',DATE_ADD(start_time,INTERVAL 49897 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query9','query 9',48411,'2016-02-01',DATE_ADD(start_time,INTERVAL 48411 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query10','query 10',26065,'2016-02-01',DATE_ADD(start_time,INTERVAL 26065 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query10','query 10',23481,'2016-02-01',DATE_ADD(start_time,INTERVAL 23481 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query10','query 10',30728,'2016-02-01',DATE_ADD(start_time,INTERVAL 30728 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query11','query 11',4967,'2016-02-01',DATE_ADD(start_time,INTERVAL 4967 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query11','query 11',6498,'2016-02-01',DATE_ADD(start_time,INTERVAL 6498 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query11','query 11',4933,'2016-02-01',DATE_ADD(start_time,INTERVAL 4933 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query12','query 12',8661,'2016-02-01',DATE_ADD(start_time,INTERVAL 8661 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query12','query 12',7869,'2016-02-01',DATE_ADD(start_time,INTERVAL 7869 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query12','query 12',7812,'2016-02-01',DATE_ADD(start_time,INTERVAL 7812 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query13','query 13',11486,'2016-02-01',DATE_ADD(start_time,INTERVAL 11486 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query13','query 13',9342,'2016-02-01',DATE_ADD(start_time,INTERVAL 9342 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query13','query 13',10427,'2016-02-01',DATE_ADD(start_time,INTERVAL 10427 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query14','query 14',4960,'2016-02-01',DATE_ADD(start_time,INTERVAL 4960 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query14','query 14',6637,'2016-02-01',DATE_ADD(start_time,INTERVAL 6637 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query14','query 14',5782,'2016-02-01',DATE_ADD(start_time,INTERVAL 5782 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query15','query 15',11208,'2016-02-01',DATE_ADD(start_time,INTERVAL 11208 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query15','query 15',9372,'2016-02-01',DATE_ADD(start_time,INTERVAL 9372 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query15','query 15',9429,'2016-02-01',DATE_ADD(start_time,INTERVAL 9429 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query16','query 16',21446,'2016-02-01',DATE_ADD(start_time,INTERVAL 21446 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query16','query 16',19847,'2016-02-01',DATE_ADD(start_time,INTERVAL 19847 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query16','query 16',21200,'2016-02-01',DATE_ADD(start_time,INTERVAL 21200 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query17','query 17',19408,'2016-02-01',DATE_ADD(start_time,INTERVAL 19408 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query17','query 17',18678,'2016-02-01',DATE_ADD(start_time,INTERVAL 18678 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query17','query 17',16708,'2016-02-01',DATE_ADD(start_time,INTERVAL 16708 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query18','query 18',29448,'2016-02-01',DATE_ADD(start_time,INTERVAL 29448 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query18','query 18',30139,'2016-02-01',DATE_ADD(start_time,INTERVAL 30139 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query18','query 18',29901,'2016-02-01',DATE_ADD(start_time,INTERVAL 29901 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query19','query 19',7119,'2016-02-01',DATE_ADD(start_time,INTERVAL 7119 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query19','query 19',7497,'2016-02-01',DATE_ADD(start_time,INTERVAL 7497 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query19','query 19',6407,'2016-02-01',DATE_ADD(start_time,INTERVAL 6407 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query20','query 20',6319,'2016-02-01',DATE_ADD(start_time,INTERVAL 6319 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query20','query 20',5738,'2016-02-01',DATE_ADD(start_time,INTERVAL 5738 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query20','query 20',4931,'2016-02-01',DATE_ADD(start_time,INTERVAL 4931 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query21','query 21',46974,'2016-02-01',DATE_ADD(start_time,INTERVAL 46974 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query21','query 21',45668,'2016-02-01',DATE_ADD(start_time,INTERVAL 45668 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query21','query 21',46022,'2016-02-01',DATE_ADD(start_time,INTERVAL 46022 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/query22','query 22',10644,'2016-02-01',DATE_ADD(start_time,INTERVAL 10644 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/query22','query 22',10863,'2016-02-01',DATE_ADD(start_time,INTERVAL 10863 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/query22','query 22',7841,'2016-02-01',DATE_ADD(start_time,INTERVAL 7841 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
"
$MYSQL "
#File 10GB_500DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query1','query 1',6947,'2016-02-01',DATE_ADD(start_time,INTERVAL 6947 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query1','query 1',3834,'2016-02-01',DATE_ADD(start_time,INTERVAL 3834 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query1','query 1',4299,'2016-02-01',DATE_ADD(start_time,INTERVAL 4299 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query2','query 2',9446,'2016-02-01',DATE_ADD(start_time,INTERVAL 9446 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query2','query 2',4702,'2016-02-01',DATE_ADD(start_time,INTERVAL 4702 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query2','query 2',7818,'2016-02-01',DATE_ADD(start_time,INTERVAL 7818 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query3','query 3',6541,'2016-02-01',DATE_ADD(start_time,INTERVAL 6541 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query3','query 3',5033,'2016-02-01',DATE_ADD(start_time,INTERVAL 5033 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query3','query 3',5898,'2016-02-01',DATE_ADD(start_time,INTERVAL 5898 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query4','query 4',6870,'2016-02-01',DATE_ADD(start_time,INTERVAL 6870 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query4','query 4',3788,'2016-02-01',DATE_ADD(start_time,INTERVAL 3788 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query4','query 4',4919,'2016-02-01',DATE_ADD(start_time,INTERVAL 4919 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query5','query 5',6366,'2016-02-01',DATE_ADD(start_time,INTERVAL 6366 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query5','query 5',4684,'2016-02-01',DATE_ADD(start_time,INTERVAL 4684 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query5','query 5',6075,'2016-02-01',DATE_ADD(start_time,INTERVAL 6075 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query6','query 6',3743,'2016-02-01',DATE_ADD(start_time,INTERVAL 3743 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query6','query 6',1829,'2016-02-01',DATE_ADD(start_time,INTERVAL 1829 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query6','query 6',2711,'2016-02-01',DATE_ADD(start_time,INTERVAL 2711 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query7','query 7',5860,'2016-02-01',DATE_ADD(start_time,INTERVAL 5860 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query7','query 7',7782,'2016-02-01',DATE_ADD(start_time,INTERVAL 7782 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query7','query 7',6605,'2016-02-01',DATE_ADD(start_time,INTERVAL 6605 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query8','query 8',7050,'2016-02-01',DATE_ADD(start_time,INTERVAL 7050 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query8','query 8',7284,'2016-02-01',DATE_ADD(start_time,INTERVAL 7284 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query8','query 8',8547,'2016-02-01',DATE_ADD(start_time,INTERVAL 8547 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query9','query 9',12219,'2016-02-01',DATE_ADD(start_time,INTERVAL 12219 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query9','query 9',11095,'2016-02-01',DATE_ADD(start_time,INTERVAL 11095 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query9','query 9',11497,'2016-02-01',DATE_ADD(start_time,INTERVAL 11497 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query10','query 10',6278,'2016-02-01',DATE_ADD(start_time,INTERVAL 6278 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query10','query 10',7901,'2016-02-01',DATE_ADD(start_time,INTERVAL 7901 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query10','query 10',5890,'2016-02-01',DATE_ADD(start_time,INTERVAL 5890 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query11','query 11',3700,'2016-02-01',DATE_ADD(start_time,INTERVAL 3700 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query11','query 11',4480,'2016-02-01',DATE_ADD(start_time,INTERVAL 4480 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query11','query 11',5175,'2016-02-01',DATE_ADD(start_time,INTERVAL 5175 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query12','query 12',3920,'2016-02-01',DATE_ADD(start_time,INTERVAL 3920 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query12','query 12',3543,'2016-02-01',DATE_ADD(start_time,INTERVAL 3543 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query12','query 12',4150,'2016-02-01',DATE_ADD(start_time,INTERVAL 4150 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query13','query 13',5531,'2016-02-01',DATE_ADD(start_time,INTERVAL 5531 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query13','query 13',4343,'2016-02-01',DATE_ADD(start_time,INTERVAL 4343 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query13','query 13',3793,'2016-02-01',DATE_ADD(start_time,INTERVAL 3793 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query14','query 14',3029,'2016-02-01',DATE_ADD(start_time,INTERVAL 3029 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query14','query 14',4074,'2016-02-01',DATE_ADD(start_time,INTERVAL 4074 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query14','query 14',3385,'2016-02-01',DATE_ADD(start_time,INTERVAL 3385 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query15','query 15',7890,'2016-02-01',DATE_ADD(start_time,INTERVAL 7890 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query15','query 15',9077,'2016-02-01',DATE_ADD(start_time,INTERVAL 9077 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query15','query 15',7473,'2016-02-01',DATE_ADD(start_time,INTERVAL 7473 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query16','query 16',8665,'2016-02-01',DATE_ADD(start_time,INTERVAL 8665 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query16','query 16',8423,'2016-02-01',DATE_ADD(start_time,INTERVAL 8423 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query16','query 16',9698,'2016-02-01',DATE_ADD(start_time,INTERVAL 9698 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query17','query 17',5266,'2016-02-01',DATE_ADD(start_time,INTERVAL 5266 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query17','query 17',6252,'2016-02-01',DATE_ADD(start_time,INTERVAL 6252 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query17','query 17',7350,'2016-02-01',DATE_ADD(start_time,INTERVAL 7350 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query18','query 18',8024,'2016-02-01',DATE_ADD(start_time,INTERVAL 8024 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query18','query 18',5741,'2016-02-01',DATE_ADD(start_time,INTERVAL 5741 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query18','query 18',7398,'2016-02-01',DATE_ADD(start_time,INTERVAL 7398 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query19','query 19',4586,'2016-02-01',DATE_ADD(start_time,INTERVAL 4586 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query19','query 19',3017,'2016-02-01',DATE_ADD(start_time,INTERVAL 3017 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query19','query 19',4164,'2016-02-01',DATE_ADD(start_time,INTERVAL 4164 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query20','query 20',5900,'2016-02-01',DATE_ADD(start_time,INTERVAL 5900 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query20','query 20',4258,'2016-02-01',DATE_ADD(start_time,INTERVAL 4258 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query20','query 20',4270,'2016-02-01',DATE_ADD(start_time,INTERVAL 4270 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query21','query 21',10938,'2016-02-01',DATE_ADD(start_time,INTERVAL 10938 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query21','query 21',10044,'2016-02-01',DATE_ADD(start_time,INTERVAL 10044 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query21','query 21',10673,'2016-02-01',DATE_ADD(start_time,INTERVAL 10673 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/query22','query 22',5382,'2016-02-01',DATE_ADD(start_time,INTERVAL 5382 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/query22','query 22',3689,'2016-02-01',DATE_ADD(start_time,INTERVAL 3689 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/query22','query 22',5041,'2016-02-01',DATE_ADD(start_time,INTERVAL 5041 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
"
$MYSQL "
#File 1GB_1000DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query1','query 1',8027,'2016-02-01',DATE_ADD(start_time,INTERVAL 8027 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query1','query 1',14470,'2016-02-01',DATE_ADD(start_time,INTERVAL 14470 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query1','query 1',3752,'2016-02-01',DATE_ADD(start_time,INTERVAL 3752 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query2','query 2',5467,'2016-02-01',DATE_ADD(start_time,INTERVAL 5467 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query2','query 2',3548,'2016-02-01',DATE_ADD(start_time,INTERVAL 3548 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query2','query 2',13821,'2016-02-01',DATE_ADD(start_time,INTERVAL 13821 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query3','query 3',5521,'2016-02-01',DATE_ADD(start_time,INTERVAL 5521 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query3','query 3',4093,'2016-02-01',DATE_ADD(start_time,INTERVAL 4093 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query3','query 3',4210,'2016-02-01',DATE_ADD(start_time,INTERVAL 4210 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query4','query 4',4250,'2016-02-01',DATE_ADD(start_time,INTERVAL 4250 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query4','query 4',4533,'2016-02-01',DATE_ADD(start_time,INTERVAL 4533 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query4','query 4',4515,'2016-02-01',DATE_ADD(start_time,INTERVAL 4515 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query5','query 5',5689,'2016-02-01',DATE_ADD(start_time,INTERVAL 5689 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query5','query 5',4990,'2016-02-01',DATE_ADD(start_time,INTERVAL 4990 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query5','query 5',5799,'2016-02-01',DATE_ADD(start_time,INTERVAL 5799 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query6','query 6',3369,'2016-02-01',DATE_ADD(start_time,INTERVAL 3369 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query6','query 6',2381,'2016-02-01',DATE_ADD(start_time,INTERVAL 2381 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query6','query 6',2205,'2016-02-01',DATE_ADD(start_time,INTERVAL 2205 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query7','query 7',6176,'2016-02-01',DATE_ADD(start_time,INTERVAL 6176 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query7','query 7',4234,'2016-02-01',DATE_ADD(start_time,INTERVAL 4234 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query7','query 7',6358,'2016-02-01',DATE_ADD(start_time,INTERVAL 6358 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query8','query 8',12218,'2016-02-01',DATE_ADD(start_time,INTERVAL 12218 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query8','query 8',6233,'2016-02-01',DATE_ADD(start_time,INTERVAL 6233 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query8','query 8',8242,'2016-02-01',DATE_ADD(start_time,INTERVAL 8242 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query9','query 9',7628,'2016-02-01',DATE_ADD(start_time,INTERVAL 7628 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query9','query 9',7316,'2016-02-01',DATE_ADD(start_time,INTERVAL 7316 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query9','query 9',8271,'2016-02-01',DATE_ADD(start_time,INTERVAL 8271 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query10','query 10',6160,'2016-02-01',DATE_ADD(start_time,INTERVAL 6160 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query10','query 10',5497,'2016-02-01',DATE_ADD(start_time,INTERVAL 5497 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query10','query 10',6619,'2016-02-01',DATE_ADD(start_time,INTERVAL 6619 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query11','query 11',3519,'2016-02-01',DATE_ADD(start_time,INTERVAL 3519 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query11','query 11',3205,'2016-02-01',DATE_ADD(start_time,INTERVAL 3205 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query11','query 11',3400,'2016-02-01',DATE_ADD(start_time,INTERVAL 3400 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query12','query 12',4118,'2016-02-01',DATE_ADD(start_time,INTERVAL 4118 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query12','query 12',3115,'2016-02-01',DATE_ADD(start_time,INTERVAL 3115 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query12','query 12',4280,'2016-02-01',DATE_ADD(start_time,INTERVAL 4280 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query13','query 13',4139,'2016-02-01',DATE_ADD(start_time,INTERVAL 4139 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query13','query 13',3582,'2016-02-01',DATE_ADD(start_time,INTERVAL 3582 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query13','query 13',5017,'2016-02-01',DATE_ADD(start_time,INTERVAL 5017 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query14','query 14',21943,'2016-02-01',DATE_ADD(start_time,INTERVAL 21943 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query14','query 14',9633,'2016-02-01',DATE_ADD(start_time,INTERVAL 9633 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query14','query 14',3047,'2016-02-01',DATE_ADD(start_time,INTERVAL 3047 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query15','query 15',8474,'2016-02-01',DATE_ADD(start_time,INTERVAL 8474 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query15','query 15',10582,'2016-02-01',DATE_ADD(start_time,INTERVAL 10582 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query15','query 15',7383,'2016-02-01',DATE_ADD(start_time,INTERVAL 7383 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query16','query 16',7985,'2016-02-01',DATE_ADD(start_time,INTERVAL 7985 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query16','query 16',7794,'2016-02-01',DATE_ADD(start_time,INTERVAL 7794 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query16','query 16',7430,'2016-02-01',DATE_ADD(start_time,INTERVAL 7430 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query17','query 17',5272,'2016-02-01',DATE_ADD(start_time,INTERVAL 5272 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query17','query 17',4274,'2016-02-01',DATE_ADD(start_time,INTERVAL 4274 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query17','query 17',3665,'2016-02-01',DATE_ADD(start_time,INTERVAL 3665 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query18','query 18',5760,'2016-02-01',DATE_ADD(start_time,INTERVAL 5760 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query18','query 18',11634,'2016-02-01',DATE_ADD(start_time,INTERVAL 11634 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query18','query 18',5311,'2016-02-01',DATE_ADD(start_time,INTERVAL 5311 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query19','query 19',10964,'2016-02-01',DATE_ADD(start_time,INTERVAL 10964 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query19','query 19',3554,'2016-02-01',DATE_ADD(start_time,INTERVAL 3554 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query19','query 19',4020,'2016-02-01',DATE_ADD(start_time,INTERVAL 4020 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query20','query 20',3338,'2016-02-01',DATE_ADD(start_time,INTERVAL 3338 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query20','query 20',3141,'2016-02-01',DATE_ADD(start_time,INTERVAL 3141 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query20','query 20',5928,'2016-02-01',DATE_ADD(start_time,INTERVAL 5928 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query21','query 21',7358,'2016-02-01',DATE_ADD(start_time,INTERVAL 7358 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query21','query 21',7229,'2016-02-01',DATE_ADD(start_time,INTERVAL 7229 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query21','query 21',10807,'2016-02-01',DATE_ADD(start_time,INTERVAL 10807 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/query22','query 22',5273,'2016-02-01',DATE_ADD(start_time,INTERVAL 5273 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/query22','query 22',14092,'2016-02-01',DATE_ADD(start_time,INTERVAL 14092 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/query22','query 22',4408,'2016-02-01',DATE_ADD(start_time,INTERVAL 4408 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
"
$MYSQL "
#File 1GB_100DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query1','query 1',13330,'2016-02-01',DATE_ADD(start_time,INTERVAL 13330 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query1','query 1',9630,'2016-02-01',DATE_ADD(start_time,INTERVAL 9630 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query1','query 1',10613,'2016-02-01',DATE_ADD(start_time,INTERVAL 10613 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query2','query 2',11810,'2016-02-01',DATE_ADD(start_time,INTERVAL 11810 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query2','query 2',8784,'2016-02-01',DATE_ADD(start_time,INTERVAL 8784 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query2','query 2',9574,'2016-02-01',DATE_ADD(start_time,INTERVAL 9574 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query3','query 3',11162,'2016-02-01',DATE_ADD(start_time,INTERVAL 11162 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query3','query 3',13562,'2016-02-01',DATE_ADD(start_time,INTERVAL 13562 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query3','query 3',10861,'2016-02-01',DATE_ADD(start_time,INTERVAL 10861 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query4','query 4',19155,'2016-02-01',DATE_ADD(start_time,INTERVAL 19155 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query4','query 4',10591,'2016-02-01',DATE_ADD(start_time,INTERVAL 10591 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query4','query 4',11384,'2016-02-01',DATE_ADD(start_time,INTERVAL 11384 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query5','query 5',58569,'2016-02-01',DATE_ADD(start_time,INTERVAL 58569 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query5','query 5',10412,'2016-02-01',DATE_ADD(start_time,INTERVAL 10412 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query5','query 5',29287,'2016-02-01',DATE_ADD(start_time,INTERVAL 29287 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query6','query 6',5947,'2016-02-01',DATE_ADD(start_time,INTERVAL 5947 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query6','query 6',7940,'2016-02-01',DATE_ADD(start_time,INTERVAL 7940 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query6','query 6',4274,'2016-02-01',DATE_ADD(start_time,INTERVAL 4274 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query7','query 7',16340,'2016-02-01',DATE_ADD(start_time,INTERVAL 16340 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query7','query 7',15549,'2016-02-01',DATE_ADD(start_time,INTERVAL 15549 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query7','query 7',17963,'2016-02-01',DATE_ADD(start_time,INTERVAL 17963 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query8','query 8',12200,'2016-02-01',DATE_ADD(start_time,INTERVAL 12200 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query8','query 8',13817,'2016-02-01',DATE_ADD(start_time,INTERVAL 13817 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query8','query 8',11979,'2016-02-01',DATE_ADD(start_time,INTERVAL 11979 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query9','query 9',36819,'2016-02-01',DATE_ADD(start_time,INTERVAL 36819 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query9','query 9',25645,'2016-02-01',DATE_ADD(start_time,INTERVAL 25645 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query9','query 9',30966,'2016-02-01',DATE_ADD(start_time,INTERVAL 30966 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query10','query 10',12310,'2016-02-01',DATE_ADD(start_time,INTERVAL 12310 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query10','query 10',12421,'2016-02-01',DATE_ADD(start_time,INTERVAL 12421 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query10','query 10',12664,'2016-02-01',DATE_ADD(start_time,INTERVAL 12664 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query11','query 11',7279,'2016-02-01',DATE_ADD(start_time,INTERVAL 7279 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query11','query 11',9429,'2016-02-01',DATE_ADD(start_time,INTERVAL 9429 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query11','query 11',7821,'2016-02-01',DATE_ADD(start_time,INTERVAL 7821 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query12','query 12',6352,'2016-02-01',DATE_ADD(start_time,INTERVAL 6352 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query12','query 12',6225,'2016-02-01',DATE_ADD(start_time,INTERVAL 6225 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query12','query 12',6693,'2016-02-01',DATE_ADD(start_time,INTERVAL 6693 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query13','query 13',8293,'2016-02-01',DATE_ADD(start_time,INTERVAL 8293 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query13','query 13',9009,'2016-02-01',DATE_ADD(start_time,INTERVAL 9009 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query13','query 13',11738,'2016-02-01',DATE_ADD(start_time,INTERVAL 11738 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query14','query 14',8607,'2016-02-01',DATE_ADD(start_time,INTERVAL 8607 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query14','query 14',6480,'2016-02-01',DATE_ADD(start_time,INTERVAL 6480 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query14','query 14',6146,'2016-02-01',DATE_ADD(start_time,INTERVAL 6146 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query15','query 15',18144,'2016-02-01',DATE_ADD(start_time,INTERVAL 18144 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query15','query 15',14856,'2016-02-01',DATE_ADD(start_time,INTERVAL 14856 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query15','query 15',15185,'2016-02-01',DATE_ADD(start_time,INTERVAL 15185 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query16','query 16',21864,'2016-02-01',DATE_ADD(start_time,INTERVAL 21864 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query16','query 16',22565,'2016-02-01',DATE_ADD(start_time,INTERVAL 22565 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query16','query 16',20838,'2016-02-01',DATE_ADD(start_time,INTERVAL 20838 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query17','query 17',14611,'2016-02-01',DATE_ADD(start_time,INTERVAL 14611 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query17','query 17',24141,'2016-02-01',DATE_ADD(start_time,INTERVAL 24141 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query17','query 17',14320,'2016-02-01',DATE_ADD(start_time,INTERVAL 14320 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query18','query 18',15290,'2016-02-01',DATE_ADD(start_time,INTERVAL 15290 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query18','query 18',16660,'2016-02-01',DATE_ADD(start_time,INTERVAL 16660 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query18','query 18',16879,'2016-02-01',DATE_ADD(start_time,INTERVAL 16879 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query19','query 19',6946,'2016-02-01',DATE_ADD(start_time,INTERVAL 6946 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query19','query 19',8723,'2016-02-01',DATE_ADD(start_time,INTERVAL 8723 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query19','query 19',6640,'2016-02-01',DATE_ADD(start_time,INTERVAL 6640 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query20','query 20',6335,'2016-02-01',DATE_ADD(start_time,INTERVAL 6335 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query20','query 20',6970,'2016-02-01',DATE_ADD(start_time,INTERVAL 6970 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query20','query 20',8097,'2016-02-01',DATE_ADD(start_time,INTERVAL 8097 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query21','query 21',30565,'2016-02-01',DATE_ADD(start_time,INTERVAL 30565 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query21','query 21',25884,'2016-02-01',DATE_ADD(start_time,INTERVAL 25884 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query21','query 21',150741,'2016-02-01',DATE_ADD(start_time,INTERVAL 150741 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/query22','query 22',8137,'2016-02-01',DATE_ADD(start_time,INTERVAL 8137 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/query22','query 22',9525,'2016-02-01',DATE_ADD(start_time,INTERVAL 9525 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/query22','query 22',10387,'2016-02-01',DATE_ADD(start_time,INTERVAL 10387 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
"
$MYSQL "
#File 1GB_400DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query1','query 1',5930,'2016-02-01',DATE_ADD(start_time,INTERVAL 5930 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query1','query 1',5526,'2016-02-01',DATE_ADD(start_time,INTERVAL 5526 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query1','query 1',5204,'2016-02-01',DATE_ADD(start_time,INTERVAL 5204 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query2','query 2',10928,'2016-02-01',DATE_ADD(start_time,INTERVAL 10928 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query2','query 2',6398,'2016-02-01',DATE_ADD(start_time,INTERVAL 6398 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query2','query 2',4014,'2016-02-01',DATE_ADD(start_time,INTERVAL 4014 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query3','query 3',6856,'2016-02-01',DATE_ADD(start_time,INTERVAL 6856 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query3','query 3',6667,'2016-02-01',DATE_ADD(start_time,INTERVAL 6667 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query3','query 3',5511,'2016-02-01',DATE_ADD(start_time,INTERVAL 5511 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query4','query 4',6351,'2016-02-01',DATE_ADD(start_time,INTERVAL 6351 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query4','query 4',4678,'2016-02-01',DATE_ADD(start_time,INTERVAL 4678 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query4','query 4',5053,'2016-02-01',DATE_ADD(start_time,INTERVAL 5053 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query5','query 5',5980,'2016-02-01',DATE_ADD(start_time,INTERVAL 5980 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query5','query 5',4709,'2016-02-01',DATE_ADD(start_time,INTERVAL 4709 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query5','query 5',4620,'2016-02-01',DATE_ADD(start_time,INTERVAL 4620 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query6','query 6',5005,'2016-02-01',DATE_ADD(start_time,INTERVAL 5005 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query6','query 6',2129,'2016-02-01',DATE_ADD(start_time,INTERVAL 2129 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query6','query 6',2875,'2016-02-01',DATE_ADD(start_time,INTERVAL 2875 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query7','query 7',7966,'2016-02-01',DATE_ADD(start_time,INTERVAL 7966 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query7','query 7',6151,'2016-02-01',DATE_ADD(start_time,INTERVAL 6151 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query7','query 7',6900,'2016-02-01',DATE_ADD(start_time,INTERVAL 6900 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query8','query 8',6024,'2016-02-01',DATE_ADD(start_time,INTERVAL 6024 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query8','query 8',6781,'2016-02-01',DATE_ADD(start_time,INTERVAL 6781 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query8','query 8',8766,'2016-02-01',DATE_ADD(start_time,INTERVAL 8766 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query9','query 9',12658,'2016-02-01',DATE_ADD(start_time,INTERVAL 12658 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query9','query 9',12367,'2016-02-01',DATE_ADD(start_time,INTERVAL 12367 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query9','query 9',12854,'2016-02-01',DATE_ADD(start_time,INTERVAL 12854 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query10','query 10',4804,'2016-02-01',DATE_ADD(start_time,INTERVAL 4804 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query10','query 10',6149,'2016-02-01',DATE_ADD(start_time,INTERVAL 6149 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query10','query 10',6723,'2016-02-01',DATE_ADD(start_time,INTERVAL 6723 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query11','query 11',4007,'2016-02-01',DATE_ADD(start_time,INTERVAL 4007 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query11','query 11',4436,'2016-02-01',DATE_ADD(start_time,INTERVAL 4436 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query11','query 11',5820,'2016-02-01',DATE_ADD(start_time,INTERVAL 5820 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query12','query 12',4952,'2016-02-01',DATE_ADD(start_time,INTERVAL 4952 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query12','query 12',2846,'2016-02-01',DATE_ADD(start_time,INTERVAL 2846 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query12','query 12',5545,'2016-02-01',DATE_ADD(start_time,INTERVAL 5545 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query13','query 13',3989,'2016-02-01',DATE_ADD(start_time,INTERVAL 3989 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query13','query 13',5364,'2016-02-01',DATE_ADD(start_time,INTERVAL 5364 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query13','query 13',4299,'2016-02-01',DATE_ADD(start_time,INTERVAL 4299 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query14','query 14',4468,'2016-02-01',DATE_ADD(start_time,INTERVAL 4468 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query14','query 14',15934,'2016-02-01',DATE_ADD(start_time,INTERVAL 15934 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query14','query 14',3093,'2016-02-01',DATE_ADD(start_time,INTERVAL 3093 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query15','query 15',7986,'2016-02-01',DATE_ADD(start_time,INTERVAL 7986 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query15','query 15',7684,'2016-02-01',DATE_ADD(start_time,INTERVAL 7684 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query15','query 15',8733,'2016-02-01',DATE_ADD(start_time,INTERVAL 8733 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query16','query 16',9327,'2016-02-01',DATE_ADD(start_time,INTERVAL 9327 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query16','query 16',7145,'2016-02-01',DATE_ADD(start_time,INTERVAL 7145 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query16','query 16',6856,'2016-02-01',DATE_ADD(start_time,INTERVAL 6856 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query17','query 17',6534,'2016-02-01',DATE_ADD(start_time,INTERVAL 6534 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query17','query 17',6201,'2016-02-01',DATE_ADD(start_time,INTERVAL 6201 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query17','query 17',8501,'2016-02-01',DATE_ADD(start_time,INTERVAL 8501 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query18','query 18',11866,'2016-02-01',DATE_ADD(start_time,INTERVAL 11866 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query18','query 18',7058,'2016-02-01',DATE_ADD(start_time,INTERVAL 7058 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query18','query 18',6940,'2016-02-01',DATE_ADD(start_time,INTERVAL 6940 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query19','query 19',5866,'2016-02-01',DATE_ADD(start_time,INTERVAL 5866 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query19','query 19',4554,'2016-02-01',DATE_ADD(start_time,INTERVAL 4554 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query19','query 19',4080,'2016-02-01',DATE_ADD(start_time,INTERVAL 4080 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query20','query 20',5989,'2016-02-01',DATE_ADD(start_time,INTERVAL 5989 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query20','query 20',3751,'2016-02-01',DATE_ADD(start_time,INTERVAL 3751 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query20','query 20',2910,'2016-02-01',DATE_ADD(start_time,INTERVAL 2910 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query21','query 21',11310,'2016-02-01',DATE_ADD(start_time,INTERVAL 11310 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query21','query 21',13526,'2016-02-01',DATE_ADD(start_time,INTERVAL 13526 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query21','query 21',10926,'2016-02-01',DATE_ADD(start_time,INTERVAL 10926 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/query22','query 22',4919,'2016-02-01',DATE_ADD(start_time,INTERVAL 4919 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/query22','query 22',3535,'2016-02-01',DATE_ADD(start_time,INTERVAL 3535 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/query22','query 22',3568,'2016-02-01',DATE_ADD(start_time,INTERVAL 3568 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
"
$MYSQL "
#File 1GB_500DWU.log
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query1','query 1',6947,'2016-02-01',DATE_ADD(start_time,INTERVAL 6947 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query1','query 1',3834,'2016-02-01',DATE_ADD(start_time,INTERVAL 3834 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query1','query 1',4299,'2016-02-01',DATE_ADD(start_time,INTERVAL 4299 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query2','query 2',9446,'2016-02-01',DATE_ADD(start_time,INTERVAL 9446 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query2','query 2',4702,'2016-02-01',DATE_ADD(start_time,INTERVAL 4702 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query2','query 2',7818,'2016-02-01',DATE_ADD(start_time,INTERVAL 7818 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query3','query 3',6541,'2016-02-01',DATE_ADD(start_time,INTERVAL 6541 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query3','query 3',5033,'2016-02-01',DATE_ADD(start_time,INTERVAL 5033 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query3','query 3',5898,'2016-02-01',DATE_ADD(start_time,INTERVAL 5898 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query4','query 4',6870,'2016-02-01',DATE_ADD(start_time,INTERVAL 6870 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query4','query 4',3788,'2016-02-01',DATE_ADD(start_time,INTERVAL 3788 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query4','query 4',4919,'2016-02-01',DATE_ADD(start_time,INTERVAL 4919 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query5','query 5',6366,'2016-02-01',DATE_ADD(start_time,INTERVAL 6366 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query5','query 5',4684,'2016-02-01',DATE_ADD(start_time,INTERVAL 4684 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query5','query 5',6075,'2016-02-01',DATE_ADD(start_time,INTERVAL 6075 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query6','query 6',3743,'2016-02-01',DATE_ADD(start_time,INTERVAL 3743 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query6','query 6',1829,'2016-02-01',DATE_ADD(start_time,INTERVAL 1829 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query6','query 6',2711,'2016-02-01',DATE_ADD(start_time,INTERVAL 2711 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query7','query 7',5860,'2016-02-01',DATE_ADD(start_time,INTERVAL 5860 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query7','query 7',7782,'2016-02-01',DATE_ADD(start_time,INTERVAL 7782 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query7','query 7',6605,'2016-02-01',DATE_ADD(start_time,INTERVAL 6605 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query8','query 8',7050,'2016-02-01',DATE_ADD(start_time,INTERVAL 7050 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query8','query 8',7284,'2016-02-01',DATE_ADD(start_time,INTERVAL 7284 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query8','query 8',8547,'2016-02-01',DATE_ADD(start_time,INTERVAL 8547 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query9','query 9',12219,'2016-02-01',DATE_ADD(start_time,INTERVAL 12219 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query9','query 9',11095,'2016-02-01',DATE_ADD(start_time,INTERVAL 11095 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query9','query 9',11497,'2016-02-01',DATE_ADD(start_time,INTERVAL 11497 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query10','query 10',6278,'2016-02-01',DATE_ADD(start_time,INTERVAL 6278 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query10','query 10',7901,'2016-02-01',DATE_ADD(start_time,INTERVAL 7901 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query10','query 10',5890,'2016-02-01',DATE_ADD(start_time,INTERVAL 5890 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query11','query 11',3700,'2016-02-01',DATE_ADD(start_time,INTERVAL 3700 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query11','query 11',4480,'2016-02-01',DATE_ADD(start_time,INTERVAL 4480 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query11','query 11',5175,'2016-02-01',DATE_ADD(start_time,INTERVAL 5175 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query12','query 12',3920,'2016-02-01',DATE_ADD(start_time,INTERVAL 3920 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query12','query 12',3543,'2016-02-01',DATE_ADD(start_time,INTERVAL 3543 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query12','query 12',4150,'2016-02-01',DATE_ADD(start_time,INTERVAL 4150 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query13','query 13',5531,'2016-02-01',DATE_ADD(start_time,INTERVAL 5531 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query13','query 13',4343,'2016-02-01',DATE_ADD(start_time,INTERVAL 4343 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query13','query 13',3793,'2016-02-01',DATE_ADD(start_time,INTERVAL 3793 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query14','query 14',3029,'2016-02-01',DATE_ADD(start_time,INTERVAL 3029 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query14','query 14',4074,'2016-02-01',DATE_ADD(start_time,INTERVAL 4074 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query14','query 14',3385,'2016-02-01',DATE_ADD(start_time,INTERVAL 3385 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query15','query 15',7890,'2016-02-01',DATE_ADD(start_time,INTERVAL 7890 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query15','query 15',9077,'2016-02-01',DATE_ADD(start_time,INTERVAL 9077 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query15','query 15',7473,'2016-02-01',DATE_ADD(start_time,INTERVAL 7473 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query16','query 16',8665,'2016-02-01',DATE_ADD(start_time,INTERVAL 8665 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query16','query 16',8423,'2016-02-01',DATE_ADD(start_time,INTERVAL 8423 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query16','query 16',9698,'2016-02-01',DATE_ADD(start_time,INTERVAL 9698 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query17','query 17',5266,'2016-02-01',DATE_ADD(start_time,INTERVAL 5266 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query17','query 17',6252,'2016-02-01',DATE_ADD(start_time,INTERVAL 6252 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query17','query 17',7350,'2016-02-01',DATE_ADD(start_time,INTERVAL 7350 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query18','query 18',8024,'2016-02-01',DATE_ADD(start_time,INTERVAL 8024 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query18','query 18',5741,'2016-02-01',DATE_ADD(start_time,INTERVAL 5741 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query18','query 18',7398,'2016-02-01',DATE_ADD(start_time,INTERVAL 7398 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query19','query 19',4586,'2016-02-01',DATE_ADD(start_time,INTERVAL 4586 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query19','query 19',3017,'2016-02-01',DATE_ADD(start_time,INTERVAL 3017 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query19','query 19',4164,'2016-02-01',DATE_ADD(start_time,INTERVAL 4164 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query20','query 20',5900,'2016-02-01',DATE_ADD(start_time,INTERVAL 5900 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query20','query 20',4258,'2016-02-01',DATE_ADD(start_time,INTERVAL 4258 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query20','query 20',4270,'2016-02-01',DATE_ADD(start_time,INTERVAL 4270 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query21','query 21',10938,'2016-02-01',DATE_ADD(start_time,INTERVAL 10938 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query21','query 21',10044,'2016-02-01',DATE_ADD(start_time,INTERVAL 10044 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query21','query 21',10673,'2016-02-01',DATE_ADD(start_time,INTERVAL 10673 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/query22','query 22',5382,'2016-02-01',DATE_ADD(start_time,INTERVAL 5382 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/query22','query 22',3689,'2016-02-01',DATE_ADD(start_time,INTERVAL 3689 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/query22','query 22',5041,'2016-02-01',DATE_ADD(start_time,INTERVAL 5041 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);


#ALL
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_1/ALL','ALL',1097482,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 1097482 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_2/ALL','ALL',1092274,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 1092274 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_100GB_1000DWU.log_3/ALL','ALL',1222502,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 1222502 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_1/ALL','ALL',7905665,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 7905665 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_2/ALL','ALL',7841960,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 7841960 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_100GB_100DWU.log_3/ALL','ALL',7862982,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 7862982 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_1/ALL','ALL',2827867,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 2827867 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_2/ALL','ALL',2334294,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 2334294 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_100GB_400DWU.log_3/ALL','ALL',2288647,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 2288647 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_1/ALL','ALL',2205947,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 2205947 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_2/ALL','ALL',2256881,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 2256881 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_100GB_500DWU.log_3/ALL','ALL',2097218,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 2097218 SECOND),'ETH','SaaS','TPC-H','DW_manual',100000000000,100,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_1/ALL','ALL',152648,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 152648 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_2/ALL','ALL',139130,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 139130 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_10GB_1000DWU.log_3/ALL','ALL',128488,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 128488 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_1/ALL','ALL',1130259,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 1130259 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_2/ALL','ALL',1050740,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 1050740 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_10GB_100DWU.log_3/ALL','ALL',1129264,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 1129264 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_1/ALL','ALL',421850,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 421850 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_2/ALL','ALL',353715,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 353715 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_10GB_400DWU.log_3/ALL','ALL',354696,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 354696 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_1/ALL','ALL',144151,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 144151 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_2/ALL','ALL',124873,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 124873 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_10GB_500DWU.log_3/ALL','ALL',136829,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 136829 SECOND),'ETH','SaaS','TPC-H','DW_manual',10000000000,10,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_1/ALL','ALL',152648,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 152648 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_2/ALL','ALL',139130,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 139130 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(87,'20160201_TCPH_1GB_1000DWU.log_3/ALL','ALL',128488,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 128488 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_1/ALL','ALL',350065,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 350065 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_2/ALL','ALL',288818,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 288818 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(81,'20160201_TCPH_1GB_100DWU.log_3/ALL','ALL',425050,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 425050 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_1/ALL','ALL',153715,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 153715 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_2/ALL','ALL',143589,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 143589 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(84,'20160201_TCPH_1GB_400DWU.log_3/ALL','ALL',133791,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 133791 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_1/ALL','ALL',144151,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 144151 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_2/ALL','ALL',124873,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 124873 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);
INSERT IGNORE INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details) values(85,'20160201_TCPH_1GB_500DWU.log_3/ALL','ALL',136829,'2016-02-01 00:00:00',DATE_ADD(start_time,INTERVAL 136829 SECOND),'ETH','SaaS','TPC-H','DW_manual',1000000000,1,1,0,0);

"

#$MYSQL "
#
##insert ignore into aloja2.clusters  set name='m1000-01',     id_cluster=1, cost_hour=12, type='on-premise', link='http://aloja.bsc.es/?page_id=51';
##insert ignore into aloja2.clusters  set name='al-02', id_cluster=2, cost_hour=7, type='IaaS', link='http://www.windowsazure.com/en-us/pricing/calculator/';
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
