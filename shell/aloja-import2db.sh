#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

source "$CUR_DIR/common/include_import.sh"
source "$CUR_DIR/common/import_functions.sh"

set_import_globals

#in case we only want to insert the data for the execs table (much faster)
if [ "$1" ] ; then
 ONLY_META_DATA="1"
 REDO_ALL=""
 REDO_UNTARS=""
 MOVE_TO_DONE=""
fi

#TODO check if these variables are still needed
first_host=""
hostn=""


#logger "Dropping database $DB"
#sudo mysql $MYSQL_CREDENTIALS -e "DROP database $DB;"

if [ "$INSERT_DB" == "1" ] ; then
  source "$CUR_DIR/common/create_db.sh"
fi

######################################



logger "Starting"

for folder in 201* ; do
	if [[ "$folder" =~ hdi[0-9]+ ]]; then
		#HDinsight on windows log -- hdi linux are named hdil
		source "$CUR_DIR/hdinsight/hdi-import2db.sh"
		importHDIJobs "$ONLY_META_DATA" 
	else
		import_folder "$folder"
	fi
done #end for folder