# установка заббикса на разные ОС
# @param ver Версия заббикса (latest или конкретная версия пакета)
# @param agent_variant Вариант агента (classic или agent2)
class zabbix (
  Variant[Enum['latest'], String] $ver = 'latest',
  Enum['classic','agent2'] $agent_variant = 'classic',
) {
#согласно документации версию пакета надо указывать или "latest"
#или прям полностью вместе со всеми суфиксам и прочими афексами
#т.е. для каждого дистра придется расписывать индивидуально. что гемор
#поэтому latest или надо городить более сложную обвязку
  include repos::zabbix
  $runtime_dir = $facts['runtime_dir']
  $os_name = $facts['os']['name']
  $os_release_major = $facts['os']['release']['major']

  # zabbix-agent2 недоступен / не гарантирован на старых ОС:
  # - XenServer 6, CentOS 5 — пакета zabbix-agent2 не существует.
  # - CentOS 6 — agent2 для EL6 может отсутствовать в локальном зеркале.
  # - CentOS 7 — пакет zabbix-agent2 ставится, но без SysV-скрипта,
  #   и systemd-провайдер Puppet на EL7 в нашей среде не функционален —
  #   сервис не стартует. Пока проще исключить EL7 из поддержки agent2.
  # На этих ОС принудительный фолбэк на классический агент.
  $legacy_os = ($os_name == 'XenServer' and $os_release_major == '6') or ($os_name == 'CentOS' and $os_release_major in ['5'])
  $effective_variant = $legacy_os ? { true => 'classic', default => $agent_variant }

  if $effective_variant == 'agent2' {
    $packagename = 'zabbix-agent2'
    $servicename = 'zabbix-agent2'
    $confpath    = '/etc/zabbix/zabbix_agent2.conf'
    $include_dir = '/etc/zabbix/zabbix_agent2.d'
    $pidfile     = "${runtime_dir}/zabbix/zabbix_agent2.pid"
    $logfile     = '/var/log/zabbix/zabbix_agent2.log'

    # Освобождаем порт 10050: выпиливаем classic-агент, если он стоит.
    # ensure=>absent идемпотентен — на чистых хостах no-op.
    package { 'zabbix-agent-classic':
      ensure => absent,
      name   => 'zabbix-agent',
      before => Package[$packagename],
    }
  } else {
    $packagename = 'zabbix-agent'
    $servicename = 'zabbix-agent'
    $confpath    = '/etc/zabbix/zabbix_agentd.conf'
    $include_dir = '/etc/zabbix/zabbix_agentd.d'
    $pidfile     = "${runtime_dir}/zabbix/zabbix_agentd.pid"
    $logfile     = '/var/log/zabbix/zabbix_agentd.log'
  }

  package { $packagename:
    ensure => $ver,
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
