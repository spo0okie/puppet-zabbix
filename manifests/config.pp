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
		require	=>	Package["${zabbix::packagename}"],
		notify	=>	Service["${zabbix::servicename}"]
	}
	$config={
		''=>{
			'Hostname'				=>"${::fqdn}",
			'HostInterface'			=>"${::fqdn}",
			'HostMetadataItem'		=>"system.uname",
			'LogFile'				=>'/var/log/zabbix/zabbix_agentd.log',
			#'PidFile'				=>'/var/run/zabbix/zabbix_agentd.pid',
			'Include'				=>'/etc/zabbix/zabbix_agentd.d/*.conf',
			'LogFileSize'			=>1,
			'EnableRemoteCommands'	=>1,
			'LogRemoteCommands'		=>0,
			'UnsafeUserParameters'	=>1,
			'Timeout'				=>30,
			'Server'				=>"$server",
			'ServerActive'			=>"$serverActive"
		}
	}
	file {'/etc/zabbix/zabbix_agentd.d':
		ensure	=>	directory,
		mode	=>	'0755'
	} ->
	create_ini_settings ($config,$config_defaults)
}
