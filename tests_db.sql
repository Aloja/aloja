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
-- Dumping data for table `BWM`
--
-- WHERE:  1 limit 10

LOCK TABLES `BWM` WRITE;
/*!40000 ALTER TABLE `BWM` DISABLE KEYS */;
/*!40000 ALTER TABLE `BWM` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `BWM2`
--
-- WHERE:  1 limit 10

LOCK TABLES `BWM2` WRITE;
/*!40000 ALTER TABLE `BWM2` DISABLE KEYS */;
INSERT INTO `BWM2` VALUES (1,1,'minerva-1001',1390974830,'eth2',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(2,1,'minerva-1001',1390974830,'eth1',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(3,1,'minerva-1001',1390974830,'eth0',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(4,1,'minerva-1001',1390974830,'ib1',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(5,1,'minerva-1001',1390974830,'ib0',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(6,1,'minerva-1001',1390974830,'bond0',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(7,1,'minerva-1001',1390974830,'total',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(8,1,'minerva-1001',1390974831,'eth3',14909.090,14597.400,29506.490,14612.000,14924.000,105.890,89.910,195.800,90.000,106.000,0.000,0.000,0.000,0.000),(9,1,'minerva-1001',1390974831,'eth2',5870.130,6335.660,12205.790,6342.000,5876.000,91.910,92.910,184.820,93.000,92.000,0.000,0.000,0.000,0.000),(10,1,'minerva-1001',1390974831,'eth1',0.000,123.880,123.880,124.000,0.000,0.000,1.000,1.000,1.000,0.000,0.000,0.000,0.000,0.000);
/*!40000 ALTER TABLE `BWM2` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `JOB_details`
--
-- WHERE:  1 limit 10

LOCK TABLES `JOB_details` WRITE;
/*!40000 ALTER TABLE `JOB_details` DISABLE KEYS */;
INSERT INTO `JOB_details` VALUES (1,1,'job_201401290551_0001','job_201401290551_0001','Create bayes data','2014-01-29 05:51:41','2014-01-29 05:51:42','2014-01-29 05:53:38','NORMAL','npoggi',96,0,96,0,0,98,NULL,NULL,443011,NULL,NULL,2253526,NULL,300635437,24290,14018,300635437,NULL,10272,96,80000,279,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(2,1,'job_201401290551_0002','job_201401290551_0002','DocumentProcessor::DocumentTokenizer: input-folder: /HiBench/Bayes/Input','2014-01-29 05:53:58','2014-01-29 05:53:58','2014-01-29 05:54:35','NORMAL','npoggi',96,0,96,0,0,96,12,NULL,582838,NULL,84,2171990,NULL,297864271,300647437,300635437,297864271,NULL,12000,80000,80000,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(3,1,'job_201401290551_0003','job_201401290551_0003','CollocDriver.generateCollocations:/HiBench/Bayes/Output/vectors/tokenized-documents','2014-01-29 05:54:37','2014-01-29 05:54:37','2014-01-29 06:06:19','NORMAL','npoggi',96,8,96,1,0,104,14,1,3141112,645000,90,33390632917,24505247200,276268208,297879247,297864271,276268208,654736640,14976,80000,323380670,NULL,12048450224,8883090739,17017197,143591595,6915558,8790841922,704422689,524633614),(4,1,'job_201401290551_0004','job_201401290551_0004','CollocDriver.computeNGrams: /HiBench/Bayes/Output/vectors/wordcount','2014-01-29 06:06:19','2014-01-29 06:06:20','2014-01-29 06:08:22','NORMAL','npoggi',1,0,1,1,0,1,NULL,1,86184,25608,1,855434169,623322062,65139318,276268363,276268208,65139318,25565088,155,6915558,6915558,NULL,218234736,232065858,3506624,6915558,1926709,NULL,NULL,NULL),(5,1,'job_201401290551_0005','job_201401290551_0005','DictionaryVectorizer::MakePartialVectors: input-folder: /HiBench/Bayes/Output/vectors/tokenized-documents, dictionary-file: /HiB','2014-01-29 06:08:27','2014-01-29 06:08:27','2014-01-29 06:09:28','NORMAL','npoggi',96,0,96,1,0,96,5,1,402695,38507,91,594203519,295937653,501701,355235846,297864271,501701,160000,14976,80000,80000,NULL,295617647,295938223,100,80000,100,292870819,NULL,NULL),(6,1,'job_201401290551_0006','job_201401290551_0006','PartialVectorMerger::MergePartialVectors','2014-01-29 06:09:29','2014-01-29 06:09:29','2014-01-29 06:10:04','NORMAL','npoggi',1,0,1,1,0,1,NULL,1,12903,10511,1,1044601,499237,501701,501855,501701,501701,200,154,100,100,NULL,498831,499237,100,100,100,NULL,NULL,NULL),(7,1,'job_201401290551_0007','job_201401290551_0007','VectorTfIdf Document Frequency Count running over input: /HiBench/Bayes/Output/vectors/tf-vectors','2014-01-29 06:10:05','2014-01-29 06:10:05','2014-01-29 06:10:40','NORMAL','npoggi',1,0,1,1,0,1,NULL,1,12736,10483,1,848351,401274,579053,501848,501701,579053,57324,147,100,47129,NULL,565548,401274,28662,28662,28662,NULL,47129,28662),(8,1,'job_201401290551_0008','job_201401290551_0008',': MakePartialVectors: input-folder: /HiBench/Bayes/Output/vectors/tf-vectors, dictionary-file: /HiBench/Bayes/Output/vectors/fre','2014-01-29 06:10:41','2014-01-29 06:10:41','2014-01-29 06:11:16','NORMAL','npoggi',1,0,1,1,0,1,NULL,1,13011,10544,1,1046149,499237,498801,1080881,501701,498801,200,147,100,100,NULL,498831,499237,100,100,100,NULL,NULL,NULL),(9,1,'job_201401290551_0009','job_201401290551_0009','PartialVectorMerger::MergePartialVectors','2014-01-29 06:11:17','2014-01-29 06:11:17','2014-01-29 06:11:52','NORMAL','npoggi',1,0,1,1,0,1,NULL,1,13095,10514,1,1038805,496337,498801,498955,498801,498801,200,154,100,100,NULL,495931,496337,100,100,100,NULL,NULL,NULL),(10,1,'job_201401290551_0010','job_201401290551_0010','TrainNaiveBayesJob-IndexInstancesMapper-Reducer','2014-01-29 06:11:58','2014-01-29 06:11:58','2014-01-29 06:12:31','NORMAL','npoggi',1,0,1,1,0,1,1,1,12726,10516,NULL,377183,164929,498318,501046,498801,498318,200,150,100,100,NULL,495441,164921,100,100,100,NULL,100,100);
/*!40000 ALTER TABLE `JOB_details` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `JOB_status`
--
-- WHERE:  1 limit 10

LOCK TABLES `JOB_status` WRITE;
/*!40000 ALTER TABLE `JOB_status` DISABLE KEYS */;
INSERT INTO `JOB_status` VALUES (1,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:41',0,0,0,0,0),(2,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:42',0,0,0,0,0),(3,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:43',0,0,0,0,0),(4,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:44',1,0,0,0,0),(5,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:45',1,0,0,0,0),(6,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:46',1,0,0,0,0),(7,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:47',1,0,0,0,0),(8,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:48',0,0,0,0,0),(9,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:49',0,0,0,0,0),(10,1,'job_201401290551_0001','job_201401290551_0001','2014-01-29 05:51:50',1,0,0,0,0);
/*!40000 ALTER TABLE `JOB_status` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `JOB_tasks`
--
-- WHERE:  1 limit 10

LOCK TABLES `JOB_tasks` WRITE;
/*!40000 ALTER TABLE `JOB_tasks` DISABLE KEYS */;
INSERT INTO `JOB_tasks` VALUES (1,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000097','SETUP','SUCCESS','2014-01-29 05:51:44','2014-01-29 05:51:50',NULL,NULL,NULL,NULL,23475,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(2,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000000','MAP','SUCCESS','2014-01-29 05:51:50','2014-01-29 05:51:56',NULL,NULL,262,3143364,23474,NULL,3143364,369,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(3,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000001','MAP','SUCCESS','2014-01-29 05:51:53','2014-01-29 05:51:59',NULL,NULL,259,3137503,23473,NULL,3137503,366,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(4,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000002','MAP','SUCCESS','2014-01-29 05:51:53','2014-01-29 05:51:59',NULL,NULL,256,3128376,23473,NULL,3128376,363,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(5,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000003','MAP','SUCCESS','2014-01-29 05:51:53','2014-01-29 05:51:59',NULL,NULL,253,3124469,23474,NULL,3124469,360,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(6,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000004','MAP','SUCCESS','2014-01-29 05:51:56','2014-01-29 05:52:02',NULL,NULL,250,3132279,23473,NULL,3132279,357,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(7,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000005','MAP','SUCCESS','2014-01-29 05:51:56','2014-01-29 05:52:02',NULL,NULL,247,3147958,23473,NULL,3147958,354,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(8,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000006','MAP','SUCCESS','2014-01-29 05:51:56','2014-01-29 05:52:02',NULL,NULL,244,3136195,23474,NULL,3136195,351,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(9,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000007','MAP','SUCCESS','2014-01-29 05:51:59','2014-01-29 05:52:05',NULL,NULL,241,3137766,23473,NULL,3137766,348,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(10,1,'job_201401290551_0001','job_201401290551_0001','task_201401290551_0001_m_000008','MAP','SUCCESS','2014-01-29 05:51:59','2014-01-29 05:52:05',NULL,NULL,238,3131549,23473,NULL,3131549,345,NULL,107,1,834,3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `JOB_tasks` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_block_devices`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_block_devices` WRITE;
/*!40000 ALTER TABLE `SAR_block_devices` DISABLE KEYS */;
INSERT INTO `SAR_block_devices` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51','dev8-0',149.000,1752.000,160.000,12.830,0.180,1.180,0.940,14.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:51','dev8-16',700.000,14176.000,0.000,20.250,0.120,0.170,0.140,9.600),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:51','dev8-32',125.000,2912.000,0.000,23.300,0.010,0.100,0.100,1.200),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:51','dev252-0',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:51','dev252-1',147.000,1736.000,64.000,12.240,0.170,1.140,0.930,13.600),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:51','dev252-2',14.000,16.000,96.000,8.000,0.000,0.290,0.290,0.400),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:51','dev252-3',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:52','dev8-0',0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:52','dev8-16',345.000,12944.000,0.000,37.520,0.090,0.260,0.200,6.800),(10,1,'minerva-1001',1.000,'2014-01-29 05:53:52','dev8-32',101.000,2912.000,72.000,29.540,0.000,0.040,0.040,0.400);
/*!40000 ALTER TABLE `SAR_block_devices` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_cpu`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_cpu` WRITE;
/*!40000 ALTER TABLE `SAR_cpu` DISABLE KEYS */;
INSERT INTO `SAR_cpu` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51','-1',2.510,0.000,1.590,0.840,0.000,95.060),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52','-1',6.680,0.000,0.880,0.250,0.000,92.200),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53','-1',7.490,0.000,0.630,0.000,0.000,91.890),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54','-1',4.260,0.000,1.170,0.080,0.000,94.490),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55','-1',3.920,0.000,1.170,0.080,0.000,94.830),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56','-1',5.650,0.000,1.590,0.000,0.000,92.760),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57','-1',8.700,0.000,0.670,0.080,0.000,90.550),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58','-1',4.560,0.000,0.630,0.290,0.000,94.520),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59','-1',0.130,0.000,0.330,0.000,0.000,99.540),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00','-1',0.040,0.000,0.210,0.000,0.000,99.750);
/*!40000 ALTER TABLE `SAR_cpu` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_interrupts`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_interrupts` WRITE;
/*!40000 ALTER TABLE `SAR_interrupts` DISABLE KEYS */;
INSERT INTO `SAR_interrupts` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51','-1',6274.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52','-1',4667.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53','-1',4255.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54','-1',4058.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55','-1',1840.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56','-1',2615.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57','-1',5631.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58','-1',5802.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59','-1',1403.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00','-1',1411.000);
/*!40000 ALTER TABLE `SAR_interrupts` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_io_paging`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_io_paging` WRITE;
/*!40000 ALTER TABLE `SAR_io_paging` DISABLE KEYS */;
INSERT INTO `SAR_io_paging` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',9420.000,80.000,68186.000,16.000,18172.000,0.000,0.000,0.000,0.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',7928.000,36.000,38034.000,1.000,26666.000,0.000,0.000,0.000,0.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',0.000,0.000,32585.000,0.000,11903.000,0.000,0.000,0.000,0.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',4756.000,0.000,44556.000,2.000,24563.000,0.000,0.000,0.000,0.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',10908.000,0.000,35258.000,0.000,2197.000,0.000,0.000,0.000,0.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',14852.000,16.000,54551.000,0.000,2901.000,0.000,0.000,0.000,0.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',984.000,44.000,20703.000,0.000,14705.000,0.000,0.000,0.000,0.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',924.000,8756.000,8554.000,0.000,6172.000,0.000,0.000,0.000,0.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',0.000,0.000,7502.000,0.000,2957.000,0.000,0.000,0.000,0.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',0.000,12.000,6743.000,0.000,2066.000,0.000,0.000,0.000,0.000);
/*!40000 ALTER TABLE `SAR_io_paging` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_io_rate`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_io_rate` WRITE;
/*!40000 ALTER TABLE `SAR_io_rate` DISABLE KEYS */;
INSERT INTO `SAR_io_rate` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',1135.000,1107.000,28.000,20592.000,320.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',446.000,443.000,3.000,15856.000,72.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',0.000,0.000,0.000,0.000,0.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',171.000,171.000,0.000,9704.000,0.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',89.000,89.000,0.000,21816.000,0.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',140.000,134.000,6.000,29712.000,64.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',79.000,66.000,13.000,1968.000,152.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',114.000,60.000,54.000,1848.000,17512.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',0.000,0.000,0.000,0.000,0.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',2.000,0.000,2.000,0.000,24.000);
/*!40000 ALTER TABLE `SAR_io_rate` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_load`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_load` WRITE;
/*!40000 ALTER TABLE `SAR_load` DISABLE KEYS */;
INSERT INTO `SAR_load` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',2.000,782.000,0.240,0.320,0.230,0.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',1.000,782.000,0.240,0.320,0.230,0.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',1.000,784.000,0.240,0.320,0.230,0.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',2.000,782.000,0.240,0.320,0.230,0.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',3.000,782.000,0.300,0.330,0.230,0.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',3.000,782.000,0.300,0.330,0.230,0.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',2.000,787.000,0.300,0.330,0.230,0.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',1.000,790.000,0.300,0.330,0.230,0.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',0.000,790.000,0.300,0.330,0.230,0.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',0.000,790.000,0.280,0.330,0.230,0.000);
/*!40000 ALTER TABLE `SAR_load` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_memory`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_memory` WRITE;
/*!40000 ALTER TABLE `SAR_memory` DISABLE KEYS */;
INSERT INTO `SAR_memory` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',-8316.000,406.000,1948.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',1531.000,3.000,1919.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',-11905.000,0.000,188.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',-2600.000,316.000,3123.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',-44579.000,900.000,13053.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',-67550.000,1002.000,17797.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',-6033.000,2.000,304.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',-1244.000,15.000,207.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',496.000,0.000,137.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',-12.000,2.000,8.000);
/*!40000 ALTER TABLE `SAR_memory` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_memory_util`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_memory_util` WRITE;
/*!40000 ALTER TABLE `SAR_memory_util` DISABLE KEYS */;
INSERT INTO `SAR_memory_util` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',63060772.000,2890120.000,4.380,10704.000,58904.000,8026740.000,8.610,1435064.000,28516.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',63066896.000,2883996.000,4.370,10716.000,66580.000,6989760.000,7.500,1419652.000,34992.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',63019276.000,2931616.000,4.450,10716.000,67332.000,8029608.000,8.610,1472232.000,32348.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',63008876.000,2942016.000,4.460,11980.000,79824.000,8027896.000,8.610,1471488.000,42392.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',62830560.000,3120332.000,4.730,15580.000,132036.000,8027896.000,8.610,1597600.000,86668.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',62560360.000,3390532.000,5.140,19588.000,203224.000,8028072.000,8.610,1796280.000,146764.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',62536228.000,3414664.000,5.180,19596.000,204440.000,8033244.000,8.620,1826112.000,140996.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',62531252.000,3419640.000,5.190,19656.000,205268.000,8036324.000,8.620,1832964.000,138848.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',62533236.000,3417656.000,5.180,19656.000,205816.000,8036424.000,8.620,1832164.000,138960.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',62533188.000,3417704.000,5.180,19664.000,205848.000,8036424.000,8.620,1831664.000,138992.000);
/*!40000 ALTER TABLE `SAR_memory_util` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_net_devices`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_net_devices` WRITE;
/*!40000 ALTER TABLE `SAR_net_devices` DISABLE KEYS */;
INSERT INTO `SAR_net_devices` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth3',18.000,26.000,2.850,3.200,0.000,0.000,1.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:51','lo',39.000,39.000,8.480,8.480,0.000,0.000,0.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth2',16.000,15.000,1.110,0.890,0.000,0.000,1.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:51','virbr0',0.000,0.000,0.000,0.000,0.000,0.000,0.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth1',1.000,0.000,0.120,0.000,0.000,0.000,1.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth0',1.000,0.000,0.120,0.000,0.000,0.000,1.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:51','ib1',0.000,0.000,0.000,0.000,0.000,0.000,0.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:51','ib0',2.000,1.000,0.390,0.190,0.000,0.000,0.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:51','bond0',36.000,41.000,4.200,4.090,0.000,0.000,4.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:53:52','eth3',36.000,35.000,4.750,2.570,0.000,0.000,1.000);
/*!40000 ALTER TABLE `SAR_net_devices` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_net_errors`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_net_errors` WRITE;
/*!40000 ALTER TABLE `SAR_net_errors` DISABLE KEYS */;
INSERT INTO `SAR_net_errors` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth3','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:51','lo','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth2','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:51','virbr0','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth1','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:51','eth0','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:51','ib1','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:51','ib0','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:51','bond0','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00'),(10,1,'minerva-1001',1.000,'2014-01-29 05:53:52','eth3','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00','0.00');
/*!40000 ALTER TABLE `SAR_net_errors` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_net_sockets`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_net_sockets` WRITE;
/*!40000 ALTER TABLE `SAR_net_sockets` DISABLE KEYS */;
INSERT INTO `SAR_net_sockets` VALUES (1,1,'minerva-1001','1','2014-01-29 05-53-51','288','22','16','0','0','1511'),(2,1,'minerva-1001','1','2014-01-29 05-53-52','292','24','16','0','0','1538'),(3,1,'minerva-1001','1','2014-01-29 05-53-53','291','22','16','0','0','1554'),(4,1,'minerva-1001','1','2014-01-29 05-53-54','290','22','16','0','0','1565'),(5,1,'minerva-1001','1','2014-01-29 05-53-55','289','22','16','0','0','1580'),(6,1,'minerva-1001','1','2014-01-29 05-53-56','292','24','16','0','0','1595'),(7,1,'minerva-1001','1','2014-01-29 05-53-57','295','25','16','0','0','1609'),(8,1,'minerva-1001','1','2014-01-29 05-53-58','298','24','16','0','0','1624'),(9,1,'minerva-1001','1','2014-01-29 05-53-59','301','24','16','0','0','1636'),(10,1,'minerva-1001','1','2014-01-29 05-54-00','300','24','16','0','0','1446');
/*!40000 ALTER TABLE `SAR_net_sockets` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_swap`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_swap` WRITE;
/*!40000 ALTER TABLE `SAR_swap` DISABLE KEYS */;
INSERT INTO `SAR_swap` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',27262972.000,0.000,0.000,0.000,0.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',27262972.000,0.000,0.000,0.000,0.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',27262972.000,0.000,0.000,0.000,0.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',27262972.000,0.000,0.000,0.000,0.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',27262972.000,0.000,0.000,0.000,0.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',27262972.000,0.000,0.000,0.000,0.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',27262972.000,0.000,0.000,0.000,0.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',27262972.000,0.000,0.000,0.000,0.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',27262972.000,0.000,0.000,0.000,0.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',27262972.000,0.000,0.000,0.000,0.000);
/*!40000 ALTER TABLE `SAR_swap` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_swap_util`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_swap_util` WRITE;
/*!40000 ALTER TABLE `SAR_swap_util` DISABLE KEYS */;
INSERT INTO `SAR_swap_util` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',0.000,0.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',0.000,0.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',0.000,0.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',0.000,0.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',0.000,0.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',0.000,0.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',0.000,0.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',0.000,0.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',0.000,0.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',0.000,0.000);
/*!40000 ALTER TABLE `SAR_swap_util` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `SAR_switches`
--
-- WHERE:  1 limit 10

LOCK TABLES `SAR_switches` WRITE;
/*!40000 ALTER TABLE `SAR_switches` DISABLE KEYS */;
INSERT INTO `SAR_switches` VALUES (1,1,'minerva-1001',1.000,'2014-01-29 05:53:51',228.000,6761.000),(2,1,'minerva-1001',1.000,'2014-01-29 05:53:52',89.000,4440.000),(3,1,'minerva-1001',1.000,'2014-01-29 05:53:53',58.000,3238.000),(4,1,'minerva-1001',1.000,'2014-01-29 05:53:54',130.000,3822.000),(5,1,'minerva-1001',1.000,'2014-01-29 05:53:55',23.000,1853.000),(6,1,'minerva-1001',1.000,'2014-01-29 05:53:56',25.000,2896.000),(7,1,'minerva-1001',1.000,'2014-01-29 05:53:57',25.000,4422.000),(8,1,'minerva-1001',1.000,'2014-01-29 05:53:58',40.000,5981.000),(9,1,'minerva-1001',1.000,'2014-01-29 05:53:59',25.000,1540.000),(10,1,'minerva-1001',1.000,'2014-01-29 05:54:00',23.000,1434.000);
/*!40000 ALTER TABLE `SAR_switches` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `VMSTATS`
--
-- WHERE:  1 limit 10

LOCK TABLES `VMSTATS` WRITE;
/*!40000 ALTER TABLE `VMSTATS` DISABLE KEYS */;
INSERT INTO `VMSTATS` VALUES (1,1,'minerva-1001',0,0.000,0.000,0.000,63093508.000,8680.000,50816.000,0.000,0.000,11.000,9.000,2.000,3.000,0.000,0.000,99.000,0.000),(2,1,'minerva-1001',1,2.000,0.000,0.000,63091340.000,9080.000,51180.000,0.000,0.000,924.000,0.000,6962.000,8075.000,2.000,3.000,95.000,0.000),(3,1,'minerva-1001',2,2.000,0.000,0.000,63050560.000,10704.000,62172.000,0.000,0.000,12656.000,80.000,6579.000,7214.000,3.000,2.000,94.000,1.000),(4,1,'minerva-1001',3,2.000,0.000,0.000,63057760.000,10716.000,66580.000,0.000,0.000,4692.000,36.000,4421.000,4038.000,6.000,1.000,93.000,0.000),(5,1,'minerva-1001',4,1.000,0.000,0.000,63072480.000,11004.000,67088.000,0.000,0.000,392.000,0.000,3854.000,3028.000,7.000,1.000,92.000,0.000),(6,1,'minerva-1001',5,0.000,1.000,0.000,62982048.000,12520.000,87444.000,0.000,0.000,5904.000,0.000,3262.000,2979.000,4.000,1.000,95.000,0.000),(7,1,'minerva-1001',6,3.000,0.000,0.000,62787516.000,16056.000,147336.000,0.000,0.000,12312.000,0.000,2079.000,1947.000,5.000,1.000,94.000,0.000),(8,1,'minerva-1001',7,1.000,0.000,0.000,62554416.000,19588.000,203224.000,0.000,0.000,11956.000,16.000,2746.000,2865.000,6.000,1.000,93.000,0.000),(9,1,'minerva-1001',8,2.000,0.000,0.000,62535536.000,19628.000,204408.000,0.000,0.000,936.000,8708.000,7505.000,6209.000,9.000,1.000,90.000,0.000),(10,1,'minerva-1001',9,0.000,0.000,0.000,62531500.000,19656.000,205268.000,0.000,0.000,924.000,92.000,3438.000,4021.000,3.000,1.000,96.000,0.000);
/*!40000 ALTER TABLE `VMSTATS` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `clusters`
--
-- WHERE:  1 limit 10

LOCK TABLES `clusters` WRITE;
/*!40000 ALTER TABLE `clusters` DISABLE KEYS */;
INSERT INTO `clusters` VALUES (1,'Local 1',12.000,'Colocated','http://hadoop.bsc.es/?page_id=51'),(2,'Azure Linux',7.000,'IaaS Cloud','http://www.windowsazure.com/en-us/pricing/calculator/');
/*!40000 ALTER TABLE `clusters` ENABLE KEYS */;
UNLOCK TABLES;

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
  `valid` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_exec`),
  UNIQUE KEY `exec_UNIQUE` (`exec`)
) ENGINE=InnoDB AUTO_INCREMENT=223 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `execs`
--
-- WHERE:  1 limit 10

LOCK TABLES `execs` WRITE;
/*!40000 ALTER TABLE `execs` DISABLE KEYS */;
INSERT INTO `execs` VALUES (1,1,'20140129_055025_conf_IB_HDD_b_m12_i20_r1_I32768_c0_z256/bayes','bayes',1159.000,'2014-01-29 05:53:50','2014-01-29 06:13:09','IB','HDD','b',12,20,1,32768,0,256,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140129065350&period=1159',1),(2,1,'20140212_173426_conf_ETH_HDD_b_m12_i10_r3_I4096_c0_z128/pagerank','pagerank',2454.000,'2014-02-12 17:44:33','2014-02-12 18:25:27','ETH','HDD','b',12,10,3,4096,0,128,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140212184433&period=2454',1),(3,1,'20140224_164712_conf_ETH_HDD_b_m12_i10_r1_I65536_c0_z32/pagerank','pagerank',2146.000,'2014-02-24 16:54:33','2014-02-24 17:30:19','ETH','HDD','b',12,10,1,65536,0,32,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140224175433&period=2146',1),(4,1,'20140302_180247_conf_IB_SSD_b_m12_i10_r1_I65536_c2_z256/pagerank','pagerank',1883.000,'2014-03-02 18:09:20','2014-03-02 18:40:43','IB','SSD','b',12,10,1,65536,2,256,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140302190920&period=1883',1),(5,1,'20140302_225333_conf_IB_SSD_b_m12_i10_r1_I65536_c3_z32/sort','sort',585.000,'2014-03-02 22:56:56','2014-03-02 23:06:41','IB','SSD','b',12,10,1,65536,3,32,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140302235656&period=585',1),(6,1,'20140303_034028_conf_IB_SSD_b_m12_i10_r1_I65536_c3_z128/sort','sort',502.000,'2014-03-03 03:43:48','2014-03-03 03:52:10','IB','SSD','b',12,10,1,65536,3,128,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140303044348&period=502',1),(7,1,'20140618_153713_conf_ETH_SSD_b_m12_i10_r1_I65536_c0_z64/bayes','bayes',1158.000,'2014-06-18 17:34:30','2014-06-18 17:53:48','ETH','SSD','b',12,10,1,65536,0,64,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140618173430&period=1158',1),(8,1,'20140618_153713_conf_ETH_SSD_b_m12_i10_r1_I65536_c0_z64/dfsioe_read','dfsioe_read',3294.000,'2014-06-18 17:59:42','2014-06-18 18:54:36','ETH','SSD','b',12,10,1,65536,0,64,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140618175942&period=3294',1),(9,1,'20140618_153713_conf_ETH_SSD_b_m12_i10_r1_I65536_c0_z64/dfsioe_write','dfsioe_write',432.000,'2014-06-18 18:55:47','2014-06-18 19:02:59','ETH','SSD','b',12,10,1,65536,0,64,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140618185547&period=432',1),(10,1,'20140618_153713_conf_ETH_SSD_b_m12_i10_r1_I65536_c0_z64/kmeans','kmeans',1236.000,'2014-06-18 16:31:21','2014-06-18 16:51:57','ETH','SSD','b',12,10,1,65536,0,64,'http://minerva.bsc.es:8099/zabbix/screens.php?&fullscreen=0&elementid=19&stime=20140618163122&period=1236',1);
/*!40000 ALTER TABLE `execs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `execs_conf_parameters`
--

DROP TABLE IF EXISTS `execs_conf_parameters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `execs_conf_parameters` (
  `id_execs_conf_parameters` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `job_name` varchar(255) NOT NULL,
  `parameter_name` varchar(255) NOT NULL,
  `parameter_value` varchar(255) NOT NULL,
  PRIMARY KEY (`id_execs_conf_parameters`),
  UNIQUE KEY `avoid_duplicates_UNIQUE` (`id_exec`,`job_name`,`parameter_name`),
  KEY `index2` (`id_exec`),
  KEY `index_job_name` (`job_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4377 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `execs_conf_parameters`
--
-- WHERE:  1 limit 10

LOCK TABLES `execs_conf_parameters` WRITE;
/*!40000 ALTER TABLE `execs_conf_parameters` DISABLE KEYS */;
INSERT INTO `execs_conf_parameters` VALUES (1,7,'job_201406181732_0011','fs.s3n.impl','org.apache.hadoop.fs.s3native.NativeS3FileSystem'),(2,7,'job_201406181732_0011','mapred.task.cache.levels','2'),(3,7,'job_201406181732_0011','hadoop.tmp.dir','/scratch/ssd/npoggi/hadoop-hibench_3/hadoop'),(4,7,'job_201406181732_0011','hadoop.native.lib','true'),(5,7,'job_201406181732_0011','map.sort.class','org.apache.hadoop.util.QuickSort'),(6,7,'job_201406181732_0011','dfs.namenode.decommission.nodes.per.interval','5'),(7,7,'job_201406181732_0011','dfs.https.need.client.auth','false'),(8,7,'job_201406181732_0011','ipc.client.idlethreshold','4000'),(9,7,'job_201406181732_0011','dfs.datanode.data.dir.perm','755'),(10,7,'job_201406181732_0011','mapred.system.dir','${hadoop.tmp.dir}/mapred/system');
/*!40000 ALTER TABLE `execs_conf_parameters` ENABLE KEYS */;
UNLOCK TABLES;

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

--
-- Dumping data for table `hosts`
--
-- WHERE:  1 limit 10

LOCK TABLES `hosts` WRITE;
/*!40000 ALTER TABLE `hosts` DISABLE KEYS */;
INSERT INTO `hosts` VALUES (1,'minerva-1001',1,'master'),(2,'minerva-1002',1,'slave'),(3,'minerva-1003',1,'slave'),(4,'minerva-1004',1,'slave'),(5,'al-1001',2,'master'),(6,'al-1002',2,'slave'),(7,'al-1003',2,'slave'),(8,'al-1004',2,'slave');
/*!40000 ALTER TABLE `hosts` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-08-21 11:07:49
