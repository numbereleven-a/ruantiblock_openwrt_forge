#!/bin/sh
# Function-level checks with synthetic interfaces; no networking commands run.
ROOT="$1"
WORK="$2"
mkdir -p "$WORK" || exit 1
FAILED=0
check() {
    label="$1"; shift
    if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; FAILED=$((FAILED + 1)); fi
}
load_function() { eval "$(sed -n "/^${2}() {/,/^}/p" "$1")"; }
load_function "$ROOT/usr/share/ruantiblock/user_instances_common" MainInstanceNeedsVpnRouteCheck
load_function "$ROOT/usr/libexec/ruantiblock/ruab_route_check" GetVpnRouteStatus
load_function "$ROOT/usr/libexec/ruantiblock/ruab_route_check" Main
load_function "$ROOT/etc/init.d/ruantiblock" get_dnsmasq_confdir

PROXY_MODE=2 BLLIST_PRESET='' BLLIST_MODULE='' ENABLE_FPROXY=1
check full-proxy-needs-main-route MainInstanceNeedsVpnRouteCheck
ENABLE_FPROXY=0
unused_main() { ! MainInstanceNeedsVpnRouteCheck; }
check unused-main-route-not-needed unused_main

# Preserve a selected dnsmasq instance even when ubus lists another one first.
VAR_DIR="$WORK" UBUS_ATTEMPTS=1
ubus() { :; }
jsonfilter() { printf "VAR='/tmp/dnsmasq.first' '/tmp/dnsmasq.selected'\n"; }
selected=$(get_dnsmasq_confdir /tmp/dnsmasq.selected)
check dnsmasq-selected-instance-preserved test "$selected" = /tmp/dnsmasq.selected
selected=$(get_dnsmasq_confdir /tmp/dnsmasq.removed)
check dnsmasq-removed-instance-fallback test "$selected" = /tmp/dnsmasq.first

export ROUTE_LOG="$WORK/routes.log"
APP_EXEC="$WORK/reload"
printf '#!/bin/sh\nprintf "%%s\\n" "$1" >> "$ROUTE_LOG"\n' > "$APP_EXEC"
chmod +x "$APP_EXEC"
PID_FILE="$WORK/monitor.pid"
VPN_ROUTE_TABLE_ID_START=149 DEBUG=0
INSTANCES_DEF_IF_VPN=tun-default
ClearUserInstanceVars() { unset U_IF_VPN; }
IncludeUserInstanceVars() {
    U_IF_VPN="$1"
    [ "$1" != default-instance ] || U_IF_VPN=''
}
CheckIfaceStatus() { [ -n "$1" ] && [ "$1" != tun-down ]; }
VpnRouteInstanceStatus() { [ "$ROUTES_READY" = 1 ]; }
sleep() { rm -f "$PID_FILE"; }
run_monitor() {
    : > "$PID_FILE"
    : > "$ROUTE_LOG"
    Main
}
USER_INSTANCES_VPN_FNAMES='tun-down tun-ready' ROUTES_READY=0 PROXY_MODE=3
run_monitor
check ready-vpn-recovered-despite-other-vpn-down grep -q '^reload$' "$ROUTE_LOG"
USER_INSTANCES_VPN_FNAMES='tun-ready tun-down'
run_monitor
check recovery-independent-of-list-order grep -q '^reload$' "$ROUTE_LOG"
USER_INSTANCES_VPN_FNAMES='default-instance'
run_monitor
check default-vpn-interface-recovered grep -q '^reload$' "$ROUTE_LOG"
USER_INSTANCES_VPN_FNAMES='tun-down'
run_monitor
check disconnected-vpn-does-not-loop test ! -s "$ROUTE_LOG"
USER_INSTANCES_VPN_FNAMES='tun-ready' ROUTES_READY=1
run_monitor
check healthy-routes-do-not-reload test ! -s "$ROUTE_LOG"
USER_INSTANCES_VPN_FNAMES='' ROUTES_READY=0 PROXY_MODE=2 IF_VPN=tun-ready
run_monitor
check unused-main-route-does-not-loop test ! -s "$ROUTE_LOG"
ENABLE_FPROXY=1
run_monitor
check full-proxy-main-route-recovered grep -q '^reload$' "$ROUTE_LOG"
USER_INSTANCES_VPN_FNAMES='tun-down'
run_monitor
check main-recovered-despite-user-vpn-down grep -q '^reload$' "$ROUTE_LOG"
printf 'FAILED=%s\n' "$FAILED"
test "$FAILED" -eq 0
