define zabbix::script () {
  file {"/etc/zabbix/scripts/$title":
    source  => "puppet:///modules/zabbix/scripts/$title",
    mode    => '0755',
    require => [
      Package[$zabbix::packagename],
      File['/etc/zabbix/scripts'],
    ],
    notify  => Service[$zabbix::servicename]
  } ->
  file_line {"sudo_$title":
    path    => $users::sudoers::filepath,
    line    => "zabbix      ALL=(root)  NOPASSWD: /etc/zabbix/scripts/$title",
    match   => "/etc/zabbix/scripts/$title"
  }
}
