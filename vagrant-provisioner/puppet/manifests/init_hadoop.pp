exec { 'apt-get update':
  path => '/usr/bin'
}

package { ['python-software-properties', 'vim', 'git']:
  ensure => present,
  require => Exec['apt-get update'],
}
