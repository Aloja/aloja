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
    alias /var/presentations/aloja-web;
    index template.html;
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
xdebug.default_enable = 0
xdebug.remote_enable = 0
opcache.enable=1
'

}

#$1 env (prod, dev)
get_mysqld_conf(){
  if [ "$1" == "dev" ] ; then
    #dev, for vagrant
    echo -e "
[mysqld]

bind-address=0.0.0.0
skip-external-locking
key_buffer_size		= 64M
tmp_table_size		= 32M
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
"
  else
  #prod
  echo -e "
[mysqld]

bind-address=0.0.0.0
skip-external-locking
key_buffer_size		= 512M
tmp_table_size		= 128M
query_cache_limit	= 128M
query_cache_size  = 512M

# Set Base Innodb Specific settings here
innodb_autoinc_lock_mode=0
innodb_flush_method		= O_DIRECT
innodb_file_per_table		= 1
innodb_file_format		= barracuda
innodb_max_dirty_pages_pct 	= 90
innodb_lock_wait_timeout 	= 60
innodb_flush_log_at_trx_commit 	= 2
innodb_additional_mem_pool_size = 512M
innodb_buffer_pool_size 	= 2048M
innodb_thread_concurrency 	= 16
"
  fi
}

get_ssh_config() {
  echo -e "
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=quiet
  ControlMaster=auto
  ControlPath=$homePrefixAloja/$userAloja/.ssh/%r@%h-%p
  GSSAPIAuthentication=no
  ServerAliveInterval=30
  ServerAliveCountMax=3
"
# Other possible options to test
#  ControlPersist=600

}

