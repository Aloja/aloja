vm_install_base_packages() {

  if check_sudo ; then

    local bootstrap_file="vm_install_packages"

    if check_bootstraped "$bootstrap_file" ""; then
      logger "Installing packages for for VM $vm_name "

      local base_packages="dsh rsync sshfs sysstat gawk libxml2-utils ntp"

      #sudo sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list;

      #only update apt sources when is 1 day old (86400) to save time
      local install_packages_command='
#if [ ! -f /var/lib/apt/periodic/update-success-stamp ] || [ "$( $(date +%s) - $(stat -c %Y /var/lib/apt/periodic/update-success-stamp) )" -ge 86400 ]; then
#  sudo apt-get update -m;
#fi

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -m;
sudo apt-get -o Dpkg::Options::="--force-confold" install -y -f '

      local install_packages_command="$install_packages_command ssh $base_packages; sudo apt-get autoremove -y;"

      vm_execute "$install_packages_command"

      test_install_extra_packages="$(vm_execute "sar -V |grep 'Sebastien Godard' && dsh --version |grep 'Junichi'")"
      if [ ! -z "$test_install_extra_packages" ] ; then
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        logger "ERROR: installing base packages for $vm_name. Test output: $test_install_extra_packages"
      fi

    else
      logger "Packages already initialized"
    fi
  else
    logger "WARNING: no sudo access or disabled, no packages installed"
  fi
}

vm_install_extra_packages() {
  if check_sudo ; then

    local bootstrap_file="vm_install_extra_packages"

    if check_bootstraped "$bootstrap_file" ""; then
      logger "Installing extra packages for for VM $vm_name "

      vm_execute "sudo apt-get install -y -f screen vim mc git iotop htop;"

      local test_install_extra_packages="$(vm_execute "vim --version |grep 'VIM - Vi IMproved'")"
      if [ ! -z "$test_install_extra_packages" ] ; then
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        logger "ERROR: installing extra packages for $vm_name. Test output: $test_install_extra_packages"
      fi

    else
      logger "Extra packages already initialized"
    fi
  else
    logger "WARNING: no sudo access or disabled, no extra packages installed"
  fi
}




#$1 datadir (optional, if not uses default) $2 prod (default) or dev
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
sudo mkdir -p /etc/mysql/conf.d;
  "

    vm_update_template "/etc/mysql/conf.d/overrides.cnf" "$(get_mysqld_conf "$2")
$datadir" "secured"

    logger "INFO: Installing Percona"

    local ubuntu_version="trusty"
    vm_update_template "/etc/apt/sources.list" "deb http://repo.percona.com/apt $ubuntu_version main
deb-src http://repo.percona.com/apt $ubuntu_version main" "secured_file"

    #here we don't use templates as template backups are also read
    vm_execute "
sudo echo -e 'Package: *
Pin: release o=Percona Development Team
Pin-Priority: 1001' > /etc/apt/preferences.d/00percona.pref"

    #first install version 5.5 in case of migration
    vm_execute "
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A;
sudo apt-get update;
sudo apt-get install -y --force-yes percona-server-server-5.5" #first install 5.5 in case of migrations

    #upgrade to latest now
    test_action="$(vm_execute " [ \"\$\(sudo mysql -e 'SHOW VARIABLES LIKE \"version%\";' |grep 'Percona' && sudo mysql -e 'SHOW VARIABLES LIKE \"innodb_autoinc_lock_mode%\";' |grep '0'\)\" ] && echo '$testKey'")"
    if [ "$test_action" == "$testKey" ] ; then
      logger "INFO: Upgrading to latest version"
      vm_execute "sudo apt-get install -y --force-yes percona-server-server percona-xtrabackup qpress php5-mysql;"
    fi

    #retest
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

#$1 sample data data
install_ALOJA_DB() {

  local bootstrap_file="install_ALOJA_DB"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"


    logger "INFO: Attempting to create database schema and default values..."
    vm_execute "
bash $(get_repo_path)/shell/create-update_DB.sh
"

    if [ "$1" ] ; then
      logger "INFO: Inserting sample data (12k execs + 5 with perf details)"
      vm_execute "
sudo bash -c 'bzip2 -dc $(get_repo_path)/aloja.8d_2015_5execs.sql.bz2|mysql -f -b --show-warnings -B aloja2'
sudo bash -c 'bzip2 -dc $(get_repo_path)/aloja.execs.8d_2015.sql.bz2|mysql -f -b --show-warnings -B aloja2 '

"
#sudo bash -c 'bzip2 -dc $(get_repo_path)/aloja.execs.8d_2015.sql.bz2|mysql -f -b --show-warnings -B aloja2 '
#sudo bash -c 'bzip2 -dc $(get_repo_path)/aloja.8d_2015_5execs.sql.bz2|mysql -f -b --show-warnings -B aloja2'

#sudo bash -c 'bzip2 -dc $(get_repo_path)/shell/common/aloja2.sql.bz2|mysql aloja2 '
#sudo bash -c 'bzip2 -dc $(get_repo_path)/shell/common/aloja2.execs.sql.bz2|mysql aloja2 '

    fi


    test_action="$(vm_execute " [ \"\$(sudo mysql -B -e 'select * from aloja2.clusters;' |grep 'vagrant-99' )\" ] && echo '$testKey'")"

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

vm_install_webserver() {

  local bootstrap_file="vm_install_webserver"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    #TODO: remove php5-xdebug for prod servers
    logger "INFO: Installing NGINX and PHP"

    vm_execute "
sudo apt-get -y install python-software-properties software-properties-common python3-software-PROPERTIES
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
git clone https://github.com/Aloja/aloja.git /tmp/aloja
sudo cp -ru /tmp/aloja/. /var/www/

cd /var/www
sudo git checkout '$repo'

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

#update.packages(ask = FALSE,repos='http://cran.r-project.org',dependencies = c('Suggests'),quiet=TRUE);


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



install_sharelatex() {

  local bootstrap_file="install_sharelatex"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"


    logger "INFO: Installing ShareLatex"
    vm_execute "

sudo apt-get install git build-essential curl python-software-properties zlib1g-dev zip unzip
sudo add-apt-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install -y nodejs
sudo npm install -g grunt-cli
sudo npm install -g node-gyp

sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-get update
sudo apt-get install -y redis-server

#We recommend you have the append only option enabled so redis persists to disk. If you do not have this enabled a restart may mean you loose some document updates.
#appendonly yes


sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-org

sudo apt-get install aspell

#There are lots of additional dictionaries available, which can be listed with:
#apt-cache search aspell | grep aspell

wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xvf install-tl-unx.tar.gz
cd install-tl-*
sudo ./install-tl

export PATH=/usr/local/texlive/2014/bin/x86_64-linux:$PATH

#TEXDIR='/usr/local/texlive/2014'
#export PATH=$TEXDIR/bin/i386-linux:$PATH    # for 32-bit installation
#export PATH=$TEXDIR/bin/x86_64-linux:$PATH  # for 64-bit installation
#export INFOPATH=$INFOPATH:$TEXDIR/texmf-dist/doc/info
#export MANPATH=$MANPATH:$TEXDIR/texmf-dist/doc/man

sudo tlmgr install latexmk

git clone https://github.com/sharelatex/sharelatex.git
cd sharelatex
npm install
grunt install

#grunt check --force

grunt run:all


"
    test_action="$(vm_execute " [ \"\$\(which sharelatex)\" ] && echo '$testKey'")"

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
