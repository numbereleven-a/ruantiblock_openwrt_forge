# Changelog / История изменений

## 2.1.16-r1 core package

Package version:

- `ruantiblock` — `2.1.16-r1`

### English

#### Fixed

- UCI no longer overwrites missing options, including `BLLIST_MODULE` and `dnsmasq_confdir`.
- Stale PID files no longer block startup and updates.
- Fixed the AWK configuration syntax.
- Fixed hotplug status handling.
- Fixed unquoted numeric arguments in `NftInstanceAdd` callers so values such as `90 40` no longer shift subsequent parameters.

#### Security

- Removed `eval`-based assignment in `NftInstanceAdd` and quoted all positional arguments, preventing shell injection via crafted UCI values and argument-shift via spaces.
- Hardened UCI parsing in `config_script` and `config_script_user_instances` by escaping `\`, `$` and `` ` `` inside values before `eval`, blocking command substitution.
- Escaped `\`, `"`, `$` and `` ` `` in URLs inside `ruab_parser_user_entries` before constructing the shell `wget` command.

### Русский

#### Исправления

- UCI больше не затирает отсутствующие параметры, включая `BLLIST_MODULE` и `dnsmasq_confdir`.
- Устаревшие PID-файлы больше не блокируют запуск и обновление.
- Исправлен AWK-синтаксис конфигурации.
- Исправлена обработка статусов в hotplug.
- Исправлена передача неквотированных числовых аргументов в `NftInstanceAdd` — значения вроде `90 40` больше не сдвигают последующие параметры.

#### Безопасность

- Убран `eval` в `NftInstanceAdd`, все позиционные аргументы квотированы — исключена инъекция через crafted UCI и сдвиг аргументов пробелами.
- Ужесточён разбор UCI в `config_script` и `config_script_user_instances` — `\`, `$` и `` ` `` в значениях экранируются перед `eval`.
- В `ruab_parser_user_entries` экранированы `\`, `"`, `$` и `` ` `` в URL перед сборкой shell-команды `wget`.

## 2.1.15-r4 core package

Package version:

- `ruantiblock` — `2.1.15-r4`

### English

#### Fixed

- Preserved external `BLLIST_MODULE` and instance defaults when the corresponding UCI options are absent.
- Corrected the generated AWK blocks so UCI configuration is parsed without syntax errors.
- Ignored stale start and update PID files when their processes are no longer running.
- Rebuilt route-table cleanup from the previously active instance mapping, avoiding route-table deletion for disabled instances.
- Fixed hotplug status handling so empty, starting, updating, disabled, and error states do not trigger an unnecessary reload.

### Русский

#### Исправления

- Сохранены внешний `BLLIST_MODULE` и значения по умолчанию для экземпляров, если соответствующие параметры отсутствуют в UCI.
- Исправлены сгенерированные блоки AWK, поэтому конфигурация UCI разбирается без синтаксических ошибок.
- Устаревшие PID-файлы запуска и обновления теперь игнорируются, если соответствующие процессы больше не работают.
- Очистка таблиц маршрутизации выполняется по предыдущей карте активных экземпляров, поэтому таблицы выключенных экземпляров не удаляются.
- Исправлена обработка статусов в hotplug: пустой статус, запуск, обновление, отключённое состояние и ошибка больше не вызывают лишнюю перезагрузку.

## 2.1.16-r1 LuCI package

Package version:

- `luci-app-ruantiblock` — `2.1.16-r1`

### English

#### Changed

- Strengthened address validation: IP octets must be in the `0–255` range and ports in the `0–65535` range.
- Cron is no longer reloaded after a failed crontab write.

#### Fixed

- Fixed LuCI log loading: available `logread` paths and additional filter parameters are now handled.
- Fixed stale blacklist preset data after reopening the settings page.
- Fixed handling of incomplete statistics responses so empty or missing data does not break the interface.
- Fixed service status refresh after a polling error so the interface does not keep stale state.
- Fixed cron task detection, including correct removal of its own entries and writing an empty crontab.
- Fixed update-helper file permissions so the helpers run correctly after package installation.
- Escaped HTML output in the dnsmasq tables on the information page.

#### Security

- Moved the update-check PID file from `/tmp` to `/var/run/luci-app-ruantiblock/`.
- Added a `/proc/<PID>/comm` check before killing the process.
- Replaced the broad ACL glob `/usr/bin/ruantiblock*` with an explicit list of UI commands.

### Русский

#### Изменения

- Усилена проверка адресов: IP-октеты должны быть в диапазоне `0–255`, а порт — в диапазоне `0–65535`.
- Cron больше не перезагружается после неудачной записи его конфигурации.

#### Исправления

- Исправлена загрузка LuCI-логов: теперь учитываются доступные пути `logread` и дополнительные параметры фильтрации.
- Исправлено сохранение устаревших данных blacklist-пресетов после повторного открытия страницы настроек.
- Исправлена обработка неполных ответов статистики, чтобы пустые или отсутствующие данные не вызывали ошибку интерфейса.
- Исправлено обновление статуса службы после ошибки опроса, чтобы интерфейс не оставался с устаревшим состоянием.
- Исправлено распознавание заданий cron, включая корректное удаление собственных записей и запись пустого crontab.
- Исправлены права update-helper-файлов, чтобы они корректно запускались после установки пакета.
- Экранирован HTML-вывод таблиц dnsmasq на странице информации.

#### Безопасность

- PID-файл проверки обновлений перенесён из `/tmp` в `/var/run/luci-app-ruantiblock/`.
- Перед kill добавлена проверка `/proc/<PID>/comm`.
- Широкий шаблон ACL `/usr/bin/ruantiblock*` заменён явным списком команд интерфейса.

## 2.1.15-r10 LuCI package

Package version:

- `luci-app-ruantiblock` — `2.1.15-r10`

### English

#### Fixed

- Fixed LuCI log loading for available `logread` paths and timestamped filters.
- Fixed stale blacklist preset data after returning to the settings page.
- Fixed delayed service restart after applying settings.
- Fixed cron task detection, empty crontab writing, and unnecessary cron restarts after a failed write.
- Fixed handling of incomplete statistics responses and stale service status after a failed poll.
- Fixed comparison of release versions with an `-rN` suffix.

### Русский

#### Исправлено

- Исправлена загрузка логов LuCI для доступных путей `logread` и фильтров с временными метками.
- Исправлено сохранение устаревших данных о пресетах чёрного списка при повторном открытии настроек.
- Исправлен перезапуск службы после применения настроек.
- Исправлено определение заданий cron, запись пустого crontab и лишний перезапуск cron после ошибки записи.
- Исправлена обработка неполных ответов статистики и обновление статуса службы после ошибки опроса.
- Исправлено сравнение версий релизов с суффиксом `-rN`.

## 2.1.15-r9 package set

Package versions:

- `ruantiblock` — `2.1.15-r2`
- `luci-app-ruantiblock` — `2.1.15-r9`
- `ruantiblock-mod-lua` — `2.1.12-r5`
- `ruantiblock-mod-py` — `2.1.12-r5`

## Upgrade note / Примечание об обновлении

### English

If the separate `luci-i18n-ruantiblock-ru` package is installed, remove it once before installing the new LuCI package:

```sh
opkg remove luci-i18n-ruantiblock-ru
opkg install ./luci-app-ruantiblock_2.1.15-r9_all.ipk
```

Do not remove `luci-app-ruantiblock` or its configuration files. This step is only needed when switching from the old separate translation package; future LuCI upgrades can be installed normally.

### Русский

Если установлен отдельный пакет `luci-i18n-ruantiblock-ru`, перед первым обновлением удалите его:

```sh
opkg remove luci-i18n-ruantiblock-ru
opkg install ./luci-app-ruantiblock_2.1.15-r9_all.ipk
```

Сам пакет `luci-app-ruantiblock` и его конфигурационные файлы удалять не нужно. Этот шаг требуется только при переходе со старого отдельного пакета локализации; дальнейшие обновления LuCI устанавливаются обычным способом.

### English

#### Added

- Added a manual check for newer releases through the public GitHub Releases API.
- Added separate core and LuCI version display in the web interface.
- Added detailed VPN routing diagnostics with the affected instance, interface, route table, and failure reason when available.

#### Fixed

- Stopped using stale routing settings for user lists: they are rebuilt from the current configuration after changes.
- Rebuilt the DNS configuration for user lists after their VPN or proxy settings change.
- Removed nftables sets for disabled or deleted user lists.
- Made blacklist download failures stop the affected update cleanly without leaving partial data active.
- Handled missing crontab entries without aborting package removal or service maintenance.

### Русский

#### Добавлено

- Добавлена ручная проверка новых релизов через публичный GitHub Releases API.
- В веб-интерфейсе добавлено раздельное отображение версий core и LuCI.
- Добавлена подробная диагностика VPN-маршрутизации с экземпляром, интерфейсом, таблицей маршрутизации и причиной ошибки, если эти данные доступны.

#### Исправлено

- Устранено использование устаревших настроек маршрутизации пользовательских списков: после изменений они строятся заново по текущей конфигурации.
- Исправлена пересборка DNS-конфигурации пользовательских списков после изменения настроек VPN или прокси.
- Исправлено удаление nftables-наборов отключённых или удалённых пользовательских списков.
- Ошибка загрузки чёрного списка теперь корректно прерывает его обновление без активации неполных данных.
- Обработано отсутствие записей crontab, чтобы оно не прерывало удаление пакета и обслуживание службы.

## 2.1.12-r5

### English

#### Added

- Increased the default number of user lists from 5 to 10. On upgrade, the old default of 5 is migrated to 10 while other valid custom limits are preserved.
- Added a configurable user-list limit from 1 to 50 to **Settings → User entries**.
- Added an **Add user list** button which automatically creates the first available `listN` section within the selected limit.
- Added removal controls for user lists in the same LuCI table.

#### Fixed

- Restored domain routing through active VPN lists after a disabled user list is edited or saved.
- Moved the dnsmasq restart into the `Start()` procedure, immediately after the nft sets are applied.
- Removed the conditional dnsmasq restart from the init script because it is no longer required.

The fix is related to [issue #176](https://github.com/gSpotx2f/ruantiblock_openwrt/issues/176) and the relevant part of [PR #158](https://github.com/gSpotx2f/ruantiblock_openwrt/pull/158).

### Русский

#### Добавлено

- Количество пользовательских списков по умолчанию увеличено с 5 до 10. При обновлении прежнее значение 5 заменяется на 10, а другие корректные пользовательские лимиты сохраняются.
- На странице **Настройки → Записи пользователя** добавлен настраиваемый лимит пользовательских списков от 1 до 50.
- Добавлена кнопка **Добавить пользовательский список**, которая автоматически создаёт первую свободную секцию `listN` в пределах выбранного лимита.
- В той же таблице LuCI добавлено удаление пользовательских списков.

#### Исправлено

- Восстановлена маршрутизация доменов из активных VPN-списков после изменения или сохранения выключенного пользовательского списка.
- Перезапуск dnsmasq перенесён в процедуру `Start()` и выполняется сразу после применения nft-наборов.
- Удалён условный перезапуск dnsmasq из init-скрипта, который больше не требуется.

Исправление связано с [issue #176](https://github.com/gSpotx2f/ruantiblock_openwrt/issues/176) и релевантной частью [PR #158](https://github.com/gSpotx2f/ruantiblock_openwrt/pull/158).
