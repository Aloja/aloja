#!/bin/bash

importHDIJobs() {
	for jhist in `find $folder/mapred/history/done/ -type f -name *.jhist | grep SUCCEEDED` ; do
		java -cp ../aloja-tools/lib/aloja-tools.jar alojatools.JhistToJSON $jhist tasks.out globals.out
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
		if [[ $jobName =~ "tera" ]]; then
			jobName="terasort"
		fi
		
		if [ $jobName != "TempletonControllerJob" ]; then
			id_exec=""
		    get_id_exec "$folder"
		    if [ -z $id_exec ]; then
		       	id_exec="NULL"
		   	fi
		    	
		    benchType="HDI"
		    if [ $jobName="random-text-writer" ]; then
				benchType="HDI-prep"
			fi
			
			##Select cluster number
			IFS='_' read -ra folderArray <<< "$folder"
			numberOfNodes=`echo ${folderArray[1]} | grep -oP "[0-9]+"`
			cluster=20
			if [ "$numberOfNodes" -eq "4" ]; then
				cluster=20	 
			fi  	        
			
			insert="INSERT INTO execs (id_exec,id_cluster,exec,bench,exe_time,start_time,end_time,net,disk,bench_type,maps,iosf,replication,iofilebuf,comp,blk_size,zabbix_link,valid,hadoop_version)
		             VALUES ($id_exec, $cluster, \"$folder\", \"$jobName\",$totalTime,\"$startTime\",\"$finishTime\",0,0,\"$benchType\",0,0,0,0,0,0,\"n/a\",1,2)
		             ON DUPLICATE KEY UPDATE
		                  start_time='$startTime',
		                  end_time='$finishTime';"
		    logger "$insert"

		     $MYSQL "$insert"
		        
		     values=`../shell/jq -S '' globals.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`
	    	 insert="INSERT INTO HDI_JOB_details SET id_exec=$id_exec,${values%?}
		               ON DUPLICATE KEY UPDATE
		             LAUNCH_TIME=`../shell/jq '.["LAUNCH_TIME"]' globals.out`,
		             FINISH_TIME=`../shell/jq '.["SUBMIT_TIME"]' globals.out`;"
		     logger "$insert"

		     $MYSQL "$insert"
		        
				
		     read -a tasks <<< `../shell/jq -r 'keys' tasks.out | sed 's/,/\ /g' | sed 's/\[/\ /g' | sed 's/\]/\ /g'`
		    for task in $tasks ; do
		    	taskId=`echo $task | sed 's/"/\ /g'`
		    	values=`../shell/jq --raw-output ".$task" tasks.out | sed 's/}/\ /g' | sed 's/{/\ /g' | sed 's/,/\ /g' | tr -d ' ' | grep -v '^$' | tr "\n" "," |sed 's/\"\([a-zA-Z_]*\)\":/\1=/g'`

		    		insert="INSERT INTO HDI_JOB_tasks SET TASK_ID=$task,JOB_ID=$jobId,${values%?}
						ON DUPLICATE KEY UPDATE JOB_ID=JOB_ID;"

				echo $insert
				logger $insert
				$MYSQL "$insert"
		    done
		fi

		#cleaning
		rm tasks.out
		rm globals.out
	done
}