# Source the original script and add functions
source_file "$ALOJA_REPO_PATH/shell/common/common_BigBench.sh"

# Returns the the path to the BigBench binary, the proper exports are
#assumed to be set already
get_BigBench_cmd_schedule() {
  local BigBench_cmd
  BigBench_bin="$(get_local_apps_path)/${BIG_BENCH_FOLDER}/bin/bigBench"
  BigBench_cmd="$BigBench_bin"
  echo -e "$BigBench_cmd"
}

# $1 input workload file
# $2 output schedule file
# $3 batch multiplier
# $4 random seed (-1 to do not set the seed)
generateScheduleFile() {
	# Set the queries to choose from
	# This line enables all 30 queries (specified as a sequence)
	queries=($(seq -f "%g" -s " "  1 30))
	# This line enables only particular queries (e.g. only SQL queries)
	# queries=(6 7 9 11 12 13 14 15 16 17 21 22 23 24)
	queriesLen=${#queries[@]}
	# IMPORTANT: setting the random seed guarantees the same schedule every time
	if [ $4 -ne -1 ]; then
		RANDOM=$4
	fi
	while IFS='' read -r line || [[ -n "$line" ]]; do
    	for word in $line; do 
        	# NOTE: the following commented lines will work only for integer values
			# Convert the floating point number read into an integer
        	# IMPORTANT: the number is truncated
        	# workLoad=${word%.*}
        	# Scale the workload by the multiplier
        	# workLoad=$((workLoad*$3))
			# NOTE: the following lines work for integer and floating point values
			# Scale the workload by the multiplier
			workLoad=$(echo $word*$3 | bc)
			# Round the number
			workLoad=$(echo "($workLoad+0.5)/1" | bc)
        	printf "%s\n"  "$workLoad" >> "$2"
        	# Generate the schedule for each workload
        	shuffle
        	for ((i=1;i<=workLoad;i++)); do
            	#The two lines below enable to chose a query randomly,
            	#thus repetition can occur
            	#Add zero since positions in the array begin with 0
            	#queryIdx="$((0 + (RANDOM % queriesLen)))"
            	#query=${queries[queryIdx]}
            	#The line below uses the fact that the queries array
            	#has been shuffled, thus avoiding the possible repetition
            	#of a query. However, there must be sufficient queries in
            	#order to fulfill the schedule.
            	query=${queries[$((i-1))]}
            	printf "%s "  "$query" >> "$2"
        	done
        	printf "\n" >> "$2"
    	done
	done < "$1"	
}

#This function shuffles the elements of an array in-place using the 
#Knuth-Fisher-Yates shuffle algorithm. 
shuffle() {
   local i tmp size max rand

   # $RANDOM % (i+1) is biased because of the limited range of $RANDOM
   # Compensate by using a range which is a multiple of the array size.
   size=${#queries[*]}
   max=$(( 32768 / size * size ))

   for ((i=size-1; i>0; i--)); do
      while (( (rand=$RANDOM) >= max )); do :; done
      rand=$(( rand % (i+1) ))
      tmp=${queries[i]} queries[i]=${queries[rand]} queries[rand]=$tmp
   done
}

# $1 schedule file generated from the workload
# $2 name of the output script to be generated
# $3 name of the output log that the execution of the generated script will generate
# $4 scale factor for the BigBench data
# $5 time to wait (in seconds) between each batch
generateExecutionScript() {
	local lineIdx=0
	local nQueries=0
	local queries=()
	local secPerWorkload=$5
	printf "#!/bin/bash\n" >> "$2"
	printf "#Script generated dynamically to execute the workload\n" >> $2
	local bb_exports
	local bb_bin
	local bb_cmd
	local batch_exports
	bb_exports="$(get_BigBench_exports  "$4")"
	bb_bin="$(get_BigBench_cmd_schedule)"
	printf "%s\n" "$bb_exports"  >> $2
	printf "\n" >> $2
	printf "nBatch=0\n" >> $2
	printf "nQuery=0\n" >> $2
	printf "%s\n" "initTime=\$(date +\"%s\")" >> $2 
	printf "t=0\n" >> $2 
	printf "echo \"EXECUTION BEGINS AT: \$(date)\" >> $3 \n" >> $2
	printf "echo \"initTime: \$initTime\" >> $3 \n" >> $2
	printf "tNow=0\n" >> $2 
	local i=0
	#Obtain the number of lines in the schedule file to add only the necessary sleeps
	local nLines=$(cat "$1" | wc -l)
	# Enumerates the current batch in the loop, whereas nBatch is a variable within the generated script.
	local batchCounter=0
 	#Read the file line by line
	while IFS='' read -r line || [[ -n "$line" ]]; do
   		if [ $((lineIdx%2)) -eq 0 ]; then
       		nQueries="$line"
       		timePerQuery=$((secPerWorkload / nQueries))
       		printf "nBatch=\$((nBatch+1))\n" >> $2
       		batchCounter=$((batchCounter+1))
       		# Add the exports specific to the batch
			batch_exports="$(get_BigBench_exports_batch  "$4" "$batchCounter")"
			printf "%s\n" "$batch_exports"  >> $2
			printf 
       		printf "echo \"---------------------WORKLOAD \$nBatch STARTED -------------------\" >> $3 \n" >> $2
       		printf "nQuery=1\n" >> $2
   		else
       		idx=0
       		#Tokenize the line read to separate the different numbers
       		for word in $line; do 
           		queries[idx]="$word"
           		idx=$((idx+1))
       		done
       		for ((i=0;i<nQueries;i++)); do
           		query=${queries[i]}
           		printf "%s\n" "tNow=\$(date +\"%s\") ; " >> $2
           		printf "%s\n" "echo \"QUERY \$nQuery (Q$query) OF BATCH \$nBatch STARTED \$(((tNow-initTime))) AFTER\" >>$3 ;" >> $2
           		bb_cmd="( $bb_bin runQuery -q $query -U -z ${BIG_BENCH_PARAMETERS_FILE}_$4 -t $batchCounter ; "
				bb_cmd+="t=\$(date +\"%s\") ; "
				bb_cmd+="echo \"QUERY \$nQuery (Q$query) OF BATCH \$nBatch COMPLETED \$(((t-initTime))) AFTER\" >> $3 ) &"
				printf "%s\n" "$bb_cmd" >> $2
				printf "nQuery=\$((nQuery+1))\n" >> $2
       		done
       		#Add a sleep to mark the next batch (avoid it for the last batch)
       		if [[ $((lineIdx+2)) -lt "$nLines" ]]; then
       			printf "sleep %s\n" "$secPerWorkload" >> $2
       		fi
   		fi
   		lineIdx=$((lineIdx+1))
	done < "$1"
	printf "wait\n" >> $2
}

# Helper to print a line with required exports for a particular batch
# $1 scale factor to use
# $2 batch number
get_BigBench_exports_batch() {
  local to_export
  to_export="
    export BIG_BENCH_LOGS_DIR='$(get_local_bench_path)/BigBench_logs/bigbench_$1/batch_$2';
    export BIG_BENCH_HDFS_ABSOLUTE_QUERY_RESULT_DIR='$HDFS_DATA_ABSOLUTE_PATH/query_results/bigbench_$1/batch_$2';
    export BIG_BENCH_HDFS_ABSOLUTE_TEMP_DIR='$HDFS_DATA_ABSOLUTE_PATH/bigbench_$1/batch_$2/temp';
    #################################### IMPORTANT #################################################
    export HADOOP_OPTS=' -Djava.io.tmpdir=./tmp ';"
  echo -e "$to_export\n"
}



