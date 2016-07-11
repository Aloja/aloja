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

# TODO add these fields
#20160302_155418 31424: WARNING: Field FAILED_REDUCES not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field FINISHED_MAPS not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field JOB_PRIORITY not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field LAUNCH_TIME not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field MB_MILLIS_MAPS not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field MB_MILLIS_REDUCES not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field MILLIS_MAPS not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field MILLIS_REDUCES not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field RACK_LOCAL_MAPS not found on table HDI_JOB_tasks
#20160302_155418 31424: WARNING: Field SLOTS_MILLIS_MAPS not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field SLOTS_MILLIS_REDUCES not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field SUBMIT_TIME not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field TOTAL_LAUNCHED_MAPS not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field TOTAL_LAUNCHED_REDUCES not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field TOTAL_MAPS not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field TOTAL_REDUCES not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field USER not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field VCORES_MILLIS_MAPS not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field VCORES_MILLIS_REDUCES not found on table HDI_JOB_tasks
#20160302_155419 31424: WARNING: Field job_name not found on table HDI_JOB_tasks


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
  \`DATA_LOCAL_MAPS\` bigint(20) DEFAULT NULL,

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
  PRIMARY KEY (id_AOP4Hadoop),
  UNIQUE KEY avoid_duplicates_UNIQUE (id_exec),
  KEY index2 (id_exec)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS AOP_nodes_perf (
  id_exec int(11) NOT NULL,
  node1 varchar(255) NOT NULL,
  node2 varchar(255) NOT NULL,
  data int(11) DEFAULT NULL,
  PRIMARY KEY (id_exec, node1, node2),
  UNIQUE KEY avoid_duplicates_UNIQUE (id_exec, node1, node2),
  KEY index2(id_exec)
) ENGINE=InnoDB;
"
logger "INFO: AOP"

# CREATE TABLE IF NOT EXISTS AOP4Hadoop (
#   id_AOP4Hadoop int(11) NOT NULL AUTO_INCREMENT,
#   id_exec int(11) NOT NULL,
#   date datetime DEFAULT NULL,
#   mili_secs int(11) DEFAULT NULL,
#   host_name varchar(127) DEFAULT NULL,
#   PID int(11) DEFAULT NULL,
#   moment varchar(127) DEFAULT NULL,
#   event varchar(127) DEFAULT NULL,
#   extra1 varchar(255) DEFAULT NULL,
#   PRIMARY KEY (id_AOP4Hadoop),
#   UNIQUE KEY avoid_duplicates_UNIQUE (id_exec,date,mili_secs,host_name,event),
#   KEY index2 (id_exec)
# ) ENGINE=InnoDB;


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

$MYSQL "alter table execs
 add column  \`JAVA_XMS\` bigint DEFAULT NULL,
  add column  \`JAVA_XMX\` bigint DEFAULT NULL;"


$MYSQL "alter table execs add column  \`run_num\` int DEFAULT 1;"

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
$MYSQL "alter table aloja_logs.HDI_JOB_tasks ADD COLUMN \`DATA_LOCAL_MAPS\` bigint(20) DEFAULT NULL;"


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

# Azure DW (SaaS)

$MYSQL "delete from execs where disk='SaaS' and bench_type='TPC-H' and (exec_type='DW_manual' OR exec_type='ADLA_manual' OR exec_type='ADLS_manual') ;"

source_file "$ALOJA_REPO_PATH/shell/common/DB/create_SaaS.sh"

# Create aggregate ALL for TPC-H
$MYSQL "
INSERT INTO execs(id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,exec_type,datasize,scale_factor,valid,filter,perf_details,maps)
select
  c.id_cluster,
  if (exec_type='DW_manual',
      CONCAT(substring(exec, 1, locate('/', exec)),'ALL'),
      CONCAT('20160301_TPCH_ADLA_',scale_factor,'GB','_',datanodes,'P_',vm_size,'_',run_num,'/ALL')
  ) exec2,
  'ALL',SUM(exe_time),start_time,DATE_ADD(start_time, INTERVAL SUM(exe_time) SECOND),
  'ETH','SaaS','TPC-H',exec_type,datasize,scale_factor,'1','0','0',datanodes
from execs e join clusters c using (id_cluster)
where bench_type = 'TPC-H' and bench != 'ALL' and c.type = 'SaaS' and exe_time > 1
group by run_num,exec_type,datasize,id_cluster, if (exec_type='DW_manual',1,0)
having count(*) = 22 order by exec2; #161"

# Fix for ML tools
$MYSQL "UPDATE execs SET hadoop_version='0', maps=0, iosf=0, replication=1, iofilebuf=0, comp=0, blk_size=0 WHERE (hadoop_version IS NULL OR maps IS NULL) and bench_type='TPC-H';"




# Update perf aggregates
source_file "$ALOJA_REPO_PATH/shell/common/DB/update_precal_metrics.sh"

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
