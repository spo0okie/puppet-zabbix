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
  case $::operatingsystem {
    'FreeBSD': {
      $packagename='zabbix32-agent'
      $servicename='zabbix_agentd'
    }
    default: {
      $packagename='zabbix-agent'
      $servicename='zabbix-agent'
    }
  }
  case $::operatingsystem {
    'XenServer': {
      package { 'zabbix-agent':
        ensure          => installed,
        name            => $packagename,
        provider        => rpm,
        source          => 'http://storage-docker.azimuth.holding.local/Zabbix/rhel5/zabbix-agent-6.0.9-release1.el5.x86_64.rpm',
        install_options => ['--httpproxy','klg-proxy.azimuth.holding.local', '--httpport', '3128'],
      }
    }
    default: {
      package { 'zabbix-agent':
        ensure => $ver,
        name   => $packagename,
      }
    }
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
