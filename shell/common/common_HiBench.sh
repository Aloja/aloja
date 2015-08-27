#HIBENCH BENCHMARK SPECIFIC FUNCTIONS

execute_HiBench(){
  for bench in $(echo "$LIST_BENCHS") ; do
    restart_hadoop

    #Delete previous data
    #$DSH_MASTER "$BENCH_H_DIR/bin/hadoop fs -rmr /HiBench"
    echo "" > "$BENCH_HIB_DIR/$bench/hibench.report"

    # Check if there is a custom config for this bench, and call it
    if type "benchmark_hibench_config_${bench}" &>/dev/null
    then
      eval "benchmark_hibench_config_${bench}"
    fi

    #just in case check if the input file exists in hadoop
    if [ "$DELETE_HDFS" == "0" ] ; then
      get_bench_name $bench
      input_exists=$($DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hadoop fs -ls /HiBench/$full_name/Input 2> /dev/null |grep 'Found '")

      if [ "$input_exists" != "" ] ; then
        loggerb  "Input folder seems OK"
      else
        loggerb  "Input folder does not exist, RESET and RESTART"
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_H_DIR/bin/hadoop fs -ls '/HiBench/$full_name/Input'"
        DELETE_HDFS=1
        restart_hadoop
      fi
    fi

    logger "STARTING $bench"
    ##mkdir -p "$PREPARED/$bench"

    #if [ ! -f "$PREPARED/${i}.tbza" ] ; then

      #hive leaves tmp config files
      #if [ "$bench" != "hivebench" ] ; then
      #  $DSH_MASTER "rm /tmp/hive* /tmp/pristine/hive*"
      #fi

      if [ "$DELETE_HDFS" == "1" ] ; then
        if [ "$bench" != "dfsioe" ] ; then
          execute_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare.sh "prep_"
        elif [ "$bench" == "dfsioe" ] ; then
          execute_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare-read.sh "prep_"
        fi
      else
        loggerb  "Reusing previous RUN prepared $bench"
      fi


      #if [ "$bench" = "wordcount" ] ; then
      #  echo "# $(date +"%H:%M:%S") SAVING PREPARED DATA for $bench"
      #
      #  $DIR/bin/hadoop fs -get /HiBench $PREPARED/$bench/
      #  tar -cjf $PREPARED/${i}.tbz $PREPARED/$bench/
      #  rm -rf $PREPARED/$bench
      #fi
    #else
    #  echo "# $(date +"%H:%M:%S") RESTORING PREPARED DATA for $bench"
    #  tar -xjf $PREPARED/${i}.tbz $PREPARED/
    #  $HADOOPDIR/bin/hadoop fs -put $PREPARED/HiBench /HiBench
    #  rm -rf $PREPARED/HiBench
    #fi

    logger "INFO: $(date +"%H:%M:%S") RUNNING $bench"

    if [ "$bench" != "hivebench" ] && [ "$bench" != "dfsioe" ] ; then
      execute_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/run.sh
    elif [ "$bench" == "hivebench" ] ; then
      execute_hadoop hivebench_agregation ${BENCH_HIB_DIR}/hivebench/bin/run-aggregation.sh
      execute_hadoop hivebench_join ${BENCH_HIB_DIR}/hivebench/bin/run-join.sh
    elif [ "$bench" == "dfsioe" ] ; then
      execute_hadoop dfsioe_read ${BENCH_HIB_DIR}/dfsioe/bin/run-read.sh
      execute_hadoop dfsioe_write ${BENCH_HIB_DIR}/dfsioe/bin/run-write.sh
    fi

  done
}

execute_HDI_HiBench(){
  for bench in $(echo "$LIST_BENCHS") ; do
    #Delete previous data
    echo "" > "$BENCH_HIB_DIR/$bench/hibench.report"

    # Check if there is a custom config for this bench, and call it
    if type "benchmark_hibench_config_${bench}" &>/dev/null
    then
      eval "benchmark_hibench_config_${bench}"
    fi

    #just in case check if the input file exists in hadoop
    if [ "$DELETE_HDFS" == "0" ] ; then
      get_bench_name $bench
      input_exists=$($DSH_MASTER hdfs dfs -ls "/HiBench/$full_name/Input" 2> /dev/null |grep "Found ")

      if [ "$input_exists" != "" ] ; then
        loggerb  "Input folder seems OK"
      else
        loggerb  "Input folder does not exist, RESET and RESTART"
        $DSH_MASTER hdfs dfs -ls "/HiBench/$full_name/Input"
        DELETE_HDFS=1
        format_nodes
      fi
    fi

    echo "# $(date +"%H:%M:%S") STARTING $bench"

      if [ "$DELETE_HDFS" == "1" ] ; then
        if [ "$bench" != "dfsioe" ] ; then
          execute_hdi_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare.sh "prep_"
        elif [ "$bench" == "dfsioe" ] ; then
          execute_hdi_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/prepare-read.sh "prep_"
        fi
      else
        loggerb  "Reusing previous RUN prepared $bench"
      fi

    loggerb  "$(date +"%H:%M:%S") RUNNING $bench"

    if [ "$bench" != "hivebench" ] && [ "$bench" != "dfsioe" ] ; then
      execute_hdi_hadoop $bench ${BENCH_HIB_DIR}/$bench/bin/run.sh
    elif [ "$bench" == "hivebench" ] ; then
      execute_hdi_hadoop hivebench_agregation ${BENCH_HIB_DIR}/hivebench/bin/run-aggregation.sh
      execute_hdi_hadoop hivebench_join ${BENCH_HIB_DIR}/hivebench/bin/run-join.sh
    elif [ "$bench" == "dfsioe" ] ; then
      execute_hdi_hadoop dfsioe_read ${BENCH_HIB_DIR}/dfsioe/bin/run-read.sh
      execute_hdi_hadoop dfsioe_write ${BENCH_HIB_DIR}/dfsioe/bin/run-write.sh
    fi

  done
}
