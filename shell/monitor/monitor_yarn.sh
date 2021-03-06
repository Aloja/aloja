#!/bin/bash

_monitor_yarn () {
    local root_dir=$1
    local experiment_id=${@: -1}
    local url=http://"$(get_master_name)":8088/ws/v1/cluster/apps

    curl -sS --compressed -H "Accept: application/json" -G "$url" -d applicationTags="$experiment_id"  2>/dev/null |
    "$root_dir"/aloja-tools/jq -c '.apps.app[]? | [
        { index: { "_id": .id } },
        {
            id,
            "experimentId": .applicationTags,
            name,
            state,
            finalStatus,
            progress,
            startedTime,
            finishedTime,
            elapsedTime,
            allocatedMB,
            allocatedVCores,
            memorySeconds,
            vcoreSeconds
        }
    ] | .[]'
}
