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
  $confpath='/etc/zabbix/zabbix_agentd.conf'
  $runtime_dir = $facts['runtime_dir']
  $os_name = $facts['os']['name']
  $os_release_major = $facts['os']['release']['major']

  # Для XenServer 6 и CentOS 5 отключаем TLS
  if $os_name == 'XenServer' and $os_release_major == '6' {
    $effective_psk_identity = 'disabled'
  } elsif $os_name == 'CentOS' and $os_release_major == '5' {
    $effective_psk_identity = 'disabled'
  } else {
    $effective_psk_identity = $pskIdentity
  }
  file { '/etc/zabbix/zabbix_agentd.d':
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
      File['/etc/zabbix/zabbix_agentd.d'],
    ],
    notify  => Service[$zabbix::servicename],
  }
  $config = {
    'Hostname'              => ($facts['networking']['fqdn']).downcase,
    'HostInterface'         => ($facts['networking']['fqdn']).downcase,
    'HostMetadataItem'      => 'system.uname',
    'LogFile'               => '/var/log/zabbix/zabbix_agentd.log',
    'PidFile'               => "${runtime_dir}/zabbix/zabbix_agentd.pid",
    'Include'               => '/etc/zabbix/zabbix_agentd.d/*.conf',
    'LogFileSize'           => 1,
    'EnableRemoteCommands'  => 1,
    'LogRemoteCommands'     => 0,
    'UnsafeUserParameters'  => 1,
    'Timeout'               => 30,
    'Server'                => $server,
    'ServerActive'          => $serverActive,
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

  create_ini_settings (''=> $config + $psk_conf, $config_defaults)
}
