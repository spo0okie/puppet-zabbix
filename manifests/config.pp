#Класс настройки заббикса
# @param server Zabbix server address
# @param serverActive Active Zabbix server address
# @param pskIdentity Pre-shared key identity for TLS communication
class zabbix::config (
  String $server = '127.0.0.1',
  String $serverActive = '127.0.0.1',
  Optional[String] $pskIdentity = undef
) {
  include zabbix
  $confpath      = $zabbix::confpath
  $include_dir   = $zabbix::include_dir
  $pidfile       = $zabbix::pidfile
  $logfile       = $zabbix::logfile
  $agent_variant = $zabbix::effective_variant
  $os_name = $facts['os']['name']
  $os_release_major = $facts['os']['release']['major']

  # Старые ОС с устаревшими версиями zabbix-agent:
  # - не поддерживают TLS (XenServer 6, CentOS 5)
  # - не понимают AllowKey/DenyKey (XenServer 6, CentOS 5)
  # CentOS 6 здесь нет: agent версии 5.0 на EL6 уже понимает AllowKey
  # и TLS, поэтому legacy-обработка конфига не нужна (фолбэк на classic
  # для EL6 выполняется на уровне zabbix-класса по другой причине —
  # ненадёжная доступность zabbix-agent2 в локальном зеркале).
  $legacy_os = ($os_name == 'XenServer' and $os_release_major == '6') or ($os_name == 'CentOS' and $os_release_major == '5')

  if $legacy_os {
    $effective_psk_identity = 'disabled'
  } else {
    $effective_psk_identity = $pskIdentity
  }
  file { $include_dir:
    ensure => directory,
    mode   => '0755',
  }
  file { '/etc/zabbix/key':
    ensure => directory,
    mode   => '0755',
  }
  -> file { '/etc/zabbix/key/agent-key.psk':
    source  => 'puppet:///modules/zabbix/keys/agent-key.psk',
  }
  $config_defaults = {
    path    => $confpath,
    ensure  => present,
    require => [
      Package[$zabbix::packagename],
      File[$include_dir],
    ],
    notify  => Service[$zabbix::servicename],
  }
  $fqdn=($facts['networking']['fqdn'].downcase)
  $base_config = {
    'Hostname'              => $fqdn,
    'HostInterface'         => $fqdn,
    'HostMetadataItem'      => 'system.uname',
    'LogFile'               => $logfile,
    'PidFile'               => $pidfile,
    'LogFileSize'           => 1,
    'UnsafeUserParameters'  => 1,
    'Timeout'               => 30,
    'Server'                => $server,
    'ServerActive'          => $serverActive,
  }

  # на classic вклчаем include; на agent2 Include повторяются для разных папок и create_ini_settings ломает
  if $agent_variant == 'classic' {
    $include_conf = {
      'Include' => "${include_dir}/*.conf",
    }
  } else {
    $include_conf = {}
    file_line { 'zabbix_include_main':
      path  => $confpath,
      line  => "Include=${include_dir}/*.conf",
      match => '^Include=.*\.d/\*\.conf$',
      notify => Service[$zabbix::servicename],
    } ->
    file_line { 'zabbix_include_plugins':
      path  => $confpath,
      line  => "Include=${include_dir}/plugins.d/*.conf",
      match => '^Include=.*plugins\.d/\*\.conf$',
      notify => Service[$zabbix::servicename],
    }
  }

  # Remote commands: на старых ОС остаётся EnableRemoteCommands,
  # на современных (включая zabbix-agent2) — AllowKey=system.run[*].
  if $legacy_os {
    $remote_cmd_conf = {
      'EnableRemoteCommands' => 1,
      'LogRemoteCommands'    => 0,
    }
  } else {
    $remote_cmd_conf = {
      'AllowKey' => 'system.run[*]',
    }
  }

  if $effective_psk_identity == undef {
    $psk_conf = {
      'TLSAccept'             => 'unencrypted',
      'TLSConnect'            => 'unencrypted',
    }
  } elsif $effective_psk_identity == 'disabled' {
    $psk_conf = {}
  } else {
    $psk_conf = {
      'TLSAccept'           => 'psk',
      'TLSConnect'          => 'psk',
      'TLSPSKIdentity'      => $pskIdentity,
      'TLSPSKFile'          => '/etc/zabbix/key/agent-key.psk',
    }
  }

  inifile::create_ini_settings (''=> $base_config + $remote_cmd_conf + $psk_conf + $include_conf, $config_defaults)
}
