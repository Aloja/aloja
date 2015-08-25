#!/usr/bin/env bash

# Script to orchestrate benchmark execution and metrics collection
# NOTE: you need to have your cluster configured first
# for usage run run_benchs.sh -h

# 1.) load cluster config and common functions

[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONF_DIR="$ALOJA_REPO_PATH/shell/conf" #TODO remove when migrated to use ALOJA_REPO_PATH
source "$ALOJA_REPO_PATH/shell/common/include_benchmarks.sh"

logger  "INFO: configs loaded, we can start\n"

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

# check if to copy aplic folders locally
check_aplic_updates

# 3.) Run the benchmarks

##GLOBAL ARRAYS FOR TIMES
#declared globally here due to multi bash version issues
declare -A EXEC_TIME
declare -A EXEC_START
declare -A EXEC_END

# hadoop vars
initialize_hadoop_vars #TODO execute only for hadoop

benchmark_config

start_time=$(date '+%s')

########################################################
loggerb  "Starting execution of $BENCH"

# Benchmark stages
benchmark_run

stop_monit

benchmark_teardown

benchmark_save

loggerb  "$(date +"%H:%M:%S") DONE $bench"


########################################################
end_time=$(date '+%s')

benchmark_cleanup


#copy
loggerb "INFO: Copying resulting files From: $HDD/* To: $JOB_PATH/"
$DSH "cp $HDD/* $HDD_TMP/* $JOB_PATH/"

# Save current config (all environment variables)
( set -o posix ; set ) | grep -i -v "password" > $JOB_PATH/config.sh


# Execute post-process of traces
if [ "$INSTRUMENTATION" == "1" ] ; then
  instrumentation_post_process
fi


#report
#finish_date=`$DATE`
#total_time=`expr $(date '+%s') - $(date '+%s')`
#$(touch ${JOB_PATH}/finish_${finish_date})
#$(touch ${JOB_PATH}/total_${total_time})
du -h $JOB_PATH|tail -n 1
loggerb  "DONE, total time $total_time seconds. Path $JOB_PATH"
