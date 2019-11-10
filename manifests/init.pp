class zabbix {
	case $::operatingsystem {
		CentOS: {
			yumrepo { 'zabbix32_repo':
				descr	=>	"Zabbix Official Repository - ${::architecture}",
				enabled	=>	1,
				baseurl	=>	"http://repo.zabbix.com/zabbix/3.4/rhel/${::operatingsystemmajrelease}/${::architecture}",
				gpgcheck=>	0,
				before	=>	Package['zabbix-agent']
			}
			yumrepo { 'zabbix_non_supported':
				descr	=>	"Zabbix Official Repository non-supported - ${::architecture}",
				baseurl	=>	"http://repo.zabbix.com/non-supported/rhel/${::operatingsystemmajrelease}/${::architecture}/",
				enabled	=>	1,
				gpgcheck=>	0,
				before	=>	Package['zabbix-agent']
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