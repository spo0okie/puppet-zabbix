class zabbix (
	$ver = latest,	#версия заббикса
) {
	include repos::zabbix
	case $::operatingsystem {
		'FreeBSD': {
			$packagename='zabbix32-agent'
			$servicename='zabbix_agentd'
		}
		'CentOS': {
			$packagename='zabbix-agent'
			$servicename='zabbix-agent'
		}
		default: {
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