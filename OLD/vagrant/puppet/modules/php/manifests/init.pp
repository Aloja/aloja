# vagrant/puppet/modules/php/manifests/init.pp
class php {
  # Install the php5-fpm and php5-cli packages
  package { ['php5-fpm', 'php5-cli', 'php5-mysql', 'php5-xdebug', 'php5-curl']:
    ensure => present,
    require => Exec['apt-get update'],
    notify => Service['php5-fpm']
  }
  # Make sure php5-fpm is running
  service { 'php5-fpm':
    ensure => 'running',
    require => Package['php5-fpm'],
  }

if $environment == 'dev' {
file {'/etc/php5/fpm/conf.d/90-overrides.ini':
  ensure => present,
  owner => root, group => root, mode => 644,
  notify => Service['php5-fpm', 'nginx'],
  content => "memory_limit = 1024M
",

}
} else {
file {'/etc/php5/fpm/conf.d/90-overrides.ini':
  ensure => present,
  owner => root, group => root, mode => 644,
  notify => Service['php5-fpm', 'nginx'],
  content => "memory_limit = 1024M
xdebug.default_enable = 0
xdebug.remote_enable = 0
",
}
}

#
#  # Use a custom mysql configuration file
#  file { '/etc/php5/fpm/php.ini':
#    source  => 'puppet:///modules/php/php.ini',
#    require => Package['php5-fpm'],
#    notify  => Service['php5-fpm'],
#  }
#
#  # Use a custom mysql configuration file
#  file { '/etc/php5/cli/php.ini':
#    source  => 'puppet:///modules/php/php.ini',
#    require => Package['php5-cli'],
#  }

}
