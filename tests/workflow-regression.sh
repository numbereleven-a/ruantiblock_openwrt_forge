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
check luci-displayed-version test "$(cat "$ROOT/luci-app-ruantiblock/root/usr/share/luci-app-ruantiblock/version")" = "${core_version}-r${core_release}"
check ipk-suffix-present grep -q 'archive_suffix: openwrt-23.05-24.10-ipk' "$WORKFLOW"
check apk-suffix-present grep -q 'archive_suffix: openwrt-25.12-apk' "$WORKFLOW"
check workflow-derives-version grep -q "core_version=.*PKG_VERSION" "$WORKFLOW"
check no-hardcoded-version sh -c '! grep -Eq "archive: ruantiblock-[0-9]" "$1"' sh "$WORKFLOW"
check translation-not-duplicated test ! -e "$ROOT/luci-app-ruantiblock/root/usr/lib/lua/luci/i18n/ruantiblock.ru.lmo"

ipk_name="ruantiblock-${core_version}-r${core_release}-openwrt-23.05-24.10-ipk.zip"
apk_name="ruantiblock-${core_version}-r${core_release}-openwrt-25.12-apk.zip"
check ipk-name test "$ipk_name" = 'ruantiblock-2.3.0-r1-openwrt-23.05-24.10-ipk.zip'
check apk-name test "$apk_name" = 'ruantiblock-2.3.0-r1-openwrt-25.12-apk.zip'

test_prerm_upgrade_detection() {
    prerm_tmp=$(mktemp -d) || return 1
    trap 'rm -rf "$prerm_tmp"' EXIT
    sed -n '/^define Package\/\$(PKG_NAME)\/prerm$/,/^endef$/p' "$ROOT/ruantiblock/Makefile" \
        | sed '1d;$d;s/\$\$/$/g' \
        | sed \
            -e "s|FILE_INIT_SCRIPT=\"/etc/init.d/ruantiblock\"|FILE_INIT_SCRIPT=\"$prerm_tmp/init\"|" \
            -e "s|FILE_MAIN_SCRIPT=\"/usr/bin/ruantiblock\"|FILE_MAIN_SCRIPT=\"$prerm_tmp/main\"|" \
            -e "s|STATE_FILE=\"/tmp/.ruantiblock_upgrade_state\"|STATE_FILE=\"$prerm_tmp/state\"|" \
            -e "s|CRONTAB_FILE=\"/etc/crontabs/root\"|CRONTAB_FILE=\"$prerm_tmp/crontab\"|" \
            -e "s|/tmp/dnsmasq\*\.d/|$prerm_tmp/dnsmasq.d/|g" \
            -e "s|/etc/init.d/cron restart|printf 'cron-restart\\\\n' >> \"$prerm_tmp/log\"|" \
        > "$prerm_tmp/prerm-pkg"
    mkdir -p "$prerm_tmp/dnsmasq.d"
    cat > "$prerm_tmp/init" <<EOF
#!/bin/sh
printf 'init:%s\n' "\$1" >> "$prerm_tmp/log"
[ "\$1" = "enabled" ] && exit 0
exit 0
EOF
    cat > "$prerm_tmp/main" <<EOF
#!/bin/sh
printf 'main:%s\n' "\$1" >> "$prerm_tmp/log"
exit 0
EOF
    chmod +x "$prerm_tmp/init" "$prerm_tmp/main"

    # Case 1: opkg default_prerm upgrade (PKG_UPGRADE=1, $1=script path, $2=upgrade)
    : > "$prerm_tmp/log"
    rm -f "$prerm_tmp/state"
    printf '0 4 * * * %s update\n0 5 * * * /usr/bin/other\n' "$prerm_tmp/main" > "$prerm_tmp/crontab"
    ( set -- /usr/lib/opkg/info/ruantiblock.prerm upgrade; PKG_UPGRADE=1 . "$prerm_tmp/prerm-pkg" ) || return 1
    [ "$(cat "$prerm_tmp/state" 2>/dev/null)" = "enabled" ] || return 1
    grep -q '^main:destroy$' "$prerm_tmp/log" || return 1
    ! grep -q '^init:disable$' "$prerm_tmp/log" || return 1
    grep -q "$prerm_tmp/main update" "$prerm_tmp/crontab" || return 1

    # Case 2: default_prerm positional $2=upgrade without PKG_UPGRADE
    : > "$prerm_tmp/log"
    rm -f "$prerm_tmp/state"
    ( set -- /usr/lib/opkg/info/ruantiblock.prerm upgrade; PKG_UPGRADE= . "$prerm_tmp/prerm-pkg" ) || return 1
    [ "$(cat "$prerm_tmp/state" 2>/dev/null)" = "enabled" ] || return 1
    ! grep -q '^init:disable$' "$prerm_tmp/log" || return 1
    grep -q "$prerm_tmp/main update" "$prerm_tmp/crontab" || return 1

    # Case 3: opkg default_prerm remove (uninstall branch must disable and strip ruantiblock cron only)
    : > "$prerm_tmp/log"
    rm -f "$prerm_tmp/state"
    ( set -- /usr/lib/opkg/info/ruantiblock.prerm remove; PKG_UPGRADE= . "$prerm_tmp/prerm-pkg" ) || return 1
    [ ! -e "$prerm_tmp/state" ] || return 1
    grep -q '^init:disable$' "$prerm_tmp/log" || return 1
    grep -q '^cron-restart$' "$prerm_tmp/log" || return 1
    ! grep -q "$prerm_tmp/main update" "$prerm_tmp/crontab" || return 1
    grep -q '/usr/bin/other' "$prerm_tmp/crontab" || return 1

    rm -rf "$prerm_tmp"
    trap - EXIT
    return 0
}

check prerm-upgrade-detection test_prerm_upgrade_detection

exit "$FAILED"
