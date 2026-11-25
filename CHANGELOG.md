# Changelog / История изменений

## 2.3.0-r1 core, LuCI and parser modules

Package versions: `ruantiblock`, `luci-app-ruantiblock`, `ruantiblock-mod-lua` and `ruantiblock-mod-py` — `2.3.0-r1`.

### English

#### Added

- Added a **Restart** button on the main LuCI Service page (`admin/services/ruantiblock/service`) with Russian translation.

#### Fixed

- Enabled TLS certificate verification by default for `wget` and Lua HTTPS requests, added `+ca-bundle` to `ruantiblock` dependencies, and strictly validated downloaded native `ruantiblock.ip` and `ruantiblock.dnsmasq` files before applying them.
- Fixed `cron.js` to read `/etc/crontabs/root` via `fs.read_direct` so read errors cannot be silently swallowed by `fs.lines` and overwrite unrelated cron jobs, and granted `cgi-io` `download` in `luci-app-ruantiblock` rpcd ACL alongside `exec`.
- Fixed LuCI Service status rendering when the service is disabled (fresh DOM status badge elements instead of moving a shared node), added the missing `return` in the Update button handler, guarded empty dnsmasq directory selection on Shutdown, preserved disabled button states after `ui.createHandlerFn` settles, and reported action/status errors without unhandled rejections.
- Moved mutating service `exec` commands and `luci.setInitAction` from `read` to `write` in `luci-app-ruantiblock` rpcd ACL.
- Fixed Lua parser and `iptool.lua` CIDR normalization and `/0` overlap handling, fixed `idn.lua` UTF-8 label validation and Lua leading-dot FQDN rejection, fixed duplicate FQDN and post-optimization SLD/IP limit handling in both Lua and Python parsers without dropping capped domains/IPs, re-checked normalized CIDRs against `ip_excluded` in Python, rejected malformed ASCII domains in Python, checked `wget` exit codes and `os.rename` in Lua, and made `rublacklist` JSON field extraction resilient to escaped quotes and key order.
- Fixed `ruab_parser_user_entries` handling of leading/trailing whitespace in `U_ENTRIES_REMOTE` and local loop variables in awk functions.
- Fixed `ruantiblock` `Reload()` to create/refresh instance nftables sets, update or clean up `INSTANCES_CACHE`, and stop `ruab_route_check` when monitoring is no longer needed; checked `START_PID_FILE` before `CheckStatus` in `raw-status`.
- Fixed `ruab_route_check` to require an IPv4 address (unless `vpn_gw_ip` is set) before triggering recovery reloads, and moved `40-ruantiblock` hotplug waiting off the synchronous `ifup` path after interface matching.
- Fixed `opkg` package upgrade detection in `ruantiblock` `prerm` (`PKG_UPGRADE=1` / `$2=upgrade` when invoked via OpenWrt `default_prerm`) so service autostart state and `/etc/crontabs/root` entries are preserved across upgrades instead of running the uninstall branch.
- Fixed `info_output` JSON generation for empty/multiline `update_status`, normalized uppercase domains and tightened DNS validation in `AddBypassEntries`, fixed LuCI log highlight entity corruption, cleared removed user list files only on Save & Apply in Settings, kept Statistics polling active across enabled/disabled transitions without stale tables, terminated child `uclient-fetch` on `check-updates` signal cleanup, fixed `-opkg` cleanup in `uninstall.sh`, removed unused module dependencies (`+idn`, `+python3-setuptools`), and synced `README` with release archive contents.

### Русский

#### Добавлено

- Добавлена кнопка **Restart** («Перезапустить») на главную страницу службы LuCI (`admin/services/ruantiblock/service`) с русским переводом.

#### Исправлено

- Включена проверка TLS-сертификатов по умолчанию для `wget` и Lua HTTPS-запросов, добавлена зависимость `+ca-bundle` в пакет `ruantiblock` и строгая проверка загружаемых нативных файлов `ruantiblock.ip` и `ruantiblock.dnsmasq` перед применением.
- В `cron.js` чтение `/etc/crontabs/root` переведено на `fs.read_direct`, чтобы ошибки чтения не скрывались внутри `fs.lines` и не приводили к потере сторонних задач cron; в ACL `luci-app-ruantiblock` добавлено право `download` для `cgi-io`.
- Исправлено отображение статуса выключенной службы в LuCI (создание отдельных DOM-элементов вместо переноса общего узла), добавлен пропущенный `return` в обработчике кнопки «Обновить», защищён пустой выбор каталога dnsmasq при выключении, сохранено отключённое состояние кнопок после завершения `ui.createHandlerFn` и добавлено уведомление об ошибках действий службы без необработанных отклонений промисов.
- В ACL `luci-app-ruantiblock` мутирующие команды службы и `luci.setInitAction` перенесены из секции `read` в `write`.
- В Lua-парсере и `iptool.lua` исправлены нормализация нестрогих CIDR и обработка `/0`, в `idn.lua` и Lua-парсере исправлены проверка UTF-8 меток и запрет ведущей точки в доменах, в обоих парсерах (Lua и Python) устранено ложное схлопывание от дубликатов без потери доменов/IP при срабатывании лимитов, в Python добавлена перепроверка нормализованных CIDR по `ip_excluded` и запрещены некорректные ASCII-домены, в Lua добавлена проверка кода возврата `wget` и `os.rename`, улучшен разбор полей `rublacklist` с экранированными кавычками и произвольным порядком ключей.
- В `ruab_parser_user_entries` исправлена обработка пробелов по краям `U_ENTRIES_REMOTE` и локализация переменных циклов `awk`.
- В `Reload()` добавлены создание/обновление nft-сетов экземпляров, обновление или очистка `INSTANCES_CACHE` и остановка `ruab_route_check`, если мониторинг больше не требуется; в `raw-status` проверка `START_PID_FILE` выполняется до `CheckStatus`.
- В `ruab_route_check` добавлена проверка наличия IPv4-адреса интерфейса (если не задан `vpn_gw_ip`) для предотвращения циклических перезагрузок, а в `40-ruantiblock` ожидание статуса перенесено в фон и выполняется только после совпадения VPN-интерфейса.
- Исправлено определение обновления пакета `opkg` в `prerm` пакета `ruantiblock` (`PKG_UPGRADE=1` / `$2=upgrade` при вызове через OpenWrt `default_prerm`), чтобы при обновлении сохранялись состояние автозапуска службы и задания в `/etc/crontabs/root` вместо выполнения ветки удаления.
- Исправлена генерация JSON в `info_output` при пустом/многострочном `update_status`, добавлены приведение к нижнему регистру и строгая проверка DNS в `AddBypassEntries`, исправлено повреждение HTML-сущностей при подсветке в журнале LuCI, очистка файлов удалённых списков перенесена в Save & Apply, на странице статистики опрос и полная перерисовка работают при любых переходах enabled/disabled, добавлено завершение `uclient-fetch` при отмене `check-updates`, исправлен суффикс `-opkg` в `uninstall.sh`, удалены неиспользуемые зависимости модулей (`+idn`, `+python3-setuptools`) и актуализированы `README`.

## 2.1.20-r6 core, LuCI and parser modules

Package versions: `ruantiblock`, `luci-app-ruantiblock`, `ruantiblock-mod-lua` and `ruantiblock-mod-py` — `2.1.20-r6`.

### English

#### Fixed

- Escaped shell arguments and tightened IDN domain validation in the Lua parser (`encoding_iconv` and `wget` fallback).
- Filtered main-instance transparent proxy nftables rules by enabled L4 protocols so disabled UDP/ICMP traffic is not routed to `lo` in `tproxy` mode.
- Cleaned up both main-instance policy routing tables on rule teardown and cleared stale `tproxy` loopback rules before re-adding them.
- Prevented false `40-ruantiblock` hotplug reloads on `ifup` events with an empty device name and moved the delayed reload to the background.
- Restored IP nftables sets when blacklist preparation fails with rollback while `nftset_clear_sets` is enabled.
- Normalized non-strict CIDR entries, rejected invalid IDNA conversions, summed multi-parser optimization counts, supported multi-domain `rublacklist` entries, fixed Lua subdomain suffix matching, and made parser file writes atomic.
- Fixed LuCI Statistics rule counters and labels for lists with both TCP and UDP enabled in transparent proxy mode, and kept `info_output` JSON valid when optional sets are absent or URLs contain backslashes/quotes.
- Fixed LuCI async ordering in `service.js` (`dialogDestroy` UCI apply and `update` status refresh) and `update-checker.js`, validated `ruab_route_check` PID before stopping, and fixed `uninstall.sh` glob/torrc cleanup and `autoinstall.sh` temp-dir/cron handling.
- Enabled service autostart by default on fresh installation, preserved autostart and cron entries across package upgrades, and added `+nftables-json` to package dependencies.

### Русский

#### Исправлено

- Экранированы аргументы shell и усилена проверка IDN-доменов в Lua-парсере (`encoding_iconv` и fallback на `wget`).
- В правилах nftables главного экземпляра для прозрачного прокси добавлена фильтрация по активным L4-протоколам, чтобы отключённый UDP/ICMP-трафик не уходил в `lo` в режиме `tproxy`.
- При удалении правил очищаются обе стартовые таблицы маршрутизации главного экземпляра, а для `tproxy` старые `lo`-правила удаляются перед повторным добавлением.
- Устранены ложные перезагрузки в hotplug-скрипте `40-ruantiblock` при `ifup` с пустым именем устройства, отложенный `reload` вынесен в фон.
- Добавлено восстановление IP-сетов nftables после отката неудачной подготовки списков при включённом `nftset_clear_sets`.
- В парсерах нормализованы нестрогие CIDR, запрещён пропуск невалидного IDNA в `dnsmasq`, исправлено суммирование счётчиков нескольких парсеров, добавлена обработка многодоменных записей `rublacklist`, исправлено сравнение суффикса субдоменов в Lua и сделана атомарная запись файлов.
- Исправлены счётчики и подписи правил в статистике LuCI для списков с одновременно включёнными TCP и UDP, а также генерация валидного JSON в `info_output` при отсутствующих сетах и спецсимволах в URL.
- Исправлены асинхронные гонки в `service.js` (`dialogDestroy` и обновление статуса при `update`) и `update-checker.js`, добавлена проверка PID перед остановкой `ruab_route_check`, исправлены `uninstall.sh` и `autoinstall.sh`.
- Включён автозапуск службы по умолчанию при новой установке, сохранены состояние автозапуска и задания cron при обновлении пакета, добавлена зависимость `+nftables-json`.

## 2.1.20-r5 core, LuCI and parser modules

Package versions: `ruantiblock`, `luci-app-ruantiblock`, `ruantiblock-mod-lua` and `ruantiblock-mod-py` — `2.1.20-r5`.

### English

#### Added

- Added independent TCP and UDP selection for user lists in transparent proxy mode. TCP remains enabled by default.

### Русский

#### Добавлено

- Добавлен независимый выбор TCP и UDP для пользовательских списков в режиме прозрачного прокси. По умолчанию TCP включён.

## 2.1.20-r4 core, LuCI and parser modules

Package versions: `ruantiblock`, `luci-app-ruantiblock`, `ruantiblock-mod-lua` and `ruantiblock-mod-py` — `2.1.20-r4`.

### English

#### Fixed

- Fixed adding user lists and opening empty files in LuCI editors when RPC returns `NoDataError`.

### Русский

#### Исправлено

- Исправлено добавление пользовательских списков и открытие пустых файлов в редакторах LuCI, когда RPC возвращает `NoDataError`.

## 2.1.20-r3 core, LuCI and parser modules

Package versions: `ruantiblock`, `luci-app-ruantiblock`, `ruantiblock-mod-lua` and `ruantiblock-mod-py` — `2.1.20-r3`.

### English

#### Fixed

- Rejected invalid IPv4 addresses and CIDR prefixes in the optional Python and Lua blacklist parsers before writing nftables data.
- Refreshed VPN instance selection on each route-monitor check and started the monitor when the first VPN list is added on reload.
- Accepted a blacklist with exactly the configured minimum number of entries in the Lua parser, matching Python behavior.
- Updated IPK and APK autoinstall scripts to use the matching release archives, verify package checksums and avoid the old upstream packages.

### Русский

#### Исправлено

- Дополнительные парсеры Python и Lua теперь отбрасывают неверные IPv4-адреса и CIDR-префиксы до записи данных для nftables.
- VPN-монитор обновляет перечень списков перед каждой проверкой и запускается после `reload`, если добавлен первый VPN-список.
- Lua-парсер теперь принимает список, в котором ровно заданное минимальное число записей, как и Python-парсер.
- Установщики IPK и APK теперь берут пакеты из архивов соответствующего релиза и проверяют контрольные суммы вместо установки старых пакетов оригинального проекта.

## 2.1.19-r1 core and LuCI packages

Package versions: `ruantiblock` and `luci-app-ruantiblock` — `2.1.19-r1`.

### English

#### Fixed

- Propagated nft set and rule creation errors instead of masking them with subsequent successful commands.
- Applied the main, user-list and bypass IP sets in one nft transaction, preventing partial updates when any input file is rejected.
- Handled missing blacklist-update metadata and incomplete response entries on the LuCI statistics page.
- Kept global LuCI polling running after statistics query errors or a disabled service, with repeated error notifications suppressed until a successful response.

### Русский

#### Исправлено

- Ошибки создания nft-наборов и правил больше не скрываются за успешным результатом последующих команд.
- IP-наборы основного списка, пользовательских списков и исключений теперь обновляются одной операцией nftables, без частичного применения при ошибке в одном из файлов.
- Страница статистики LuCI корректно обрабатывает отсутствующие данные последнего обновления и неполные элементы ответа.
- Ошибки запроса статистики и выключенная служба больше не останавливают общий опрос LuCI; повторные уведомления не накапливаются до успешного ответа.

## 2.1.18-r2 core and LuCI packages

Package versions: `ruantiblock` and `luci-app-ruantiblock` — `2.1.18-r2`.

### English

#### Fixed

- Consolidated dnsmasq nftset rules for duplicate and nested domains so DNS answers populate every applicable main, user-list and bypass set.
- Rebuilt local bypass entries during service startup and restart even when the startup update is disabled.
- Preserved the previous DNS configuration and source data when preparation fails, and stopped applying incomplete updates.
- Rolled back DNS file replacements when publication fails and moved temporary files outside the active dnsmasq configuration directory.
- Removed partial network configuration after a failed startup so the next start can recover normally.
- Validated bypass IP addresses, prefixes and DNS ports before applying entries, and removed the premature clearing of bypass sets.
- Reported dnsmasq restart failures through startup and update return codes.
- Preserved the selected dnsmasq instance when the default configuration directory also exists.

### Русский

#### Исправлено

- Объединены правила dnsmasq для одинаковых и вложенных доменов, чтобы DNS-ответы добавлялись во все подходящие наборы основного списка, пользовательских списков и исключений.
- Локальные исключения теперь заново строятся при запуске и перезапуске службы, даже если обновление при старте выключено.
- При ошибке подготовки сохраняются прежние DNS-конфигурация и исходные данные, а применение неполного обновления прекращается.
- При ошибке замены DNS-файлов восстанавливается прежняя конфигурация, а временные файлы создаются вне рабочего каталога dnsmasq.
- После неудачного запуска удаляется частично созданная сетевая конфигурация, чтобы повторный запуск мог восстановить работу.
- Добавлена проверка IP-адресов, префиксов и DNS-портов исключений до применения записей и убрана преждевременная очистка наборов исключений.
- Ошибка перезапуска dnsmasq теперь отражается в результате запуска и обновления службы.
- Сохраняется выбранный экземпляр dnsmasq, даже если одновременно существует стандартный каталог конфигурации.

## 2.1.18-r1 core and LuCI packages

Package versions: `ruantiblock` and `luci-app-ruantiblock` — `2.1.18-r1`.

### English

#### Added

- Added a per-user-list device filter: domain and IP entries can now apply only to devices with the specified IPv4 addresses.
- Added device selection and an IPv4 address list to LuCI, independently of the selected VPN, Tor or transparent proxy mode.

#### Changed

- Devices outside a list's IPv4 filter continue to subsequent routing rules; an empty device list matches no devices.
- Existing user lists continue to apply to all devices unless the new filter is enabled.

### Русский

#### Добавлено

- Добавлено ограничение пользовательского списка по устройствам: домены и IP из списка могут действовать только для устройств с указанными IPv4-адресами.
- В LuCI добавлены выбор устройств и перечень IPv4-адресов независимо от выбранного режима VPN, Tor или прозрачного прокси.

#### Изменено

- Устройства, не входящие в перечень IPv4-адресов списка, обрабатываются следующими правилами маршрутизации; пустой перечень не выбирает ни одного устройства.
- Существующие пользовательские списки продолжают действовать для всех устройств, пока новый фильтр не включён.

## 2.1.17-r1 core and LuCI packages

Package versions: `ruantiblock` and `luci-app-ruantiblock` — `2.1.17-r1`.

### English

#### Fixed

- Rejected invalid IPv4 octets and CIDR prefixes in user lists, preventing malformed entries from breaking the shared nft data file.
- Normalized uppercase domain names in user lists instead of silently skipping them.
- Removed synchronous remote-list downloads from startup: cached entries are reused, and missing remote data is fetched in the background without duplicating the configured startup update.
- Preserved cached remote entries and active data after a failed safe update, while applying local-list changes during restart.
- Removed the unconditional IP-set flush before loading replacement data, preserving old IP sets when loading fails unless pre-update clearing is explicitly enabled.
- Fixed the PID recorded for delayed restart so status checks detect the running background process.
- Preserved repeated spaces and tabs when importing main and user-list UCI settings.
- Preserved argument boundaries when executing nft commands.
- Returned control to the caller after an incomplete native-blacklist download configuration, allowing normal cleanup to finish.
- Restored the hotplug default when the VPN route-check option is absent from UCI.
- Fixed the cron page after read errors, allowed a missing crontab, and blocked changes when an existing crontab could not be read.

### Русский

#### Исправлено

- Добавлена проверка октетов IPv4 и длины CIDR-префикса в пользовательских списках, чтобы неверная запись не ломала общий файл данных nft.
- Домены с заглавными буквами приводятся к нижнему регистру вместо молчаливого пропуска.
- Убрано ожидание загрузки удалённых списков при старте: используются сохранённые записи, а недостающие данные загружаются в фоне без дублирования настроенного обновления при запуске.
- Сохранены ранее загруженные удалённые записи и рабочие данные при неудачном безопасном обновлении, при этом изменения локальных списков применяются при перезапуске.
- Убрана безусловная очистка IP-наборов перед загрузкой новых данных, чтобы при ошибке сохранялись старые IP, если предварительная очистка явно не включена в настройках.
- Исправлен PID отложенного перезапуска, чтобы проверка статуса видела работающий фоновый процесс.
- Сохранены повторяющиеся пробелы и табуляция при чтении основных настроек и настроек пользовательских списков из UCI.
- Исправлена передача аргументов с пробелами в команды nft.
- Исправлён выход при неполной конфигурации загрузки основного списка, чтобы вызывающий код мог завершить очистку.
- Восстановлено значение по умолчанию в hotplug при отсутствии настройки проверки VPN-маршрутов в UCI.
- Исправлена страница cron при ошибках чтения: отсутствие файла допускается, а изменение недоступного для чтения расписания блокируется.

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
- Updated nft set loading to process each available data file independently and identify the file that failed.
- Improved VPN startup recovery by waiting for startup or update completion and recognizing logical interface names.

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
- Исправлена загрузка nft-наборов: теперь каждый доступный файл данных обрабатывается отдельно, а ошибочный файл указывается в сообщении.
- Улучшено восстановление VPN при запуске: служба ожидает завершения запуска или обновления и учитывает логические имена интерфейсов.

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
- Improved LuCI status polling by retrying aborted requests and preserving the current status when a poll fails.
- Fixed cron task detection, including correct removal of its own entries and writing an empty crontab.
- Fixed update-helper file permissions so the helpers run correctly after package installation.
- Escaped HTML output in the dnsmasq tables on the information page.
- Suppressed duplicate LuCI notifications for transient browser-aborted status requests and retried the initial status query.

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
- Улучшен опрос статуса LuCI: прерванные запросы повторяются, а текущий статус сохраняется при ошибке опроса.
- Исправлено распознавание заданий cron, включая корректное удаление собственных записей и запись пустого crontab.
- Исправлены права update-helper-файлов, чтобы они корректно запускались после установки пакета.
- Экранирован HTML-вывод таблиц dnsmasq на странице информации.
- Убраны дублирующиеся уведомления LuCI при временном прерывании запроса статуса браузером; первоначальный запрос теперь повторяется.

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
