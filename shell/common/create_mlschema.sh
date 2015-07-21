#file must be sourced

logger "INFO: Creating DB machine learning tables for $DB (if necessary)"

$MYSQL "

CREATE TABLE IF NOT EXISTS \`learners\` (
  \`sid_learner\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_learner\` varchar(255) NOT NULL,
  \`instance\` varchar(255) NOT NULL,
  \`model\` longtext NOT NULL,
  \`algorithm\` varchar(255) NOT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`sid_learner\`),
  UNIQUE KEY \`id_learner_UNIQUE\` (\`id_learner\`),
  KEY \`idx_instance\` (\`instance\`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS \`predictions\` (
  \`id_prediction\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_exec\` int(11) NOT NULL,
  \`id_cluster\` int(11) DEFAULT NULL,
  \`exec\` varchar(255) DEFAULT NULL,
  \`bench\` varchar(255) DEFAULT NULL,
  \`exe_time\` decimal(20,3) DEFAULT '0',
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
  \`valid\` int(11) DEFAULT '1',
  \`hadoop_version\` varchar(127) DEFAULT NULL,
  \`filter\` int(11) DEFAULT '0',
  \`outlier\` int(11) DEFAULT '0',
  \`pred_time\` decimal(20,3) DEFAULT '0',
  \`instance\` varchar(255) DEFAULT NULL,
  \`id_learner\` varchar(255) DEFAULT NULL,
  \`predict_code\` int(8) DEFAULT '0',
  \`name\` varchar(127) DEFAULT NULL,
  \`type\` varchar(127) DEFAULT NULL,
  \`datanodes\` int(11) DEFAULT NULL,
  \`provider\` varchar(127) DEFAULT NULL,
  \`headnodes\` int(11) DEFAULT NULL,
  \`vm_size\` varchar(127) DEFAULT NULL,
  \`vm_OS\` varchar(127) DEFAULT NULL,
  \`vm_cores\` int(11) DEFAULT NULL,
  \`vm_RAM\` decimal(10,3) DEFAULT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`id_prediction\`),
  KEY \`idx_bench\` (\`bench\`),
  KEY \`idx_exe_time\` (\`exe_time\`),
  KEY \`idx_bench_type\` (\`bench_type\`),
  FOREIGN KEY (\`id_learner\`) REFERENCES learners(\`id_learner\`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`trees\` (
  \`id_findattrs\` varchar(255) NOT NULL,
  \`id_learner\` varchar(255) NOT NULL,
  \`instance\` varchar(255) NOT NULL,
  \`model\` longtext NOT NULL,
  \`tree_code\` longtext NOT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`id_findattrs\`),
  KEY \`idx_instance\` (\`instance\`),
  FOREIGN KEY (\`id_learner\`) REFERENCES learners(\`id_learner\`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`resolutions\` (
  \`sid_resolution\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_resolution\` varchar(255) NOT NULL,
  \`id_learner\` varchar(255) NOT NULL,
  \`id_exec\` int(11) NOT NULL,
  \`instance\` varchar(255) NOT NULL,
  \`model\` longtext NOT NULL,
  \`sigma\` int(8) NOT NULL,
  \`outlier_code\` int(8) DEFAULT 0,  
  \`predicted\` int(11) DEFAULT 0,  
  \`observed\` int(11) DEFAULT 0, 
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`sid_resolution\`),
  KEY \`idx_instance\` (\`instance\`),
  FOREIGN KEY (\`id_learner\`) REFERENCES learners(\`id_learner\`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`minconfigs\` (
  \`id_minconfigs\` varchar(255) NOT NULL,
  \`id_learner\` varchar(255) NOT NULL,
  \`instance\` varchar(255) NOT NULL,
  \`model\` longtext NOT NULL,
  \`is_new\` int(1) NOT NULL DEFAULT 0,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`id_minconfigs\`),
  KEY \`idx_instance\` (\`instance\`),
  FOREIGN KEY (\`id_learner\`) REFERENCES learners(\`id_learner\`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`minconfigs_props\` (
  \`sid_minconfigs_props\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_minconfigs\` varchar(255) NOT NULL,
  \`cluster\` int(11) NOT NULL,
  \`MAE\` decimal(20,3) DEFAULT NULL,
  \`RAE\` decimal(20,3) DEFAULT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`sid_minconfigs_props\`),
  FOREIGN KEY (\`id_minconfigs\`) REFERENCES minconfigs(\`id_minconfigs\`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`minconfigs_centers\` (
  \`sid_minconfigs_centers\` int(11) NOT NULL AUTO_INCREMENT,
  \`id_minconfigs\` varchar(255) NOT NULL,
  \`cluster\` int(11) NOT NULL,
  \`id_exec\` int(11) NOT NULL,
  \`exe_time\` decimal(20,3) DEFAULT '0',
  \`bench\` varchar(255) DEFAULT NULL,
  \`net\` varchar(255) DEFAULT NULL,
  \`disk\` varchar(255) DEFAULT NULL,
  \`maps\` int(11) DEFAULT NULL,
  \`iosf\` int(11) DEFAULT NULL,
  \`replication\` int(11) DEFAULT NULL,
  \`iofilebuf\` int(11) DEFAULT NULL,
  \`comp\` int(11) DEFAULT NULL,
  \`blk_size\` int(11) DEFAULT NULL,
  \`id_cluster\` int(11) DEFAULT NULL,
  \`bench_type\` varchar(255) DEFAULT NULL,
  \`support\` mediumtext DEFAULT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`sid_minconfigs_centers\`),
  FOREIGN KEY (\`id_minconfigs\`) REFERENCES minconfigs(\`id_minconfigs\`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`summaries\` (
  \`id_summaries\` varchar(255) NOT NULL,
  \`instance\` varchar(255) NOT NULL,
  \`model\` longtext NOT NULL,
  \`summary\` longtext NOT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`id_summaries\`),
  KEY \`idx_instance\` (\`instance\`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`model_storage\` (
  \`id_hash\` varchar(255) NOT NULL,
  \`type\` varchar(255) NOT NULL,
  \`file\` MEDIUMBLOB NOT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`id_hash\`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS \`precisions\` (
  \`id_precision\` varchar(255) NOT NULL,
  \`instance\` varchar(255) NOT NULL,
  \`model\` longtext NOT NULL,
  \`diversity\` longtext NOT NULL,
  \`precisions\` longtext NOT NULL,
  \`discvar\` varchar(255) NOT NULL,
  \`creation_time\` datetime NOT NULL,
  PRIMARY KEY (\`id_precision\`,\`discvar\`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

"

$MYSQL "ALTER TABLE \`learners\` MODIFY \`model\` longtext NOT NULL;"
$MYSQL "ALTER TABLE \`trees\` MODIFY \`model\` longtext NOT NULL;"
$MYSQL "ALTER TABLE \`trees\` MODIFY \`tree_code\` longtext NOT NULL;"
$MYSQL "ALTER TABLE \`resolutions\` MODIFY \`model\` longtext NOT NULL;"
$MYSQL "ALTER TABLE \`minconfigs\` MODIFY \`model\` longtext NOT NULL;"
$MYSQL "ALTER TABLE \`minconfigs_centers\` MODIFY \`support\` mediumtext NOT NULL;"
$MYSQL "ALTER TABLE \`summaries\` MODIFY \`model\` longtext NOT NULL"
$MYSQL "ALTER TABLE \`summaries\` MODIFY \`summary\` longtext NOT NULL;"
$MYSQL "ALTER TABLE \`minconfigs_centers\` ADD \`bench_type\` varchar(255) ;"

#$MYSQL "ALTER TABLE \`learners\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`predictions\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`trees\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`resolutions\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`minconfigs\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`minconfigs_props\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`minconfigs_centers\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`summaries\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
#$MYSQL "ALTER TABLE \`model_storage\` MODIFY \`creation_time\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"

