CUR_DIR_TMP="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CUR_DIR_TMP/on-premise.sh"

#overrides and custom minerva100 functions
#TODO move to another place, this right now is in secure but it cannot be read when executing benchs
homePrefixAloja="/home" #/home is not on the default location on minerva100

get_mount_disks() {

  local create_string="
    #mkdir -p ~/{share,minerva};
    sudo mkdir -p /scratch/attached/{1..$attachedVolumes} /scratch/local;
    $(get_extra_mount_disks)
    sudo chown -R $userAloja: /scratch;
    sudo mount -a;
  "
  echo -e "$create_string"
}



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

get_ssh_pass() {
  #check if we can change from root user
  if [ ! -z "${requireRootFirst[$vm_name]}" ] ; then
    #"WARNING: connecting as root"
    echo "${passwordAlojaPre}"
  else
    echo "${passwordAloja}"
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

# for bscaloja, has a special /public dir
get_nginx_conf(){

echo -e '
server {
  listen 80 default_server;

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

  location ~ ^/public/(.*) {
    alias /scratch/attached/1/public/$1;
    autoindex on;
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
  expires off;

  # allow the server to close the connection after a client stops responding. Frees up socket-associated memory.
  reset_timedout_connection on;

  gzip on;
  gzip_static on;
  gzip_comp_level 2;
  gzip_proxied any;
  gzip_vary on;
  gzip_min_length 512;
  gzip_buffers 16 8k;
  gzip_http_version 1.1;
  gzip_disable "msie6";

  types {
    application/x-font-ttf                  ttf;
    font/opentype                           ott;
    application/font-woff                   woff;
  }

  gzip_types text/plain text/css text/javascript application/json application/x-javascript text/xml application/xml application/xml+rss text/x-component application/javascript application/rss+xml font/truetype application/x-font-ttf font/opentype;

}'

}

# restrict access to mysql port to BSC ips
do_iptables(){

  local bootstrap_file="${FUNCNAME[0]}"

  if check_bootstraped "$bootstrap_file" ""; then
    logger "Executing $bootstrap_file"

    vm_execute '

    echo "#!/bin/bash

[ \"\$IFACE\" != \"em1\" ] && exit 0

iptables -F

iptables -A INPUT -i lo -p tcp -m tcp --dport 3306 -j ACCEPT
iptables -A INPUT -s 84.88.50.0/23 -p tcp -m tcp --dport 3306 -j ACCEPT
iptables -A INPUT -s 84.88.52.0/23 -p tcp -m tcp --dport 3306 -j ACCEPT
iptables -A INPUT -s 84.88.54.0/25 -p tcp -m tcp --dport 3306 -j ACCEPT
iptables -A INPUT -s 84.88.184.0/26 -p tcp -m tcp --dport 3306 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 3306 -j DROP

" | sudo tee /etc/network/if-pre-up.d/iptablesload > /dev/null

  sudo chmod +x /etc/network/if-pre-up.d/iptablesload
  sudo IFACE=em1 /etc/network/if-pre-up.d/iptablesload
'

    check_bootstraped "$bootstrap_file" "set"

  else
    logger "$bootstrap_file already configured"
  fi

}
