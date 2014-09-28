

class influxdb (
  $user           = 'influxdb',
  $user_uid       = undef,
  $group          = 'influxdb',
  $group_gid      = undef,
  $web_user       = 'root',
  $web_pwd        = 'root',
  $databases      = [],
  $admins         = [],
  $tmp            = '/tmp',
  $service_ensure = 'running',
  $service_enable = true,
) {

  validate_string($user)
  validate_string($group)
  validate_string($web_user)
  validate_string($web_pwd)
  validate_array($databases)
  validate_array($admins)
  validate_absolute_path($tmp)
  validate_string($service_ensure)
  validate_bool($service_enable)

  if $operatingsystem != 'CentOS' {
    fail('Your operating system is not supported yet!')
  }

  ensure_packages(['wget', 'curl'])

  if($group_gid) {
    group { 'influxdb group':
      ensure => 'present',
      name   => $group,
      gid    => $group_gid,
    }
  } else {
    group { 'influxdb group':
      ensure => 'present',
      name   => $group,
    }
  }

  if($user_uid) {
    user { 'influxdb user':
      ensure  => 'present',
      name    => $user,
      uid     => $user_uid,
      groups  => $group,
      comment => 'InfluxDB user',
      shell   => '/sbin/nologin',
      system  => true,
      require => Group['influxdb group'],
    }
  } else {
    user { 'influxdb user':
      ensure  => 'present',
      name    => $user,
      groups  => $group,
      comment => 'InfluxDB user',
      shell   => '/sbin/nologin',
      system  => true,
      require => Group['influxdb group'],
    }
  }

  exec { 'download influxdb':
    cwd     => $tmp,
    path    => '/sbin:/bin:/usr/bin',
    command => "wget http://s3.amazonaws.com/influxdb/influxdb-latest-1.${architecture}.rpm",
    creates => "${tmp}/influxdb-latest-1.${architecture}.rpm",
    require => Package['wget'],
  }

  package { 'influxdb':
    ensure   => 'present',
    name     => 'influxdb',
    provider => 'rpm',
    source   => "${tmp}/influxdb-latest-1.${architecture}.rpm",
    require  => Exec['download influxdb'],
  }

  file { 'fix init script':
    ensure  => 'present',
    path    => '/opt/influxdb/current/scripts/init.sh',
    source  => "puppet:///modules/${module_name}/init.sh",
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => Package['influxdb'],
  }

  service {'influxdb service':
    ensure     => $service_ensure,
    name       => 'influxdb',
    enable     => $service_enable,
    hasstatus  => true,
    hasrestart => true,
    require    => [Package['influxdb'], User['influxdb user'], File['fix init script']],
  }

  $databases.each |$database| {
    exec { "create database ${database}":
      cwd     => $tmp,
      path    => '/sbin:/bin:/usr/bin',
      command => "curl -s \"http://localhost:8086/db?u=${web_user}&p=${web_pwd}\" -d \"{\\\"name\\\": \\\"${database}\\\"}\"",
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
