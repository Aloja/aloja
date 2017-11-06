#!/bin/bash

declare _monitor_pid _monitor_experiment_id _monitor_log_dir _monitor_update_es _monitor_current_test_id

declare -r _monitor_eshost=https://aloja.bsc.es
declare -r _monitor_experiment_index=metadata
declare -r _monitor_test_index=tests
declare -r _monitor_mapping=aloja

declare -r _monitor_proxy_email="$userDashboard"
declare -r _monitor_proxy_password="$passwordDashboard"

declare -r _monitor_cookie_file=/tmp/monitor_cookies

declare -a _monitor_func
declare -a _monitor_experiment_info_func=()

_monitor_start () {

  _monitor_experiment_id=$1
  _monitor_log_dir=$2
  _monitor_update_es=$3
  _monitor_func=( "${@:4}" "$_monitor_experiment_id" )

  mkdir -p "$_monitor_log_dir"

  # update/create experiment info
  if [ ${#_monitor_experiment_info_func[@]} -gt 0 ]; then
    _monitor_create_experiment
  fi

  _monitor_update_experiment "running"

  # start background task
  _monitor_invoke &
  _monitor_pid=$!
}

_monitor_set_experiment_info_func(){

  _monitor_experiment_info_func=( "$@" )
}

_monitor_get_code(){

  local output=$1
  tail -n 1 <<< "$output"
}

_monitor_get_body(){

  local output=$1
  head -n -1 <<< "$output"
}

_monitor_do_curl(){

  curl -sS -w '\n%{http_code}\n' -c "$_monitor_cookie_file" -b "$_monitor_cookie_file" -XPOST -H 'Content-Type: application/json' "$@"

}


_monitor_login(){

  local output code

  rm -f "$_monitor_cookie_file"
  output=$(_monitor_do_curl -d '{"email": "'"$_monitor_proxy_email"'", "password": "'"$_monitor_proxy_password"'" }' ${_monitor_eshost}/auth/log_in)
  code=$(_monitor_get_code "$output")

  [ "$code" = "200" ]
}

_monitor_send(){

  local url=$1
  local json=$2
  local log=$3

  local output body code

  if [ $_monitor_update_es -eq 0 ]; then
    return
  fi

  output=$(_monitor_do_curl --data-binary "$json" "$url")

  body=$(_monitor_get_body "$output")
  code=$(_monitor_get_code "$output")

  if [ "$code" = "401" ]; then

    if _monitor_login; then

      output=$(_monitor_do_curl --data-binary "$json" "$url")
      body=$(_monitor_get_body "$output")
      code=$(_monitor_get_code "$output")

      if [ "$code" != "200" ]; then
        logger "WARNING: Cannot send to the dashboard (got code $code), realtime data sending disabled"
        _monitor_update_es=0
      fi

    else
      logger "WARNING: Cannot log into the dashboard, realtime data sending disabled"
      _monitor_update_es=0
    fi

  elif [ "$code" != "200" ]; then
    logger "WARNING: Cannot send to the dashboard (got code $code), realtime data sending disabled"
    _monitor_update_es=0
  fi

  echo "$body" >> "$log"

}


_monitor_create_experiment(){

  local url="${_monitor_eshost}/${_monitor_experiment_index}/${_monitor_mapping}/${_monitor_experiment_id}/_update?pretty"
  local inner_json full_json

  inner_json=$( "${_monitor_experiment_info_func[@]}" )

  full_json='{
  "doc" : "'"$inner_json"'" },
  "upsert": "'"$inner_json"'" }
}
'

  printf '%s\n' "$full_json" > "$_monitor_log_dir/experiment_info.json"
  _monitor_send "$url" "$full_json" "$_monitor_log_dir/experiment_info.log"

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

  local url="${_monitor_eshost}/api/${_monitor_test_index}/${_monitor_mapping}/_bulk?pretty"
  local json=$( "${_monitor_func[@]}" )

  if [[ $json ]]; then
    # overwrite with latest non-empty result
    printf '%s\n' "$json" > "$_monitor_log_dir/update_tests.json"
    _monitor_send "$url" "$json"$'\n' "$_monitor_log_dir/update_tests.log"
  fi
}

_monitor_update_experiment () {

  local status=$1
  local url="${_monitor_eshost}/api/${_monitor_experiment_index}/${_monitor_mapping}/${_monitor_experiment_id}/_update?pretty"
  local json='{
  "doc" : { "status": "'"$status"'" },
  "upsert": { "status": "'"$status"'" }
}'

  printf '%s\n' "$json" > "$_monitor_log_dir/update_experiment.json"
  _monitor_send "$url" "$json" "$_monitor_log_dir/update_experiment.log"
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
