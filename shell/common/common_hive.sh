#HIVE SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

get_hadoop_config_folder() {
  local config_folder_name

  if [ "$HADOOP_CUSTOM_CONFIG" ] ; then
    config_folder_name="$HADOOP_CUSTOM_CONFIG"
  elif [ "$HADOOP_EXTRA_JARS" == "AOP4Hadoop" ] ; then
    config_folder_name="hadoop1_AOP_conf_template"
  elif [ "$(get_hadoop_major_version)" == "2" ]; then
    config_folder_name="hadoop2_conf_template"
  else
    config_folder_name="hadoop1_conf_template"
  fi

  echo -e "$config_folder_name"
}

# Sets the required files to download/copy
set_hive_requires() {
  if [ "$(get_hadoop_major_version)" == "2" ]; then
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION.tar.gz"
    BENCH_REQUIRED_FILES["hive"]="http://apache.rediris.es/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz"
  else
    BENCH_REQUIRED_FILES["$HADOOP_VERSION"]="http://archive.apache.org/dist/hadoop/core/$HADOOP_VERSION/$HADOOP_VERSION-bin.tar.gz"
    BENCH_REQUIRED_FILES["hive"]="https://archive.apache.org/dist/hive/hive-0.13.1/apache-hive-0.13.1-bin.tar.gz"
  fi
}

# Helper to print a line with Hadoop requiered exports
get_hive_exports() {
  local to_export

  if [ "$(get_hadoop_major_version)" == "2" ]; then
    HIVE_VERSION='apache-hive-1.2.1-bin'
  else
    HIVE_VERSION='apache-hive-0.13.1-bin'
  fi

  to_export="$(get_java_exports)
$(get_hadoop_exports)
export HIVE_VERSION='$HIVE_VERSION';
export HIVE_HOME='$(get_local_apps_path)/${HIVE_VERSION}';
export PATH=$PATH:${BENCH_HADOOP_DIR}/bin/:$(get_local_apps_path)/${HIVE_VERSION}/bin:$(get_local_apps_path)/jdk1.7.0_25/bin/;
"
  if [ "$EXECUTE_TPCH" ]; then
    to_export="${to_export} export TPCH_HOME='$(get_local_apps_path)/tpch-hive';"
  fi

  echo -e "$to_export\n"
}

# Returns the the path to the hadoop binary with the proper exports
get_hive_cmd() {
  local hive_exports
  local hive_cmd

  if [ "$EXECUTE_TPCH" ] ; then
    hive_exports="$(get_hive_exports)
      cd $HIVE_HOME/bin;"
  else
    hive_exports="$(get_hive_exports) cd $HIVE_HOME/bin;"
  fi

  EXP=$(get_hive_env)

  SETTINGS="${HIVE_HOME}/${HIVE_SETTINGS_FILENAME}"
  COMMAND="hive -i $SETTINGS"

  hive_cmd="$hive_exports hive -i $SETTINGS"

  echo -e "$hive_cmd"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_hive(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"

  local hive_cmd="$(get_hive_cmd) $cmd"

  logger "DEBUG: Hive command:$hive_cmd"

  if [ "$time_exec" ] ; then
    save_disk_usage "BEFORE"
    restart_monit
    set_bench_start "$bench"
  fi

  # Run the command and time it
  time_cmd_master "$hive_cmd" "$time_exec"

  if [ "$time_exec" ] ; then
    set_bench_end "$bench"
    stop_monit
    save_disk_usage "AFTER"
    save_hadoop "$bench"
  fi
}

prepare_hive_config() {

  $DSH_MASTER "$(get_hive_exports) echo \"set fs.file.impl.disable.cache=true;
  set fs.hdfs.impl.disable.cache=true;
  set hive.auto.convert.join.noconditionaltask=true;
  set hive.auto.convert.join=true;
  set hive.auto.convert.sortmerge.join.noconditionaltask=true;
  set hive.auto.convert.sortmerge.join=true;
  set hive.compactor.abortedtxn.threshold=1000;
  set hive.compactor.check.interval=300;
  set hive.compactor.delta.num.threshold=10;
  set hive.compactor.delta.pct.threshold=0.1f;
  set hive.compactor.initiator.on=false;
  set hive.compactor.worker.threads=0;
  set hive.compactor.worker.timeout=86400;
  set hive.compute.query.using.stats=true;
  set hive.enforce.bucketing=true;
  set hive.enforce.sorting=true;
  set hive.enforce.sortmergebucketmapjoin=true;
  set hive.exec.failure.hooks=org.apache.hadoop.hive.ql.hooks.ATSHook;
  set hive.exec.post.hooks=org.apache.hadoop.hive.ql.hooks.ATSHook;
  set hive.exec.pre.hooks=org.apache.hadoop.hive.ql.hooks.ATSHook;
  set hive.execution.engine=mr;
  set hive.limit.pushdown.memory.usage=0.04;
  set hive.map.aggr=true;
  set hive.mapjoin.bucket.cache.size=10000;
  set hive.mapred.reduce.tasks.speculative.execution=false;
  set hive.metastore.cache.pinobjtypes=Table,Database,Type,FieldSchema,Order;
  set hive.metastore.client.socket.timeout=60;
  set hive.metastore.execute.setugi=true;
  set hive.metastore.warehouse.dir=/apps/hive/warehouse;
  set hive.optimize.bucketmapjoin.sortedmerge=false;
  set hive.optimize.bucketmapjoin=true;
  set hive.optimize.index.filter=true;
  set hive.optimize.mapjoin.mapreduce=true;
  set hive.optimize.reducededuplication.min.reducer=4;
  set hive.optimize.reducededuplication=true;
  set hive.orc.splits.include.file.footer=false;
  set hive.security.authorization.enabled=false;
  set hive.security.metastore.authorization.manager=org.apache.hadoop.hive.ql.security.authorization.StorageBasedAuthorizationProvider;
  set hive.semantic.analyzer.factory.impl=org.apache.hivealog.cli.HCatSemanticAnalyzerFactory;
  set hive.server2.enable.doAs=false;
  set hive.stats.autogather=true;
  set hive.txn.manager=org.apache.hadoop.hive.ql.lockmgr.DummyTxnManager;
  set hive.txn.max.open.batch=1000;
  set hive.txn.timeout=300;
  set hive.vectorized.execution.enabled=true;
  set hive.vectorized.groupby.checkinterval=1024;
  set hive.vectorized.groupby.flush.percent=1;
  set hive.vectorized.groupby.maxentries=1024;\" > $HIVE_HOME/$HIVE_SETTINGS_FILENAME"
}

#get_hive_env(){
#  echo "export HADOOP_PREFIX=${BENCH_HADOOP_DIR} && \
#        export HADOOP_USER_CLASSPATH_FIRST=true && \
#        export PATH=$PATH:$HIVE_HOME/bin:$HADOOP_HOME/bin:$JAVA_HOME/bin && \
#  "
#}
#
#prepare_hive_config() {
#
#subs=$(cat <<EOF
#s,##HADOOP_HOME##,$BENCH_HADOOP_DIR,g;
#s,##HIVE_HOME##,$HIVE_HOME,g;
#EOF
#)
#
#  #to avoid perl warnings
#  export LC_CTYPE=en_US.UTF-8
#  export LC_ALL=en_US.UTF-8
#
#  logger "INFO: Copying Hive and Hive-testbench dirs"
#  $DSH "cp -ru $BENCH_SOURCE_DIR/apache-hive-1.2.0-bin $HIVE_B_DIR/"
#
#  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-env.sh.template > $HIVE_HOME/conf/hive-env.sh"
#  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-default.xml.template > $HIVE_HOME/conf/hive-default.xml"
#  $DSH "/usr/bin/perl -pe \"$subs\" $HIVE_HOME/conf/hive-log4j.properties.template > $HIVE_HOME/conf/hive-log4j.properties"
#  $DSH "/usr/bin/perl -pe \"$subs\" $TPCH_SOURCE_DIR/sample-queries-tpch/$TPCH_SETTINGS_FILE_NAME.template > $TPCH_SOURCE_DIR/sample-queries-tpch/$TPCH_SETTINGS_FILE_NAME"
#}