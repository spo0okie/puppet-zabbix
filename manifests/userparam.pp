define zabbix::userparam () {
  file {"/etc/zabbix/zabbix_agentd.d/userparam_$title.conf":
    source  => "puppet:///modules/zabbix/userparam/$title.conf",
    mode    =>  '0644',
    require =>  [
      Package[$zabbix::packagename],
      File['/etc/zabbix/zabbix_agentd.d'],
    ],
    notify  =>  Service[$zabbix::servicename]
  }
}
