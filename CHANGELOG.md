# Changelog / История изменений

## 2.1.12-r5

### English

#### Added

- Increased the default number of user lists from 5 to 10. On upgrade, the old default of 5 is migrated to 10 while other valid custom limits are preserved.
- Added a configurable user-list limit from 1 to 50 to **Settings → User entries**.
- Added an **Add user list** button which automatically creates the first available `listN` section within the selected limit.
- Added removal controls for user lists in the same LuCI table.
- Added the installed Ruantiblock version to the Service page heading.

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
- В заголовок страницы «Сервис» добавлена версия установленного Ruantiblock.

#### Исправлено

- Восстановлена маршрутизация доменов из активных VPN-списков после изменения или сохранения выключенного пользовательского списка.
- Перезапуск dnsmasq перенесён в процедуру `Start()` и выполняется сразу после применения nft-наборов.
- Удалён условный перезапуск dnsmasq из init-скрипта, который больше не требуется.

Исправление связано с [issue #176](https://github.com/gSpotx2f/ruantiblock_openwrt/issues/176) и релевантной частью [PR #158](https://github.com/gSpotx2f/ruantiblock_openwrt/pull/158).
