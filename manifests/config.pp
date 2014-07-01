
class influxdb::config(
  $config_path = '/opt/influxdb/shared/config.toml',
  $hostname = '',
  $bind_adress = '0.0.0.0',
) {

  Ini_setting {
    ensure  => present,
    path    => $config_path,
    notify  => Service['influxdb'],
    require => Package['influxdb'],
  }

  ini_setting { 'hostname':
    section => '',
    setting => 'hostname',
    value   => "\"${hostname}\"",
  }

  ini_setting { 'bind_address':
    section => '',
    setting => 'bind-address',
    value   => "\"${bind_address}\"",
  }
}
