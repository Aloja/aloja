# Benchmark to test derby installation, data load and query completion

QUERY_TYPE="SQL"

source_file "$ALOJA_REPO_PATH/shell/common/common_newBigBench.sh"
set_newBigBench_requires

source_file "$ALOJA_REPO_PATH/shell/common/common_derby.sh"
set_derby_requires

#BENCH_REQUIRED_FILES["tpch-hive"]="$ALOJA_PUBLIC_HTTP/aplic2/tarballs/tpch-hive.tar.gz"
[ ! "$BENCH_LIST" ] && BENCH_LIST="schedule"

benchmark_suite_config() {
    logger "WARNING: Using Derby DB in client/server mode"
    initialize_derby_vars "BigBench_DB"
    start_derby

    initialize_newBigBench_vars
    prepare_newBigBench
}

benchmark_suite_cleanup() {
  clean_derby
}

benchmark_suite_run() {
  local bench_name="${FUNCNAME[0]##*benchmark_}"
  logger "INFO: Running $bench_name"

  #TODO: review to generate data first time when DELETE_HDFS=0
  if [ "$DELETE_HDFS" == "1" ]; then
    prepare_newBigBench_data
    benchmark_populateDerby
  else
    logger "INFO: Reusing previous RUN BigBench data"
  fi

  #for query in $BENCH_LIST ; do
    #benchmark_query "$query"
	#echo "Executing query: $query"
  #done
  benchmark_schedule
}

benchmark_schedule() {
 local bench_name="${FUNCNAME[0]##*benchmark_}"
 logger "INFO: Running $bench_name"
 #Generate the query files with connection instructions
 local queries=(6 7 9 12 13 14 15 16 17 21 22 24)
 local queriesLen=${#queries[@]}
 for ((i=0;i<queriesLen;i++)); do
	numQuery=${queries[i]}
	query_file="$LOCAL_QUERIES_DIR/q$numQuery"
	query_file+=".sql"
	echo "$query_file"
	url=$(get_database_connection_url)
	echo "connect '$url';" > $query_file
	cat "$QUERIES_DIR/Queries/q$numQuery.sql" >> $query_file
 done
  #for query in $BENCH_LIST ; do
    #benchmark_query "$query"
	#echo "Executing query: $query"
  #done
 workloadFile="$QUERIES_DIR/sampleWorkloadTiny.txt"
 echo "------------------------------------------------------------------"
 echo "WORKLOAD DATA"
 echo "------------------------------------------------------------------"
 cat "$workloadFile"
 generateScheduleScript="$QUERIES_DIR/generateScheduleFromWorkload.sh"
 scheduleFile="$QUERIES_DIR/schedule.txt" 
 bash "$generateScheduleScript" "$workloadFile" > "$scheduleFile"
 echo "------------------------------------------------------------------"
 echo "QUERY SCHEDULE"
 echo "------------------------------------------------------------------"
 cat "$scheduleFile"
 lineIdx=0
 nQueries=0
 queries=()
 secPerWorkload=60
 nBatch=0
 #genExecScript=$LOCAL_QUERIES_DIR/executeWorkload.sh
 #execLog=$LOCAL_QUERIES_DIR/executionLog.txt
 genExecScript=$QUERIES_DIR/executeWorkload.sh
 execLog=$QUERIES_DIR/executionLog.txt
 echo "#!/bin/bash" > $genExecScript
 echo "#Script generated dynamically to execute the workload" >> $genExecScript
 local derby_exports
 local derby_cmd
 derby_exports="$(get_derby_exports)"
 derby_bin="$DERBY_HOME/bin/ij"
 echo "$derby_exports" >> $genExecScript
 echo "nBatch=0" >> $genExecScript
 echo "nQuery=0" >> $genExecScript
 echo "initTime=\$(date +\"%s\")" >> $genExecScript 
 echo "t=0" >> $genExecScript 
 echo "echo \"EXECUTION BEGINS AT: \$(date)\" >> $execLog " >> $genExecScript
 #Read the file line by line
 while IFS='' read -r line || [[ -n "$line" ]]; do
   	if [ $((lineIdx%2)) -eq 0 ]; then
       	nQueries="$line"
       	timePerQuery=$((secPerWorkload / nQueries))
       	echo "nBatch=\$((nBatch+1))" >> $genExecScript
       	echo "echo \"---------------------WORKLOAD \$nBatch STARTED -------------------\" >> $execLog " >> $genExecScript
       	echo "nQuery=1" >> $genExecScript
   	else
       	idx=0
       	#Tokenize the line read to separate the different numbers
       	for word in $line; do 
           	queries[idx]="$word"
           	idx=$((idx+1))
       	done
       	for ((i=0;i<nQueries;i++)); do
           	query=${queries[i]}
			query_file=$LOCAL_QUERIES_DIR/q$query.sql   
			#Condition used only for testing (only the else part should be used)
			if [ $i -eq 1 ]; then
				derby_cmd="( sleep 60 ; "
				derby_cmd+="$derby_bin $query_file ; "
				derby_cmd+="t=\$(date +\"%s\") ; "
				derby_cmd+="echo \"QUERY \$nQuery OF BATCH \$nBatch COMPLETED \$(((t-initTime))) AFTER\" >> $execLog ) &"
			else
				derby_cmd="( $derby_bin $query_file ; "
				derby_cmd+="t=\$(date +\"%s\") ; "
				derby_cmd+="echo \"QUERY \$nQuery OF BATCH \$nBatch COMPLETED \$(((t-initTime))) AFTER\" >> $execLog ) &"
			fi	
			echo "$derby_cmd" >> $genExecScript
			echo "nQuery=\$((nQuery+1))" >> $genExecScript
       	done
   	fi
   	lineIdx=$((lineIdx+1))
 done < "$scheduleFile"
 echo "wait" >> $genExecScript
 echo "-----------------------GENERATED SCRIPT------------------------------"
 cat "$genExecScript"
 echo ""
 echo "$genExecScript"
 execute_master "$bench_name" "bash $genExecScript" "time" "dont_save"
 save_derby "$bench_name"
 cat "$execLog"
 echo $execLog
}


benchmark_populateDerby() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"

  query_file=$LOCAL_QUERIES_DIR/create_tables.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  cat "$QUERIES_DIR/Load_Derby/createTables.sql" >> $query_file

  execute_derby "$bench_name"  "$query_file" "time"

  #Load the data into the tables by a generated script
  load_file=$LOCAL_QUERIES_DIR/load_tables.sql
  echo "connect '$url';" > $load_file

  for f in $DATA_DIR/base/* ; do
    #The table has the same name as the file, minus the extension and it must be in uppercase
    tableName=$(basename "$f")
    #Remove the extension
    tableName="${tableName%.*}"
    #Convert table name to uppercase
    tableName=${tableName^^}
#    fFull=$(realpath "$f")
    stmt="CALL SYSCS_UTIL.SYSCS_IMPORT_TABLE (NULL,'$tableName','$f','|','\"',NULL,0);"
    echo $stmt >> $load_file
  done
  execute_derby "$bench_name"  "$load_file" "time"
}

benchmark_query(){
  local bench_name="${FUNCNAME[0]#benchmark_}-$1"
  logger "INFO: Running $bench_name"

  query_file=$LOCAL_QUERIES_DIR/q$1.sql
  url=$(get_database_connection_url)
  echo "connect '$url';" > $query_file
  cat "$QUERIES_DIR/Queries/q$1.sql" >> $query_file

  execute_derby "$bench_name" "$query_file" "time" #-f scale factor
}

# $1 Number of throughput run
benchmark_throughput() {
  local bench_name="${FUNCNAME[0]#benchmark_}-${BB_PARALLEL_STREAMS}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "runBenchmark -U -i THROUGHPUT_TEST_$1 -z $HIVE_SETTINGS_FILE" "time" #-f scale factor
}

benchmark_refreshMetastore() {
  local bench_name="${FUNCNAME[0]#benchmark_}"
  logger "INFO: Running $bench_name"
  execute_BigBench "$bench_name" "refreshMetastore -U -z $HIVE_SETTINGS_FILE" "time"
}


