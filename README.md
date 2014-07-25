
## Local Installation

### Requirements

Before installing ALOJA you need the following packages:

- Vagrant: http://www.vagrantup.com/downloads.html
- Sysstats package (apt-get install sysstat on debian-based distributions)
- gawk package for awk 
- puppet

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

### Filling up some date in database
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
