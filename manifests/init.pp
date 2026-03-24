# установка заббикса на разные ОС
class zabbix (
  $ver = latest, #версия заббикса
) {
#согласно документации версию пакета надо указывать или "latest"
#или прям полностью вместе со всеми суфиксам и прочими афексами
#т.е. для каждого дистра придется расписывать индивидуально. что гемор
#поэтому latest или надо городить более сложную обвязку
  include repos::zabbix
  $runtime_dir = $facts['runtime_dir']
  $packagename='zabbix-agent'
  $servicename='zabbix-agent'
  package { 'zabbix-agent':
    ensure => $ver,
    name   => $packagename,
  }
  -> file { '/var/log/zabbix/':
    ensure => directory,
    mode   => '0700', #если сделать 777 - logrotate начнет ругаться, что неправильные права
    owner  => 'zabbix',
  }
  -> file { "${runtime_dir}/zabbix":
    ensure => directory,
    mode   => '0755',
    owner  => 'zabbix',
  }
  -> service { $servicename:
    ensure => running,
    enable => true,
  }
}
