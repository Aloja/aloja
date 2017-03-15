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

generateScheduleFile() {
	queries=($(seq -f "%g" -s " "  1 30))
	queriesLen=${#queries[@]}
	#IMPORTANT: setting the random seed guarantees the same schedule every time
	RANDOM=2345
	while IFS='' read -r line || [[ -n "$line" ]]; do
    	for word in $line; do 
        	#Convert the floating point number read into an integer
        	#IMPORTANT: the number is truncated
        	workLoad=${word%.*}
        	printf "%s\n"  "$workLoad" >> "$2"
        	#Generate the schedule for each workload
        	#shuffle
        	for ((i=1;i<=workLoad;i++)); do
            	#The two lines below enable to chose a query randomly,
            	#thus repetition can occur
            	#Add zero since positions in the array begin with 0
            	queryIdx="$((0 + (RANDOM % queriesLen)))"
            	query=${queries[queryIdx]}
            	#The line below uses the fact that the queries array
            	#has been shuffled, thus avoiding the possible repetition
            	#of a query. However, there must be sufficient queries in
            	#order to fulfill the schedule.
            	#query=${queries[i]}
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

#$1 schedule file, $2 output script, $3 output log, $4 scale factor
generateExecutionScript() {
	local lineIdx=0
	local nQueries=0
	local queries=()
	local secPerWorkload=120
	printf "#!/bin/bash\n" >> "$2"
	printf "#Script generated dynamically to execute the workload\n" >> $2
	local bb_exports
	local bb_bin
	local bb_cmd
	bb_exports="$(get_BigBench_exports  "$4")"
	bb_bin="$(get_BigBench_cmd_schedule)"
	printf "%s\n" "$bb_exports"  >> $2
	printf "\n" >> $2
	printf "nBatch=0\n" >> $2
	printf "nQuery=0\n" >> $2
	printf "%s\n" "initTime=\$(date +\"%s\")" >> $2 
	printf "t=0\n" >> $2 
	printf "echo \"EXECUTION BEGINS AT: \$(date)\" >> $3 \n" >> $2
	local i=0
	#Obtain the number of lines in the schedule file to add only the necessary sleeps
	local nLines=$(cat "$1" | wc -l)
 	#Read the file line by line
	while IFS='' read -r line || [[ -n "$line" ]]; do
   		if [ $((lineIdx%2)) -eq 0 ]; then
       		nQueries="$line"
       		timePerQuery=$((secPerWorkload / nQueries))
       		printf "nBatch=\$((nBatch+1))\n" >> $2
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
           		bb_cmd="( $bb_bin runQuery -q $query -U -z ${BIG_BENCH_PARAMETERS_FILE}_$4 ; "
				bb_cmd+="t=\$(date +\"%s\") ; "
				bb_cmd+="echo \"QUERY \$nQuery OF BATCH \$nBatch COMPLETED \$(((t-initTime))) AFTER\" >> $3 ) &"
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

