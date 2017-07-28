# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Benchmark to test Spark installation and configurations

source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"

SPARK_VERSION="$SPARK2_VERSION" #use spark2
source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
set_spark_requires

# Bench list - queries 1 to 22
BENCH_LIST="6"

# Set Bench name
bench_name="TPCH-on-Native_Spark"
native_spark_folder_name="native_spark-master"

BENCH_REQUIRED_FILES["$native_spark_folder_name"]="https://github.com/rradowitz/native_spark/archive/master.zip"

# Local
native_spark_local_dir="$(get_local_apps_path)/$native_spark_folder_name"
native_spark_local_JarPath="/vagrant/blobs/aplic2/tarballs"
#native_spark_local_JarPath_2="/scratch/local/aplic2/apps/Aloja-nativeSpark-master"

# HDFS
native_spark_hdfs_dir="/$native_spark_folder"
  
# Create Output folder
# logger "INFO: Creating temporary output and native spark folder"
# execute_hadoop_new "$bench_name" "fs -mkdir -p /$native_spark_folder/{output}"

# Set scaleFactor for data input dir
scaleFactor=$TPCH_SCALE_FACTOR
if [ "$TPCH_USE_LOCAL_FACTOR" > 0 ] ; then
  scaleFactor=$TPCH_USE_LOCAL_FACTOR
fi


benchmark_suite_config() {
  initialize_hadoop_vars
  prepare_hadoop_config "$NET" "$DISK" "$BENCH_SUITE"
  start_hadoop

  initialize_spark_vars
  prepare_spark_config
}

benchmark_suite_cleanup() {
  clean_hadoop
}

benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"
  
  logger "INFO: Setting engine to Native-Spark"
  #$ENGINE="Native-Spark"
    
  tpc-h_datagen

  BENCH_CURRENT_NUM_RUN="1" #reset the global counter

  # Iterate at least one time
  while true; do
    [ "$BENCH_NUM_RUNS" ] && logger "INFO: Starting iteration $BENCH_CURRENT_NUM_RUN of $BENCH_NUM_RUNS"

    for query in $BENCH_LIST ; do
      logger "INFO: RUNNING Query $query -- current run: $BENCH_CURRENT_NUM_RUN"
      execute_tpchquery_spark "$query"
    done

    # Check if requested to iterate multiple times
    if [ ! "$BENCH_NUM_RUNS" ] || [[ "$BENCH_CURRENT_NUM_RUN" -ge "$BENCH_NUM_RUNS" ]] ; then
      break
    else
      BENCH_CURRENT_NUM_RUN="$((BENCH_CURRENT_NUM_RUN + 1))"
    fi
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# $1 query number
# jar is expecting 3 args [scaleFactor, BenchNum, query]
# scaleFactor for data input_dir
# BenchNum for data output_dir
# query for TPCH query
execute_tpchquery_spark() {
  #local query="$1"
  execute_spark "tpch_query_$query" "--class main.scala.TpchQuery $native_spark_local_dir/spark-tpc-h-queries_2.11-1.0.jar $scaleFactor $BENCH_CURRENT_NUM_RUN $query" "time"
  #execute_spark "tpch_query_$query" "--class main.scala.TpchQuery $native_spark_local_dir/spark-tpc-h-queries_2.11-1.0.jar $scaleFactor $BENCH_CURRENT_NUM_RUN $query --driver-memory 1024m --executor-memory 1024m" "time"
}
