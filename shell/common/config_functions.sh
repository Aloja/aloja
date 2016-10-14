get_nginx_conf(){
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

# $1 env
get_php_conf(){
  echo -e '
memory_limit = 1024M
allow_url_fopen = Off
allow_url_include = Off
max_execution_time = 600
xdebug.default_enable = 0
xdebug.remote_enable = 0
opcache.enable=1
'

}

# $1 env (prod, dev)
# $2 binlog_location
# $3 relaylog_location
# $4 role (master, slave)
# $5 server_id
# ... extra key=value arguments

get_mysqld_conf(){

  local env=$1
  local binlog_location=$2
  local relaylog_location=$3
  local role=$4
  local server_id=$5

  shift 5

  if [ "${env}" == "dev" ]; then
    key_buffer_size=64M
    tmp_table_size=32M
    query_cache_limit=3M
    query_cache_size=32M
    innodb_lock_wait_timeout=20
    innodb_additional_mem_pool_size=16M
    innodb_buffer_pool_size=128M
    innodb_thread_concurrency=8
  else
    key_buffer_size=512M
    tmp_table_size=128M
    query_cache_limit=128M
    query_cache_size=512M
    innodb_lock_wait_timeout=60
    innodb_additional_mem_pool_size=512M
    innodb_buffer_pool_size=2048M
    innodb_thread_concurrency=16
  fi

  echo -e "
[mysqld]

bind-address=0.0.0.0
skip-external-locking
key_buffer_size		= ${key_buffer_size}
tmp_table_size		= ${tmp_table_size}
query_cache_limit	= ${query_cache_limit}
query_cache_size        = ${query_cache_size}

gtid_mode       = ON
log-slave-updates = 1
enforce-gtid-consistency = 1
explicit_defaults_for_timestamp = 1
binlog_format = mixed

server_id       = ${server_id}

log_bin         = ${binlog_location}
relay_log       = ${relaylog_location}
"

  if [ "$role" != "master" ]; then
    echo -e "
read_only = 1
replicate-ignore-db = mysql
"
  fi
  
  echo
  for p in "$@"; do
    echo "${p}"
  done
  echo

  echo -e "
# Set Base Innodb Specific settings here
innodb_autoinc_lock_mode=0
innodb_flush_method		= O_DIRECT
innodb_file_per_table		= 1
innodb_file_format		= barracuda
innodb_max_dirty_pages_pct 	= 90
innodb_lock_wait_timeout 	= ${innodb_lock_wait_timeout}
innodb_flush_log_at_trx_commit 	= 2
innodb_additional_mem_pool_size = ${innodb_additional_mem_pool_size}
innodb_buffer_pool_size 	= ${innodb_buffer_pool_size}
innodb_thread_concurrency 	= ${innodb_thread_concurrency}
"
}


get_ssh_config() {
  echo -e "
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=quiet
  ControlMaster=auto
  ControlPath=$homePrefixAloja/$userAloja/.ssh/%h
  GSSAPIAuthentication=no
  ServerAliveInterval=30
  ServerAliveCountMax=3
  connectTimeout=10
"
# Other possible options to test
#  ControlPersist=600 #this one is causing problems for some reason
# %r@%h-%p
# _%C
}

