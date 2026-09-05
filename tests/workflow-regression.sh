#!/bin/sh
# Checks that release archive names follow matching package metadata.
ROOT="$1"
WORKFLOW="$ROOT/.github/workflows/build-release.yml"
FAILED=0

check() {
    label="$1"
    shift
    if "$@"; then
        echo "PASS $label"
    else
        echo "FAIL $label"
        FAILED=$((FAILED + 1))
    fi
}

read_value() {
    sed -n "s/^$2:=//p" "$1"
}

core_version=$(read_value "$ROOT/ruantiblock/Makefile" PKG_VERSION)
core_release=$(read_value "$ROOT/ruantiblock/Makefile" PKG_RELEASE)
luci_version=$(read_value "$ROOT/luci-app-ruantiblock/Makefile" PKG_VERSION)
luci_release=$(read_value "$ROOT/luci-app-ruantiblock/Makefile" PKG_RELEASE)

check core-version-present test -n "$core_version"
check core-release-present test -n "$core_release"
check package-versions-match test "$core_version" = "$luci_version"
check package-releases-match test "$core_release" = "$luci_release"
check ipk-suffix-present grep -q 'archive_suffix: openwrt-23.05-24.10-ipk' "$WORKFLOW"
check apk-suffix-present grep -q 'archive_suffix: openwrt-25.12-apk' "$WORKFLOW"
check workflow-derives-version grep -q "core_version=.*PKG_VERSION" "$WORKFLOW"
check no-hardcoded-version sh -c '! grep -Eq "archive: ruantiblock-[0-9]" "$1"' sh "$WORKFLOW"
check translation-not-duplicated test ! -e "$ROOT/luci-app-ruantiblock/root/usr/lib/lua/luci/i18n/ruantiblock.ru.lmo"

ipk_name="ruantiblock-${core_version}-r${core_release}-openwrt-23.05-24.10-ipk.zip"
apk_name="ruantiblock-${core_version}-r${core_release}-openwrt-25.12-apk.zip"
check ipk-name test "$ipk_name" = 'ruantiblock-2.1.18-r2-openwrt-23.05-24.10-ipk.zip'
check apk-name test "$apk_name" = 'ruantiblock-2.1.18-r2-openwrt-25.12-apk.zip'

exit "$FAILED"
