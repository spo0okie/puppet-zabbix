define zabbix::userparam () {
  file { "${zabbix::include_dir}/userparam_${title}.conf":
    source  => "puppet:///modules/zabbix/userparam/${title}.conf",
    mode    => '0644',
    require => [
      Package[$zabbix::packagename],
      File[$zabbix::include_dir],
    ],
    notify  => Service[$zabbix::servicename],
  }
}
