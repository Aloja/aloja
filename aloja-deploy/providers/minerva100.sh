CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/on-premise.sh"

#overrides and custom minerva100 functions
#TODO move to another place, this right now is in secure but it cannot be read when executing benchs
homePrefixAloja="/users/scratch" #/home is not on the default location on minerva100


#minerva needs *real* user first
get_ssh_user() {

  #check if we can change from root user
  if [ ! -z "${requireRootFirst[$vm_name]}" ] ; then
    #"WARNING: connecting as root"
    echo "${userAlojaPre}"
  else
    echo "${userAloja}"
  fi
}

vm_initial_bootstrap() {

  local bootstrap_file="Initial_Bootstrap"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Bootstraping $vm_name "

    vm_execute "
sudo useradd --create-home --home $homePrefixAloja/$userAloja -s /bin/bash $userAloja;
sudo echo -n '$userAloja:$passwordAloja' |sudo chpasswd;
sudo adduser $userAloja sudo;
sudo adduser $userAloja adm;


sudo bash -c \"echo '%sudo ALL=NOPASSWD:ALL' >> /etc/sudoers\";

sudo mkdir -p $homePrefixAloja/$userAloja/.ssh;
sudo bash -c \"echo '${insecureKey}' >> $homePrefixAloja/$userAloja/.ssh/authorized_keys\";
sudo chown -R $userAloja: $homePrefixAloja/$userAloja/.ssh;
sudo cp $homePrefixAloja/$userAloja/.profile $homePrefixAloja/$userAloja/.bashrc /root/;
"

    test_action="$(vm_execute " [ -f $homePrefixAloja/$userAloja/.ssh/authorized_keys ] && echo '$testKey'")"

    if [ "$test_action" == "$testKey" ] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    logger "$bootstrap_file already configured"
  fi

}

#$1 vm_name
get_vm_id() {
  echo "${1:(-3)}" #echo the last 3 digits for minerva100
}

vm_create_RAID0() {

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    local num_drives="6"
    vm_execute "
sudo umount /dev/sdb{b..g}1;
yes | sudo mdadm -C /dev/md0 -l raid0 -n $num_drives /dev/sd{b..g}1;
sudo mkfs.ext4 /dev/md0;
"
#mount done by fstab
#sudo mount /dev/md0 /scratch/attached/1;
#not necessary to mark partition as raid auto apparently
#parted -s /dev/sdf -- mklabel gpt mkpart primary 0% 100% set 1 raid on

    logger "INFO: Updating /etc/fstab template"
    vm_update_template "/etc/fstab" "/dev/md0	/scratch/attached/1	ext4	defaults	0	0" "secured_file"

    logger "INFO: remounting disks according to fstab"
    vm_execute "
sudo mount -a;
sudo chown -R pristine: /scratch/attached/1;
"

    test_action="$(vm_execute " [ \"\$(sudo mdadm --examine /dev/sdb1 |grep 'Raid Devices : $num_drives')\" ] && echo '$testKey'")"

    if [[ "$test_action" == *"$testKey"* ]] ; then
      #set the lock
      check_bootstraped "$bootstrap_file" "set"
    else
      logger "ERROR at $bootstrap_file for $vm_name. Test output: $test_action"
    fi

  else
    logger "$bootstrap_file already configured"
  fi

}

vm_final_bootstrap() {

  logger "Checking if to install Infiniband on node"
  vm_install_IB

#  logger "INFO: removing security packages and configs from Ubuntu 14.04"
#  vm_execute "
#sudo service apparmor stop
#sudo update-rc.d -f apparmor remove
#sudo apt-get purge -y apparmor apparmor-utils -y
#sudo ufw disable;
#"

  logger "INFO: making sure minerva-100 config is up to date"
  vm_execute "
sudo apt-get -y remove hadoop puppet;
sudo apt-get -y autoremove;
"

#sudo apt-get -y remove libvirt-bin libvirt0;

#logger "INFO: Recreating /etc/hosts with IB names for $(get_vm_IB_hostname $vm_name)"
#vm_update_template "/etc/hosts" "$(get_IB_hostnames)" "secured_file"


}

#$1 vm_name
get_vm_IB_hostname() {
  #TODO improve for other possible clusters and namings
  echo "minerva-ib-${1:(-3)}"
}

get_IB_hostnames() {

  # Also getting regular node names because of DNS failures in minerva
  #a ip addr|grep inet|grep 172|awk '{print $3 "\t" $1}'
  
  echo -e "
#regular hostname  
#172.20.12.1 minerva-102.mnv minerva-101
#172.20.12.2 minerva-102.mnv minerva-102
#172.20.12.3 minerva-103.mnv minerva-103
#172.20.12.4 minerva-104.mnv minerva-104
#172.20.12.5 minerva-105.mnv minerva-105
#172.20.12.6 minerva-106.mnv minerva-106
#172.20.12.7 minerva-107.mnv minerva-107
#172.20.12.8 minerva-108.mnv minerva-108
#172.20.12.9 minerva-109.mnv minerva-109
#172.20.12.10  minerva-110.mnv minerva-110
#172.20.12.11  minerva-111.mnv minerva-111
#172.20.12.12  minerva-112.mnv minerva-112
#172.20.12.13  minerva-13.mnv  minerva-113
#172.20.12.14  minerva-14.mnv  minerva-114
#172.20.12.15  minerva-115.mnv minerva-115
#172.20.12.16  minerva-116.mnv minerva-116
#172.20.12.17  minerva-117.mnv minerva-117
#172.20.12.18  minerva-118.mnv minerva-118
  
#IB hostname  
10.0.1.1	minerva-ib-101
10.0.1.2	minerva-ib-102
10.0.1.3	minerva-ib-103
10.0.1.4	minerva-ib-104
10.0.1.5	minerva-ib-105
10.0.1.6	minerva-ib-106
10.0.1.7	minerva-ib-107
10.0.1.8	minerva-ib-108
10.0.1.9	minerva-ib-109
10.0.1.10	minerva-ib-110
10.0.1.11	minerva-ib-111
10.0.1.12	minerva-ib-112
10.0.1.13	minerva-ib-113
10.0.1.14	minerva-ib-114
10.0.1.15	minerva-ib-115
10.0.1.16	minerva-ib-116
10.0.1.17	minerva-ib-117
10.0.1.18	minerva-ib-118
"

}

get_extra_fstab() {

  local minerva100_tmp="$homePrefixAloja/$userAloja/tmp"
  vm_execute "mkdir -p $minerva100_tmp"
  local create_string="$minerva100_tmp       /scratch/local    none bind,nobootwait 0 0"

  if [ "$clusterName" == "minerva100-10-18-21" ] ; then
    local create_string="$create_string
/scratch/attached/6       /scratch/ssd/1    none bind,nobootwait 0 0
/scratch/attached/7       /scratch/ssd/2    none bind,nobootwait 0 0"

  elif [ "$clusterName" == "minerva100-02-18-22" ] ; then
    local create_string="$create_string
/scratch/attached/7       /scratch/ssd/1    none bind,nobootwait 0 0"
  fi

  echo -e "$create_string"
}

get_extra_mount_disks() {
  if [ "$clusterName" == "minerva100-10-18-21" ] ; then
    echo -e "sudo mkdir -p /scratch/ssd/{1..2};"
  elif [ "$clusterName" == "minerva100-02-18-22" ] ; then
    echo -e "sudo mkdir -p /scratch/ssd/1;"
  fi
}

#for Infiniband on clusters that support it
get_node_names_IB() {
#  if [ "$clusterName" == "minerva100-10-18-21" ] || [ "$clusterName" == "minerva100-02-18-22" ] ; then
    #logger "INFO: generating host names for IB"
    local nodes="$(get_node_names)"
    echo -e "$(convert_regular2IB_hostnames "$nodes")"
#  else
#    #logger "WARN: Special hosts for InfiniBand not defined, using regular hostsnames"
#    echo -e "$(get_node_names)"
#  fi
}

#for Infiniband on clusters that support it
get_master_name_IB() {
#  if [ "$clusterName" == "minerva100-10-18-21" ] || [ "$clusterName" == "minerva100-02-18-22" ]  ; then
    #logger "INFO: generating host name for IB"
    local nodes="$(get_master_name)"
    echo -e "$(convert_regular2IB_hostnames "$nodes")"
#  else
#    #logger "WARN: Special master name for InfiniBand not defined, using regular"
#    echo "$(get_master_name)"
#  fi
}

#$1 host list
convert_regular2IB_hostnames() {
  for host in $1 ; do
    local hosts_IB="$hosts_IB\n${host:0:(-4)}-ib${host:(-4)}"
  done

  echo -e "$(echo -e "$hosts_IB"|tail -n +2 )" #cut the first \n
}

# as a special case, on minerva machine we don't install ganglia as it's already installed
must_install_ganglia(){
  echo 0
}

# special gmond config for minerva nodes (already have ganglia installed)
# $1 cluster name
config_ganglia_gmond(){

  local bootstrap_file="${FUNCNAME[0]}"
  local result

  if check_bootstraped "$bootstrap_file" ""; then

    logger "Executing $bootstrap_file"

    logger "INFO: Configuring ganglia-monitor (gmond)"

    vm_local_scp files/ganglia_minerva.conf.t /tmp/aloja.conf "" ""

    vm_execute "

    # create conf from template
    sudo mkdir -p /etc/ganglia/conf.d || exit 1;
    sudo mv /tmp/aloja.conf /etc/ganglia/conf.d || exit 1;
    sudo /etc/init.d/ganglia-monitor restart || exit 1;"

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

get_nginx_conf(){

echo -e '
server {
  listen 80 default_server;
  listen 8080 default_server;

  root /var/www/aloja-web/;
  index index.html index.php;
  autoindex on;

  location / {
    index index.php;
    try_files $uri $uri/ /index.php?q=$uri&$args;
    autoindex on;
  }

  location /slides {
    alias /var/www/aloja-web/presentations/aloja-web;
    index template.html;
  }

  location /ganglia {

    root /var/www/;

    location ~ \.php$ {
      fastcgi_pass unix:/var/run/php5-fpm.sock;
      fastcgi_index index.php;
      include fastcgi_params;
    }
  }

  location ~ \.php$ {
#    try_files $uri =404;
    try_files $uri /index.php?c=404&q=$uri&$args;
    fastcgi_pass unix:/var/run/php5-fpm.sock;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_read_timeout 600; # Set fairly high for debugging
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
}'

}

#$1 env (prod, dev)
#get_mysqld_conf(){
#
#  echo -e "
#[mysqld]
#
#bind-address=0.0.0.0
#skip-external-locking
#key_buffer_size		= 512M
#tmp_table_size		= 128M
#query_cache_limit	= 128M
#query_cache_size  = 512M
#
## 5.6 stuff (GTID) + binlog
#
#gtid_mode                       = ON
#log-slave-updates               = 1
#enforce-gtid-consistency        = 1
#explicit_defaults_for_timestamp = 1
#
#binlog_format = mixed
#server_id = 1
#
#log_bin         = /scratch/attached/1/mysql/binlogs/mysql-binlog
#
#
## Set Base Innodb Specific settings here
#innodb_autoinc_lock_mode=0
#innodb_flush_method		= O_DIRECT
#innodb_file_per_table		= 1
#innodb_file_format		= barracuda
#innodb_max_dirty_pages_pct 	= 90
#innodb_lock_wait_timeout 	= 60
#innodb_flush_log_at_trx_commit 	= 2
#innodb_additional_mem_pool_size = 512M
#innodb_buffer_pool_size 	= 2048M
#innodb_thread_concurrency 	= 16
#"
#
#}


