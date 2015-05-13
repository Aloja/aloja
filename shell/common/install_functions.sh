#$1 datadir (optional, if not uses default)
install_percona() {

  local bootstrap_file="install_percona"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    if [ "$1" ] ; then
      local datadir="datadir=$1"
    else
      local datadir=""
    fi


    logger "Installing Percona server"

    logger "INFO: Removing previous MySQL (if installed)"
    vm_execute "
sudo cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
sudo service mysql stop;
sudo apt-get remove -y mysql-server mysql-client mysql-common;
sudo apt-get autoremove -y;
  "

    vm_update_template "/etc/mysql/conf.d/overrides.cnf" "$(get_mysqld_conf)
$datadir" "secured"

    logger "INFO: Installing Percona"

    local ubuntu_version="trusty"
    vm_update_template "/etc/apt/sources.list" "deb http://repo.percona.com/apt $ubuntu_version main
deb-src http://repo.percona.com/apt $ubuntu_version main" "secured_file"

    #here we don't use templates as template backups are also read
    vm_execute "
sudo echo -e 'Package: *
Pin: release o=Percona Development Team
Pin-Priority: 1001 > /etc/apt/preferences.d/00percona.pref"

    #first install version 5.5 in case of migration
    vm_execute "
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A;
sudo apt-get update;
sudo apt-get install -y percona-server-server-5.5"

    test_action="$(vm_execute " [ \"\$\(sudo mysql -e 'SHOW VARIABLES LIKE \"version%\";' |grep 'Percona' && sudo mysql -e 'SHOW VARIABLES LIKE \"innodb_autoinc_lock_mode%\";' |grep '0'\)\" ] && echo '$testKey'")"
    if [ "$test_action" == "$testKey" ] ; then
      logger "INFO: Upgrading to latest version"
      vm_execute "sudo apt-get install -y percona-server-server percona-xtrabackup qpress php5-mysql;"
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

# NOT USED ANY MORE
#vm_install_pyxtrabackup() {
#
#  local bootstrap_file="vm_install_pyxtrabackup"
#
#  if check_bootstraped "$bootstrap_file" ""; then
#    logger "Executing $bootstrap_file"
#
#    logger "INFO: Installing pip and pyxtrabackup"
#    vm_execute "
#sudo apt-get install -y curl python;
#sudo curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | sudo python2.7;
#sudo pip install pyxtrabackup;
#"
#
#    test_action="$(vm_execute " [ \"\$(which pyxtrabackup |grep 'pyxtrabackup')\" ] && echo '$testKey'")"
#
#    if [ "$test_action" == "$testKey" ] ; then
#      logger "INFO: $bootstrap_file installed succesfully"
#      #set the lock
#      check_bootstraped "$bootstrap_file" "set"
#    else
#      logger "ERROR: at $bootstrap_file for $vm_name. Test output: $test_action"
#    fi
#
#  else
#    logger "$bootstrap_file already configured"
#  fi
#
#}


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

vm_install_webserver() {

  local bootstrap_file="vm_install_webserver"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    #TODO: remove php5-xdebug for prod servers
    logger "INFO: Installing NGINX and PHP"

    vm_execute "
sudo apt-get install python-software-properties software-properties-common python3-software-PROPERTIES
sudo add-apt-repository -y ppa:ondrej/php5 #up to date PHP version
sudo apt-get update
sudo apt-get install --force-yes -y php5-fpm php5-cli php5-mysql php5-xdebug php5-curl nginx

sudo bash -c 'cat << \"EOF\" > /etc/nginx/sites-available/default
$(get_nginx_conf)
EOF
'

sudo service nginx restart

sudo bash -c 'sudo cat << \"EOF\" > /etc/php5/fpm/conf.d/90-overrides.ini
$(get_php_conf)
EOF
'

sudo service php5-fpm restart
"

    test_action="$(vm_execute " [ \"\$\(pgrep nginx && pgrep php5-fpm)\" ] && echo '$testKey'")"

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

#$1 repo name (optional)
vm_install_repo() {

  local bootstrap_file="vm_install_repo"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    if [ "$1" ] ; then
      local repo="$1"
    else
      local repo="master"
    fi

    logger "INFO: Installing branch $1"
    vm_execute "

sudo mkdir -p /var/www

sudo rm -rf /tmp/aloja;
mkdir -p /tmp/aloja
sudo git clone https://github.com/Aloja/aloja.git /tmp/aloja
sudo cp -ru /tmp/aloja/* /var/www/

cd /var/www
sudo git checkout $repo

sudo mkdir -p /var/www/aloja-web/vendor
sudo chown www-data: -R /var/www && sudo chmod 775 -R /var/www/aloja-web/vendor
sudo bash -c 'cd /var/www/aloja-web/ && php composer.phar update'
sudo chown www-data: -R /var/www && sudo chmod 775 -R /var/www/aloja-web/vendor

sudo cp /var/www/aloja-web/config/config.sample.yml /var/www/aloja-web/config/config.yml

sudo service php5-fpm restart
sudo service nginx restart

"
    test_action="$(vm_execute " [ \"\$\(wget -q -O- http://localhost/|grep 'ALOJA')\" ] && echo '$testKey'")"

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

install_R() {

  local bootstrap_file="install_R"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

	## For Ubuntu 12.04
#	add-apt-repository 'deb http://cran.es.r-project.org/bin/linux/ubuntu precise/'
#	apt-get update
#	apt-get install "openjdk-7-jre-lib" "openjdk-7-jre-headless" "openjdk-7-jdk" "r-base" "r-base-core" "r-base-dev" "r-base-html" \
#	"r-cran-bitops" "r-cran-boot" "r-cran-class" "r-cran-cluster" "r-cran-codetools" "r-cran-foreign" "r-cran-kernsmooth" \
#	"r-cran-lattice" "r-cran-mass" "r-cran-matrix" "r-cran-mgcv" "r-cran-nlme" "r-cran-nnet" "r-cran-rpart" "r-cran-spatial" \
#	"r-cran-survival" "r-recommended" "r-cran-colorspace" "r-cran-getopt" "r-cran-rcolorbrewer" "r-cran-rcpp" "libcurl4-openssl-dev" \
#	"libxml2-dev" "gsettings-desktop-schemas" -y --force-yes

# Only for Ubuntu 12.04
#install.packages(c("rjson","evaluate","labeling","memoise","munsell","stringr","rJava"),repos="http://cran.r-project.org",
#dependencies=TRUE,quiet=TRUE); # Installed on Update: RCurl, plyr, dichromat, devtools, digest, reshape, scales


    logger "INFO: Installing R packages for Ubuntu 14"
    vm_execute "
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

## For Ubuntu 14.04
sudo add-apt-repository 'deb http://cran.r-project.org/bin/linux/ubuntu trusty/'
sudo apt-get update
sudo wget http://security.ubuntu.com/ubuntu/pool/main/t/tiff/libtiff4_3.9.5-2ubuntu1.6_amd64.deb
sudo dpkg -i ./libtiff4_3.9.5-2ubuntu1.6_amd64.deb
sudo apt-get install curl libxml2-dev libcurl4-openssl-dev openjdk-7-jre-lib openjdk-7-jre-headless openjdk-7-jdk r-base r-base-core r-base-dev r-base-html \
	r-cran-bitops r-cran-boot r-cran-class r-cran-cluster r-cran-codetools r-cran-foreign r-cran-kernsmooth \
	r-cran-lattice r-cran-mass r-cran-matrix r-cran-mgcv r-cran-nlme r-cran-nnet r-cran-rpart r-cran-spatial \
	r-cran-survival r-recommended r-cran-rjson r-cran-rcurl r-cran-colorspace r-cran-dichromat r-cran-digest \
	r-cran-evaluate r-cran-getopt r-cran-labeling r-cran-memoise r-cran-munsell r-cran-plyr r-cran-rcolorbrewer \
	r-cran-rcpp r-cran-reshape r-cran-rjava r-cran-scales r-cran-stringr gsettings-desktop-schemas -y --force-yes

sudo R CMD javareconf

cat <<- EOF > /tmp/packages.r
#!/usr/bin/env Rscript

update.packages(ask = FALSE,repos='http://cran.r-project.org',dependencies = c('Suggests'),quiet=TRUE);


# For all Ubuntu releases until 14.04
install.packages(c('devtools','DiscriMiner','emoa','httr','jsonlite','optparse','pracma','rgp','rstudioapi','session','whisker',
'RWeka','RWekajars','ggplot2','rms','snowfall','genalg','FSelector'),repos='http://cran.r-project.org',dependencies=TRUE,quiet=TRUE);
EOF

sudo chmod a+x /tmp/packages.r
sudo /tmp/packages.r
"

    test_action="$(vm_execute " [ \"\$\(which R)\" ] && echo '$testKey'")"

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