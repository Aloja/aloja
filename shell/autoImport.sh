#!/bin/bash

#simple script to check if folder has been imported before to move it or not
CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR=$(pwd)

source "$CUR_DIR/common/common.sh"

SHARE_DIR="$CUR_DIR/.."
IMPORT_DIR="$CUR_DIR/../import-jobs"
DONE_DIR="$IMPORT_DIR/DONE"
FAIL_DIR="$IMPORT_DIR/FAIL"

while true ; do

  logger "\nChecking for new files to copy...\n\n"
  bash $CUR_DIR/moveJobs2Import.sh

  logger "\nImporting jobs\n\n"
  cd "$IMPORT_DIR"
  bash $CUR_DIR/aloja-import2db.sh

  logger "\nRestarting MySQL\n\n"
  sudo /etc/init.d/mysql restart

  logger "\nDeleting caches\n\n"

  cd /var/www/;
  sudo git reset --hard HEAD;
  sudo git pull origin provider/rackspace;
  sudo rm -rf /var/www/aloja-web/cache/{query,twig}/* /tmp/CACHE_*;
  sudo rm -rf /tmp/twig/;
  sudo /etc/init.d/varnish restart;
  sudo service php5-fpm restart;
  sudo /etc/init.d/nginx restart;
  cd -

  logger "\nGenerating basic caches...\n\n"
  cd /tmp
  wget 'http://localhost/'
  wget 'http://localhost/benchdata'
  wget 'http://localhost/counters'
  wget 'http://localhost/benchexecs'
  wget 'http://localhost/bestconfig'
  wget 'http://localhost/configimprovement'
  wget 'http://localhost/parameval'
  wget 'http://localhost/costperfeval'
  wget 'http://localhost/perfcharts?random=1'
  wget 'http://localhost/metrics'
  wget 'http://localhost/metrics?type=MEMORY'
  wget 'http://localhost/metrics?type=DISK'
  wget 'http://localhost/metrics?type=NETWORK'
  wget 'http://localhost/dbscan'
  wget 'http://localhost/dbscanexecs'
  #wget 'http://localhost/'

  cd -

  logger "\nSleeping for 15 mins\n\n"
  sleep 900

done

