# Changelog / История изменений

## 2.1.15-r9 package set

Package versions:

- `ruantiblock` — `2.1.15-r2`
- `luci-app-ruantiblock` — `2.1.15-r9`
- `ruantiblock-mod-lua` — `2.1.12-r5`
- `ruantiblock-mod-py` — `2.1.12-r5`

### English

#### Added

- Added a manual check for newer releases through the public GitHub Releases API.
- Added separate core and LuCI version display in the web interface.
- Added detailed VPN routing diagnostics with the affected instance, interface, route table, and failure reason when available.
- Added configurable limits and controls for creating and removing user lists in LuCI.

#### Fixed

- Rebuilt user DNS configuration from current settings instead of stale instance data.
- Fixed cleanup of nftables state during service shutdown and restart.
- Made blacklist download failures stop the affected update cleanly without leaving partial data active.
- Handled missing crontab entries without aborting package removal or service maintenance.
- Synchronized dnsmasq with the active nftables state during service startup.

### Русский

#### Добавлено

- Добавлена ручная проверка новых релизов через публичный GitHub Releases API.
- В веб-интерфейсе добавлено раздельное отображение версий core и LuCI.
- Добавлена подробная диагностика VPN-маршрутизации с экземпляром, интерфейсом, таблицей маршрутизации и причиной ошибки, если эти данные доступны.
- В LuCI добавлены настраиваемые ограничения и управление созданием и удалением пользовательских списков.

#### Исправлено

- Пользовательская DNS-конфигурация пересобирается по текущим настройкам, а не по устаревшим данным экземпляра.
- Исправлена очистка состояния nftables при остановке и перезапуске службы.
- Ошибка загрузки чёрного списка теперь корректно прерывает его обновление без активации неполных данных.
- Обработано отсутствие записей crontab, чтобы оно не прерывало удаление пакета и обслуживание службы.
- При запуске службы состояние dnsmasq синхронизируется с активным состоянием nftables.

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
