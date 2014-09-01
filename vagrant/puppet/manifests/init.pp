exec { 'third_party_libs':
  command => 'bash -c "cd /vagrant/workspace/aloja-web && php composer.phar update"',
  onlyif => '[ ! -h /vagrant/workspace/aloja-web/vendor ]',
  path => '/usr/bin:/bin'
}

if $environment == 'dev' {
    exec { 'set_document_root':
      command => 'ln -fs /vagrant/workspace/* /var/www',
      onlyif => '[ ! -h /var/www ]',
      path => '/usr/bin:/bin',
    }
}

file { '/var/www/':
  ensure => 'directory',
}

include apt
apt::ppa { 'ppa:ondrej/php5': }

exec { 'apt-get update':
  path => '/usr/bin'
}

#exec { 'touch ~/touched':
#    path => '/usr/bin'
#}

package { ['python-software-properties', 'vim', 'git', 'dsh']:
  ensure => present,
  require => Exec['apt-get update'],
}


include nginx, php #, mysql

vcsrepo { "/var/www/":
  ensure => latest,
  provider => git,
  require => [ Package[ 'git' ] ],
  source => "https://someuser:password@github.com/Aloja/aloja.git",
  revision => 'azureProd',
}

#include '::mysql::server'
if $environment == 'prod' {
   $mysql_options = {'bind-address' => '0.0.0.0',
                 'innodb_buffer_pool_size' => 512M,
                 'innodb_file_per_table' => 1,
                 'innodb_flush_method' => O_DIRECT,
                 'query_cache_size' => 128M,
                 'max_connections' => 300,
                 'thread_cache_size' => 50,
                 'table_open_cache' => 600
                 }
} else {
   $mysql_options = {'bind-address' => '0.0.0.0'}
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
        source => "https://user:somepassword@github.com/Aloja/aloja.git",
        revision => 'prod',
    }
}

class { '::mysql::server':
#root_password => 'vagrant',
  override_options => {
    'mysqld' => $mysql_options
  },
  require => Exec['apt-get update'],
  restart => true,
}

class { '::mysql::client':
  require => Exec['apt-get update'],
}

mysql_user { 'vagrant@%':
  ensure                   => 'present',
  max_connections_per_hour => '0',
  max_queries_per_hour     => '0',
  max_updates_per_hour     => '0',
  max_user_connections     => '0',
  password_hash => mysql_password('vagrant'),

  require => Class['::mysql::server', '::mysql::client'],
}

mysql_grant { 'vagrant@%/*.*':
  ensure     => 'present',
  options    => ['GRANT'],
  privileges => ['ALL'],
  table      => '*.*',
  user       => 'vagrant@%',

  require => Class['::mysql::server', '::mysql::client'],
}


#database_user { 'vagrant@%':
#  password_hash   => mysql_password('vagrant')
#}
#database_grant { 'vagrant@%/*':
#  privileges  => ['ALL'],
#}

#TODO make path puppet relative
file { '/home/vagrant/.bashrc':
  source  => '/vagrant/puppet/files/vagrant/.bashrc',
}
file { '/home/vagrant/.vimrc':
  source  => '/vagrant/puppet/files/vagrant/.vimrc',
}
