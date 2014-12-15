# vagrant/puppet/modules/varnish/manifests/init.pp
class confvarnish {
    class { 'varnish': 
    varnish_listen_port => 80,
    varnish_storage_size => '1G',
    varnish_ttl => '5s'
    }

    #Default vcl file for varnish
    file { 'vagrant-varnish':
        path => '/etc/varnish/default.vcl',
        ensure => file,
        source => "puppet:///modules/confvarnish/varnish.vcl",
        require => Package['varnish'],
        notify => Service['varnish'],
    }
}
