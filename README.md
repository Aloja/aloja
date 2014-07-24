ALOJA
=====

ALOJA is an initiative of the [BSC-MSR](http://www.bscmsrc.eu/) research centre in Barcelona to explore Hadoop's performance under different deployment scenarios.

For more information:

- Website: http://hadoop.bsc.es/
- Blog: http://hadoop.bsc.es/blog/
- Email: hadoop@bsc.es

## Local Installation

### Requirements

Before installing ALOJA you need the following packages:

- Vagrant: http://www.vagrantup.com/downloads.html

### Installation

First [download the master branch as a zip file](https://github.com/Aloja/aloja/archive/master.zip) or clone the repo:

    git clone https://github.com/Aloja/aloja.git

Go inside `vagrant` directory and execute:

    vagrant up

This will download and create the virtual machine (it may take some time).

When the previous command finishes, the virtual machine should be up and running. You can check with `vagrant status`, it should show something similar to this:

    $ vagrant status
    Current machine states:

    default                   running (virtualbox)

Congratulations, everything is ready!

You can access the website locally in this url: http://127.0.0.1:8080/aloja-web/index.php

### MySQL Access

The MySQL database is accessible from the host, use the following configuration with your preferred client:

- Hostname: 127.0.0.1
- Port: 4306
- Username: vagrant
- Password: vagrant
- Database: aloja2
