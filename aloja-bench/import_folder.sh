#!/usr/bin/env bash

# Script to import a supplied benchmark run folder into ALOJA-WEB

[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
source "$ALOJA_REPO_PATH/shell/common/include_import.sh"

input_folder="$1"
reload_caches="$2"

import_from_folder "$input_folder"

logger "INFO: URL of perf charts http://localhost:8080/perfcharts?execs[]=$id_exec"

logger "All done, took $(getElapsedTime startTime) seconds"