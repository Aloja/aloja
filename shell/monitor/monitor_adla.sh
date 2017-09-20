#!/bin/bash

declare -A _ADLA_test_ids

_monitor_ADLA(){

  local experiment_id=$1 adla_account=$2 current_job_id job_id output

  # currently running test (ADLA UUID)
  current_job_id=$(_monitor_get_test_id)
 
  # remember all jobs seen so far, to always emit the status for everything seen so far
  _ADLA_test_ids[${current_job_id}]=1
  
  for job_id in "${!_ADLA_test_ids[@]}"; do

    output=$(az dla job show --output json --account "${adla_account}" --job-identity "${job_id}")

    jq -c --arg exp_id "${experiment_id}" '[
      { index: { "_id": .jobId } },
      {
        id: .jobId,
        experimentId: $exp_id,
        name,
        degreeOfParallelism,
        priority,
        submitTime,
        startedTime: .startTime,
        finishedTime: .endTime,
        finalStatus: .result,
        state,
        runtimeVersion: .properties.runtimeVersion,
        totalCompilationTime: .properties.totalCompilationTime,
        totalPauseTime: .properties.totalPauseTime,
        totalQueuedTime: .properties.totalQueuedTime,
        totalRunningTime: .properties.totalRunningTime
      }
    ] | .[]' <<< "$output"

  done

}

# global experiment metadata in JSON format
_monitor_ADLA_get_experiment_info(){

  local json

  local bb_streams=$1
  local bb_scale_factor=$2
  local adla_account=$3
  local azure_location=$4

  json=$(cat << EOJ
{
  "engine": "ADLA",
  "bb_streams": "$bb_streams",
  "scale_factor": "$bb_scale_factor",
  "name": "BigBench",
  "adla_account": "$adla_account",
  "azure_location": "$azure_location",
  "cloud_provider": "azure",
  "start_time": "$(date +%s)"
}
EOJ
)

  echo "$json"

}

