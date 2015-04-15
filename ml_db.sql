DROP TABLE IF EXISTS `learners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `learners` (
  `sid_learner` int(11) NOT NULL AUTO_INCREMENT,
  `id_learner` varchar(255) NOT NULL,
  `instance` varchar(255) NOT NULL,
  `model` varchar(1024) NOT NULL,
  `algorithm` varchar(255) NOT NULL,
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`sid_learner`),
  UNIQUE KEY `id_learner_UNIQUE` (`id_learner`),
  KEY `idx_instance` (`instance`),
  KEY `idx_model` (`model`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `predictions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `predictions` (
  `id_prediction` int(11) NOT NULL AUTO_INCREMENT,
  `id_exec` int(11) NOT NULL,
  `id_cluster` int(11) DEFAULT NULL,
  `exec` varchar(255) DEFAULT NULL,
  `bench` varchar(255) DEFAULT NULL,
  `exe_time` decimal(20,3) DEFAULT '0',
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
  `valid` int(11) DEFAULT '1',
  `hadoop_version` varchar(127) DEFAULT NULL,
  `filter` int(11) DEFAULT '0',
  `outlier` int(11) DEFAULT '0',
  `pred_time` decimal(20,3) DEFAULT '0',
  `instance` varchar(255) DEFAULT NULL,
  `id_learner` varchar(255) DEFAULT NULL,
  `predict_code` int(8) DEFAULT '0',
  `name` varchar(127) DEFAULT NULL,
  `type` varchar(127) DEFAULT NULL,
  `datanodes` int(11) DEFAULT NULL,
  `provider` varchar(127) DEFAULT NULL,
  `headnodes` int(11) DEFAULT NULL,
  `vm_size` varchar(127) DEFAULT NULL,
  `vm_OS` varchar(127) DEFAULT NULL,
  `vm_cores` int(11) DEFAULT NULL,
  `vm_RAM` decimal(10,3) DEFAULT NULL,
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`id_prediction`),
  KEY `idx_bench` (`bench`),
  KEY `idx_exe_time` (`exe_time`),
  KEY `idx_bench_type` (`bench_type`),
  FOREIGN KEY (`id_learner`) REFERENCES learners(`id_learner`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;


DROP TABLE IF EXISTS `trees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `trees` (
  `id_findattrs` varchar(255) NOT NULL,
  `id_learner` varchar(255) NOT NULL,
  `instance` varchar(255) NOT NULL,
  `model` varchar(1024) NOT NULL,
  `tree_code` varchar(8192) NOT NULL,
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`id_findattrs`),
  KEY `idx_instance` (`instance`),
  KEY `idx_model` (`model`),
  FOREIGN KEY (`id_learner`) REFERENCES learners(`id_learner`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `resolutions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `resolutions` (
  `sid_resolution` int(11) NOT NULL AUTO_INCREMENT,
  `id_resolution` varchar(255) NOT NULL,
  `id_learner` varchar(255) NOT NULL,
  `id_exec` int(11) NOT NULL,
  `instance` varchar(255) NOT NULL,
  `model` varchar(1024) NOT NULL,
  `outlier_code` int(8) DEFAULT 0,  
  `predicted` int(11) DEFAULT 0,  
  `observed` int(11) DEFAULT 0, 
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`sid_resolution`),
  KEY `idx_instance` (`instance`),
  KEY `idx_model` (`model`),
  FOREIGN KEY (`id_learner`) REFERENCES learners(`id_learner`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `minconfigs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `minconfigs` (
  `id_minconfigs` varchar(255) NOT NULL,
  `id_learner` varchar(255) NOT NULL,
  `instance` varchar(255) NOT NULL,
  `model` varchar(1024) NOT NULL,
  `is_new` int(1) NOT NULL DEFAULT 0,
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`id_minconfigs`),
  KEY `idx_instance` (`instance`),
  KEY `idx_model` (`model`),
  FOREIGN KEY (`id_learner`) REFERENCES learners(`id_learner`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `minconfigs_props`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `minconfigs_props` (
  `sid_minconfigs_props` int(11) NOT NULL AUTO_INCREMENT,
  `id_minconfigs` varchar(255) NOT NULL,
  `cluster` int(11) NOT NULL,
  `MAE` decimal(20,3) DEFAULT NULL,
  `RAE` decimal(20,3) DEFAULT NULL,
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`sid_minconfigs_props`),
  FOREIGN KEY (`id_minconfigs`) REFERENCES minconfigs(`id_minconfigs`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `minconfigs_centers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `minconfigs_centers` (
  `sid_minconfigs_centers` int(11) NOT NULL AUTO_INCREMENT,
  `id_minconfigs` varchar(255) NOT NULL,
  `cluster` int(11) NOT NULL,
  `id_exec` int(11) NOT NULL,
  `exe_time` decimal(20,3) DEFAULT '0',
  `bench` varchar(255) DEFAULT NULL,
  `net` varchar(255) DEFAULT NULL,
  `disk` varchar(255) DEFAULT NULL,
  `maps` int(11) DEFAULT NULL,
  `iosf` int(11) DEFAULT NULL,
  `replication` int(11) DEFAULT NULL,
  `iofilebuf` int(11) DEFAULT NULL,
  `comp` int(11) DEFAULT NULL,
  `blk_size` int(11) DEFAULT NULL,
  `id_cluster` int(11) DEFAULT NULL,
  `support` varchar(4096) DEFAULT NULL,
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`sid_minconfigs_centers`),
  FOREIGN KEY (`id_minconfigs`) REFERENCES minconfigs(`id_minconfigs`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `summaries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `summaries` (
  `id_summaries` varchar(255) NOT NULL,
  `instance` varchar(255) NOT NULL,
  `model` varchar(1024) NOT NULL,
  `summary` varchar(65536) NOT NULL,
  `creation_time` datetime NOT NULL DEFAULT NOW(),
  PRIMARY KEY (`id_summaries`),
  KEY `idx_instance` (`instance`),
  KEY `idx_model` (`model`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;

