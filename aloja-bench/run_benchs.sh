#!/usr/bin/env bash

# Script to orchestrate benchmark execution and metrics collection
# NOTE: you need to have your cluster configured first
# for usage execute run_benchs.sh -h

# Load cluster config and common functions

[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
CONF_DIR="$ALOJA_REPO_PATH/shell/conf" #TODO remove when migrated to use ALOJA_REPO_PATH
source "$ALOJA_REPO_PATH/shell/common/include_benchmarks.sh"

logger  "INFO: configs loaded, ready to start"

# Validate and initialize run

# Check we meet basics and we can continue
validate "$DISK"

# Initialize configs and paths
initialize

# In PaaS this is already setup (or should)
if [ "$clusterType" != "PaaS" ]; then
 # change swappiness and other basic OS configs for benchmarking
 update_OS_config
fi

# create the directory and copy binaries
prepare_folder "$DISK"

# Save globals at the beginning (for debugging purposes)
save_env "$JOB_PATH/config.sh"

# Check if needed to download files and configs
install_files

# 3.) Run the benchmarks

benchmark_suite_config

# At this point, if the user presses ctrl+c or the script is killed to clean up afterwards and copy the files if remote is defined
update_traps "benchmark_suite_cleanup; rsync_extenal '$JOB_NAME';" "update_logger"

start_time=$(date '+%s')

########################################################
logger  "INFO: Starting $BENCH_SUITE benchmark suite"

# Benchmark stages

benchmark_suite_run

#bench suite specifics
benchmark_suite_save

logger  "INFO: $(date +"%H:%M:%S") DONE $bench"

########################################################
end_time=$(date '+%s')

# Clean suite specific things
benchmark_suite_cleanup
# Cleans the local bench folder from nodes
clean_bench_local_folder

# Save env vars and globals
save_env "$JOB_PATH/config.sh"

# Execute post-process of traces if enabled (https://github.com/Aloja/hadoop-instrumentation)
if [ "$INSTRUMENTATION" == "1" ] ; then
  instrumentation_post_process
fi

if [ "$ALOJA_AUTO_IMPORT" == "1" ] ; then
  logger "INFO: Auto importing run to ALOJA-WEB"
  source_file "$ALOJA_REPO_PATH/shell/common/import_functions.sh"

  # TODO it should not be necessary to include the hadoop file to import
  source_file "$ALOJA_REPO_PATH/shell/common/common_hadoop.sh"

  import_from_folder "$JOB_NAME" #"reload_caches"
  logger "INFO: URL of perf charts http://localhost:8080/perfcharts?execs[]=$id_exec"
fi

# Check if and rsync result to external source
rsync_extenal "$JOB_NAME"

if [ "$BENCH_LEAVE_SERVICES" ] ; then
 logger "INFO: Printing exports needed to use running services.  You might need them not only in the master node."
 print_exports
fi

logger "INFO: Size and path: $(du -h $JOB_PATH|tail -n 1)"
logger "All done, took $(getElapsedTime startTime) seconds"
