class zabbix (
	$ver = latest,	#версия заббикса
) {
#согласно документации версию пакета надо указывать или "latest"
#или прям полностью вместе со всеми суфиксам и прочими афексами
#т.е. для каждого дистра придется расписывать индивидуально. что гемор
#поэтому latest или надо городить более сложную обвязку
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
		ensure	=>	$ver
	} ->
	file {'/var/log/zabbix/':
		ensure	=>	directory,
		mode	=>	'0770' #если сделать 777 - logrotate начнет ругаться, что неправильные права
	} ->
	service {"$servicename":
		ensure	=>	running,
		enable	=>	true
	}
}
