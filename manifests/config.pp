class zabbix::config (
	$server = '127.0.0.1',
	$serverActive = '127.0.0.1'
) {
	case $::operatingsystem {
		'FreeBSD': {
			$confpath='/usr/local/etc/zabbix32/zabbix_agentd.conf'
		}
		default: {
			$confpath='/etc/zabbix/zabbix_agentd.conf'
		}
	}
	$config_defaults={
		path	=>	$confpath,
		ensure	=>	present,
		require	=>	Package['zabbix-agent'],
		notify	=>	Service["${zabbix::servicename}"]
	}
	$config={
		''=>{
			'Hostname'				=>"${::fqdn}",
			'LogFile'				=>'/var/log/zabbix/zabbix_agentd.log',
			'PidFile'				=>'/var/run/zabbix/zabbix_agentd.pid',
			'LogFile'				=>'/var/log/zabbix/zabbix_agentd.log',
			'LogFileSize'			=>5,
			'EnableRemoteCommands'	=>1,
			'LogRemoteCommands'		=>1,
			'UnsafeUserParameters'	=>1,
			'Timeout'				=>20,
			'Server'				=>"$server",
			'ServerActive'			=>"$serverActive"
		}
	}
	create_ini_settings ($config,$config_defaults)
}
