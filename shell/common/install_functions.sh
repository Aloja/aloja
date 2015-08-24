# File to group install functions

# Function to group install packages to avoid repetition of options
# $1 list of packages
# $2 if to update the repo first (optional)
install_packages() {
  local packages_list="$1"
  local update_repo="$2"

  [ ! "$packages_list" ] && die "No package to install defined. Exiting..."

  if check_sudo ; then

    if [[ "$vmOSType" == "Ubuntu" ]] ; then #&& "$vmOSTypeVersion" == "14.04"
      if [ "$update_repo" ] ; then

        #sudo sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list;
        #only update apt sources when is 1 day old (86400) to save time
        #if [ ! -f /var/lib/apt/periodic/update-success-stamp ] || [ "$( $(date +%s) - $(stat -c %Y /var/lib/apt/periodic/update-success-stamp) )" -ge 86400 ]; then
        #  sudo apt-get update -m;
        #fi

        logger "INFO: Updating repo for $vmOSType $vmOSTypeVersion"
        vm_execute "
export DEBIAN_FRONTEND=noninteractive;
sudo apt-get update -m;
  " || return $?
      fi

      logger "INFO: Intalling for $vmOSType $vmOSTypeVersion packages: $packages_list"

      vm_execute "
export DEBIAN_FRONTEND=noninteractive;
sudo apt-get -o Dpkg::Options::='--force-confold' install -y --force-yes $packages_list
  " || return $?

  #sudo apt-get autoremove -y;

    else
      die " OS type: $vmOSType install packages not implemented yet. You have work to do!, Exiting..."
    fi

  else
      logger "WARNING: no sudo access or disabled, no packages installed"
  fi
}

# Unifies repo updates
# $1 repo
# $2 don't update the repo (optional, to save time)
install_repo() {
  local repo="$1"
  local dont_update="$2"

  [ ! "$repo" ] && die "no repo defined. Exiting"

  if check_sudo ; then
    if [[ "$vmOSType" == "Ubuntu" ]] ; then

      [ ! "$dont_update" ] && local update="sudo apt-get update -m;" || local update=""

      vm_execute "
export DEBIAN_FRONTEND=noninteractive;
sudo add-apt-repository -y '$repo'
$update
"
    else
      die " OS type: $vmOSType install packages not implemented yet. You have work to do!, Exiting..."
    fi
  else
      logger "WARNING: no sudo access or disabled, no repo installed"
  fi
}

# Function to wrap wget usage
# $1 Full URL
# $2 output filename and path (optional)
aloja_wget() {
  local URL="$1"
  local out_file_name="$2"

  local wget_command="wget --progress=dot -e dotbytes=10M $URL"
  [ "$out_file_name" ] && wget_command="$wget_command -O $out_file_name"

  vm_execute "$wget_command" #--no-verbose

  return $?
}

# install the base packages for VMs
vm_install_base_packages() {
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Installing packages for for VM $vm_name "

    install_packages "ssh dsh rsync sshfs sysstat gawk libxml2-utils ntp wget curl unzip wamerican" "update" #wamerican is for hivebench

    local test_action="$(vm_execute "sar -V |grep 'Sebastien Godard' && dsh --version |grep 'Junichi' && echo '$testKey'")" #checks for sysstat
    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR: installing base packages for $vm_name. Test output: $test_action"
    fi

  else
    logger "Packages already initialized"
  fi
}

vm_install_extra_packages() {
    local bootstrap_file="${FUNCNAME[0]}"

    if check_bootstraped "$bootstrap_file" ""; then
      logger "Installing extra packages for for VM $vm_name "

      install_packages "screen vim mc git iotop htop;"

      local test_action="$(vm_execute "vim --version |grep 'VIM - Vi IMproved' && echo '$testKey'")"
      if [[ "$test_action" == *"$testKey"* ]] ; then
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        logger "ERROR: installing extra packages for $vm_name. Test output: $test_install_extra_packages"
      fi

    else
      logger "Extra packages already initialized"
    fi
}

#$1 datadir (optional, if not uses default) $2 prod (default) or dev
install_percona() {

  local bootstrap_file="${FUNCNAME[0]}"

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

#for 5.5 to 5.6 migrations first install 5.5 in case of migrations
#sudo apt-get install -y --force-yes percona-server-server-5.5

    #here we don't use templates as template backups are also read
    vm_execute "
sudo echo -e 'Package: *
Pin: release o=Percona Development Team
Pin-Priority: 1001' > /etc/apt/preferences.d/00percona.pref;
sudo apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A;
sudo apt-get update;"

    install_packages "percona-server-server percona-xtrabackup qpress php5-mysql"

    #test
    local test_action="$(vm_execute " [ \"\$(sudo mysql -e 'SHOW VARIABLES LIKE \"version%\";' |grep 'Percona')\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

# Creates the default DB and installs a dump if specified
# $1 dump URL
install_ALOJA_DB() {

  local bootstrap_file="${FUNCNAME[0]}"

  local download_URL="$1"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    if [ "$download_URL" ] ; then
      logger "INFO: Downloading DB dump from $download_URL"
      # TODO this code expects the file to be tar.bz2
      local dump_name="/tmp/dump.tar.bz2"

      aloja_wget "$download_URL" "$dump_name"

      logger "INFO: Installing DB dump into MySQL"
      # need to drop aloja_logs so that imported tables are moved
      vm_execute "
sudo bash -c 'bzip2 -dc $dump_name|mysql -f -b --show-warnings -B';
rm '$dump_name';
"

    fi

    logger "INFO: Updating database schema and default values..."
    vm_execute "
bash $(get_repo_path)/shell/create-update_DB.sh
"

    local test_action="$(vm_execute " [ \"\$(sudo mysql -B -e 'select * from aloja2.clusters;' |grep 'vagrant-99' )\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

# executes create-update DB script
update_ALOJA_DB () {
  logger "Updating DB..."
  local result="$(vm_execute "$(get_repo_path)/shell/create-update_DB.sh 2>&1 /dev/null")"  #hide update output
  logger "Updating DB ready"
}

# OLD install DB function, enable manually
#$1 sample data data
install_ALOJA_DB_test() {

  local bootstrap_file="${FUNCNAME[0]}"

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

    local test_action="$(vm_execute " [ \"\$(sudo mysql -B -e 'select * from aloja2.clusters;' |grep 'vagrant-99' )\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

  local bootstrap_file="${FUNCNAME[0]}"

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

      vm_execute "[ ! -f '$work_dir/$driver_name' ] && wget --no-verbose '$ALOJA_PUBLIC_HTTP/files/IB/$driver_name' -O '$work_dir/$driver_name'"
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

      local test_action="$(vm_execute " [ \"\$(ping -c 1 $(get_vm_IB_hostname $vm_name))\" ] && echo '$testKey'")"

      if [[ "$test_action" == *"$testKey"* ]] ; then
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

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    #TODO: remove php5-xdebug for prod servers
    logger "INFO: Installing NGINX and PHP"

    install_packages "python-software-properties software-properties-common python3-software-PROPERTIES"
    install_repo "ppa:ondrej/php5" #up to date PHP version
    install_packages "php5-fpm php5-cli php5-mysql php5-xdebug php5-curl nginx"

    logger "INFO: Configuring NGINX and PHP"
    vm_execute "
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

    local test_action="$(vm_execute " [ \"\$\(pgrep nginx && pgrep php5-fpm)\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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


#install defined PHP composer vendors
install_PHP_vendors() {

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Checking if to download vendor files"

    local test_action="$(vm_execute " [ -f '/var/www/aloja-web/vendor/autoload.php' ] && echo '$testKey'")"

    if [[ "$test_action" != *"$testKey"* ]] ; then
      logger "INFO: downloading and copying bundled vendors folder"

      aloja_wget "$ALOJA_PUBLIC_HTTP/files/PHP_vendors_20150818.tar.bz2"  "/tmp/PHP_vendors.tar.bz2"

      vm_execute "
cd /tmp;
tar -xjf PHP_vendors.tar.bz2;
sudo cp -r vendor /var/www/aloja-web/;
"
    fi

    logger "INFO: Installing PHP composer vendors"
    vm_execute "
sudo mkdir -p /var/www/aloja-web/vendor;
sudo chown www-data: -R /var/www && sudo chmod 775 -R /var/www/aloja-web/vendor;
sudo bash -c 'cd /var/www/aloja-web/ && php composer.phar update';
sudo chown www-data: -R /var/www && sudo chmod 775 -R /var/www/aloja-web/vendor;
"
    local test_action="$(vm_execute " [ -f '/var/www/aloja-web/vendor/autoload.php' ] && echo '$testKey'")"

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

  if [ "$1" ] ; then
    local repo="$1"
  else
    local repo="master"
  fi

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Installing branch $1"
    vm_execute "

sudo mkdir -p /var/www;
sudo rm -rf /tmp/aloja;
mkdir -p /tmp/aloja
git clone https://github.com/Aloja/aloja.git /tmp/aloja
sudo cp -ru /tmp/aloja/. /var/www/

cd /var/www
sudo git checkout '$repo'

sudo cp /var/www/aloja-web/config/config.sample.yml /var/www/aloja-web/config/config.yml

sudo service php5-fpm restart
sudo service nginx restart
"
    local test_action="$(vm_execute " [ \"\$\(wget -q -O- http://localhost/|grep 'ALOJA')\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
      logger "INFO: $bootstrap_file installed succesfully"
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR: at $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    logger "$bootstrap_file already configured"
    logger "updating the ALOJA-WEB git repo to: origin $repo"
    vm_execute "
cd /var/www/;
sudo git checkout $repo;
sudo git fetch;
if [ ! \"\$(git status| grep 'branch is up-to-date')\" ] ; then
  sudo git reset --hard HEAD;
  sudo git pull --no-edit origin $repo;
  sudo rm -rf /var/www/aloja-web/cache/twig/* /tmp/twig/*;
  sudo service php5-fpm restart;
  sudo service nginx restart;
fi
cd -;
"
  fi

  #now install the PHP composer vendors
  install_PHP_vendors
}


#install R packages (slow)
install_R() {

  local bootstrap_file="${FUNCNAME[0]}"

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


    if [[ "$vmOSType" == "Ubuntu" && "$vmOSTypeVersion" == "14.04" ]] ; then

      logger "INFO: Installing R packages for Ubuntu 14 from repo"
      vm_execute "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9;"

      install_repo "deb http://cran.r-project.org/bin/linux/ubuntu trusty/"

      logger "INFO: Updating libtiff4 for R" #TODO remove when not necessary
      local libtiff_file="libtiff4_3.9.5-2ubuntu1.6_amd64.deb" #http://launchpad.net/~ubuntu-security/+archive/ubuntu/ppa/+build/5979984/+files/$libtiff_file
      aloja_wget "$ALOJA_PUBLIC_HTTP/files/$libtiff_file" "$libtiff_file"
      vm_execute "
sudo dpkg -i ./$libtiff_file;
sudo rm $libtiff_file"

      logger "INFO: Installing R dependencies (JAVA)"
      install_packages "libxml2-dev libcurl4-openssl-dev openjdk-7-jre-lib openjdk-7-jre-headless openjdk-7-jdk"
      vm_execute "sudo R CMD javareconf"

      logger "INFO: Installing R core and available packages in repo"
      local R_packages="r-base r-base-core r-base-dev r-base-html r-cran-bitops r-cran-boot r-cran-class r-cran-cluster"
      R_packages="$R_packages r-cran-codetools r-cran-foreign r-cran-kernsmooth r-cran-lattice r-cran-mass r-cran-matrix"
      R_packages="$R_packages r-cran-mgcv r-cran-nlme r-cran-nnet r-cran-rpart r-cran-spatial r-cran-survival r-recommended"
      R_packages="$R_packages r-cran-rjson r-cran-rcurl r-cran-colorspace r-cran-dichromat r-cran-digest r-cran-evaluate"
      R_packages="$R_packages r-cran-getopt r-cran-labeling r-cran-memoise r-cran-munsell r-cran-plyr r-cran-rcolorbrewer"
      R_packages="$R_packages r-cran-rcpp r-cran-reshape r-cran-rjava r-cran-scales r-cran-stringr gsettings-desktop-schemas"

      install_packages "$R_packages"
#
#      logger "INFO: Downloading precompiled R binary updates (to save time)"
#      local R_file="R_Ubuntu-14.04_20150813.tar.bz2"
#      aloja_wget "$ALOJA_PUBLIC_HTTP/files/$R_file" "/tmp/$R_file"
#
#      logger "INFO: Uncompressing and copying files"
#      vm_execute "
#cd /tmp;
#tar -xjf '$R_file';
#sudo cp -rf 'R' /usr/lib/
#rm -rf '$R_file' 'R';
#"

      logger "INFO: Updating package (will take a while if changes are found)"
      vm_execute "
cat <<- EOF > /tmp/packages.r
#!/usr/bin/env Rscript

#update.packages(ask = FALSE,repos='http://cran.r-project.org',dependencies = c('Suggests'),quiet=FALSE);

# For all Ubuntu releases until 14.04
install.packages(c('devtools','DiscriMiner','emoa','httr','jsonlite','optparse','pracma','rgp','rstudioapi','session','whisker',
'RWeka','RWekajars','ggplot2','rms','snowfall','genalg','FSelector'),repos='http://cran.r-project.org',dependencies=TRUE,quiet=FALSE);

update.packages(ask = FALSE,repos='http://cran.r-project.org',dependencies = c('Suggests'),quiet=FALSE);

EOF

sudo chmod a+x /tmp/packages.r
sudo /tmp/packages.r
"

      local test_action="$(vm_execute " [ \"\$\(which R)\" ] && echo '$testKey'")"

      if [[ "$test_action" == *"$testKey"* ]] ; then
        logger "INFO: $bootstrap_file installed succesfully"
        #set the lock
        check_bootstraped "$bootstrap_file" "set"
      else
        logger "ERROR: at $bootstrap_file for $vm_name. Test output: $test_action"
      fi
  else
    logger "ERROR: cannot install R packages automatically for OS version different than Ubuntu 14.04"
  fi

  else
    logger "$bootstrap_file already configured"
  fi

}

# Install the Azure cli tools
# Docs at: https://azure.microsoft.com/en-us/documentation/articles/xplat-cli/
install_azure_cli() {

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Installing Azure command line tools https://azure.microsoft.com/en-us/documentation/articles/xplat-cli/"

    install_packages "nodejs-legacy npm"
    vm_execute "sudo npm install -g azure-cli"

    local test_action="$(vm_execute " \[ \$(which azure) \] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

# Install the OpenStack and Rackspace cli tools
# Docs at: https://azure.microsoft.com/en-us/documentation/articles/xplat-cli/
install_openstack_cli() {

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Installing OpenStack and Rackspace CLI"

    install_packages "python-dev python-pip"
    vm_execute "
sudo pip install --upgrade python-novaclient
sudo pip install --upgrade rackspace-neutronclient
sudo pip install --upgrade rackspace-novaclient
"

    local test_action="$(vm_execute " \[ \$(which nova) \] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

# Install script for private sharelatex VM
install_sharelatex() {

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"


    logger "INFO: Installing ShareLatex"

    install_repo "ppa:chris-lea/node.js" "no update"
    install_repo "ppa:chris-lea/redis-server"

    install_packages "nodejs redis-server git build-essential curl python-software-properties zlib1g-dev zip unzip"

    vm_execute "sudo npm install -g grunt-cli
sudo npm install -g node-gyp

#We recommend you have the append only option enabled so redis persists to disk. If you do not have this enabled a restart may mean you loose some document updates.
#appendonly yes


sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
sudo apt-get update
sudo apt-get install -y mongodb-org

sudo apt-get install aspell

#There are lots of additional dictionaries available, which can be listed with:
#apt-cache search aspell | grep aspell

wget --progress=dot http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
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
    local test_action="$(vm_execute " [ \"\$\(which sharelatex)\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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



install_ganglia_gmond(){
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Installing ganglia-monitor (gmond)"

    install_packages "ganglia-monitor"

    test_action="$(vm_execute " [ \"\$\(pgrep gmond)\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

# $1 cluster name
config_ganglia_gmond(){

  local bootstrap_file="${FUNCNAME[0]}"
  local result mcastif

  if check_bootstraped "$bootstrap_file" ""; then

    logger "Executing $bootstrap_file"

    logger "INFO: Configuring ganglia-monitor (gmond)"

    vm_local_scp files/gmond.conf.t /tmp/ "" ""

    vm_execute "

    # create conf from template
    awk -v clustername='$1' -v node0='${1}-00' '

    { sub(/%%%CLUSTERNAME%%%/, clustername)
      sub(/%%%NODE0%%%/, node0)
    }
    { print }
    ' /tmp/gmond.conf.t > /tmp/gmond.conf

    # copy conf to destination
    sudo cp /tmp/gmond.conf /etc/ganglia

    sudo /etc/init.d/ganglia-monitor restart"

    result=$?

    if [ $result -eq 0 ] ; then
      logger "INFO: $bootstrap_file installed succesfully"
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR: at $bootstrap_file for $vm_name."
    fi

  else
    logger "$bootstrap_file already configured"
  fi

}


install_ganglia_gmetad(){
  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Installing gmetad"

    install_packages "gmetad"

    test_action="$(vm_execute " [ \"\$\(pgrep gmetad)\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

# parameters: list of clusters to manage
config_ganglia_gmetad(){
  
  local bootstrap_file="${FUNCNAME[0]}"
  local cname sep clist

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Configuring gmetad"

    clist=
    sep=
    for cname in "$@"; do
      clist="${clist}${sep}${cname}"
      sep=%
    done

    vm_local_scp files/gmetad.conf.t /tmp/ "" ""

    vm_execute "

    # create conf from template
    awk -v clist='${clist}' -v dq='\"' '

    BEGIN{
      nds = split(clist, temp, /%/)
      for (i=1; i <= nds; i++) {
        space = index(temp[i], \" \")
        dsname[i] = substr(temp[i], 1, space - 1)
        dsnode[i] = substr(temp[i], space + 1)
      }
    }

    /%%%DATASOURCELIST%%%/ {
      for (i = 1; i <= nds; i++) {
        print \"data_source \" dq dsname[i] dq \" \" dsnode[i]
      }
      next
    }

    { print }

    ' /tmp/gmetad.conf.t > /tmp/gmetad.conf

    # copy conf to destination
    sudo cp /tmp/gmetad.conf /etc/ganglia

    sudo /etc/init.d/gmetad restart"

    result=$?

    test_action="$(vm_execute " [ \"\$\(grep '^data_source ' /etc/ganglia/gmetad.conf)\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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


install_ganglia_web(){

  local bootstrap_file="${FUNCNAME[0]}"
  local tarball gdir

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    logger "INFO: Installing ganglia_web"

    tarball=ganglia-web-3.7.0.tar.gz
    gdir=${tarball%.tar.gz}

    install_packages "php5-gd rrdtool" || die "Error installing ganglia-web"
    aloja_wget "$ALOJA_PUBLIC_HTTP/files/$tarball" "/tmp/$tarball" || die "Error installing ganglia-web"

    vm_local_scp files/ganglia_conf.php.t /tmp/ "" ""

    vm_execute "
    cd /tmp || exit 1;
    tar -xf $tarball || exit 1;
    sudo mv $gdir ganglia || exit 1;
    sudo rm -rf /var/www/ganglia || exit 1;
    sudo mv ganglia /var/www/ || exit 1;
    sudo mkdir -p /var/www/ganglia/dwoo/{compiled,cache} || exit 1;
    sudo mv /tmp/ganglia_conf.php.t /var/www/ganglia/conf.php || exit 1;
    sudo chown -R www-data:www-data /var/www/ganglia || exit 1;
"

    if [ $? -ne 0 ]; then
      die "Error installing ganglia-web"
    fi

    # look for the freshly added line
    test_action="$(vm_execute " [ \"\$\(grep ' = ./var/www/ganglia.;' /var/www/ganglia/conf.php\)\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
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

config_ganglia_web(){

  :

}

# input: list of clusters
install_ssh_tunnel(){

  local bootstrap_file="${FUNCNAME[0]}"
  local cname tlist sep

  if check_bootstraped "$bootstrap_file" ""; then

    logger "Executing $bootstrap_file"

    logger "INFO: Installing ssh-tunnel"

    install_packages "autossh" || die "Error installing autossh"

    vm_rsync files/ssh-tunnel /tmp/ "--delete" || die "Error copying ssh-tunnel files"
    
    vm_execute "
    sudo mv /tmp/ssh-tunnel/etc/init.d/ssh-tunnel /etc/init.d || exit 1;
    sudo mv /tmp/ssh-tunnel/usr/local/bin/ssh-tunnel /usr/local/bin || exit 1;
    sudo chmod +x /etc/init.d/ssh-tunnel /usr/local/bin/ssh-tunnel || exit 1;

    # autostart
    sudo update-rc.d ssh-tunnel defaults || exit 1

    # config
    sudo rm -rf /etc/ssh-tunnel || exit 1
    sudo mv /tmp/ssh-tunnel/etc/ssh-tunnel /etc || exit 1

    # copy ssh key
    sudo cp ~pristine/.ssh/id_rsa /etc/ssh-tunnel/keys-enabled || exit 1
    sudo chmod 400 /etc/ssh-tunnel/keys-enabled/id_rsa || exit 1
"

    if [ $? -ne 0 ]; then
      die "Error installing ssh-tunnel"
    fi

    # ssh-tunnel config to all clusters

    tlist=
    sep=

    for cname in "$@"; do
      local ssh_port=$(export type=cluster; source include/include_deploy.sh "${cname}" >/dev/null 2>&1; vm_name=$(get_master_name) get_vm_ssh_port)
      local dns_name=$(export type=cluster; source include/include_deploy.sh "${cname}" >/dev/null 2>&1; get_ssh_host)
      local master_name=$(export type=cluster; source include/include_deploy.sh "${cname}" >/dev/null 2>&1; get_master_name)

      local tunnel="${cname} -p ${ssh_port} -o StrictHostKeychecking=no -L ${ssh_port}:${master_name}:8649 pristine@${dns_name}"
      tlist="${tlist}${sep}${tunnel}"
      sep=$'\n'
    done

    vm_execute "

sudo echo '$tlist' > /etc/ssh-tunnel/groups-enabled/default || exit 1
sudo /etc/init.d/ssh-tunnel restart || exit 1
"

    if [ $? -ne 0 ]; then
      die "Error installing ssh-tunnel"
    fi

    logger "INFO: $bootstrap_file installed succesfully"
    #set the lock
    check_bootstraped "$bootstrap_file" "set"

  else
    logger "$bootstrap_file already configured"
  fi

}



