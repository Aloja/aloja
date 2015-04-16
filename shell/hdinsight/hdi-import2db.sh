#!/bin/bash

importHDIJobs() {
     ### NOTE: Converting perf metrics windows time to Linux
     ## date -d"02/13/2015 11:30:24.300" +"%Y-%m-%d %H:%M:%S"
    ##to timestamp: date -d"02/13/2015 11:30:24.300" +"%s"
	for jhist in `find $folder/mapred/history/done/ -type f -name *.jhist | grep SUCCEEDED` ; do
		java -cp "$CUR_DIR/../aloja-tools/lib/aloja-tools.jar" alojatools.JhistToJSON $jhist tasks.out globals.out
		jobTimestamp=${array[2]}
		jobName="`../aloja-tools/jq -r '.job_name' globals.out`"
		jobId="`../aloja-tools/jq '.JOB_ID' globals.out`"
		startTime="`../aloja-tools/jq -r '.LAUNCH_TIME' globals.out`"
		startTimeTS="`expr $startTime / 1000`"
		finishTime="`../aloja-tools/jq -r '.FINISH_TIME' globals.out`"
		finishTimeTS="`expr $finishTime / 1000`"
		totalTime="`expr $finishTime - $startTime`"
		totalTime="`expr $totalTime / 1000`"
		startTime=`date -d @$startTimeTS +"%Y-%m-%d %H:%M:%S"`
		finishTime=`date -d @$finishTimeTS +"%Y-%m-%d %H:%M:%S"`
		if [[ $jobName =~ "word" ]]; then
			jobName="wordcount"
		fi
		
		if [ "$jobName" != "TempletonControllerJob" ]; then
			tmp=`../aloja-tools/jq -r '.JOB_ID' globals.out`
			exec="$folder/$jobName_$tmp"

			id_exec=""
		    
		    id_exec=$(get_id_exec "$exec")
		    if [ -z $id_exec ]; then
		       	id_exec="NULL"
		   	fi
		    	
		    benchType="HDI"
		    if [ $jobName == "random-text-writer" ]; then
				benchType="HDI-prep"
				jobName="prep_wordcount"
			fi
			if [[ $jobName =~ "TeraGen" ]]; then
				benchType="HDI-prep"
				jobName="prep_terasort"
			fi
			if [[ $jobName =~ "TeraSort" ]]; then
				jobName="terasort"
			fi
			
			##Select cluster number
			IFS='_' read -ra folderArray <<< "$folder"
			numberOfNodes=`echo ${folderArray[1]} | grep -oP "[0-9]+"`
			cluster=20
			if [ "$numberOfNodes" -eq "4" ]; then
				cluster=20	 
			elif [ "$numberOfNodes" -eq "8" ]; then
				cluster=23
			elif [ "$numberOfNodes" -eq "16" ]; then
				cluster=24
			elif [ "$numberOfNodes" -eq "32" ]; then
				cluster=25
			fi
			
			valid=`echo "$jhist" | grep SUCCEEDED | wc -l`
			
			get_hdi_exec_params "$folder" "`../aloja-tools/jq -r '.JOB_ID' globals.out`"  	        
			
			insert="INSERT INTO execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link,valid,hadoop_version)
		             VALUES ($id_exec, $cluster, \"$exec\", \"$jobName\",$totalTime,\"$startTime\",\"$finishTime\",\"$net\",\"$disk\",\"$benchType\",$maps,$iosf,$replication,$iofilebuf,$compressCodec,$blocksize,\"n/a\",$valid,2)
		             ON DUPLICATE KEY UPDATE
		                  start_time='$startTime',
		                  end_time='$finishTime',
                          net='$net',disk='$disk',
                          maps=$maps,replication=$replication,
                          iosf=$iosf,iofilebuf=$iofilebuf,
                          comp=$compressCodec,blk_size=$blocksize
                          ;"
		    logger "$insert"

		     $MYSQL "$insert"
		    
		     if [ "$id_exec" == "NULL" ]; then
		    	id_exec=$(get_id_exec "$exec")
			 fi
		        
		     values=`../aloja-tools/jq -S '' globals.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`
	    	 insert="INSERT INTO HDI_JOB_details SET id_exec=$id_exec,${values%?}
		               ON DUPLICATE KEY UPDATE
		             LAUNCH_TIME=`../aloja-tools/jq '.["LAUNCH_TIME"]' globals.out`,
		             FINISH_TIME=`../aloja-tools/jq '.["SUBMIT_TIME"]' globals.out`;"
		     logger "$insert"

		     $MYSQL "$insert"

		    result=`$MYSQL "select count(*) from JOB_status JOIN execs e USING (id_exec) where e.id_exec=$id_exec" -N`
			
			if [ -z "$1" ] && [ $result -eq 0 ]; then	
				waste=()
				reduce=()
				map=()
				for i in `seq 0 1 $totalTime`; do
					waste[$i]=0
					reduce[$i]=0
					map[$i]=0		
				done
				
			    runnignTime=`expr $finishTimeTS - $startTimeTS`
			     read -a tasks <<< `../aloja-tools/jq -r 'keys' tasks.out | sed 's/,/\ /g' | sed 's/\[/\ /g' | sed 's/\]/\ /g'`
			    for task in "${tasks[@]}" ; do
			    	taskId=`echo $task | sed 's/"/\ /g'`
			    	taskStatus=`../aloja-tools/jq --raw-output ".$task.TASK_STATUS" tasks.out`
					taskType=`../aloja-tools/jq --raw-output ".$task.TASK_TYPE" tasks.out`
					taskStartTime=`../aloja-tools/jq --raw-output ".$task.TASK_START_TIME" tasks.out`
					taskFinishTime=`../aloja-tools/jq --raw-output ".$task.TASK_FINISH_TIME" tasks.out`
					taskStartTime=`expr $taskStartTime / 1000`
					taskFinishTime=`expr $taskFinishTime / 1000`
			    	values=`../aloja-tools/jq --raw-output ".$task" tasks.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`
	
			    		insert="INSERT INTO HDI_JOB_tasks SET TASK_ID=$task,JOB_ID=$jobId,id_exec=$id_exec,${values%?}
							ON DUPLICATE KEY UPDATE JOB_ID=JOB_ID,${values%?};"
	
					logger $insert
					$MYSQL "$insert"
	
					if [ "$taskStatus" == "FAILED" ]; then
						normalStartTime=`expr $taskStartTime - $startTimeTS`
						normalFinishTime=`expr $taskFinishTime - $startTimeTS`
						for i in `seq $normalStartTime 1 $normalFinishTime`; do
							waste[$i]=`expr ${waste[$i]} + 1`
						done
					elif [ "$taskType" == "MAP" ]; then
						normalStartTime=`expr $taskStartTime - $startTimeTS`
						normalFinishTime=`expr $taskFinishTime - $startTimeTS`
						for i in `seq $normalStartTime 1 $normalFinishTime`; do
							map[$i]=`expr ${map[$i]} + 1`
						done
					elif [ "$taskType" == "REDUCE" ]; then
						normalStartTime=`expr $taskStartTime - $startTimeTS`
						normalFinishTime=`expr $taskFinishTime - $startTimeTS`
						for i in `seq $normalStartTime 1 $normalFinishTime`; do
							reduce[$i]=`expr ${reduce[$i]} + 1`
						done
					fi
			    done
			    for i in `seq 0 1 $totalTime`; do
			    	currentTime=`expr $startTimeTS + $i`
			    	currentDate=`date -d @$currentTime +"%Y-%m-%d %H:%M:%S"`
			    	insert="INSERT INTO JOB_status(id_exec,job_name,JOBID,date,maps,shuffle,merge,reduce,waste)
							VALUES ($id_exec,'$jobName',$jobId,'$currentDate',${map[$i]},0,0,${reduce[$i]},${waste[$i]})
							ON DUPLICATE KEY UPDATE waste=${waste[$i]},maps=${map[$i]},reduce=${reduce[$i]},date='$currentDate';"
	
					logger $insert
					$MYSQL "$insert"
				done
			fi
		fi

		#cleaning
		rm tasks.out
		rm globals.out
	done
}

get_hdi_exec_params() {
	idJob=$2
	folder=$1	
	
	xmlFile=$(find $folder/mapred/history/done/ -type f -name *$idJob*.xml | head -n 1)
	replication=$(xmllint --xpath "string(//property[name='dfs.replication']/value)" $xmlFile)
	compressCodec=$(xmllint --xpath "string(//property[name='mapreduce.map.output.compress.codec']/value)" $xmlFile)
	maps=$(xmllint --xpath "string(//property[name='mapreduce.tasktracker.map.tasks.maximum']/value)" $xmlFile)
	blocksize=$(xmllint --xpath "string(//property[name='dfs.blocksize']/value)" $xmlFile)
	iosf=$(xmllint --xpath "string(//property[name='mapreduce.task.io.sort.factor']/value)" $xmlFile)
	iofilebuf=$(xmllint --xpath "string(//property[name='io.file.buffer.size']/value)" $xmlFile)
	
	if [ "$compressCodec" = "org.apache.hadoop.io.compress.SnappyCodec" ]; then
		compressCodec=3	
	fi
	
	blocksize=`expr $blocksize / 1000000`
    net="ETH"
    disk="RR1"	
}
