CONF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load hadoop defaults
source "$CONF_DIR/common_hadoop.sh"


benchmark_suite_config() {
  export TPCH_B_DIR="${HDD}/aplic"
  export TPCH_SOURCE_DIR="${BENCH_SOURCE_DIR}/tpch-hive"
  export TPCH_HOME="$TPCH_SOURCE_DIR"
  export HIVE_VERSION="apache-hive-1.2.0-bin"
  export HIVE_B_DIR="$TPCH_B_DIR"
  export HIVE_HOME="${TPCH_B_DIR}/${HIVE_VERSION}"
  [ ! "$TPCH_SETTINGS_FILE_NAME" ] && export TPCH_SETTINGS_FILE_NAME="tpch.settings"
  [ ! "$TPCH_DATA_DIR" ] && export TPCH_DATA_DIR=/tpch/tpch-generate
  BENCH_SAVE_PREPARE_LOCATION="${BENCH_LOCAL_DIR}${TPCH_DATA_DIR}"
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  prepare_hive_config
}

benchmark_suite_run() {
  execute_TPCH
}

benchmark_suite_save() {
  : # Empty
}

benchmark_suite_cleanup() {
  stop_hadoop
}

benchmark_TPCH_config_query1() {
   export QUERY="query1"
}

benchmark_TPCH_config_query2() {
   export QUERY="query2"
}

benchmark_TPCH_config_query3() {
   export QUERY="query3"
}

benchmark_TPCH_config_query4() {
   export QUERY="query4"
}

benchmark_TPCH_config_query5() {
   export QUERY="query5"
}

benchmark_TPCH_config_query6() {
   export QUERY="query6"
}

benchmark_TPCH_config_query7() {
   export QUERY="query7"
}

benchmark_TPCH_config_query8() {
   export QUERY="query8"
}

benchmark_TPCH_config_query9() {
   export QUERY="query9"
}

benchmark_TPCH_config_query10() {
   export QUERY="query10"
}

benchmark_TPCH_config_query11() {
   export QUERY="query11"
}

benchmark_TPCH_config_query12() {
   export QUERY="query12"
}

benchmark_TPCH_config_query13() {
   export QUERY="query13"
}

benchmark_TPCH_config_query14() {
   export QUERY="query14"
}

benchmark_TPCH_config_query15() {
   export QUERY="query15"
}

benchmark_TPCH_config_query16() {
   export QUERY="query16"
}

benchmark_TPCH_config_query17() {
   export QUERY="query17"
}

benchmark_TPCH_config_query18() {
   export QUERY="query18"
}

benchmark_TPCH_config_query19() {
   export QUERY="query19"
}

benchmark_TPCH_config_query20() {
   export QUERY="query20"
}

benchmark_TPCH_config_query21() {
   export QUERY="query21"
}

benchmark_TPCH_config_query22() {
   export QUERY="query22"
}