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

  # PATCH: manage missing shebang in init script for Debian packaging
  if $::osfamily == 'Debian' {
    $memcached = '/etc/init.d/pe-memcached'
    exec { 'insert-missing-shebang-for-pe-memcached':
      path     => '/bin:/usr/bin',
      provider => shell,
      command  => "f=$(echo '#!/bin/bash' | cat - ${memcached}); echo \"\$f\" > ${memcached}",
      unless   => "grep -q '#!/bin/' $memcached",
      before   => Service['pe-httpd'],
      require  => Package['pe-httpd'],
    }
  }

  # Manage the conf.d directory. This should probably be split out from the
  # (non-existent on RedHat) sites-enabled directory. Then we wouldn't have
  # to ship the default conf files in the module.
  file { '/etc/puppetlabs/httpd/conf.d':
    ensure  => directory,
    purge   => true,
    recurse => true,
    force   => true,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    source  => "puppet:///modules/pe_httpd/conf.d/${::osfamily}",
    notify  => Service['pe-httpd'],
  }

}
