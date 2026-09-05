#!/bin/sh
# Isolated checks for generated dnsmasq files and startup ordering.
ROOT="$1"
WORK="$2"
mkdir -p "$WORK/data" "$WORK/conf" || exit 1
FAILED=0
check() {
    label="$1"; shift
    if "$@"; then echo "PASS $label"; else echo "FAIL $label"; FAILED=$((FAILED + 1)); fi
}
load_function() { eval "$(sed -n "/^${2}() {/,/^}/p" "$1")"; }
CORE="$ROOT/usr/bin/ruantiblock"
load_function "$CORE" MergeDnsmasqNftsets
load_function "$CORE" AddBypassEntries
load_function "$CORE" Start
AWK_CMD=awk
DEBUG=0
MakeLogRecord() { :; }
DNSMASQ_DATA_FILE_BYPASS="$WORK/data/bypass.dnsmasq"
DNSMASQ_DATA_FILE_USER_INSTANCES="$WORK/data/users.dnsmasq"
DNSMASQ_DATA_FILE="$WORK/data/main.dnsmasq"
DNSMASQ_CONFIG_FILE_BYPASS="$WORK/conf/00-bypass.dnsmasq"
DNSMASQ_CONFIG_FILE_USER_INSTANCES="$WORK/conf/01-users.dnsmasq"
DNSMASQ_CONFIG_FILE="$WORK/conf/02-main.dnsmasq"
DNSMASQ_DATA_FILE_NFTSETS="$WORK/conf/03-nftsets.dnsmasq"

printf 'server=/example/192.0.2.53\nnftset=/example/4#ip#r#bd\n' > "$DNSMASQ_DATA_FILE_BYPASS"
printf 'nftset=/shared.example/4#ip#r#d.list1\nnftset=/shared.example/4#ip#r#d.list2\nnftset=/other.example/4#ip#r#d.list3\nnftset=/one.example/two.example/4#ip#r#grouped\n' > "$DNSMASQ_DATA_FILE_USER_INSTANCES"
printf 'nftset=/example/4#ip#r#d\nnftset=/shared.example/4#ip#r#d\n' > "$DNSMASQ_DATA_FILE"
MergeDnsmasqNftsets
check merge-completed test "$?" -eq 0
check source-data-preserved grep -q '^nftset=/shared.example/' "$DNSMASQ_DATA_FILE_USER_INSTANCES"
check server-setting-preserved grep -q '^server=/example/192.0.2.53$' "$DNSMASQ_CONFIG_FILE_BYPASS"
no_original_nftsets() { ! grep -h '^nftset=/' "$DNSMASQ_CONFIG_FILE_BYPASS" "$DNSMASQ_CONFIG_FILE_USER_INSTANCES" "$DNSMASQ_CONFIG_FILE" | grep -q .; }
check original-rules-removed-from-live-config no_original_nftsets
check exact-domain-consolidated test "$(grep -c '^nftset=/shared.example/' "$DNSMASQ_DATA_FILE_NFTSETS")" -eq 1
rule_has() {
    awk -F/ -v domain="$1" -v target="$2" '
        $1 == "nftset=" && $2 == domain {
            count = split($3, targets, ",");
            for(i = 1; i <= count; i++) if(targets[i] == target) found = 1;
        }
        END { exit found ? 0 : 1 }' "$DNSMASQ_DATA_FILE_NFTSETS"
}
for target in '4#ip#r#bd' '4#ip#r#d' '4#ip#r#d.list1' '4#ip#r#d.list2'; do
    check "shared-domain-target-${target##*#}" rule_has shared.example "$target"
done
check child-inherits-bypass rule_has other.example '4#ip#r#bd'
check child-inherits-main rule_has other.example '4#ip#r#d'
check child-keeps-own-target rule_has other.example '4#ip#r#d.list3'
check grouped-first-domain rule_has one.example '4#ip#r#grouped'
check grouped-second-domain rule_has two.example '4#ip#r#grouped'

before=$(sha256sum "$DNSMASQ_CONFIG_FILE_BYPASS" "$DNSMASQ_CONFIG_FILE_USER_INSTANCES" "$DNSMASQ_CONFIG_FILE" "$DNSMASQ_DATA_FILE_NFTSETS")
printf 'nftset=/broken/\n' > "$DNSMASQ_DATA_FILE_USER_INSTANCES"
MergeDnsmasqNftsets >/dev/null 2>&1
check malformed-rule-rejected test "$?" -ne 0
after=$(sha256sum "$DNSMASQ_CONFIG_FILE_BYPASS" "$DNSMASQ_CONFIG_FILE_USER_INSTANCES" "$DNSMASQ_CONFIG_FILE" "$DNSMASQ_DATA_FILE_NFTSETS")
check failed-merge-preserves-live-config test "$before" = "$after"

# Verify that a normal start rebuilds bypass data before loading nft sets.
sequence="$WORK/start-sequence"
: > "$sequence"
Init() { :; }
CheckStatus() { return 1; }
ClearStalePidFile() { :; }
MakeToken() { :; }
DropNetConfig() { :; }
SetNetConfig() { :; }
PreStartCheck() { echo prestart >> "$sequence"; }
AddBypassEntries() { echo bypass >> "$sequence"; }
AddUserEntries() { echo users >> "$sequence"; USER_ENTRIES_REMOTE_PENDING=0; }
MergeDnsmasqNftsets() { echo merge >> "$sequence"; }
UpdateBllistSets() { echo load >> "$sequence"; return 0; }
RestartDnsmasq() { echo dnsmasq >> "$sequence"; }
MakeInstancesCache() { :; }
START_PID_FILE="$WORK/start.pid"
VPN_ROUTE_CHECK=0
PROXY_MODE=2
RUAB_DEFER_REMOTE_UPDATE=0
USER_ENTRIES_REMOTE_PENDING=0
Start start >/dev/null 2>&1
check startup-completed test "$?" -eq 0
printf 'prestart\nbypass\nusers\nmerge\nload\ndnsmasq\n' > "$WORK/expected-sequence"
check bypass-built-before-load cmp "$WORK/expected-sequence" "$sequence"
check startup-pid-cleared test ! -e "$START_PID_FILE"

echo "FAILED=$FAILED"
test "$FAILED" -eq 0
