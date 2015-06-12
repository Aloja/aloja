
## Local Installation
[![Build Status](https://travis-ci.org/Aloja/aloja.svg?branch=master)](https://travis-ci.org/Aloja/aloja)
### Requirements

### Quick start

First get familiar with the Web app, browse data and views at: [**http://hadoop.bsc.es**](http://hadoop.bsc.es)

##### To experiment on a local DEV copy:

```bash
git clone https://github.com/Aloja/aloja.git
cd aloja
vagrant up
xdg-open [http://localhost:8080](http://localhost:8080)
```
**Note:** Requires git, vagrant >= v1.6, and a web browser

### About ALOJA

The [**ALOJA**](http://hadoop.bsc.es) research project is an initiative from the [Barcelona Supercomputing Center (BSC)]( http://www.bsc.es) to explore new hardware architectures for Big Data processing.  One of the main goals of the project is to produce a systematic study of SW and HW configuration and deployment options; where we are analyzing the cost-effectiveness of the different cloud services (*IaaS or PasS*) as well as on-premise hardware, both commodity and up-scale. 

In ALOJA we have currently created the largest vendor-neutral repository of Hadoop benchmark with over **42,000 public results**, as well as several tools for the management of the full-cycle from planning and execution of benchmarks, to data analysis and automated tools to produce insights to better understand system behavior and take decisions on framework and cluster design.

This repository includes the on-going open source tools of this project that consists of:
-Cluster definition and automated deployment
-Benchmark selection and iteration of configurations
-Metrics collections, results gathering, and importing into a DB
-Web application to manage results
-Advanced data views for aggregate results with filters
-Predictive Analytics (PA) aka Machine Learning tools for modeling and Knowledge Discovery





Before installing ALOJA you need the following packages:

- Vagrant (minimum version 1.6.3): http://www.vagrantup.com/downloads.html
- Sysstats package (apt-get install sysstat on debian-based distributions)
- gawk package for awk 
- puppet

### Installation

First [download the master branch as a zip file](https://github.com/Aloja/aloja/archive/master.zip) or clone the repo:

    git clone https://github.com/Aloja/aloja.git

Then go inside aloja-web directory and execute `composer.phar self-update` and `composer.phar update` to update composer and install third-party libraries respectively  

Once installed go inside `vagrant` directory and execute:

    vagrant up

This will download and create the virtual machine (it may take some time).

When the previous command finishes, the virtual machine should be up and running. You can check with `vagrant status`, it should show something similar to this:

    $ vagrant status
    Current machine states:

    default                   running (virtualbox)

Congratulations, everything is ready!

You can access the website locally in this url: http://127.0.0.1:8080/aloja-web/index.php

### Filling up some data in database
To be able to see the charts with data it is necessary to fill up the MySQL database with the jobs logs.  
Go inside `jobs` directory and run the following command:
./../shell/file2db.sh
This will take logs data inside the jobs directory to fill up the database.  

**If you are not using ubuntu** first of all you'll ned to execute the following steps:  
Go into `shell/sar/ubuntu/` directory and run the following commands:  
`./configure && make`  
`./sar`    
`./sadf`  

### MySQL Access

The MySQL database is accessible from the host, use the following configuration with your preferred client:

- Hostname: 127.0.0.1
- Port: 4306
- Username: vagrant
- Password: vagrant
- Database: aloja2

## Ubuntu machines production deployment
1. Change puppet environment variable to 'prod' in `vagrant/Vagrantfile`

2. Change github username and password on `vagrant/puppet/manifests/init.pp` vcsrepo module

3. Copy aloja-web/config/config.sample.yml to aloja-web/config/config.yml and change the parameters properly

4. Go inside `vagrant/` and run `vagrant up`

*WARNING*: Be aware that production's environment comes with server cache enabled, so you'll not see further changes on your code

## Functional tests

Once you have your local environment set up, you should run the functional tests and check that they pass, also it should be run every time some functionality is change or added for new important functionalities. To run tests complete the following checklist:
- Nodejs and npm packages are installed 
- Install casperjs and gruntJS globally `npm install -g casperjs && npm install -g grunt-cli`
- Run `npm install` to locally install grunt-casper
- Run `npm tests` to execute the tests

Tests are localted in the aloja-web/tests directory. Each JS file is a functional test for one page. They are written in CasperJS.
