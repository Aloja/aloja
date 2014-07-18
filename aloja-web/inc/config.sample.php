<?php
    define('MYSQL_USER', 'vagrant');
    define('MYSQL_PWD', 'vagrant');
    //MySQL on Vagrant VM
    define('DB_CONN_CHAIN','mysql:host=localhost;dbname=aloja2;');
    //Prod MySQL, need to SSH first in Vagrant VM with: ssh -L localhost:3307:gallactica:3306 user@minerva.bsc.es
    //define('DB_CONN_CHAIN','mysql:host=127.0.0.1;dbname=aloja2;port=3307');
    define('IN_CACHE',false);
    define('ENABLE_DEBUG',true);