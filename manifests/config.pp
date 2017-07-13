class zabbix::config (
	$site = ''
) {
	case $::operatingsystem {
		FreeBSD: {
			confpath='/usr/local/etc/zabbix32/zabbix_agentd.conf'
		}
		default: {
			confpath='/etc/zabbix/zabbix_agentd.conf'
		}
	}
	ini_setting {
		path=>$confpath,ensure=>present,setting=
	
}