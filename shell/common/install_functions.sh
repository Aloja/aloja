
vm_install_percona() {

  local bootstrap_file="vm_install_percona"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "Installing Percona server"

    logger "INFO: Removing previous MySQL (if installed)"
    vm_execute "
sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
sudo service mysql stop;
sudo apt-get remove -y mysql-server mysql-client mysql-common;
sudo apt-get autoremove -y;
  "

    logger "INFO: Installing Percona"

    local ubuntu_version="trusty"
    vm_update_template "/etc/apt/sources.list" "deb http://repo.percona.com/apt $ubuntu_version main
deb-src http://repo.percona.com/apt $ubuntu_version main" "secured_file"


    vm_update_template "/etc/apt/preferences.d/00percona.pref" "Package: *
Pin: release o=Percona Development Team
Pin-Priority: 1001" "secured_file"

    vm_execute "
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A;
sudo apt-get update;
sudo apt-get install -y percona-server-server-5.5"

    test_action="$(vm_execute " [ \"\$(sudo mysql -e 'SHOW VARIABLES LIKE \"version%\";' |grep 'Percona')\" ] && echo '$testKey'")"
    if [ "$test_action" == "$testKey" ] ; then
      logger "INFO: Upgrading to latest version"
      vm_execute "sudo apt-get install -y percona-server-server percona-xtrabackup php5-mysql;"
    fi

    test_action="$(vm_execute " [ \"\$(sudo mysql -e 'SHOW VARIABLES LIKE \"version%\";' |grep 'Percona')\" ] && echo '$testKey'")"

    if [ "$test_action" == "$testKey" ] ; then
      logger "INFO: $bootstrap_file installed succesfully"
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR: at $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    logger "$bootstrap_file already configured"
  fi

}

vm_install_pyxtrabackup() {

  local bootstrap_file="vm_install_pyxtrabackup"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Installing pip and pyxtrabackup"
    vm_execute "
sudo apt-get install -y curl python;
sudo curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | sudo python2.7;
sudo pip install pyxtrabackup;
"

    test_action="$(vm_execute " [ \"\$(which pyxtrabackup |grep 'pyxtrabackup')\" ] && echo '$testKey'")"

    if [ "$test_action" == "$testKey" ] ; then
      logger "INFO: $bootstrap_file installed succesfully"
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR: at $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    logger "$bootstrap_file already configured"
  fi

}


vm_install_IB() {

  local bootstrap_file="vm_install_IB"

  if check_bootstraped "$bootstrap_file" ""; then

    #since the installation is quite slow we first test if it is working
    test_action="$(vm_execute " [ \"\$(ping -c 1 $(get_vm_IB_hostname $vm_name))\" ] && echo '$testKey'")"

    if [ "$test_action" != "$testKey" ] ; then

      local work_dir="/tmp"
      local driver_name="MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64.tgz"

      logger "INFO: Installing InfiniBand drivers"
      logger "INFO: uninstalling conflicting packages (if needed)"
      vm_execute "sudo apt-get -y remove libopenmpi1.6 openmpi-doc libopenmpi-dev openmpi-common mpi-default-bin openmpi-bin;"

      logger "INFO: Downloading drivers (if needed)"

      vm_execute "[ ! -f "$work_dir/$driver_name" ] && wget 'https://www.dropbox.com/s/d8u924cuiurhy3v/$driver_name?dl=1' -O '$work_dir/$driver_name'"
      #cp /home/dcarrera/MLNX_OFED_LINUX-2.4-1.0.0-ubuntu14.04-x86_64.tgz .

      logger "INFO: Untaring drivers"
      vm_execute "cd $work_dir; tar -xzf '$driver_name'"

      logger "INFO: Installing drivers"
      vm_execute "
cd $work_dir/${driver_name%.*}
sudo ./mlnxofedinstall --without-fw-update --hpc -q
sudo /etc/init.d/openibd restart
sudo /usr/bin/hca_self_test.ofed
"

      logger "INFO: Checking if installation was succesfull"
      if [ "$(grep IB /etc/network/interfaces 2> /dev/null)" ] ; then
        logger "INFO: IB interface already created"
      else
        logger "INFO: IB interface NOT created, intalling..."
        local IP_suffix="$(vm_execute 'ifconfig eth0 |grep Mask | cut -d "." -f 4 |cut -d " " -f 1')"
        logger "INFO: Updating /etc/network/interfaces with IP_suffix: $IP_suffix"
        vm_update_template "/etc/network/interfaces" "
#IB Interface
iface ib0 inet static
address 10.0.1.$IP_suffix
netmask 255.255.0.0" "secured_file"

        logger "INFO: bringing up interface"
        vm_execute "sudo ifdown ib0; sudo ifup ib0;"

      fi

      logger "INFO: Recreating /etc/hosts with IB names for $(get_vm_IB_hostname $vm_name)"
      vm_update_template "/etc/hosts" "$(get_IB_hostnames)" "secured_file"

      test_action="$(vm_execute " [ \"\$(ping -c 1 $(get_vm_IB_hostname $vm_name))\" ] && echo '$testKey'")"

      if [ "$test_action" == "$testKey" ] ; then
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
      fi
    else
      logger "$bootstrap_file already configured"
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    fi
  else
    logger "$bootstrap_file already configured"
  fi
}


make_webserver(){

#upgrade without prompts
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

if ! which nginx > /dev/null ; then
  sudo apt-get install python-software-properties software-properties-common python3-software-PROPERTIES
  add-apt-repository -y ppa:ondrej/php5 #up to date PHP version
  apt-get update
  apt-get install --force-yes -y python-software-properties zip git \
                     dsh sysstat bwm-ng \
                     php5-fpm php5-cli php5-mysql php5-xdebug php5-curl \
                     nginx

  echo -e '
server {
  listen 80;
  server_name _;
  root /var/www/aloja-web/;

  index index.html index.php;
  autoindex on;

  location / {
    index index.php;
    try_files $uri $uri/ /index.php?q=$uri&$args;
    autoindex on;
  }

  location /slides {
    alias /var/presentations/aloja-web;
    index template.html;
  }

  location ~ \.php$ {
#    try_files $uri =404;
    try_files $uri /index.php?c=404&q=$uri&$args;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_index index.php;
    include fastcgi_params;
    #fastcgi_read_timeout 600; # Set fairly high for debugging
    fastcgi_intercept_errors on;
  }

  error_page 404 /index.php?c=404&q=$uri&$args;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  #keepalive_timeout ;

  #avoid caches
  sendfile off;
  expires off;

  # allow the server to close the connection after a client stops responding. Frees up socket-associated memory.
  reset_timedout_connection on;

  #perf optimizations
  tcp_nodelay on;

  gzip on;
  gzip_comp_level 2;
  gzip_proxied any;
  gzip_types text/plain text/css text/javascript application/json application/x-javascript text/xml application/xml application/xml+rss;
  gzip_disable "msie6";
}
' > "/etc/nginx/sites-available/default"


#echo -e '' > "/etc/nginx/nginx.conf"

  service nginx restart

  echo -e '
memory_limit = 1024M
xdebug.default_enable = 0
xdebug.remote_enable = 0
' > "/etc/php5/fpm/conf.d/90-overrides.ini"

  service php5-fpm restart

  sudo chown www-data.www-data -R /var/www/aloja-web/vendor && sudo chmod 775 -R /var/www/aloja-web/vendor
  bash -c "cd /vagrant/workspace/aloja-web && php composer.phar update"


fi

if ! which mysqld > /dev/null ; then
  export DEBIAN_FRONTEND=noninteractive

  add-apt-repository 'deb http://repo.percona.com/apt trusty main'
  echo -e "Package: *
  Pin: release o=Percona Development Team
  Pin-Priority: 1001" > "/etc/apt/preferences.d/00percona.pref"

  apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A;
  apt-get update;
  apt-get install --force-yes -y percona-server-server-5.6

  echo -e '
[mysqld]

bind-address=0.0.0.0
skip-external-locking
key_buffer_size		= 64M
tmp_table_size		= 32M
table_cache      	= 256
query_cache_limit	= 3M
query_cache_size  = 32M

# Set Base Innodb Specific settings here
innodb_autoinc_lock_mode=0
innodb_flush_method		= O_DIRECT
innodb_file_per_table		= 1
innodb_file_format		= barracuda
innodb_max_dirty_pages_pct 	= 90
innodb_lock_wait_timeout 	= 20
innodb_flush_log_at_trx_commit 	= 2
innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size 	= 128M
innodb_thread_concurrency 	= 8

' > "/etc/mysql/conf.d/overrides.cnf"

  service mysql restart

  bash "/vagrant/shell/create-update_DB.sh"

fi


if ! which R > /dev/null; then
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

	## For Ubuntu 14.04
	add-apt-repository 'deb http://cran.es.r-project.org/bin/linux/ubuntu trusty/'
	apt-get update
	wget http://security.ubuntu.com/ubuntu/pool/main/t/tiff/libtiff4_3.9.5-2ubuntu1.6_amd64.deb
	dpkg -i ./libtiff4_3.9.5-2ubuntu1.6_amd64.deb
	apt-get install "openjdk-7-jre-lib" "openjdk-7-jre-headless" "openjdk-7-jdk" "r-base" "r-base-core" "r-base-dev" "r-base-html" \
	"r-cran-bitops" "r-cran-boot" "r-cran-class" "r-cran-cluster" "r-cran-codetools" "r-cran-foreign" "r-cran-kernsmooth" \
	"r-cran-lattice" "r-cran-mass" "r-cran-matrix" "r-cran-mgcv" "r-cran-nlme" "r-cran-nnet" "r-cran-rpart" "r-cran-spatial" \
	"r-cran-survival" "r-recommended" "r-cran-rjson" "r-cran-rcurl" "r-cran-colorspace" "r-cran-dichromat" "r-cran-digest" \
	"r-cran-evaluate" "r-cran-getopt" "r-cran-labeling" "r-cran-memoise" "r-cran-munsell" "r-cran-plyr" "r-cran-rcolorbrewer" \
	"r-cran-rcpp" "r-cran-reshape" "r-cran-rjava" "r-cran-scales" "r-cran-stringr" "gsettings-desktop-schemas" -y --force-yes

	R CMD javareconf

	cat <<- EOF > /tmp/packages.r
	#!/usr/bin/env Rscript

	update.packages(ask = FALSE,repos="http://cran.es.r-project.org",dependencies = c('Suggests'),quiet=TRUE);

	# Only for Ubuntu 12.04
	#install.packages(c("rjson","evaluate","labeling","memoise","munsell","stringr","rJava"),repos="http://cran.es.r-project.org",
	#dependencies=TRUE,quiet=TRUE); # Installed on Update: RCurl, plyr, dichromat, devtools, digest, reshape, scales

	# For all Ubuntu releases until 14.04
	install.packages(c("devtools","DiscriMiner","emoa","httr","jsonlite","optparse","pracma","rgp","rstudioapi","session","whisker",
	"RWeka","RWekajars","ggplot2","rms"),repos="http://cran.es.r-project.org",dependencies=TRUE,quiet=TRUE);
	EOF

	chmod a+x /tmp/packages.r
	/tmp/packages.r
fi


}