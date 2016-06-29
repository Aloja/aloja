#file must be sourced

DBML='aloja_ml';

logger "INFO: Updating DB machine learning tables for $DBML (if necessary)"

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
$MYSQL "ALTER TABLE $DBML.learners ADD legacy int(11) DEFAULT 0;"

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

$MYSQL "ALTER TABLE $DBML.pred_execs MODIFY start_time datetime DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.pred_execs MODIFY end_time datetime DEFAULT CURRENT_TIMESTAMP;"

$MYSQL "ALTER TABLE $DBML.predictions MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.learners MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.trees MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.resolutions MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.minconfigs MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.minconfigs_props MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.minconfigs_centers MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.summaries MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.model_storage MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.precisions MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"
$MYSQL "ALTER TABLE $DBML.observed_trees MODIFY creation_time datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;"

