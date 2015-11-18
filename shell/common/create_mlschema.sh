#file must be sourced

DBML='aloja_ml';

logger "INFO: Creating DB machine learning tables for $DBML (if necessary)"

$MYSQL_CREATE "
CREATE DATABASE IF NOT EXISTS $DBML;"

$MYSQL_CREATE "
USE $DBML;

CREATE TABLE IF NOT EXISTS learners (
  sid_learner int(11) NOT NULL AUTO_INCREMENT,
  id_learner varchar(255) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  dataslice longtext NOT NULL,
  algorithm varchar(255) NOT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (sid_learner),
  UNIQUE KEY id_learner_UNIQUE (id_learner),
  KEY idx_instance (instance)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS predictions (
  id_prediction int(11) NOT NULL AUTO_INCREMENT,
  id_pred_exec int(11) DEFAULT NULL,
  id_exec int(11) DEFAULT NULL,
  exe_time decimal(20,3) DEFAULT '0',
  outlier int(11) DEFAULT '0',
  pred_time decimal(20,3) DEFAULT '0',
  instance varchar(255) DEFAULT NULL,
  full_instance longtext NOT NULL DEFAULT '',
  id_learner varchar(255) NOT NULL,
  predict_code int(8) DEFAULT '0',
  creation_time datetime NOT NULL,
  PRIMARY KEY (id_prediction),
  UNIQUE id_exec_learner (id_exec,id_pred_exec,id_learner),
  INDEX idx_id_exec_predictions (id_exec),
  KEY idx_exe_time (exe_time),
  FOREIGN KEY (id_learner) REFERENCES learners(id_learner) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS pred_execs (
  id_prediction int(11) NOT NULL AUTO_INCREMENT,
  id_cluster int(11) DEFAULT NULL,
  exec varchar(255) DEFAULT NULL,
  bench varchar(255) DEFAULT NULL,
  exe_time decimal(20,3) DEFAULT NULL,
  start_time datetime DEFAULT NULL,
  end_time datetime DEFAULT NULL,
  net varchar(255) DEFAULT NULL,
  disk varchar(255) DEFAULT NULL,
  bench_type varchar(255) DEFAULT NULL,
  maps int(11) DEFAULT NULL,
  iosf int(11) DEFAULT NULL,
  replication int(11) DEFAULT NULL,
  iofilebuf int(11) DEFAULT NULL,
  comp int(11) DEFAULT NULL,
  blk_size int(11) DEFAULT NULL,
  hadoop_version varchar(127) default NULL,
  zabbix_link varchar(255) DEFAULT NULL,
  valid int DEFAULT 0,
  filter int DEFAULT 0,
  outlier int DEFAULT 0,
  perf_details int DEFAULT 0,
  exec_type varchar(255) DEFAULT 'default',
  datasize decimal(20,3) DEFAULT NULL,
  scale_factor varchar(255) DEFAULT 'N/A',
  PRIMARY KEY (id_prediction),
  KEY idx_bench (bench),
  KEY idx_exe_time (exe_time),
  KEY idx_bench_type (bench_type),
  KEY idx_id_cluster (id_cluster),
  KEY idx_valid (valid),
  KEY idx_filter (filter),
  KEY idx_perf_details (perf_details)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS trees (
  id_findattrs varchar(255) NOT NULL,
  id_learner varchar(255) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  tree_code longtext NOT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (id_findattrs),
  KEY idx_instance (instance),
  FOREIGN KEY (id_learner) REFERENCES learners(id_learner) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS resolutions (
  sid_resolution int(11) NOT NULL AUTO_INCREMENT,
  id_resolution varchar(255) NOT NULL,
  id_learner varchar(255) NOT NULL,
  id_exec int(11) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  dataslice longtext NOT NULL DEFAULT '',
  sigma int(8) NOT NULL,
  outlier_code int(8) DEFAULT 0,
  predicted int(11) DEFAULT 0,
  observed int(11) DEFAULT 0,
  creation_time datetime NOT NULL,
  PRIMARY KEY (sid_resolution),
  KEY idx_instance (instance),
  FOREIGN KEY (id_learner) REFERENCES learners(id_learner) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS minconfigs (
  id_minconfigs varchar(255) NOT NULL,
  id_learner varchar(255) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  dataslice longtext NOT NULL DEFAULT '',
  is_new int(1) NOT NULL DEFAULT 0,
  creation_time datetime NOT NULL,
  PRIMARY KEY (id_minconfigs),
  KEY idx_instance (instance),
  FOREIGN KEY (id_learner) REFERENCES learners(id_learner) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS minconfigs_props (
  sid_minconfigs_props int(11) NOT NULL AUTO_INCREMENT,
  id_minconfigs varchar(255) NOT NULL,
  cluster int(11) NOT NULL,
  MAE decimal(20,3) DEFAULT NULL,
  RAE decimal(20,3) DEFAULT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (sid_minconfigs_props),
  FOREIGN KEY (id_minconfigs) REFERENCES minconfigs(id_minconfigs) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS minconfigs_centers (
  sid_minconfigs_centers int(11) NOT NULL AUTO_INCREMENT,
  id_minconfigs varchar(255) NOT NULL,
  cluster int(11) NOT NULL,
  id_exec int(11) NOT NULL,
  exe_time decimal(20,3) DEFAULT '0',
  bench varchar(255) DEFAULT NULL,
  net varchar(255) DEFAULT NULL,
  disk varchar(255) DEFAULT NULL,
  maps int(11) DEFAULT NULL,
  iosf int(11) DEFAULT NULL,
  replication int(11) DEFAULT NULL,
  iofilebuf int(11) DEFAULT NULL,
  comp int(11) DEFAULT NULL,
  blk_size int(11) DEFAULT NULL,
  id_cluster int(11) DEFAULT NULL,
  bench_type varchar(255) DEFAULT NULL,
  hadoop_version varchar(127) DEFAULT NULL,
  datasize int(11) DEFAULT 0,
  scale_factor varchar(255) DEFAULT NULL,
  support mediumtext DEFAULT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (sid_minconfigs_centers),
  FOREIGN KEY (id_minconfigs) REFERENCES minconfigs(id_minconfigs) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS summaries (
  id_summaries varchar(255) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  dataslice longtext NOT NULL,
  summary longtext NOT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (id_summaries),
  KEY idx_instance (instance)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS model_storage (
  id_hash varchar(255) NOT NULL,
  type varchar(255) NOT NULL,
  file MEDIUMBLOB NOT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (id_hash)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS precisions (
  id_precision varchar(255) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  dataslice longtext NOT NULL,
  diversity longtext NOT NULL,
  precisions longtext NOT NULL,
  discvar varchar(255) NOT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (id_precision,discvar)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS observed_trees (
  id_obstrees varchar(255) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  dataslice longtext NOT NULL,
  tree_code_split longtext NOT NULL,
  tree_code_gain longtext NOT NULL,
  creation_time datetime NOT NULL,
  PRIMARY KEY (id_obstrees),
  KEY idx_instance (instance)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS variable_weights (
  id_varweights varchar(255) NOT NULL,
  instance varchar(255) NOT NULL,
  model longtext NOT NULL,
  dataslice longtext NOT NULL,
  varweight_code longtext NOT NULL,
  creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_varweights),
  INDEX idx_instance (instance)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
"

$MYSQL "ALTER TABLE $DBML.learners MODIFY model longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.trees MODIFY model longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.trees MODIFY tree_code longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.resolutions MODIFY model longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.minconfigs MODIFY model longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.minconfigs_centers MODIFY support mediumtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.summaries MODIFY model longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.summaries MODIFY summary longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.minconfigs_centers ADD bench_type varchar(255);"
$MYSQL "ALTER TABLE $DBML.learners ADD dataslice longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.precisions ADD dataslice longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.summaries ADD dataslice longtext NOT NULL;"
$MYSQL "ALTER TABLE $DBML.minconfigs ADD dataslice longtext NOT NULL DEFAULT '';"
$MYSQL "ALTER TABLE $DBML.resolutions ADD dataslice longtext NOT NULL DEFAULT '';"

## DEPRECATED
#$MYSQL "ALTER TABLE $DBML.predictions ADD datasize int(11) DEFAULT 0,
#  ADD scale_factor varchar(255) DEFAULT NULL, ADD net_maxtxkbs decimal(10,3) DEFAULT 0,
#  ADD net_maxrxkbs decimal(10,3) DEFAULT 0, ADD net_maxtxpcks decimal(10,3) DEFAULT 0,
#  ADD net_maxrxpcks decimal(10,3) DEFAULT 0, ADD net_maxtxcmps decimal(10,3) DEFAULT 0,
#  ADD net_maxrxcmps decimal(10,3) DEFAULT 0, ADD net_maxrxmscts decimal(10,3) DEFAULT 0,
#  ADD disk_maxtps decimal(10,3) DEFAULT 0, ADD disk_maxsvctm decimal(10,3) DEFAULT 0,
#  ADD disk_maxrds decimal(10,3) DEFAULT 0, ADD disk_maxwrs decimal(10,3) DEFAULT 0,
#  ADD disk_maxrqsz decimal(10,3) DEFAULT 0, ADD disk_maxqusz decimal(10,3) DEFAULT 0,
#  ADD disk_maxawait decimal(10,3) DEFAULT 0, ADD disk_maxutil decimal(10,3) DEFAULT 0;"
## END DEPRECATED
## FUNCTION TO CLEAR TABLE
#$MYSQL "ALTER TABLE $DBML.predictions DROP COLUMN id_cluster,
#  DROP COLUMN exec, DROP COLUMN bench,
#  DROP COLUMN start_time, DROP COLUMN end_time,
#  DROP COLUMN net, DROP COLUMN disk,
#  DROP COLUMN bench_type, DROP COLUMN maps,
#  DROP COLUMN iosf, DROP COLUMN replication,
#  DROP COLUMN iofilebuf, DROP COLUMN comp,
#  DROP COLUMN blk_size, DROP COLUMN zabbix_link,
#  DROP COLUMN valid, DROP COLUMN hadoop_version,
#  DROP COLUMN filter, DROP COLUMN name,
#  DROP COLUMN type, DROP COLUMN datanodes,
#  DROP COLUMN provider, DROP COLUMN headnodes,
#  DROP COLUMN vm_size, DROP COLUMN vm_OS,
#  DROP COLUMN vm_cores, DROP COLUMN vm_RAM,
#  DROP COLUMN datasize, DROP COLUMN scale_factor;"
## END FUNCTION TO CLEAR TABLE

$MYSQL "ALTER TABLE $DBML.predictions ADD full_instance longtext NOT NULL DEFAULT '',
  ADD id_pred_exec int(11) DEFAULT NULL,
  MODIFY id_exec int(11) DEFAULT NULL,
  ADD CONSTRAINT id_exec_learner UNIQUE (id_exec,id_pred_exec,id_learner);";

$MYSQL "ALTER TABLE $DBML.minconfigs_centers ADD hadoop_version varchar(127) DEFAULT NULL,
  ADD datasize int(11) DEFAULT 0,
  ADD scale_factor varchar(255) DEFAULT NULL;"

$MYSQL "CREATE INDEX idx_id_exec_predictions ON $DBML.predictions(id_exec);"

$MYSQL "ALTER TABLE $DBML.predictions MODIFY start_time datetime DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.predictions MODIFY end_time datetime DEFAULT CURRENT_TIMESTAMP;"

