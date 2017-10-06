# TPC-H benchmark from Todor Ivanov https://github.com/t-ivanov/D2F-Bench/
# Benchmark to test Spark installation and configurations
SPARK_VERSION=$SPARK2_VERSION
HIVE_VERSION=$HIVE2_VERSION
use_spark="true"

# Parameter native type text, orc, parquet, json; default: text
[[ ! "$NATIVE_FORMAT" ]] && NATIVE_FORMAT="text"

# Parameter NATIVE FILTER possible values: 0, 1; default: 0 -> without predication filter
[[ ! "$NATIVE_FILTER" ]] && NATIVE_FILTER="0"

source_file "$ALOJA_REPO_PATH/shell/common/common_TPC-H.sh"
source_file "$ALOJA_REPO_PATH/shell/common/common_spark.sh"
set_spark_requires


BENCH_ENABLED="$(printf '%d ' {1..22})"

# Check supplied benchmarks
check_bench_list

if [ ! "$user_supplied_bench_list" ]; then
    BENCH_LIST="$(remove_bench_validates "$BENCH_LIST" "$BENCH_EXTRA")"
fi

# Check supplied benchmarks
check_bench_list

if [[ ! "$user_supplied_bench_list" ]]; then
    BENCH_LIST="$(remove_bench_validates "$BENCH_LIST" "$BENCH_EXTRA")"
fi

# Set Bench name
BENCH_NAME="TPCH-on-Native_Spark"
NATIVE_SPARK_FOLDER_NAME="native_spark-master"

# Required bench files download mirror
BENCH_REQUIRED_FILES["$NATIVE_SPARK_FOLDER_NAME"]="https://github.com/rradowitz/native_spark/archive/master.zip"

# Local
NATIVE_SPARK_LOCAL_DIR="$(get_local_apps_path)/$NATIVE_SPARK_FOLDER_NAME"

if [[ "$NATIVE_FORMAT" == "text" ]]; then
  NATIVE_INPUT_DIR="/tmp/tpch-generate/$(get_benchmark_data_size_gb)"
  logger "INFO: Setting INPUT_DIR to $NATIVE_INPUT_DIR"
elif [[ "$NATIVE_FORMAT" == "parquet" ]] || [[ "$NATIVE_FORMAT" == "orc" ]]; then
  NATIVE_INPUT_DIR="/apps/hive/warehouse/tpch_${NATIVE_FORMAT}_$(get_benchmark_data_size_gb).db"
  logger "INFO: Setting INPUT_DIR to $NATIVE_INPUT_DIR"
elif [[ "$NATIVE_FORMAT" == "tbl" ]]; then
  NATIVE_DB="tpch_orc_$(get_benchmark_data_size_gb)"
  logger "INFO: Setting INPUT_DIR to read from HIVE table"
else
  logger "WARN: NO INPUT_DIR SET"
fi

# Set output base dir; a subdirectory for each BENCH_CURRENT_NUM_RUN is created
# Info: do not miss last "/"
[[ ! "$NATIVE_OUTPUT_DIR" ]] && NATIVE_OUTPUT_DIR="/native_spark/output/"
# Set the output format that; possible values json, csv, orc, parquet; default: json
[[ ! "$NATIVE_OUT_FORMAT" ]] && NATIVE_OUT_FORMAT="json"
# Set if print out; possible values 0 (off) or 1 (on); default: 1 - if "on" no writing to file
[[ ! "$NATIVE_SPRINT" ]] && NATIVE_SPRINT="1"


benchmark_suite_run() {
  logger "INFO: Running $BENCH_SUITE"

  tpc-h_datagen

  BENCH_CURRENT_NUM_RUN="1" #reset the global counter

  # Iterate at least one time
  while true; do
    [[ "$BENCH_NUM_RUNS" ]] && logger "INFO: Starting iteration $BENCH_CURRENT_NUM_RUN of $BENCH_NUM_RUNS"

    for query in $BENCH_LIST ; do
      logger "INFO: RUNNING Query $query -- current run: $BENCH_CURRENT_NUM_RUN"
      execute_tpchquery_spark "$query"
    done

    # Check if requested to iterate multiple times
    if [[ ! "$BENCH_NUM_RUNS" ]] || [[ "$BENCH_CURRENT_NUM_RUN" -ge "$BENCH_NUM_RUNS" ]] ; then
      break
    else
      BENCH_CURRENT_NUM_RUN="$((BENCH_CURRENT_NUM_RUN + 1))"
    fi
  done

  logger "INFO: DONE executing $BENCH_SUITE"
}

# $1 query number
# jar is expecting 8 args [BenchNum, query, inputdir, outputdir, intputformat, outputformat, screenprint, filter]
# BenchNum for data output_dir
# query for TPCH query
# inputdir for the data input
# outputdir for data output
# TODO add csv / jdbc
# informat of inputdata [text, orc, json, parquet]
# outformat of putputdata [text, orc, json, parquet]
# TODO ADD filter
# filter to turon filter pushdown on or off
# Hive/tbl version expects 7 args [BenchNum, query, outputdir, outputformat, screenprint, filter, DB]
execute_tpchquery_spark() {
  local query="$1"

  local cmd=("--class" "main.scala.TpchQuery")
  if [[ "$NATIVE_FORMAT" == "text" ]]; then
    cmd+=("$NATIVE_SPARK_LOCAL_DIR/spark-tpc-h-queries_2.11-1.0-txt.jar")
    cmd+=("/tmp/tpch-generate/$(get_benchmark_data_size_gb)")
  elif [[ "$NATIVE_FORMAT" == "parquet" ]] || [[ "$NATIVE_FORMAT" == "orc" ]] || [[ "$NATIVE_FORMAT" == "json" ]]; then
    cmd+=("$NATIVE_SPARK_LOCAL_DIR/spark-tpc-h-queries_2.11-1.0-orc.jar" )
    cmd+=("/apps/hive/warehouse/tpch_${NATIVE_FORMAT}_$(get_benchmark_data_size_gb).db")
  elif [[ "$NATIVE_FORMAT" == "tbl" ]]; then
    NATIVE_DB="tpch_orc_$(get_benchmark_data_size_gb)"
  fi

  cmd+=("$NATIVE_OUTPUT_DIR")
  [[ "$NATIVE_FORMAT" == "tbl" ]] || cmd+=("$NATIVE_FORMAT")
  cmd+=("$NATIVE_OUT_FORMAT" "$NATIVE_SPRINT" "$NATIVE_FILTER" "$NATIVE_DB")

  local native_cmd=("${cmd[@]:0:3}" "$BENCH_CURRENT_NUM_RUN" "$query" "${cmd[@]:3}")
  execute_spark "tpch_query_$query" "$(printf '%q ' "${native_cmd[@]}")" "time"
}

benchmark_suite_cleanup() {
  clean_hadoop
}

