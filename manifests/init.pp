class zabbix {
	case $::operatingsystem {
		FreeBSD: {
			$packagename='zabbix32-agent'
		}
		CentOS: {
			yumrepo { 'zabbix32_repo':
				enabled	=>	1,
				baseurl	=>	"http://repo.zabbix.com/zabbix/3.2/rhel/${::operatingsystemmajrelease}/${::architecture}",
				gpgcheck=>	0,
				before	=>	Package['zabbix-agent']
			}
			$packagename='zabbix-agent'
		}
		default: {
			$packagename='zabbix32-agent'
		}
	}
	package {'zabbix-agent':	
		name	=>	$packagename,
		ensure	=>	installed
	}
}