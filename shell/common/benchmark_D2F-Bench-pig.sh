# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Hive version
# Benchmark to test Hive installation and configurations
source_file "$ALOJA_REPO_PATH/shell/common/common_pig.sh"
set_pig_requires

source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  for query in $BENCH_LIST ; do
    logger "INFO: RUNNING $query"
    execute_query_pig "$query"
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# $1 query number
execute_query_pig() {
  local query="$1"
  execute_pig "$query" "-f $D2F_local_dir/tpch/queries/pig/Q$(only_numbers "$query").pig -param input=$TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR -param output=$TPCH_HDFS_DIR/$TPCH_SCALE_FACTOR/ -t PredicatePushdownOptimizer -t ColumnMapKeyPrune" "time"
}

