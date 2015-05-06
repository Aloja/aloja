#!/usr/bin/env bash

#rm -rf /var/www
#ln -fs /vagrant/workspace /var/www
#

#passwordless login to localhost
if [ ! -f "/home/vagrant/.ssh/id_rsa" ] ; then
  sudo -u vagrant ssh-keygen -t rsa -P '' -f /home/vagrant/.ssh/id_rsa
  sudo -u vagrant cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
  echo -e "Host *\n\t   StrictHostKeyChecking no\nUserKnownHostsFile=/dev/null\nLogLevel=quiet" > /home/vagrant/.ssh/config
  chown -R vagrant: /home/vagrant/.ssh #just in case
fi

if ! which puppet > /dev/null; then
  sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list
  wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O /tmp/puppetlabs-release-stable.deb && \
    dpkg -i /tmp/puppetlabs-release-stable.deb && \
    apt-get update && \
    apt-get install puppet puppet-common hiera facter virt-what lsb-release -y --force-yes
fi

if ! which zip > /dev/null; then
  apt-get install zip -y --force-yes
fi

if ! which git > /dev/null; then
  apt-get install git -y --force-yes
fi

if ! which puppet > /dev/null; then
  sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list
  wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O /tmp/puppetlabs-release-stable.deb && \
     dpkg -i /tmp/puppetlabs-release-stable.deb && \
     apt-get update && \
     apt-get install puppet puppet-common hiera facter virt-what lsb-release  -y --force-yes
fi

if ! which git > /dev/null; then
  apt-get install git -y --force-yes
fi

#install puppet modules
[ -d /etc/puppet/modules ] || mkdir -p /etc/puppet/modules
for module in "puppetlabs-apt" "puppetlabs-mysql" "puppetlabs-vcsrepo" "maxchk-varnish" "rodjek-logrotate"; do
  (puppet module list | grep "$module") || puppet module install "$module"
done
#php 5.5 fpm
#apt-get install -y python-software-properties
#add-apt-repository -y ppa:ondrej/php5
#apt-get update

#upgrade without prompts
#DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

#apt-get install -y mysql-client
# apache2
#touch ~/bootstraped.txt

if ! which R > /dev/null; then
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

	## For Ubuntu 12.04
	#add-apt-repository 'deb http://cran.es.r-project.org/bin/linux/ubuntu precise/'
	#apt-get update
	#apt-get install "openjdk-7-jre-lib" "openjdk-7-jre-headless" "openjdk-7-jdk" "r-base" "r-base-core" "r-base-dev" "r-base-html" \
	#"r-cran-bitops" "r-cran-boot" "r-cran-class" "r-cran-cluster" "r-cran-codetools" "r-cran-foreign" "r-cran-kernsmooth" \
	#"r-cran-lattice" "r-cran-mass" "r-cran-matrix" "r-cran-mgcv" "r-cran-nlme" "r-cran-nnet" "r-cran-rpart" "r-cran-spatial" \
	#"r-cran-survival" "r-recommended" "r-cran-colorspace" "r-cran-getopt" "r-cran-rcolorbrewer" "r-cran-rcpp" "libcurl4-openssl-dev" \
	#"libxml2-dev" "gsettings-desktop-schemas" -y --force-yes

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
	"r-cran-rcpp" "r-cran-reshape" "r-cran-rjava" "r-cran-scales" "r-cran-stringr" "gsettings-desktop-schemas" "curl" "libxml2-dev" \
	"libcurl4-openssl-dev" -y --force-yes

	R CMD javareconf

	cat <<- EOF > /tmp/packages.r
	#!/usr/bin/env Rscript

	update.packages(ask = FALSE,repos="http://cran.r-project.org",dependencies = c('Suggests'),quiet=TRUE);

	# Only for Ubuntu 12.04
	#install.packages(c("rjson","evaluate","labeling","memoise","munsell","stringr","rJava"),repos="http://cran.es.r-project.org",
	#dependencies=TRUE,quiet=TRUE); # Installed on Update: RCurl, plyr, dichromat, devtools, digest, reshape, scales

	# For all Ubuntu releases until 14.04
	install.packages(c("devtools","DiscriMiner","emoa","httr","jsonlite","optparse","pracma","rgp","rstudioapi","session","whisker",
	"RWeka","RWekajars","ggplot2","rms","snowfall","genalg","FSelector"),repos="http://cran.r-project.org",dependencies=TRUE,quiet=TRUE);
	EOF

	chmod a+x /tmp/packages.r
	/tmp/packages.r
fi

