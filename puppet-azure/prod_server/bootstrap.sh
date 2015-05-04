#!/usr/bin/env bash

if ! which puppet > /dev/null; then
  sed -i -e 's,http://[^ ]*,mirror://mirrors.ubuntu.com/mirrors.txt,' /etc/apt/sources.list
  wget http://apt.puppetlabs.com/puppetlabs-release-stable.deb -O /tmp/puppetlabs-release-stable.deb && \
    dpkg -i /tmp/puppetlabs-release-stable.deb && \
    apt-get update && \
    apt-get install puppet puppet-common hiera facter virt-what lsb-release -y --force-yes
fi

cp -R modules/* /etc/puppet/modules

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
[ -d "/etc/puppet/modules" ] || mkdir -p /etc/puppet/modules
for module in "puppetlabs-apt" "puppetlabs-mysql" "puppetlabs-vcsrepo" "maxchk-varnish" "rodjek-logrotate"; do
  (puppet module list | grep "$module") || puppet module install "$module"
done

#MySQL prep to move data to attached disk
#if [ ! -d "/scratch/attached/1/mysql" ]; then
#	sudo cp usr.sbin.mysqld /etc/apparmor.d/usr.sbin.mysqld
#	sudo service apparmor restart
#
#	if [ "$?" -ne "0" ]; then
#		echo "Moving MySQL data to attached disk failed!"
#	fi
#fi

puppet apply --modulepath=/etc/puppet/modules manifests/init.pp --environment=prod

mysqlshow -uroot aloja2
retcode=$?
if [ "$retcode" -ne "0" ]; then
	mysql -uroot -e "create database aloja2;"
fi
mysql -uroot aloja2 < db_schema.sql

add_execs() {
	tar -xvf execs.sql.tar.gz
	mysql -uroot aloja2 < execs.sql	
}

##Add execs to MySQL AND/OR change default git branch
if [ ! -z $1 ]; then
	if [ "$1" == "execs" ]; then
		add_execs
	else
		/bin/bash updategitbranch.sh $1
		retcode=$?
		if [ "$retcode" -ne "0" ]; then
			exit	
		fi
		if [ ! -z $2 ] && [ "$2" == "execs" ]; then
			add_execs
		fi
	fi
fi

echo "Changing /var/www permissions"
chown -R www-data.www-data /var/www
chmod -R 755 /var/www

echo "Installing ALOJA-ML (R) support)"
if ! which R > /dev/null; then
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

	## For Ubuntu 12.04
#	add-apt-repository 'deb http://cran.es.r-project.org/bin/linux/ubuntu precise/'
#	apt-get update
#	apt-get install "openjdk-7-jre-lib" "openjdk-7-jre-headless" "openjdk-7-jdk" "r-base" "r-base-core" "r-base-dev" "r-base-html" \
#	"r-cran-bitops" "r-cran-boot" "r-cran-class" "r-cran-cluster" "r-cran-codetools" "r-cran-foreign" "r-cran-kernsmooth" \
#	"r-cran-lattice" "r-cran-mass" "r-cran-matrix" "r-cran-mgcv" "r-cran-nlme" "r-cran-nnet" "r-cran-rpart" "r-cran-spatial" \
#	"r-cran-survival" "r-recommended" "r-cran-colorspace" "r-cran-getopt" "r-cran-rcolorbrewer" "r-cran-rcpp" "libcurl4-openssl-dev" \
#	"libxml2-dev" "gsettings-desktop-schemas" -y --force-yes

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
	"RWeka","RWekajars","ggplot2","rms","snowfall","genalg","FSelector"),repos="http://cran.es.r-project.org",dependencies=TRUE,quiet=TRUE);
	EOF

	chmod a+x /tmp/packages.r
	/tmp/packages.r
fi
