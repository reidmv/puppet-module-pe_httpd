## PuppetDB and Console/Dashboard both have needs of the pe-httpd service
## PuppetDB => subscribe => puppet.conf
## console/dashboard  => subscribe => auth.conf

# leverage puppetlabs/apache if possible
class pe_httpd {

  # STUB STUB STUB STUB STUB
  # This is just here to make dependencies in other classes work. It can be
  # ripped out and replaced - there just needs to exist a Service['pe-httpd']
  service { 'pe-httpd':
    ensure => running,
    enable => true,
  }

  # TODO: break out the pe-memcached stuff into its own module
  service { 'pe-memcached':
    ensure => running,
    enable => true,
    before => Service['pe-httpd'],
  }

  # PATCH: manage missing shebang in init script for Debian packaging
  if $::osfamily == 'Debian' {
    $memcached = '/etc/init.d/pe-memcached'
    exec { 'insert-missing-shebang-for-pe-memcached':
      path     => '/bin:/usr/bin',
      provider => shell,
      command  => "f=$(echo '#!/bin/bash' | cat - ${memcached}); echo \"\$f\" > ${memcached}",
      unless   => "grep -q '#!/bin/' $memcached",
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
