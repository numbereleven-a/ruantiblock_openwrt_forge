## Ruantiblock

[English](#english) | [Русский](#русский)

## English

Selective routing for bypassing network restrictions on OpenWrt.

### Differences in this fork

This [fork](https://github.com/numbereleven-a/ruantiblock_openwrt_forge) is based on the [original gSpotx2f project](https://github.com/gSpotx2f/ruantiblock_openwrt) and remains compatible with its configuration.

Version `2.1.12-r5` corrects dnsmasq and nftables synchronization during Ruantiblock startup. After the nft sets are applied, dnsmasq is restarted from the main `Start()` procedure. This prevents domain routing from active user lists from being lost after a disabled list is edited or saved.

The default number of user lists has been increased from 5 to 10. In LuCI, **Settings → User entries** now has a configurable list limit (from 1 to 50) and an **Add user list** button which automatically creates the first available `listN` section within that limit. Existing lists can also be removed from the same table. On upgrade, the old default limit of 5 is migrated to 10, while other valid custom limits are preserved.

* Uses standard OpenWrt services and utilities, including nftables and dnsmasq.

* Supports L3 VPNs with interface-based routing (OpenVPN, WireGuard, PPTP, sing-box in TUN mode, and others), transparent proxies with port redirection (sing-box in TProxy mode, Xray, V2Ray, Shadowsocks-libev, Redsocks, and others), and Tor.

* Routes traffic based on domain names and IP addresses.

* Supports custom lists, multiple VPN or proxy connections, and list priorities.

* Integrates with the OpenWrt web interface.

### Installation

Each release provides two architecture-independent archives:

* OpenWrt 23.05–24.10 — IPK packages for installation with `opkg`.

* OpenWrt 25.12 and newer — APK packages for installation with `apk`.

Required packages:

* `ruantiblock` — core package.

* `luci-app-ruantiblock` — LuCI web interface.

Optional packages:

* `luci-i18n-ruantiblock-ru` — Russian translation for LuCI.

* `ruantiblock-mod-lua` — Lua list-processing module.

* `ruantiblock-mod-py` — Python list-processing module.

Installation and upgrade commands are included in each release description. Detailed configuration documentation is available in the [original project Wiki](https://github.com/gSpotx2f/ruantiblock_openwrt/wiki).

## Русский

Выборочная маршрутизация для обхода блокировок в OpenWrt.

### Отличия этого форка

Этот [форк](https://github.com/numbereleven-a/ruantiblock_openwrt_forge) основан на [оригинальном проекте gSpotx2f](https://github.com/gSpotx2f/ruantiblock_openwrt) и сохраняет совместимость с его конфигурацией.

В версии `2.1.12-r5` исправлена синхронизация dnsmasq и nftables при запуске Ruantiblock. После применения nft-наборов dnsmasq перезапускается внутри основной процедуры `Start()`. Это предотвращает потерю маршрутизации доменов из активных пользовательских списков после изменения или сохранения выключенного списка.

Количество пользовательских списков по умолчанию увеличено с 5 до 10. В LuCI на странице **Настройки → Записи пользователя** появились настраиваемый лимит списков (от 1 до 50) и кнопка **Добавить пользовательский список**: она автоматически создаёт первую свободную секцию `listN` в пределах выбранного лимита. Существующие списки можно удалить в той же таблице. При обновлении прежнее значение по умолчанию 5 заменяется на 10, а другие корректные пользовательские значения сохраняются.

* Решение построено на стандартных системных службах и утилитах OpenWrt (nftables, dnsmasq).

* Поддерживаются L3 VPN с маршрутизацией на сетевой интерфейс (OpenVPN, WireGuard, PPTP, sing-box в режиме TUN и пр.), прозрачные прокси с перенаправлением на порт (sing-box в режиме TProxy, Xray, V2Ray, Shadowsocks-libev, Redsocks и пр.), Tor.

* Перенаправление трафика на основе доменов и IP-адресов.

* Гибкие настройки для пользовательских списков, использование нескольких VPN/прокси для разных списков с приоритетами.

* Интеграция с веб-интерфейсом OpenWrt.

### Установка

Для каждой версии в разделе Releases публикуются два универсальных архива:

* OpenWrt 23.05–24.10 — пакеты IPK для установки через `opkg`.

* OpenWrt 25.12 и новее — пакеты APK для установки через `apk`.

Обязательный комплект:

* `ruantiblock` — основной пакет.

* `luci-app-ruantiblock` — веб-интерфейс LuCI.

Дополнительные пакеты:

* `luci-i18n-ruantiblock-ru` — русская локализация LuCI.

* `ruantiblock-mod-lua` — модуль обработки списков на Lua.

* `ruantiblock-mod-py` — модуль обработки списков на Python.

Команды установки и обновления приводятся в описании каждого релиза. Подробная документация по настройке Ruantiblock доступна в [Wiki оригинального проекта](https://github.com/gSpotx2f/ruantiblock_openwrt/wiki).
