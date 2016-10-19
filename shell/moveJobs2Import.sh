#!/bin/bash
#simple script to check if folder has been imported before to move it or not

#if no param is passed, then we need to source the main file
if [ ! "$1" ] ; then
  CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  source "$CUR_DIR/common/include_process_jobs.sh"
fi

#$1 folder to look
folder_already_DONE() {
  if [ "$(ls -l $DONE_DIR/$1 2> /dev/null)" ] || [ "$(ls -l $FAIL_DIR/$1 2> /dev/null)" ] || [ "$(ls -l $FAIL_DIR/{0..3}/$1 2> /dev/null)" ]  ; then
    logger "Found $1"
    return 0
  else
    logger "Not found $1"
    return 1
  fi
}

#main loop
logger "Starting..."

for jobs_folder in $SHARE_DIR/jobs_* ; do

  logger "INFO: iterating folder $jobs_folder"
  cd "$jobs_folder"

  for exec_folder in 201* ; do
    if [ -d "$exec_folder" ] ; then
      if (( "${exec_folder:0:4}" > "2015" )) ; then
        #make sure there is a finished benchmark
        #if [ "$(ls *.tar.bz2 2> /dev/null |grep -v 'host_conf.tar.bz2'|grep -v 'prep_')" ] ; then
        if [ "$(ls $exec_folder/*.tar.bz2 2> /dev/null |egrep -v -e 'host_conf.tar.bz2' -e 'prep_.*.tar.bz2')" ] ; then

          if ! folder_already_DONE "$exec_folder" ; then
            logger "Copying $exec_folder to $IMPORT_DIR"
            cp -ru "$exec_folder" "$IMPORT_DIR/"
          fi

        else
          logger "ERROR: cannot find benchmark in $exec_folder"
        fi
      else
        logger "ERROR: $exec_folder year not > 2015!"
      fi
    else
      logger "ERROR: $exec_folder not a folder!"
    fi
  done

  cd ..

done

