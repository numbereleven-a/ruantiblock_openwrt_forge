#!/bin/sh
# Check release-archive selection and extraction without installing packages.
ROOT="$1"
FORMAT="$2"
ARCHIVE="$3"
WORK="$4"

case "$FORMAT" in
    ipk)
        SCRIPT="$ROOT/autoinstall/2.x/autoinstall.sh"
        SUFFIX=openwrt-23.05-24.10-ipk
        SEP=_
        TAIL=_all.ipk
        ;;
    apk)
        SCRIPT="$ROOT/autoinstall/2.x/apk/autoinstall.sh"
        SUFFIX=openwrt-25.12-apk
        SEP=-
        TAIL=.apk
        ;;
    *) exit 1 ;;
esac

VERSION=$(sed -n 's/^PKG_VERSION:=//p' "$ROOT/ruantiblock/Makefile")-r$(sed -n 's/^PKG_RELEASE:=//p' "$ROOT/ruantiblock/Makefile")
grep -q "^RUAB_VERSION=\"$VERSION\"$" "$SCRIPT" || exit 1
grep -q 'releases/download/${RUAB_VERSION}' "$SCRIPT" || exit 1

mkdir -p "$WORK" || exit 1
(
    set -eu
    RUAB_VERSION="$VERSION"
    ARCHIVE_NAME="ruantiblock-${VERSION}-${SUFFIX}.zip"
    URL_RELEASE_ARCHIVE="https://example.invalid/${ARCHIVE_NAME}"
    PKG_DIR=""
    mktemp() { command mktemp -d "$WORK/install.XXXXXX"; }
    DlFile() { cp "$ARCHIVE" "$2"; }
    InstallPackages() { echo 'Unexpected package installation' >&2; exit 1; }
    eval "$(sed -n '/^PrepareReleasePackages() {/,/^}/p' "$SCRIPT")"
    PrepareReleasePackages
    test "$(basename "$FILE_RUAB_PKG")" = "ruantiblock${SEP}${VERSION}${TAIL}"
    test "$(basename "$FILE_MOD_LUA_PKG")" = "ruantiblock-mod-lua${SEP}${VERSION}${TAIL}"
    test "$(basename "$FILE_LUCI_APP_PKG")" = "luci-app-ruantiblock${SEP}${VERSION}${TAIL}"
    test -s "$FILE_LUCI_APP_RU_PKG"
    printf 'PASS %s-autoinstall-release-archive\n' "$FORMAT"
)
