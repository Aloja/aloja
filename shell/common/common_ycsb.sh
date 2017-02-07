#YCSB SPECIFIC FUNCTIONS
source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"
set_hadoop_requires

# Sets the required files to download/copy
set_ycsb_requires() {

  [ ! "$YCSB_VERSION" ] && die "No YCSB_VERSION specified"

  # add ycsb requirements
  YCSB_FOLDER="ycsb-${YCSB_VERSION}"
  BENCH_REQUIRED_FILES["${YCSB_FOLDER}"]="https://github.com/brianfrankcooper/YCSB/releases/download/${YCSB_VERSION}/ycsb-${YCSB_VERSION}.tar.gz"

  # workload config for YCSB
  BENCH_CONFIG_FOLDERS="$BENCH_CONFIG_FOLDERS ${YCSB_FOLDER}_conf_template"
}

# Returns the the path to the ycsb binary with the proper exports
get_ycsb_cmd() {

  local ycsb_bin

  ycsb_bin="$YCSB_HOME/bin/"
  echo "$(get_java_exports)"
  echo "export PATH=\$PATH:\${JAVA_HOME}/bin"
  echo "cd ${YCSB_HOME}"
  echo "$ycsb_bin"
}

# Performs the actual benchmark execution
# $1 benchmark name
# $2 command
# $3 if to time exec
execute_ycsb(){
  local bench="$1"
  local cmd="$2"
  local time_exec="$3"
  local ycsb_cmd

  ycsb_cmd="$(get_ycsb_cmd)$cmd"

  if [ "$time_exec" ] ; then
    execute_master "$bench: HDFS capacity before" "${chdir}$(get_hadoop_cmd) fs -df"
  fi

  # Run the command and time it
  execute_master "$bench" "export JAVA_HOME=${JAVA_HOME}; export PATH=\$PATH:${JAVA_HOME}/bin; $ycsb_cmd" "$time_exec" "dont_save"

  # Stop metrics monitors and save bench (if needed)
  if [ "$time_exec" ] ; then
    execute_master "$bench: HDFS capacity after" "${chdir}$(get_hadoop_cmd) fs -df"
    save_ycsb "$bench"
  fi
}

initialize_ycsb_vars() {

  YCSB_HOME="$(get_local_apps_path)/${YCSB_FOLDER}"
  YCSB_CONF_DIR="$(get_ycsb_conf_dir)"
}

# Sets the substitution values for the YCSB config
#get_ycsb_substitutions() {
#
#  cat <<EOF
#s,##YCSB_RECORDCOUNT##,$BENCH_DATA_SIZE,g;
#s,##YCSB_OPERATIONCOUNT##,$YCSB_OPERATIONCOUNT,g;
#EOF
#}

get_ycsb_conf_dir() {
  echo -e "$YCSB_HOME/workloads"
}

#prepare_ycsb_config() {
#  logger "INFO: Preparing YCSB run specific config"
#  $DSH "cp -r $(get_local_configs_path)/${YCSB_FOLDER}_conf_template/* $YCSB_CONF_DIR/"
#  subs=$(get_ycsb_substitutions)
#  $DSH "/usr/bin/perl -i -pe \"$subs\" $YCSB_CONF_DIR/*"
#}


# $1 bench name
save_ycsb() {

  [ ! "$1" ] && die "No bench supplied to ${FUNCNAME[0]}"

  local bench_name="$1"
  local bench_name_num="$(get_bench_name_with_num "$bench_name")"

  # Create the logs dir
  $DSH_MASTER "mkdir -p $JOB_PATH/$bench_name_num/ycsb_logs;"

  # Save ycsb logs
  $DSH_MASTER "mv $HDD/ycsb_logs/* $JOB_PATH/$bench_name_num/ycsb_logs/ 2> /dev/null"

  save_hbase "$bench_name"
}

