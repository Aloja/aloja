#!/bin/env bash

# Script to orchestrate benchmark execution and metrics collection
# for usage run run_benchs.sh -h

# 1.) load cluster config and common functions

# attempt first to load local cluster config if defined
if [[ -z "$clusterName" &&  -f ~/aloja_cluster.conf ]] ; then
  source ~/aloja_cluster.conf  #here we don't have globals loaded yet
fi

CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CUR_DIR_TMP/../shell/common/include_benchmarks.sh"

logger  "INFO: configs loaded\n"

# 2.) Check options, validate and initialize run

# check command line options
get_options "$@"
# some validations
validate
# initialize cluster node names and connect string
initialize_node_names
# set the name for the job run
set_job_config
# check if all nodes are up
test_nodes_connection
# hadoop vars
initialize_hadoop_vars #TODO execute only for hadoop
# specify which binaries to use for monitoring
set_monit_binaries

if [ "$clusterType" != "PaaS" ]; then
 # change swappiness and other basic OS configs for benchmarking
 update_OS_config
 # create the directory and copy binaries
 prepare_folder
fi

# check if to copy aplic folders locally
check_aplic_updates

# 3.) Run the benchmarks

##GLOBAL ARRAYS FOR TIMES
#declared globally here due to multi bash version issues
declare -A EXEC_TIME
declare -A EXEC_START
declare -A EXEC_END

benchmark_config

start_time=$(date '+%s')

########################################################
loggerb  "Starting execution of $BENCH"

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
