class zabbix::config (
  $server = '127.0.0.1',
  $serverActive = '127.0.0.1',
  $pskIdentity = undef
) {
  case $::operatingsystem {
    'FreeBSD': {
      $confpath='/usr/local/etc/zabbix32/zabbix_agentd.conf'
    }
    default: {
      $confpath='/etc/zabbix/zabbix_agentd.conf'
    }
  }
  file {'/etc/zabbix/zabbix_agentd.d':
    ensure  =>  directory,
    mode    =>  '0755'
  } ->
  file {'/etc/zabbix/scripts':
    ensure  =>  directory,
    mode    =>  '0755'
  }
  zabbix::script{
    'smartctl-disks-discovery.pl':;
    'ups_status.sh':;
    'zabbix_mdraid.sh':;
  } ->
  zabbix::userparam{
    'mdraid':;
    'nut':;
    'smartctl':;
    'spooarch':;
  }
  $config_defaults={
    path    =>  $confpath,
    ensure  =>  present,
    require =>  [
      Package[$zabbix::packagename],
      File['/etc/zabbix/zabbix_agentd.d'],
    ],
    notify  =>  Service[$zabbix::servicename]
  }
  $config={
    'Hostname'              =>downcase("${::fqdn}"),
    'HostInterface'         =>downcase("${::fqdn}"),
    'HostMetadataItem'      =>"system.uname",
    'LogFile'               =>'/var/log/zabbix/zabbix_agentd.log',
    'PidFile'               =>'/run/zabbix/zabbix_agentd.pid',
    'Include'               =>'/etc/zabbix/zabbix_agentd.d/*.conf',
    'LogFileSize'           =>1,
    'EnableRemoteCommands'  =>1,
    'LogRemoteCommands'     =>0,
    'UnsafeUserParameters'  =>1,
    'Timeout'               =>30,
    'Server'                =>"$server",
    'ServerActive'          =>"$serverActive",
  }
  if $pskIdentity == undef {
    $pskConf={
        'TLSAccept'           =>'unencrypted',
        'TLSConnect'          =>'unencrypted',
    }
  } else {
    file {'/etc/zabbix/key':
      ensure  =>  directory,
      mode    =>  '0755'
    }
    file {'/etc/zabbix/key/agent-key.psk':
      source  => "puppet:///code_files/zabbix/psk/$pskIdentity.psk"
    }
    $pskConf={
      'TLSAccept'           =>'psk',
      'TLSConnect'          =>'psk',
      'TLSPSKIdentity'      =>$pskIdentity,
      'TLSPSKFile'          =>'/etc/zabbix/key/agent-key.psk'
    }
  }
  create_ini_settings (''=>$config+$pskConf,$config_defaults)
}
