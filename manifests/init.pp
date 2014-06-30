

class influxdb (
  $user           = 'influxdb',
  $group          = 'influxdb',
  $databases      = [],
  $admins         = [],
  $tmp            = '/tmp',
  $service_ensure = 'running',
  $service_enable = 'true',
) {

  validate_string($user)
  validate_string($group)
  validate_array($databases)
  validate_array($admins)
  validate_absolute_path($tmp)
  validate_string($service_ensure)
  validate_bool($service_enable)

  if $operatingsystem != 'CentOS' {
    fail('Your operating system is not supported yet!')
  }

  ensure_packages(['wget', 'curl'])

  group { 'influxdb group':
    ensure => 'present',
    name   => $group,
  }

  user { 'influxdb user':
    ensure  => 'present',
    name    => $user,
    groups  => $group,
    comment => 'InfluxDB user',
    shell   => '/sbin/nologin',
    system  => true,
    require => Group['influxdb group'],
  }

  exec { 'download influxdb':
    cwd     => $tmp,
    path    => '/sbin:/bin:/usr/bin',
    command => "wget http://s3.amazonaws.com/influxdb/influxdb-latest-1.${architecture}.rpm",
    creates => "${tmp}/influxdb-latest-1.${architecture}.rpm",
    require => Package['wget'],
  }

  package { 'install influxdb':
    ensure  => 'present',
    name    => 'influxdb',
    source  => "${tmp}/influxdb-latest-1.${architecture}.rpm",
    require => Exec['download influxdb'],
  }

  service {'influxdb service':
    ensure     => $service_ensure,
    name       => 'influxdb',
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => true,
    require    => [Package['install influxdb'], User['influxdb user']],
  }

  $databases.each |$database| {
    exec { "create database ${database}":
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "curl -s \"http://localhost:8086/db?u=root&p=root\" -d \"{\\\"name\\\": \\\"${database}\\\"}\"",
      require => Service['influxdb service'],
    }
  }

  #$admins.each |$admin| {
  #  exec { "create admin ${admin}":
  #    cwd     => $tmp,
  #    path    => '/sbin:/bin:/usr/bin',
  #    command => "curl -s \"http://localhost:8086/db?u=root&p=root\" -d \"{\\\"name\\\": \\\"${database}\\\"}\"",
  #    require => Service['influxdb service'],
  #  }
  #}
}
