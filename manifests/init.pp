## PuppetDB and Console/Dashboard both have needs of the pe-httpd service
## PuppetDB => subscribe => puppet.conf
## console/dashboard  => subscribe => auth.conf

# leverage puppetlabs/apache if possible
class pe_httpd (
  $version = installed,
) {
  include pe_memcached

  package { 'pe-httpd':
    ensure => $version,
    before => Service['pe-httpd'],
  }

  service { 'pe-httpd':
    ensure  => running,
    enable  => true,
    require => Service['pe-memcached'],
  }

  file { '/etc/puppetlabs/httpd/conf.d':
    ensure  => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Service['pe-httpd'],
    require => Package['pe-httpd'],
  }

}
