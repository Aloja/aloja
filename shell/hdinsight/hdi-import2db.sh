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
		    get_id_exec "$exec"
		    if [ -z $id_exec ]; then
		       	id_exec="NULL"
		   	fi
		    	
		    benchType="HDI"
		    if [ $jobName == "random-text-writer" ]; then
				benchType="HDI-prep"
			fi
			if [[ $jobName =~ "TeraGen" ]]; then
				benchType="HDI-prep"
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
			
			insert="INSERT INTO execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link,valid,hadoop_version)
		             VALUES ($id_exec, $cluster, \"$exec\", \"$jobName\",$totalTime,\"$startTime\",\"$finishTime\",0,0,\"$benchType\",0,0,0,0,0,0,\"n/a\",$valid,2)
		             ON DUPLICATE KEY UPDATE
		                  start_time='$startTime',
		                  end_time='$finishTime';"
		    logger "$insert"

		     $MYSQL "$insert"
		    
		     if [ "$id_exec" == "NULL" ]; then
		    	get_id_exec "$exec"
			 fi
		        
		     values=`../aloja-tools/jq -S '' globals.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`
	    	 insert="INSERT INTO HDI_JOB_details SET id_exec=$id_exec,${values%?}
		               ON DUPLICATE KEY UPDATE
		             LAUNCH_TIME=`../aloja-tools/jq '.["LAUNCH_TIME"]' globals.out`,
		             FINISH_TIME=`../aloja-tools/jq '.["SUBMIT_TIME"]' globals.out`;"
		     logger "$insert"

		     $MYSQL "$insert"
			
			if [ -z "$1" ]; then	
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
