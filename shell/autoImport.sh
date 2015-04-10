#!/bin/bash
#simple script to check if folder has been imported before to move it or not

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR/common/include_process_jobs.sh"

#$1 url
hit_page() {
  wget -O /dev/null "$1"
  #-o /dev/null
}

while true ; do

  logger "\nChecking for new files to copy...\n\n"
  source $CUR_DIR/moveJobs2Import.sh "$IMPORT_DIR"

  logger "\nImporting jobs\n\n"
  cd "$IMPORT_DIR"
  bash $CUR_DIR/aloja-import2db.sh "ONLY_META_DATA"
  bash $CUR_DIR/aloja-import2db.sh

  #logger "\nRestarting MySQL and fixing permissions (just in case)\n\n"
  #sudo service mysql stop
  #sudo chown mysql:mysql /scratch/attached/1/mysql
  #sudo service mysql start

  logger "\nDeleting caches\n\n"

  cd /var/www/;
  sudo git reset --hard HEAD;
  sudo git --no-edit pull origin provider/rackspace;
  #sudo rm -rf /var/www/aloja-web/cache/{query,twig}/* /tmp/CACHE_* /tmp/twig/*;
  sudo rm -rf /var/www/aloja-web/cache/twig/* /tmp/twig/*;
  sudo /etc/init.d/varnish restart;
  sudo service php5-fpm restart;
  sudo /etc/init.d/nginx restart;
  cd -

  logger "\nGenerating basic caches...\n\n"
  hit_page 'http://localhost/?NO_CACHE=1'
  hit_page 'http://localhost/benchdata?NO_CACHE=1'
  hit_page 'http://localhost/counters?NO_CACHE=1'
  hit_page 'http://localhost/benchexecs?NO_CACHE=1'
  hit_page 'http://localhost/bestconfig?NO_CACHE=1'
  hit_page 'http://localhost/configimprovement?NO_CACHE=1'
  hit_page 'http://localhost/parameval?NO_CACHE=1'
  hit_page 'http://localhost/costperfeval?NO_CACHE=1'
  hit_page 'http://localhost/perfcharts?random=1?NO_CACHE=1'
  hit_page 'http://localhost/metrics?NO_CACHE=1'
  hit_page 'http://localhost/metrics?type=MEMORY&NO_CACHE=1'
  hit_page 'http://localhost/metrics?type=DISK&NO_CACHE=1'
  hit_page 'http://localhost/metrics?type=NETWORK&NO_CACHE=1'
  hit_page 'http://localhost/dbscan?NO_CACHE=1'
  hit_page 'http://localhost/dbscanexecs?NO_CACHE=1'

  hit_page 'http://localhost/'
  hit_page 'http://localhost/benchdata'
  hit_page 'http://localhost/counters'
  hit_page 'http://localhost/benchexecs'
  hit_page 'http://localhost/bestconfig'
  hit_page 'http://localhost/configimprovement'
  hit_page 'http://localhost/parameval'
  hit_page 'http://localhost/costperfeval'
  hit_page 'http://localhost/perfcharts?random=1'
  hit_page 'http://localhost/metrics'
  hit_page 'http://localhost/metrics?type=MEMORY'
  hit_page 'http://localhost/metrics?type=DISK'
  hit_page 'http://localhost/metrics?type=NETWORK'
  hit_page 'http://localhost/dbscan'
  hit_page 'http://localhost/dbscanexecs'
  #hit_page 'http://localhost/'

  logger "\nSleeping for 15 mins\n\n"
  sleep 900

done

