# zabbix

Puppet-модуль для установки и настройки Zabbix-агента на Linux-хостах. Поддерживает два варианта агента:

- **classic** (`zabbix-agent`) — традиционный агент, дефолт.
- **agent2** (`zabbix-agent2`) — современный агент на Go.

## Состав модуля

| Класс / тип | Назначение |
|---|---|
| `zabbix` | Установка пакета агента, базовые каталоги (`/var/log/zabbix`, `${runtime_dir}/zabbix`), управление сервисом. |
| `zabbix::config` | Генерация конфига агента (`zabbix_agentd.conf` или `zabbix_agent2.conf`), настройка сервера, TLS/PSK, `AllowKey`. |
| `zabbix::script` (defined type) | Доставка пользовательского скрипта в `/etc/zabbix/scripts/` + запись в sudoers. |
| `zabbix::userparam` (defined type) | Доставка `UserParameter`-конфига в include-каталог агента. |
| Факт `runtime_dir` | Возвращает `/run` или `/var/run` (для PID-файла). |

Файлы:

- `files/keys/agent-key.psk` — PSK-ключ для TLS.
- `files/scripts/` — пользовательские скрипты (`smartctl-disks-discovery.pl`, `ups_status.sh`, `zabbix_mdraid.sh`).
- `files/userparam/` — `UserParameter`-конфиги (`mdraid.conf`, `nut.conf`, `smartctl.conf`, `spooarch.conf`).

## Использование

### Classic agent (дефолт)

```puppet
class { 'zabbix::config':
  server       => '10.50.1.33,10.50.10.13',
  serverActive => '10.50.1.33',
  pskIdentity  => 'linux',
}
```

### Zabbix agent 2

```puppet
class { 'zabbix':
  agent_variant => 'agent2',
}
class { 'zabbix::config':
  server       => '10.50.1.33,10.50.10.13',
  serverActive => '10.50.1.33',
  pskIdentity  => 'linux',
}
```

### Параметры

**`class zabbix`**

| Параметр | Тип | Дефолт | Описание |
|---|---|---|---|
| `ver` | — | `latest` | Версия пакета агента (или `latest`). |
| `agent_variant` | `Enum['classic','agent2']` | `'classic'` | Какой агент ставить. |

**`class zabbix::config`**

| Параметр | Тип | Дефолт | Описание |
|---|---|---|---|
| `server` | `String` | `'127.0.0.1'` | Адрес(а) Zabbix-сервера (`Server=`). |
| `serverActive` | `String` | `'127.0.0.1'` | Адрес для активного режима (`ServerActive=`). |
| `pskIdentity` | `Optional[String]` | `undef` | PSK-identity для TLS. `undef` → unencrypted; на старых ОС TLS принудительно отключается. |

### Дополнительные ресурсы

```puppet
zabbix::userparam { 'smartctl': }       # /etc/zabbix/zabbix_agentd.d/userparam_smartctl.conf
zabbix::script    { 'ups_status.sh': }  # /etc/zabbix/scripts/ups_status.sh + sudoers
```

## Нюансы перехода classic ↔ agent2

### 1. Оба агента слушают порт 10050

Параллельная работа невозможна. При выборе `agent_variant => 'agent2'` модуль автоматически объявляет `package { 'zabbix-agent': ensure => absent }` **до** установки `zabbix-agent2`. На чистых хостах это no-op, на хостах с уже стоящим classic-агентом — корректная миграция:

1. Удаление пакета `zabbix-agent` (postinst пакета останавливает сервис).
2. Установка `zabbix-agent2`.
3. Запуск сервиса `zabbix-agent2`.

Обратный переход (`agent_variant => 'classic'` после agent2) аналогичной автоматики **не имеет** — модуль не удаляет `zabbix-agent2`. Если нужно вернуться, удалите пакет вручную или дополните модуль симметричной логикой.

### 2. Разные пути конфигов

| | classic | agent2 |
|---|---|---|
| Конфиг | `/etc/zabbix/zabbix_agentd.conf` | `/etc/zabbix/zabbix_agent2.conf` |
| Include-каталог | `/etc/zabbix/zabbix_agentd.d/` | `/etc/zabbix/zabbix_agent2.d/` |
| PID | `${runtime_dir}/zabbix/zabbix_agentd.pid` | `${runtime_dir}/zabbix/zabbix_agent2.pid` |
| Лог | `/var/log/zabbix/zabbix_agentd.log` | `/var/log/zabbix/zabbix_agent2.log` |

При миграции старые файлы (конфиг и include-каталог classic-агента) **не удаляются**. Это намеренно — упрощает откат. Если хочется чистоты, удалите вручную:

```sh
rm -rf /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.d
```

### 3. Несовместимые директивы конфига

В agent2 нет `EnableRemoteCommands` и `LogRemoteCommands` — наличие этих директив приводит к ошибке старта. Модуль **на современных ОС** использует вместо них `AllowKey=system.run[*]` (это эквивалент `EnableRemoteCommands=1`), причём для **обоих** вариантов агента — classic-агент с версии 5.0 поддерживает `AllowKey`, а `EnableRemoteCommands` объявлен deprecated.

На старых ОС (XenServer 6, CentOS 5) сохранены старые директивы, т.к. там стоит древняя версия `zabbix-agent`, не понимающая `AllowKey`.

### 4. Старые ОС и CentOS 7: принудительный фолбэк на classic

Для **XenServer 6**, **CentOS 5**, **CentOS 6** и **CentOS 7** модуль игнорирует `agent_variant => 'agent2'` и всегда ставит classic-агент:

- **XenServer 6 / CentOS 5** — пакета `zabbix-agent2` физически не существует, и древний classic-агент не понимает `AllowKey`/TLS, поэтому для них также сохраняются старые директивы конфига (`EnableRemoteCommands`) и принудительно отключается TLS (`pskIdentity` игнорируется).
- **CentOS 6** — пакет ставится из локального зеркала (`repos::zabbix` указывает на `repo.azimuth.holding.local/Zabbix/rhel6`), в котором наличие `zabbix-agent2` не гарантировано (EL6 EOL, agent2 для EL6 был только в Zabbix 4.4–5.0). Чтобы не ронять каталог на этапе `package install`, для EL6 форсится classic. На уровне конфига EL6 уже современный: TLS и `AllowKey` работают.
- **CentOS 7** — пакет `zabbix-agent2` ставится, но поставляет только systemd-unit (без SysV-скрипта). Auto-detect Puppet в нашей среде на EL7 не выбирает systemd-провайдер, и сервис не стартует с ошибкой `Services must specify a start command or a binary`. Явный `provider => 'systemd'` на этой версии Puppet рапортует `Provider systemd is not functional on this host`. До решения вопроса с провайдером EL7 исключён из поддержки agent2.

### Зависимость от `repos::zabbix` и локальных зеркал

Модуль `repos::zabbix` для **CentOS/RHEL 5/6/7** подключает локальное зеркало `repo.azimuth.holding.local/Zabbix/rhel{5,6,7}`. Для остальных целевых ОС используются официальные репозитории Zabbix, в которых `zabbix-agent2` гарантированно присутствует — код `repos::zabbix` править не нужно.

### 5. Hostname в конфиге

Берётся из `$facts['networking']['fqdn']` в нижнем регистре. Если хост в Zabbix зарегистрирован под другим именем — сначала переименовать в Zabbix-сервере, иначе данные перестанут поступать.

### 6. PSK-ключ

Файл `files/keys/agent-key.psk` доставляется в `/etc/zabbix/key/agent-key.psk` (один и тот же путь для обоих вариантов агента — миграция ключ не трогает). `pskIdentity` параметризуется per-host.

### 7. UserParameter и скрипты

Defined-типы `zabbix::userparam` и `zabbix::script` используют `$zabbix::include_dir` / `$zabbix::packagename` — переключение варианта агента автоматически кладёт userparam-файлы в правильный include-каталог. Существующие декларации не нужно менять.

## Зависимости

- `puppetlabs/inifile` — функция `create_ini_settings` в `zabbix::config`.
- Модуль `repos::zabbix` — подключает yum/apt-репозиторий Zabbix (включается из `zabbix`).
- Модуль `users` — `zabbix::script` использует `$users::sudoers::filepath`.

## Поддерживаемые ОС

| ОС | classic | agent2 | TLS | AllowKey |
|---|---|---|---|---|
| Debian 9–13 | ✓ | ✓ | ✓ | ✓ |
| Ubuntu 16–24 | ✓ | ✓ | ✓ | ✓ |
| RHEL / CentOS 8 | ✓ | ✓ | ✓ | ✓ |
| SLES 15 | ✓ | ✓ | ✓ | ✓ |
| RHEL / CentOS 7 | ✓ | ✗ форс classic | ✓ | ✓ |
| CentOS 6 | ✓ | ✗ форс classic | ✓ | ✓ |
| CentOS 5 | ✓ | ✗ форс classic | ✗ | ✗ (`EnableRemoteCommands`) |
| XenServer 6 | ✓ | ✗ форс classic | ✗ | ✗ (`EnableRemoteCommands`) |
