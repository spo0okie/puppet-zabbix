class zabbix {
	include repos::zabbix
	case $::operatingsystem {
		'CentOS': {
			$packagename='zabbix-agent'
			$servicename='zabbix-agent'
		}
	}
	package {'zabbix-agent':
		name	=>	$packagename,
		ensure	=>	latest
	} ->
	file {'/var/log/zabbix/':
		ensure	=>	directory,
		mode	=>	'0777'
	} ->
	service {"$servicename":
		ensure	=>	running,
		enable	=>	true
	}
}