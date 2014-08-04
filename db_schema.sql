-- MySQL dump 10.13  Distrib 5.5.38, for debian-linux-gnu (x86_64)
--
-- Host: 127.0.0.1    Database: aloja2
-- ------------------------------------------------------
-- Server version	5.5.37-0ubuntu0.12.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `BWM`
--

DROP TABLE IF EXISTS `BWM`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BWM` (
  `id_BWM` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `host` varchar(255) DEFAULT NULL,
  `unix_timestamp` int(11) DEFAULT NULL,
  `iface_name` varchar(23) DEFAULT NULL,
  `bytes_out` decimal(20,3) DEFAULT NULL,
  `bytes_in` decimal(20,3) DEFAULT NULL,
  `bytes_total` decimal(20,3) DEFAULT NULL,
  `packets_out` decimal(20,3) DEFAULT NULL,
  `packets_in` decimal(20,3) DEFAULT NULL,
  `packets_total` decimal(20,3) DEFAULT NULL,
  `errors_out` decimal(20,3) DEFAULT NULL,
  `errors_in` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_BWM`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`unix_timestamp`,`iface_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `BWM2`
--

DROP TABLE IF EXISTS `BWM2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `BWM2` (
  `id_BWM` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `host` varchar(255) DEFAULT NULL,
  `unix_timestamp` int(11) DEFAULT NULL,
  `iface_name` varchar(23) DEFAULT NULL,
  `bytes_out/s` decimal(20,3) DEFAULT NULL,
  `bytes_in/s` decimal(20,3) DEFAULT NULL,
  `bytes_total/s` decimal(20,3) DEFAULT NULL,
  `bytes_in` decimal(20,3) DEFAULT NULL,
  `bytes_out` decimal(20,3) DEFAULT NULL,
  `packets_out/s` decimal(20,3) DEFAULT NULL,
  `packets_in/s` decimal(20,3) DEFAULT NULL,
  `packets_total/s` decimal(20,3) DEFAULT NULL,
  `packets_in` decimal(20,3) DEFAULT NULL,
  `packets_out` decimal(20,3) DEFAULT NULL,
  `errors_out/s` decimal(20,3) DEFAULT NULL,
  `errors_in/s` decimal(20,3) DEFAULT NULL,
  `errors_in` decimal(20,3) DEFAULT NULL,
  `errors_out` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_BWM`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`unix_timestamp`,`iface_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2263213 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `JOB_details`
--

DROP TABLE IF EXISTS `JOB_details`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `JOB_details` (
  `id_JOB_details` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `job_name` varchar(255) DEFAULT NULL,
  `JOBID` varchar(255) NOT NULL,
  `JOBNAME` varchar(128) DEFAULT NULL,
  `SUBMIT_TIME` datetime DEFAULT NULL,
  `LAUNCH_TIME` datetime DEFAULT NULL,
  `FINISH_TIME` datetime DEFAULT NULL,
  `JOB_PRIORITY` varchar(255) DEFAULT NULL,
  `USER` varchar(128) DEFAULT NULL,
  `TOTAL_MAPS` int(11) DEFAULT NULL,
  `FAILED_MAPS` int(11) DEFAULT NULL,
  `FINISHED_MAPS` int(11) DEFAULT NULL,
  `TOTAL_REDUCES` int(11) DEFAULT NULL,
  `FAILED_REDUCES` int(11) DEFAULT NULL,
  `Launched map tasks` bigint(20) DEFAULT NULL,
  `Rack-local map tasks` bigint(20) DEFAULT NULL,
  `Launched reduce tasks` bigint(20) DEFAULT NULL,
  `SLOTS_MILLIS_MAPS` bigint(20) DEFAULT NULL,
  `SLOTS_MILLIS_REDUCES` bigint(20) DEFAULT NULL,
  `Data-local map tasks` bigint(20) DEFAULT NULL,
  `FILE_BYTES_WRITTEN` bigint(20) DEFAULT NULL,
  `FILE_BYTES_READ` bigint(20) DEFAULT NULL,
  `HDFS_BYTES_WRITTEN` bigint(20) DEFAULT NULL,
  `HDFS_BYTES_READ` bigint(20) DEFAULT NULL,
  `Bytes Read` bigint(20) DEFAULT NULL,
  `Bytes Written` bigint(20) DEFAULT NULL,
  `Spilled Records` bigint(20) DEFAULT NULL,
  `SPLIT_RAW_BYTES` bigint(20) DEFAULT NULL,
  `Map input records` bigint(20) DEFAULT NULL,
  `Map output records` bigint(20) DEFAULT NULL,
  `Map input bytes` bigint(20) DEFAULT NULL,
  `Map output bytes` bigint(20) DEFAULT NULL,
  `Map output materialized bytes` bigint(20) DEFAULT NULL,
  `Reduce input groups` bigint(20) DEFAULT NULL,
  `Reduce input records` bigint(20) DEFAULT NULL,
  `Reduce output records` bigint(20) DEFAULT NULL,
  `Reduce shuffle bytes` bigint(20) DEFAULT NULL,
  `Combine input records` bigint(20) DEFAULT NULL,
  `Combine output records` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id_JOB_details`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`job_name`),
  KEY `index2` (`id_exec`),
  KEY `index_job_name` (`job_name`),
  KEY `index_JOBNAME` (`JOBNAME`)
) ENGINE=InnoDB AUTO_INCREMENT=289 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `JOB_status`
--

DROP TABLE IF EXISTS `JOB_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `JOB_status` (
  `id_JOB_job_status` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `job_name` varchar(255) NOT NULL,
  `JOBID` varchar(255) NOT NULL,
  `date` datetime DEFAULT NULL,
  `maps` int(11) DEFAULT NULL,
  `shuffle` int(11) DEFAULT NULL,
  `merge` int(11) DEFAULT NULL,
  `reduce` int(11) DEFAULT NULL,
  `waste` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_JOB_job_status`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`job_name`,`date`),
  KEY `index2` (`id_exec`),
  KEY `index_job_name` (`job_name`)
) ENGINE=InnoDB AUTO_INCREMENT=279944 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `JOB_tasks`
--

DROP TABLE IF EXISTS `JOB_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `JOB_tasks` (
  `id_JOB_job_tasks` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `job_name` varchar(255) NOT NULL,
  `JOBID` varchar(255) NOT NULL,
  `TASKID` varchar(128) DEFAULT NULL,
  `TASK_TYPE` varchar(128) DEFAULT NULL,
  `TASK_STATUS` varchar(128) DEFAULT NULL,
  `START_TIME` datetime DEFAULT NULL,
  `FINISH_TIME` datetime DEFAULT NULL,
  `SHUFFLE_TIME` datetime DEFAULT NULL,
  `SORT_TIME` datetime DEFAULT NULL,
  `Bytes Read` bigint(20) DEFAULT NULL,
  `Bytes Written` bigint(20) DEFAULT NULL,
  `FILE_BYTES_WRITTEN` bigint(20) DEFAULT NULL,
  `FILE_BYTES_READ` bigint(20) DEFAULT NULL,
  `HDFS_BYTES_WRITTEN` bigint(20) DEFAULT NULL,
  `HDFS_BYTES_READ` bigint(20) DEFAULT NULL,
  `Spilled Records` bigint(20) DEFAULT NULL,
  `SPLIT_RAW_BYTES` bigint(20) DEFAULT NULL,
  `Map input records` bigint(20) DEFAULT NULL,
  `Map output records` bigint(20) DEFAULT NULL,
  `Map input bytes` bigint(20) DEFAULT NULL,
  `Map output bytes` bigint(20) DEFAULT NULL,
  `Map output materialized bytes` bigint(20) DEFAULT NULL,
  `Reduce input groups` bigint(20) DEFAULT NULL,
  `Reduce input records` bigint(20) DEFAULT NULL,
  `Reduce output records` bigint(20) DEFAULT NULL,
  `Reduce shuffle bytes` bigint(20) DEFAULT NULL,
  `Combine input records` bigint(20) DEFAULT NULL,
  `Combine output records` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id_JOB_job_tasks`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`job_name`,`TASKID`),
  KEY `index2` (`id_exec`),
  KEY `index_job_name` (`job_name`)
) ENGINE=InnoDB AUTO_INCREMENT=90595 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_block_devices`
--

DROP TABLE IF EXISTS `SAR_block_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_block_devices` (
  `id_SAR_block_devices` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(128) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `DEV` varchar(255) DEFAULT NULL,
  `tps` decimal(20,3) DEFAULT NULL,
  `rd_sec/s` decimal(20,3) DEFAULT NULL,
  `wr_sec/s` decimal(20,3) DEFAULT NULL,
  `avgrq-sz` decimal(20,3) DEFAULT NULL,
  `avgqu-sz` decimal(20,3) DEFAULT NULL,
  `await` decimal(20,3) DEFAULT NULL,
  `svctm` decimal(20,3) DEFAULT NULL,
  `%util` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_block_devices`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`,`DEV`)
) ENGINE=InnoDB AUTO_INCREMENT=3365592 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_cpu`
--

DROP TABLE IF EXISTS `SAR_cpu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_cpu` (
  `id_SAR_cpu` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(128) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `CPU` varchar(255) DEFAULT NULL,
  `%user` decimal(20,3) DEFAULT NULL,
  `%nice` decimal(20,3) DEFAULT NULL,
  `%system` decimal(20,3) DEFAULT NULL,
  `%iowait` decimal(20,3) DEFAULT NULL,
  `%steal` decimal(20,3) DEFAULT NULL,
  `%idle` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_cpu`),
  UNIQUE KEY `avoid_duplicates` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_interrupts`
--

DROP TABLE IF EXISTS `SAR_interrupts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_interrupts` (
  `id_SAR_interrupts` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `INTR` varchar(255) DEFAULT NULL,
  `intr/s` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_interrupts`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_io_paging`
--

DROP TABLE IF EXISTS `SAR_io_paging`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_io_paging` (
  `id_SAR_io_paging` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `pgpgin/s` decimal(20,3) DEFAULT NULL,
  `pgpgout/s` decimal(20,3) DEFAULT NULL,
  `fault/s` decimal(20,3) DEFAULT NULL,
  `majflt/s` decimal(20,3) DEFAULT NULL,
  `pgfree/s` decimal(20,3) DEFAULT NULL,
  `pgscank/s` decimal(20,3) DEFAULT NULL,
  `pgscand/s` decimal(20,3) DEFAULT NULL,
  `pgsteal/s` decimal(20,3) DEFAULT NULL,
  `%vmeff` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_io_paging`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_io_rate`
--

DROP TABLE IF EXISTS `SAR_io_rate`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_io_rate` (
  `id_SAR_io_rate` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(128) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `tps` decimal(20,3) DEFAULT NULL,
  `rtps` decimal(20,3) DEFAULT NULL,
  `wtps` decimal(20,3) DEFAULT NULL,
  `bread/s` decimal(20,3) DEFAULT NULL,
  `bwrtn/s` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_io_rate`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_load`
--

DROP TABLE IF EXISTS `SAR_load`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_load` (
  `id_SAR_load` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `runq-sz` decimal(20,3) DEFAULT NULL,
  `plist-sz` decimal(20,3) DEFAULT NULL,
  `ldavg-1` decimal(20,3) DEFAULT NULL,
  `ldavg-5` decimal(20,3) DEFAULT NULL,
  `ldavg-15` decimal(20,3) DEFAULT NULL,
  `blocked` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_load`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_memory`
--

DROP TABLE IF EXISTS `SAR_memory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_memory` (
  `id_SAR_memory` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `frmpg/s` decimal(20,3) DEFAULT NULL,
  `bufpg/s` decimal(20,3) DEFAULT NULL,
  `campg/s` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_memory`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_memory_util`
--

DROP TABLE IF EXISTS `SAR_memory_util`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_memory_util` (
  `id_SAR_memory_util` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `kbmemfree` decimal(20,3) DEFAULT NULL,
  `kbmemused` decimal(20,3) DEFAULT NULL,
  `%memused` decimal(20,3) DEFAULT NULL,
  `kbbuffers` decimal(20,3) DEFAULT NULL,
  `kbcached` decimal(20,3) DEFAULT NULL,
  `kbcommit` decimal(20,3) DEFAULT NULL,
  `%commit` decimal(20,3) DEFAULT NULL,
  `kbactive` decimal(20,3) DEFAULT NULL,
  `kbinact` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_memory_util`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_net_devices`
--

DROP TABLE IF EXISTS `SAR_net_devices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_net_devices` (
  `id_SAR_net_devices` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(128) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `IFACE` varchar(255) DEFAULT NULL,
  `rxpck/s` decimal(20,3) DEFAULT NULL,
  `txpck/s` decimal(20,3) DEFAULT NULL,
  `rxkB/s` decimal(20,3) DEFAULT NULL,
  `txkB/s` decimal(20,3) DEFAULT NULL,
  `rxcmp/s` decimal(20,3) DEFAULT NULL,
  `txcmp/s` decimal(20,3) DEFAULT NULL,
  `rxmcst/s` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_net_devices`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`,`IFACE`)
) ENGINE=InnoDB AUTO_INCREMENT=5923504 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_net_errors`
--

DROP TABLE IF EXISTS `SAR_net_errors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_net_errors` (
  `id_SAR_net_errors` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `IFACE` varchar(255) DEFAULT NULL,
  `rxerr/s` varchar(255) DEFAULT NULL,
  `txerr/s` varchar(255) DEFAULT NULL,
  `coll/s` varchar(255) DEFAULT NULL,
  `rxdrop/s` varchar(255) DEFAULT NULL,
  `txdrop/s` varchar(255) DEFAULT NULL,
  `txcarr/s` varchar(255) DEFAULT NULL,
  `rxfram/s` varchar(255) DEFAULT NULL,
  `rxfifo/s` varchar(255) DEFAULT NULL,
  `txfifo/s` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_net_errors`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`,`IFACE`)
) ENGINE=InnoDB AUTO_INCREMENT=2419330 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_net_sockets`
--

DROP TABLE IF EXISTS `SAR_net_sockets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_net_sockets` (
  `id_SAR_net_sockets` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` varchar(255) DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  `totsck` varchar(255) DEFAULT NULL,
  `tcpsck` varchar(255) DEFAULT NULL,
  `udpsck` varchar(255) DEFAULT NULL,
  `rawsck` varchar(255) DEFAULT NULL,
  `ip-frag` varchar(255) DEFAULT NULL,
  `tcp-tw` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_net_sockets`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_swap`
--

DROP TABLE IF EXISTS `SAR_swap`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_swap` (
  `id_SAR_swap` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `kbswpfree` decimal(20,3) DEFAULT NULL,
  `kbswpused` decimal(20,3) DEFAULT NULL,
  `%swpused` decimal(20,3) DEFAULT NULL,
  `kbswpcad` decimal(20,3) DEFAULT NULL,
  `%swpcad` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_swap`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_swap_util`
--

DROP TABLE IF EXISTS `SAR_swap_util`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_swap_util` (
  `id_SAR_swap_util` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `pswpin/s` decimal(20,3) DEFAULT NULL,
  `pswpout/s` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_swap_util`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SAR_switches`
--

DROP TABLE IF EXISTS `SAR_switches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SAR_switches` (
  `id_SAR_switches` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) DEFAULT NULL,
  `host` varchar(255) DEFAULT NULL,
  `interval` decimal(20,3) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `proc/s` decimal(20,3) DEFAULT NULL,
  `cswch/s` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_SAR_switches`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`date`)
) ENGINE=InnoDB AUTO_INCREMENT=791728 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `VMSTATS`
--

DROP TABLE IF EXISTS `VMSTATS`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `VMSTATS` (
  `id_VMSTATS` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `host` varchar(255) DEFAULT NULL,
  `time` int(11) DEFAULT NULL,
  `r` decimal(20,3) DEFAULT NULL,
  `b` decimal(20,3) DEFAULT NULL,
  `swpd` decimal(20,3) DEFAULT NULL,
  `free` decimal(20,3) DEFAULT NULL,
  `buff` decimal(20,3) DEFAULT NULL,
  `cache` decimal(20,3) DEFAULT NULL,
  `si` decimal(20,3) DEFAULT NULL,
  `so` decimal(20,3) DEFAULT NULL,
  `bi` decimal(20,3) DEFAULT NULL,
  `bo` decimal(20,3) DEFAULT NULL,
  `in` decimal(20,3) DEFAULT NULL,
  `cs` decimal(20,3) DEFAULT NULL,
  `us` decimal(20,3) DEFAULT NULL,
  `sy` decimal(20,3) DEFAULT NULL,
  `id` decimal(20,3) DEFAULT NULL,
  `wa` decimal(20,3) DEFAULT NULL,
  PRIMARY KEY (`id_VMSTATS`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`host`,`time`)
) ENGINE=InnoDB AUTO_INCREMENT=791716 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clusters`
--

DROP TABLE IF EXISTS `clusters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clusters` (
  `id_cluster` int(11) NOT NULL DEFAULT '0',
  `name` varchar(127) DEFAULT NULL,
  `cost_hour` decimal(10,3) DEFAULT NULL,
  `type` varchar(127) DEFAULT NULL,
  `link` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_cluster`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `execs`
--

DROP TABLE IF EXISTS `execs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `execs` (
  `id_exec` int(11) NOT NULL AUTO_INCREMENT,
  `id_cluster` int(11) DEFAULT NULL,
  `exec` varchar(255) DEFAULT NULL,
  `bench` varchar(255) DEFAULT NULL,
  `exe_time` decimal(20,3) DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `net` varchar(255) DEFAULT NULL,
  `disk` varchar(255) DEFAULT NULL,
  `bench_type` varchar(255) DEFAULT NULL,
  `maps` int(11) DEFAULT NULL,
  `iosf` int(11) DEFAULT NULL,
  `replication` int(11) DEFAULT NULL,
  `iofilebuf` int(11) DEFAULT NULL,
  `comp` int(11) DEFAULT NULL,
  `blk_size` int(11) DEFAULT NULL,
  `zabbix_link` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id_exec`),
  UNIQUE KEY `exec_UNIQUE` (`exec`)
) ENGINE=InnoDB AUTO_INCREMENT=84 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hosts`
--

DROP TABLE IF EXISTS `hosts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hosts` (
  `id_host` int(11) NOT NULL AUTO_INCREMENT,
  `host_name` varchar(128) NOT NULL,
  `id_cluster` int(11) NOT NULL,
  `role` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id_host`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-08-04 18:55:54
