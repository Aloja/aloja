#!/bin/bash

importHDIJobs() {
	for jhist in `find $folder/mapred/history/done/ -type f -name *.jhist | grep SUCCEEDED` ; do
		java -cp "$CUR_DIR/../aloja-tools/lib/aloja-tools.jar" alojatools.JhistToJSON $jhist tasks.out globals.out
		jobTimestamp=${array[2]}
		jobName="`../shell/jq -r '.job_name' globals.out`"
		jobId="`../shell/jq '.JOB_ID' globals.out`"
		startTime="`../shell/jq -r '.LAUNCH_TIME' globals.out`"
		startTimeTS="`expr $startTime / 1000`"
		finishTime="`../shell/jq -r '.FINISH_TIME' globals.out`"
		finishTimeTS="`expr $finishTime / 1000`"
		totalTime="`expr $finishTime - $startTime`"
		totalTime="`expr $totalTime / 1000`"
		startTime=`date -d @$startTimeTS +"%Y-%m-%d %H:%I:%S"`
		finishTime=`date -d @$finishTimeTS +"%Y-%m-%d %H:%I:%S"`
		if [[ $jobName =~ "word" ]]; then
			jobName="wordcount"
		fi
		
		if [ "$jobName" != "TempletonControllerJob" ]; then
			tmp=`../shell/jq -r '.JOB_ID' globals.out`
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
		        
		     values=`../shell/jq -S '' globals.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`
	    	 insert="INSERT INTO HDI_JOB_details SET id_exec=$id_exec,${values%?}
		               ON DUPLICATE KEY UPDATE
		             LAUNCH_TIME=`../shell/jq '.["LAUNCH_TIME"]' globals.out`,
		             FINISH_TIME=`../shell/jq '.["SUBMIT_TIME"]' globals.out`;"
		     logger "$insert"

		     $MYSQL "$insert"
		        
				
			waste=()
			reduce=()
			map=()
			for i in `seq 0 1 $totalTime`; do
				waste[$i]=0
				reduce[$i]=0
				map[$i]=0		
			done
			
		    runnignTime=`expr $finishTimeTS - $startTimeTS`
		     read -a tasks <<< `../shell/jq -r 'keys' tasks.out | sed 's/,/\ /g' | sed 's/\[/\ /g' | sed 's/\]/\ /g'`
		    for task in "${tasks[@]}" ; do
		    	taskId=`echo $task | sed 's/"/\ /g'`
		    	taskStatus=`../shell/jq --raw-output ".$task.TASK_STATUS" tasks.out`
				taskType=`../shell/jq --raw-output ".$task.TASK_TYPE" tasks.out`
				taskStartTime=`../shell/jq --raw-output ".$task.TASK_START_TIME" tasks.out`
				taskFinishTime=`../shell/jq --raw-output ".$task.TASK_FINISH_TIME" tasks.out`
				taskStartTime=`expr $taskStartTime / 1000`
				taskFinishTime=`expr $taskFinishTime / 1000`
		    	values=`../shell/jq --raw-output ".$task" tasks.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`

		    		insert="INSERT INTO HDI_JOB_tasks SET TASK_ID=$task,JOB_ID=$jobId,id_exec=$id_exec,${values%?}
						ON DUPLICATE KEY UPDATE JOB_ID=JOB_ID,${values%?};"

				echo $insert
				logger $insert
				$MYSQL "$insert"
				
				if [ "$taskStatus" == "FAILED" ]; then
					normalStartTime=`expr $taskStartTime - $startTimeTS`
					normalFinishTime=`expr $finishTimeTS - $taskFinishTime`
					for i in `seq $normalStartTime 1 $normalFinishTime`; do
						waste[$i]=`expr ${waste[$i]} + 1`
					done
				elif [ "$taskType" == "MAP" ]; then
					normalStartTime=`expr $taskStartTime - $startTimeTS`
					normalFinishTime=`expr $finishTimeTS - $taskFinishTime`
					for i in `seq $normalStartTime 1 $normalFinishTime`; do
						map[$i]=`expr ${map[$i]} + 1`
					done
				elif [ "$taskType" == "REDUCE" ]; then
					normalStartTime=`expr $taskStartTime - $startTimeTS`
					normalFinishTime=`expr $finishTimeTS - $taskFinishTime`
					for i in `seq $normalStartTime 1 $normalFinishTime`; do
						reduce[$i]=`expr ${reduce[$i]} + 1`
					done
				fi
		    done
		    for i in `seq 0 1 $totalTime`; do
		    	currentTime=`expr $startTimeTS + $i`
		    	currentDate=`date -d @$currentTime +"%Y-%m-%d %H:%I:%S"`
		    	
		    	insert="INSERT INTO JOB_status(id_exec,job_name,JOBID,date,maps,shuffle,merge,reduce,waste)
						VALUES ($id_exec,'$jobName',$jobId,'$currentDate',${map[$i]},0,0,${reduce[$i]},${waste[$i]})
						ON DUPLICATE KEY UPDATE waste=${waste[$i]},maps=${map[$i]},reduce=${reduce[$i]},date='$currentDate';"

				logger $insert
				$MYSQL "$insert"
			done
		fi

		#cleaning
		rm tasks.out
		rm globals.out
	done
}