#!/usr/bin/env bash

# Script to orchestrate benchmark execution and metrics collection
# NOTE: you need to have your cluster configured first
# for usage execute run_benchs.sh -h

# Load cluster config and common functions

[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
CONF_DIR="$ALOJA_REPO_PATH/shell/conf" #TODO remove when migrated to use ALOJA_REPO_PATH
source "$ALOJA_REPO_PATH/shell/common/include_benchmarks.sh"

logger  "INFO: configs loaded, ready to start"

# 2.) Validate and initialize run

# Check we meet basics and we can continue
validate "$DISK"

# Initialize configs and paths
initialize

# In PaaS this is already setup (or should)
if [ "$clusterType" != "PaaS" ]; then
 # change swappiness and other basic OS configs for benchmarking
 update_OS_config
 # create the directory and copy binaries
 prepare_folder "$DISK"
fi

# Check if needed to download files and configs
install_files

# 3.) Run the benchmarks

benchmark_suite_config

start_time=$(date '+%s')

########################################################
logger  "INFO: Starting $BENCH_SUITE benchmark"

# Benchmark stages

benchmark_suite_run

benchmark_suite_save

logger  "INFO: $(date +"%H:%M:%S") DONE $bench"


########################################################
end_time=$(date '+%s')

benchmark_suite_cleanup

# Save env vars and globals
save_env "$JOB_PATH/config.sh"

# Execute post-process of traces if enabled (https://github.com/Aloja/hadoop-instrumentation)
if [ "$INSTRUMENTATION" == "1" ] ; then
  instrumentation_post_process
fi

if [ "$ALOJA_AUTO_IMPORT" == "1" ] ; then
  logger "INFO: Auto importing run to ALOJA-WEB"
  source_file "$ALOJA_REPO_PATH/shell/common/import_functions.sh"

  import_from_folder "$JOB_NAME" "reload_caches"
  logger "INFO: URL of perf charts http://localhost:8080/perfcharts?execs[]=$id_exec"
fi

logger "INFO: Size and path: $(du -h $JOB_PATH|tail -n 1)"
logger "All done, took $(getElapsedTime startTime) seconds"
