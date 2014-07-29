#exec { 'set_document_root':
#  command => 'ln -fs /vagrant/workspace/* /var/www',
#  onlyif => '[ ! -h /var/www ]',
#  path => '/usr/bin:/bin',
#}

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

package { ['python-software-properties', 'vim', 'git']:
  ensure => present,
  require => Exec['apt-get update'],
}


include nginx, php #, mysql

#include '::mysql::server'

class { '::mysql::server':
#root_password => 'vagrant',
  override_options => {
    'mysqld' => {
      'bind-address' => '0.0.0.0',
      #'skip-external-locking ' => '',
      #'query_cache_size' => '64M'
    }
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
