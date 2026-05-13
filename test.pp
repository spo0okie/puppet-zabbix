class { 'zabbix':
  agent_variant => 'agent2',
}
class { 'zabbix::config':
  server       => '10.50.1.33,10.50.10.13',
  serverActive => '10.50.1.33',
  pskIdentity  => 'linux',
}
