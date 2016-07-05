#!/usr/bin/env bash

# Script to import a supplied benchmark run folder into ALOJA-WEB

[ ! "$ALOJA_REPO_PATH" ] && ALOJA_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
source "$ALOJA_REPO_PATH/shell/common/include_import.sh"

input_folder="$1"
reload_caches="$2"
export_to_PAT="$3"

import_from_folder "$input_folder" "$reload_caches" "$export_to_PAT"

[ ! "$reload_caches" ] && logger "WARNING: remember to reload caches manually (not specified to this script)"
logger "All done, took $(getElapsedTime startTime) seconds"