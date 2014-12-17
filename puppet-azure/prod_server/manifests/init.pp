class { 'apt':
  disable_keys => true, #dissable security check for php5
}

include apt
apt::ppa { 'ppa:ondrej/php5': }



exec { 'apt-get update':
  #path => '/usr/bin',
  command => "/usr/bin/apt-get update -y --force-yes",
}

package { ['python-software-properties', 'vim', 'git', 'dsh', 'sysstat', 'bwm-ng']:
  ensure => present,
  require => Exec['apt-get update'],
}


include nginx, php #, mysql

#include '::mysql::server'

if $environment == 'prod' {
  $mysql_options = {
    'bind-address' => '0.0.0.0',
    'innodb_autoinc_lock_mode' => '0', #prevent gaps in auto increments
    'datadir' => '/scratch/attached/1/mysql',
    'innodb_buffer_pool_size' => '512M',
    'innodb_file_per_table' => '1',
    'innodb_flush_method' => 'O_DIRECT',
    'query_cache_size' => '128M',
    'max_connections' => '300',
    'thread_cache_size' => '50',
    'table_open_cache' => '600',
  }
} else {
  $mysql_options = {
    'bind-address' => '0.0.0.0',
    'innodb_autoinc_lock_mode' => '0', #prevent gaps in auto increments
    'datadir' => '/scratch/attached/1/mysql',
  }
}

if $environment == 'prod' {
    include confvarnish
    #Logrotate rules
    logrotate::rule { 'aloja-logs':
      path => '/var/www/aloja-web/logs/*.log',
      rotate => 5,
      rotate_every => 'day',
    }
    
    vcsrepo { "/var/www/":
        ensure => latest,
        provider => git,
        require => [ Package[ 'git' ] ],
        source => "https://github.com/Aloja/aloja.git",
        revision => 'prod',
    }
}

class { '::mysql::server':
  override_options => {
  'mysqld' => $mysql_options
  },
  require => Exec['apt-get update'],
  restart => true,
}

class { '::mysql::client':
  require => Exec['apt-get update'],
}


vcsrepo { "/var/presentations/":
        ensure => latest,
        provider => git,
        require => [ Package[ 'git' ] ],
        source => "https://github.com/Aloja/presentations.git",
        revision => 'master',
}

#file { '/var/www/':
#  ensure => 'directory',
#  owner => 'www-data',
#  group => 'www-data',
#  recurse => true,
#  mode => '755'
#}

exec { 'third_party_libs':
  command => 'bash -c "cd /var/www/aloja-web && sudo php composer.phar self-update && sudo php composer.phar update"',
  onlyif => '[ ! -h /var/www/aloja-web/vendor ]',
  path => '/usr/bin:/bin'
}

exec { 'db_migrations':
  command => 'bash -c "cd /var/www/aloja-web && php vendor/bin/phinx -cconfig/phinx.yml -eproduction migrate"',
  path => '/usr/bin:/bin'
}

file { '/var/www/aloja-web/logs':
  ensure => 'directory',
  mode => '776',
  owner => 'www-data',
  group => 'www-data',
  recurse => true
}

exec { 'chmod_vendor':
  command => 'sudo chown www-data.www-data -R /var/www/aloja-web/vendor && sudo chmod 775 -R /var/www/aloja-web/vendor',
  path => '/bin:/usr/bin'
}

##Dependencies
Exec['apt-get update'] -> Vcsrepo['/var/www/']
Vcsrepo['/var/www/'] -> File['/var/www/aloja-web/logs']
Vcsrepo['/var/www/'] -> Vcsrepo['/var/presentations/']
File['/var/www/aloja-web/logs'] -> Class['::mysql::server']
Class['::mysql::server'] -> Exec['third_party_libs']
Exec['third_party_libs'] -> Service['php5-fpm']
Exec['third_party_libs'] -> Exec['chmod_vendor']
Exec['third_party_libs'] -> Exec['db_migrations']
