# Ruantiblock

[English](#english) | [Русский](README.ru.md)

## English

Selective routing for bypassing network restrictions on OpenWrt.

### Differences in this fork

This [fork](https://github.com/numbereleven-a/ruantiblock_openwrt_forge) is based on the [original gSpotx2f project](https://github.com/gSpotx2f/ruantiblock_openwrt) and remains compatible with its configuration.

This fork adds and improves:

* LuCI controls for configuring the user-list limit and adding or removing user lists.

* VPN routing diagnostics showing the affected VPN instance, interface, route table, and failure reason when available.

* Separate core and LuCI version display together with a manual check against the public GitHub Releases API. No token, automatic download, or automatic installation is used.

* Core handling for stale instance data, user DNS configuration rebuilding, nftables cleanup, failed blacklist downloads, missing crontab entries, and dnsmasq synchronization during startup.

The routing model remains compatible with the original project and uses standard OpenWrt services and utilities, including nftables and dnsmasq.

The package supports L3 VPNs with interface-based routing (OpenVPN, WireGuard, PPTP, sing-box in TUN mode, and others), transparent proxies with port redirection (sing-box in TProxy mode, Xray, V2Ray, Shadowsocks-libev, Redsocks, and others), and Tor. Traffic can be routed by domain names and IP addresses, with multiple VPN or proxy connections and list priorities.

### Downloads and installation

Choose the package format supported by the target OpenWrt release from the [latest release](https://github.com/numbereleven-a/ruantiblock_openwrt_forge/releases/latest):

* OpenWrt 23.05–24.10 — IPK packages for installation with `opkg`.

* OpenWrt 25.12 and newer — APK packages for installation with `apk`.

Required packages:

* `ruantiblock` — core package.

* `luci-app-ruantiblock` — LuCI web interface.

Optional packages:

* `ruantiblock-mod-lua` — Lua list-processing module.

* `ruantiblock-mod-py` — Python list-processing module.

Prepare the required OpenWrt dependencies as described in the [original project Wiki](https://github.com/gSpotx2f/ruantiblock_openwrt/wiki), copy the matching packages to the router, and install the required pair.

Each release archive includes `SHA256SUMS` for package verification. Installation and upgrade commands are included in the release description.
