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

$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLPrediction Default','mlprediction',1,'MLPrediction Default','/mlprediction?benchs[]=terasort&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&learn=regtree&umodel=1&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLFindAttrs Default','mlfindattributes',1,'MLFindAttrs Default','/mlfindattributes?benchs[]=terasort&id_clusters[]=1&disks[]=HDD&disks[]=SSD&mapss[]=4&comps[]=0&replications[]=1&blk_sizes[]=128&iosfs[]=10&iofilebufs[]=65536&iofilebufs[]=131072&current_model=ee7c939fefa656a3f82f80002ed39c1d&unseen=1&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLParamEval Default','mlparameval',1,'MLParamEval Default','/mlparameval?benchs[]=terasort&id_clusters[]=1&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&current_model=c26c7cb6440534304333eb1d66cd33fc&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLOutliers Default','mloutliers',1,'MLOutliers Default','/mloutliers?benchs[]=terasort&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&current_model=c26c7cb6440534304333eb1d66cd33fc&sigma=1&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLSummaries Default','mlsummaries',1,'MLSummaries Default','/mlsummaries?benchs[]=sort&benchs[]=terasort&benchs[]=wordcount&disks[]=HDD&disks[]=SSD&feature=Benchmark&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLDataCollapse Default','mldatacollapse',1,'MLDataCollapse Default','/mldatacollapse?benchs[]=bayes&benchs[]=sort&benchs[]=terasort&benchs[]=wordcount&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&iofilebufs[]=65536&iofilebufs[]=131072&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLCrossVariables Default','mlcrossvar',1,'MLCrossVariables Default','/mlcrossvar?variable1=maps&variable2=exe_time&benchs[]=terasort&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLCrossVariables3D Default','mlcrossvar3d',1,'MLCrossVariables3D Default','/mlcrossvar3d?variable1=maps&variable2=net&benchs[]=terasort&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLCrossVariables3DFA Default','mlcrossvar3dfa',1,'MLCrossVariables3DFA Default','/mlcrossvar3dfa?variable1=maps&variable2=net&benchs[]=terasort&id_clusters[]=1&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&blk_sizes[]=128&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&current_model=&unseen=1&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLMinConfigs Default','mlminconfigs',1,'MLMinConfigs Default','/mlminconfigs?benchs[]=terasort&disks[]=HDD&disks[]=SSD&comps[]=0&replications[]=1&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&learn=regtree&umodel=1&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')"
#$MYSQL "REPLACE INTO aloja2.filters_presets (name,screen,preset,description,URL) VALUES ('MLNewConfigs Default','mlnewconfigs',1,'MLNewConfigs Default','/mlnewconfigs?benchs[]=terasort&disks[]=HDD&disks[]=SSD&datanodess[]=3&vm_sizes[]=SYS-6027R-72RF&vm_coress[]=12&vm_RAMs[]=128.000&types[]=On-premise&comps[]=0&replications[]=1&iofilebufs[]=32768&iofilebufs[]=65536&iofilebufs[]=131072&hadoop_versions[]=1&learn=regtree&allunchecked=&selected-groups=&datefrom=&dateto=&minexetime=&maxexetime=')·

