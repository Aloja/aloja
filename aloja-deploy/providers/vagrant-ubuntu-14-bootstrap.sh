#!/usr/bin/env bash

if [ ! -d "/var/www/aloja-web" ] ; then
  ln -fs /vagrant /var/www
fi

#upgrade without prompts
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

if ! which nginxa > /dev/null ; then
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

if ! which mysqlda > /dev/null ; then
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

#passwordless login to localhost
if [ ! -f "/home/vagrant/.ssh/id_rsa" ] ; then
  sudo -u vagrant ssh-keygen -t rsa -P '' -f /home/vagrant/.ssh/id_rsa
  sudo -u vagrant cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
  echo -e "Host *\n\t   StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nLogLevel=quiet" > /home/vagrant/.ssh/config
  chown -R vagrant: /home/vagrant/.ssh #just in case
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
	install.packages(c("rjson","evaluate","labeling","memoise","munsell","stringr","rJava"),repos="http://cran.es.r-project.org",
	dependencies=TRUE,quiet=TRUE); # Installed on Update: RCurl, plyr, dichromat, devtools, digest, reshape, scales

	# For all Ubuntu releases until 14.04
	install.packages(c("devtools","DiscriMiner","emoa","httr","jsonlite","optparse","pracma","rgp","rstudioapi","session","whisker",
	"RWeka","RWekajars","ggplot2","rms"),repos="http://cran.es.r-project.org",dependencies=TRUE,quiet=TRUE);
	EOF

	chmod a+x /tmp/packages.r
	/tmp/packages.r
fi

