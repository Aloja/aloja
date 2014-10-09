# vagrant/puppet/modules/php/manifests/init.pp
class php {
  # Install the php5-fpm and php5-cli packages
  package { ['php5-fpm', 'php5-cli', 'php5-mysql', 'php5-curl']:
    ensure => present,
    require => Exec['apt-get update'],
    notify => Service['php5-fpm']
  }
  # Make sure php5-fpm is running
  service { 'php5-fpm':
    ensure => 'running',
    require => Package['php5-fpm'],
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
