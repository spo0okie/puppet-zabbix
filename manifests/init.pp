class zabbix {
	case $::operatingsystem {
		CentOS: {
			yumrepo { 'zabbix32_repo':
				name	=>	"Zabbix Official Repository - ${::architecture}"
				enabled	=>	1,
				baseurl	=>	"http://repo.zabbix.com/zabbix/3.4/rhel/${::operatingsystemmajrelease}/${::architecture}",
				gpgcheck=>	0,
				before	=>	Package['zabbix-agent']
			}
			yumrepo { 'zabbix_non_supported':
				name	=>	"Zabbix Official Repository non-supported - ${::architecture}"
				baseurl	=>	"http://repo.zabbix.com/non-supported/rhel/7/${::architecture}/"
				enabled=1
				gpgcheck=1
			}
			$packagename='zabbix-agent'
			$servicename='zabbix-agent'
		}
		default: {
			$packagename='zabbix32-agent'
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