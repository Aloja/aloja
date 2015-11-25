#!/usr/bin/env bash

# Script to orchestrate benchmark execution and metrics collection
# NOTE: you need to have your cluster configured first
# for usage execute run_benchs.sh -h

# Load cluster config and common functions

[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
CONF_DIR="$ALOJA_REPO_PATH/shell/conf" #TODO remove when migrated to use ALOJA_REPO_PATH
source "$ALOJA_REPO_PATH/shell/common/include_benchmarks.sh"

logger  "INFO: configs loaded, ready to start"
if [ ! -z "$CLUSTER_DISKS" ]; then
  RUN_DISK_LIST="$CLUSTER_DISKS"
fi

[ ! "$RUN_DISK_LIST" ] && RUN_DISK_LIST="HDD SDD RR1 RR2 RR3 RR4 RR5 RR6 RL1 RL2 RL3 RL4 RL5 RL6"
[ ! "$RUN_REPLICATION_LIST" ] && RUN_REPLICATION_LIST="1 2 3"
[ ! "$RUN_CONTAINERS_NUMBER" ] && RUN_CONTAINERS_NUMBER=$(seq 1 `echo "2*$numberOfNodes" | bc`)
[ ! "$RUN_IOFILE" ] && RUN_IOFILE="65536 32768 131072 4096"
[ ! "$RUN_IOFACTOR" ] && RUN_IOFACTOR="5 10 20 50"
[ ! "$RUN_BENCHS_LIST" ] && RUN_BENCHS_LIST="Hadoop-Examples" #TPC-H BigBench"
[ ! "$RUN_COMPRESSION_LIST" ]  && RUN_COMPRESSION_LIST="0 1 2 3"
[ ! "$RUN_BENCH_DATASIZES" ] && RUN_BENCH_DATASIZES="1000000000 10000000000 100000000000 1000000000000"
[ ! "$RUN_HADOOP_VERSIONS" ] && RUN_HADOOP_VERSIONS="hadoop-2.7.1 hadoop-1.2.1"
[ ! "$RUN_NET_LIST" ] && RUN_NET_LIST="ETH IB"
[ ! "$RUN_BENCHS_BIN" ] && RUN_BENCHS_BIN="$ALOJA_REPO_PATH/aloja-bench/run_benchs.sh"
[ ! "$RUN_BLOCK_SIZES" ] && RUN_BLOCK_SIZES="67108864 33554432 134217728 268435456"

for DISK in $RUN_DISK_LIST
do
    for NET in $RUN_NET_LIST
    do
        for REPLICATION in $RUN_REPLICATION_LIST
        do
            for MAX_MAPS in $RUN_CONTAINERS_NUMBER
            do
                for IO_FACTOR in $RUN_IOFACTOR
                do
                    for IO_FILE in $RUN_IOFILE
                    do
                        for BENCH in $RUN_BENCHS_LIST
                        do
                            for COMPRESS_TYPE in $RUN_COMPRESSION_LIST
                            do
                                for BLOCK_SIZE in $RUN_BLOCK_SIZES
                                do
                                    for BENCH_DATA_SIZE in $RUN_BENCH_DATASIZES
                                    do
                                        for HADOOP_VERSION in $RUN_HADOOP_VERSIONS
                                        do
                                            export HADOOP_VERSION=$HADOOP_VERSION
                                            export BENCH_DATA_SIZE=$BENCH_DATA_SIZE
                                            bash $RUN_BENCHS_BIN -C$clusterName -b $BENCH -z $BLOCK_SIZE -c $COMPRESS_TYPE -I $IO_FILE -i $IO_FACTOR -m $MAX_MAPS -r $REPLICATION -n $NET -d $DISK
                                        done
                                    done
                                done
                            done
                        done
                    done
                done
            done
        done
    done
done
