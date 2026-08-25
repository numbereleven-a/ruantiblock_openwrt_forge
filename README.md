# Ruantiblock

[English](#english) | [Русский](README.ru.md)

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

### Downloads and installation

Choose one architecture-independent archive from the latest release:

* `ruantiblock-2.1.12-r5-openwrt-23.05-24.10-ipk.zip` — OpenWrt 23.05–24.10 (`opkg`).

* `ruantiblock-2.1.12-r5-openwrt-25.12-apk.zip` — OpenWrt 25.12 and newer (`apk`).

Prepare the required OpenWrt dependencies as described in the [original project Wiki](https://github.com/gSpotx2f/ruantiblock_openwrt/wiki), extract the matching archive, copy the packages to the router, and install the required pair.

OpenWrt 23.05–24.10:

```sh
opkg update
opkg install ./ruantiblock_2.1.12-r5_all.ipk ./luci-app-ruantiblock_2.1.12-r5_all.ipk
```

OpenWrt 25.12 and newer:

```sh
apk update
apk add --allow-untrusted ./ruantiblock-2.1.12-r5.apk ./luci-app-ruantiblock-2.1.12-r5.apk
```

Optional packages in each archive:

* `luci-i18n-ruantiblock-ru` — Russian LuCI translation.

* `ruantiblock-mod-lua` — Lua list-processing module.

* `ruantiblock-mod-py` — Python list-processing module.

Each ZIP includes `SHA256SUMS` for its package files.
