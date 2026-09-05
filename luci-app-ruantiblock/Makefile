#
# (с) 2025 gSpot (https://github.com/gSpotx2f/ruantiblock_openwrt)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-ruantiblock
PKG_VERSION:=2.1.18
PKG_RELEASE:=2
PKG_MAINTAINER:=numbereleven-a <https://github.com/numbereleven-a/ruantiblock_openwrt_forge>
LUCI_TITLE:=LuCI support for ruantiblock
PKG_LICENSE:=GPL-3.0-only
LUCI_DEPENDS:=+ruantiblock +uclient-fetch +ca-bundle
LUCI_PKGARCH:=all

#include ../../luci.mk
include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
