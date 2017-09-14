#!/bin/bash

declare _monitor_pid _monitor_experiment_id _monitor_log_dir _monitor_update_es _monitor_current_test_id

declare -r _monitor_eshost=aloja.bsc.es:9200
declare -r _monitor_experiment_index=metadata
declare -r _monitor_test_index=tests
declare -r _monitor_mapping=aloja

declare -a _monitor_func

_monitor_start () {
  _monitor_experiment_id=$1
  _monitor_log_dir=$2
  _monitor_update_es=$3
  _monitor_func=( "${@:4}" "$_monitor_experiment_id" )

  mkdir -p "$_monitor_log_dir"

  _monitor_update_experiment "running"

  # start background task
  _monitor_invoke &
  _monitor_pid=$!
}

_monitor_set_test_id () {
  _monitor_current_test_id=$1
}

_monitor_get_test_id () {
  echo "$_monitor_current_test_id"
}

_monitor_invoke () {
  while true; do
    _monitor_update_tests
    sleep 30
  done
}

_monitor_update_tests () {
  local url="${_monitor_eshost}/${_monitor_test_index}/${_monitor_mapping}/_bulk?pretty"
  local json=$( "${_monitor_func[@]}" )

  if [[ $json ]]; then
    # overwrite with latest non-empty result
    printf '%s\n' "$json" > "$_monitor_log_dir/update_tests.json"
    [[ $_monitor_update_es -gt 0 ]] && curl -sS -X POST "$url" -H 'Content-Type: application/json' --data-binary "$json"$'\n' >> "$_monitor_log_dir/update_tests.log"
  fi
}

_monitor_update_experiment () {
  local status=$1
  local url="${_monitor_eshost}/${_monitor_experiment_index}/${_monitor_mapping}/${_monitor_experiment_id}/_update?pretty"
  local json='{
  "doc" : { "status": "'"$status"'" },
  "upsert": { "status": "'"$status"'" }
}'

  printf '%s\n' "$json" > "$_monitor_log_dir/update_experiment.json"
  [[ $_monitor_update_es -gt 0 ]] && curl -sS -X POST "$url" -H 'Content-Type: application/json' -d "$json" >> "$_monitor_log_dir/update_experiment.log"
}

_monitor_end () {
  _monitor_update_tests
  _monitor_update_experiment "finished"

  # wait until killed
  while kill -0 "$_monitor_pid" >/dev/null 2>&1; do
    kill "$_monitor_pid"
    sleep 1
  done
}
