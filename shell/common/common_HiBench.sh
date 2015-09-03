#HIBENCH BENCHMARK SPECIFIC FUNCTIONS

# Returns a list of required files
set_HiBench_requires() {
  if [[ "$BENCH" == HiBench* ]]; then
    if [[ "$BENCH" == HiBench2* ]]; then
      BENCH_REQUIRED_FILES["HiBench2"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/HiBench2.tar.gz"
    fi
    if [[ "$BENCH" == HiBench3* ]]; then
      BENCH_REQUIRED_FILES["HiBench3"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/HiBench3.tar.gz"
    fi
  else
    die "HiBench bench not defined"
  fi
}

get_bench_name(){
  local full_name

  if [ "$1" == "wordcount" ] ; then
    full_name="Wordcount"
  elif [ "$1" == "sort" ] ; then
    full_name="Sort"
  elif [ "$1" == "terasort" ] ; then
    full_name="Terasort"
  elif [ "$1" == "kmeans" ] ; then
    full_name="KMeans"
  elif [ "$1" == "pagerank" ] ; then
    full_name="Pagerank"
  elif [ "$1" == "bayes" ] ; then
    full_name="Bayes"
  elif [[ "$1" == "hivebench"* ]] ; then
    full_name="Hive"
  elif [ "$1" == "dfsioe" ] ; then
    full_name="DFSIOE"
  elif [ "$1" == "nutchindexing" ] ; then
    full_name="Nutch"
  else
    full_name="INVALID"
  fi

  echo -e "$full_name"
}

# TODO old code to be refactored
initialize_HiBench_vars() {
  if [[ "$BENCH" == HiBench* ]]; then
    EXECUTE_HIBENCH="true"

    if [[ "$BENCH" == HiBench* ]]; then
      BENCH_HIB_DIR="$(get_local_apps_path)/HiBench2"
    fi
    if [[ "$BENCH" == HiBench3* ]]; then
      BENCH_HIB_DIR="$(get_local_apps_path)/HiBench3"
    fi
  else
    die "Error in $BENCH"
  fi
}

# Sets all HiBench exports
# TODO refactor this dirty old code
get_HiBench_exports() {

  if [ "$(get_hadoop_major_version)" == "1" ]; then
    local hadoop_config="$HADOOP_CONF_DIR"
    local hadoop_examples_jar="$BENCH_HADOOP_DIR/hadoop-examples-*.jar"
  elif [ "$(get_hadoop_major_version)" == "2" ] ; then
    local hadoop_config="$BENCH_HADOOP_DIR/etc/hadoop"
    local hadoop_examples_jar="$BENCH_HADOOP_DIR/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar"
  else
    die "Incorrect Hadoop version. Supplied: $(get_hadoop_major_version)"
  fi

  #need to send all the environment variables over SSH
  local EXP="
export HADOOP_PREFIX=$BENCH_HADOOP_DIR;
export HADOOP_HOME=$BENCH_HADOOP_DIR;
export HADOOP_EXECUTABLE=$BENCH_HADOOP_DIR/bin/hadoop;
export HADOOP_CONF_DIR=$hadoop_config;
export YARN_CONF_DIR=$hadoop_config;
export HADOOP_EXAMPLES_JAR=$hadoop_examples_jar;
export MAPRED_EXECUTABLE=$BENCH_HADOOP_DIR/bin/mapred;
export HADOOP_VERSION=$HADOOP_VERSION;
export HADOOP_COMMON_HOME=$HADOOP_HOME;
export HADOOP_HDFS_HOME=$HADOOP_HOME;
export HADOOP_MAPRED_HOME=$HADOOP_HOME;
export HADOOP_YARN_HOME=$HADOOP_HOME;
export COMPRESS_GLOBAL=$COMPRESS_GLOBAL;
export COMPRESS_CODEC_GLOBAL=$COMPRESS_CODEC_GLOBAL;
export COMPRESS_CODEC_MAP=$COMPRESS_CODEC_MAP;
export NUM_MAPS=$NUM_MAPS;
export NUM_REDS=$NUM_REDS;
export DATASIZE=$DATASIZE;
export PAGES=$PAGES;
export USERVISITS=$USERVISITS;
export CLASSES=$CLASSES;
export NGRAMS=$NGRAMS;
export RD_NUM_OF_FILES=$RD_NUM_OF_FILES;
export RD_FILE_SIZE=$RD_FILE_SIZE;
export WT_NUM_OF_FILES=$WT_NUM_OF_FILES;
export WT_FILE_SIZE=$WT_FILE_SIZE;
export NUM_OF_CLUSTERS=$NUM_OF_CLUSTERS;
export NUM_OF_SAMPLES=$NUM_OF_SAMPLES;
export SAMPLES_PER_INPUTFILE=$SAMPLES_PER_INPUTFILE;
export DIMENSIONS=$DIMENSIONS;
export MAX_ITERATION=$MAX_ITERATION;
export NUM_ITERATIONS=$NUM_ITERATIONS;
"

  # Remove empty exports
  EXP="$(echo -e "$EXP"|grep -v '=;')"

  echo -e "$EXP"
}
execute_HiBench(){
  restart_hadoop
  for bench in $LIST_BENCHS ; do

    #Delete previous data
    #$DSH_MASTER "$BENCH_HADOOP_DIR/bin/hadoop fs -rmr /HiBench"
    echo "" > "$BENCH_HIB_DIR/$bench/hibench.report"

    # Check if there is a custom config for this bench, and call it
    if type "benchmark_hibench_config_${bench}" &>/dev/null
    then
      eval "benchmark_hibench_config_${bench}"
    fi

    #just in case check if the input file exists in hadoop
    if [ "$DELETE_HDFS" == "0" ] ; then
      input_exists=$($DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -ls /HiBench/$(get_bench_name "$bench")/Input 2> /dev/null |grep 'Found '")

      if [ "$input_exists" != "" ] ; then
        loggerb  "Input folder seems OK"
      else
        loggerb  "Input folder does not exist, RESET and RESTART"
        $DSH_MASTER "$HADOOP_EXPORTS $BENCH_HADOOP_DIR/bin/hadoop fs -ls '/HiBench/$(get_bench_name "$bench")/Input'"
        DELETE_HDFS=1
        restart_hadoop
      fi
    fi

    logger "INFO: STARTING $bench"
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
        logger "INFO: Reusing previous RUN prepared $bench"
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
      input_exists=$($DSH_MASTER hdfs dfs -ls "/HiBench/$(get_bench_name "$bench")/Input" 2> /dev/null |grep "Found ")

      if [ "$input_exists" != "" ] ; then
        loggerb  "Input folder seems OK"
      else
        loggerb  "Input folder does not exist, RESET and RESTART"
        $DSH_MASTER hdfs dfs -ls "/HiBench/$(get_bench_name "$bench")/Input"
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
