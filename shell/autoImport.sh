#!/bin/bash
#simple script to check if folder has been imported before to move it or not

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR/common/include_process_jobs.sh"

repo="master"

while true ; do

  logger "\nChecking for new files to copy...\n\n"
  source $CUR_DIR/moveJobs2Import.sh "$IMPORT_DIR"

  logger "\nImporting jobs\n\n"
  cd "$IMPORT_DIR"
  WORK_IN_MEM=1 bash $CUR_DIR/aloja-import2db.sh "ONLY_META_DATA"
  WORK_IN_MEM=1 bash $CUR_DIR/aloja-import2db.sh

  #logger "\nRestarting MySQL and fixing permissions (just in case)\n\n"
  #sudo service mysql stop
  #sudo chown mysql:mysql /scratch/attached/1/mysql
  #sudo service mysql start

  logger "\nDeleting caches\n\n"

  cd /var/www/;
  sudo git checkout "$repo";
  sudo git fetch;
  if [ ! "$(git status| grep 'branch is up-to-date')" ] ; then
    update_cache="true"
    sudo git reset --hard HEAD;
    sudo git pull --no-edit origin "$repo";
    #sudo rm -rf /var/www/aloja-web/cache/{query,twig}/* /tmp/CACHE_* /tmp/twig/*;
    sudo rm -rf /var/www/aloja-web/cache/twig/*;
    sudo service php5-fpm restart;
    sudo /etc/init.d/nginx restart;
  else
    logger "INFO: branch $repo is up to date. Not updating caches"
  fi
  cd -;

  if [ ! "$update_cache" ] ; then
    refresh_web_caches "localhost"
  fi

  logger "\nSleeping for 15 mins\n\n"
  sleep 900
done

