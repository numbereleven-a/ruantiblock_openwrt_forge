#!/bin/sh
# Fault injection uses real function bodies and isolated files only.
ROOT="$1"
WORK="$2"
mkdir -p "$WORK/data" "$WORK/conf"
FAILED=0
check() { label="$1"; shift; if "$@"; then echo "PASS $label"; else echo "FAIL $label"; FAILED=$((FAILED + 1)); fi; }
load() { eval "$(sed -n "/^${1}() {/,/^}/p" "$ROOT/usr/bin/ruantiblock")"; }
for fn in MergeDnsmasqNftsets ClearDataFiles Start Update AddBypassEntries GetBlacklistFiles PrepareBlacklistFiles; do load "$fn"; done
MakeLogRecord() { :; }; MakeToken() { :; }; PidFileActive() { return 1; }
ClearStalePidFile() { :; }; ToggleUPIDFile() { :; }; FlushInstancesNftSets() { :; }
AWK_CMD=awk
export DATA_DIR="$WORK/data" DNSMASQ_CONFDIR="$WORK/conf"
export DNSMASQ_DATA_FILE="$DATA_DIR/main" DNSMASQ_DATA_FILE_BYPASS="$DATA_DIR/bypass" DNSMASQ_DATA_FILE_USER_INSTANCES="$DATA_DIR/users"
export DNSMASQ_CONFIG_FILE="$DNSMASQ_CONFDIR/main" DNSMASQ_CONFIG_FILE_BYPASS="$DNSMASQ_CONFDIR/bypass" DNSMASQ_CONFIG_FILE_USER_INSTANCES="$DNSMASQ_CONFDIR/users" DNSMASQ_DATA_FILE_NFTSETS="$DNSMASQ_CONFDIR/merged"
export IP_DATA_FILE="$DATA_DIR/main.ip" IP_DATA_FILE_BYPASS="$DATA_DIR/bypass.ip" IP_DATA_FILE_USER_INSTANCES="$DATA_DIR/users.ip" USER_ENTRIES_STATUS_FILE="$DATA_DIR/status" UPDATE_STATUS_FILE="$DATA_DIR/main.status"
: > "$DNSMASQ_DATA_FILE"
: > "$DNSMASQ_DATA_FILE_BYPASS"
: > "$DNSMASQ_DATA_FILE_USER_INSTANCES"
preserve_preparation() (
 printf 'server=/old.example/192.0.2.53\n' > "$DNSMASQ_CONFIG_FILE_USER_INSTANCES"
 printf 'old raw\n' > "$DNSMASQ_DATA_FILE_USER_INSTANCES"
 PreStartCheck() { :; }; AddBypassEntries() { return 0; }
 GetMainInstanceEntries() { printf 'nftset=/broken/\n' > "$DNSMASQ_DATA_FILE"; return 0; }
 AddUserEntries() { ClearDataFiles user_instances; printf 'new raw\n' > "$DNSMASQ_DATA_FILE_USER_INSTANCES"; }
 GetBlacklistFiles >/dev/null 2>&1; rc=$?
 test "$rc" = 4 && grep -q old.example "$DNSMASQ_CONFIG_FILE_USER_INSTANCES" && grep -q 'old raw' "$DNSMASQ_DATA_FILE_USER_INSTANCES"
)
check failed-preparation-preserves-live-and-source preserve_preparation
update_failure() (
 GetBlacklistFiles() { return "$prepare_rc"; }
 UpdateBllistSets() { echo load >> "$WORK/actions"; }
 RestartDnsmasq() { echo restart >> "$WORK/actions"; return "$dns_rc"; }
 : > "$WORK/actions"
 prepare_rc=4; dns_rc=0
 Update update >/dev/null 2>&1; rc=$?
 test "$rc" = 4 && test ! -s "$WORK/actions" || exit 1
 prepare_rc=1
 Update update >/dev/null 2>&1
 grep -q load "$WORK/actions" || exit 1
 prepare_rc=0; dns_rc=1
 Update update >/dev/null 2>&1; test "$?" != 0
)
check fatal-preparation-stops-apply-and-dns-error-propagates update_failure
start_failure() (
 Init() { :; }; CheckStatus() { test "$active" = 1; }
 DropNetConfig() { active=0; }; SetNetConfig() { active=1; }
 PreStartCheck() { :; }; AddBypassEntries() { return 0; }; AddUserEntries() { return 0; }
 MergeDnsmasqNftsets() { return "$merge_rc"; }
 UpdateBllistSets() { return 0; }; RestartDnsmasq() { return "$dns_rc"; }; MakeInstancesCache() { :; }
 active=0; merge_rc=1; dns_rc=0; START_PID_FILE="$WORK/start.pid"
 Start start >/dev/null 2>&1; rc=$?
 test "$rc" != 0 && test "$active" = 0 && test ! -e "$START_PID_FILE" || exit 1
 merge_rc=0
 Start start >/dev/null 2>&1; test "$?" = 0 && test "$active" = 1 || exit 1
 active=0; dns_rc=1
 Start start >/dev/null 2>&1; test "$?" != 0 && test "$active" = 0
)
check failed-start-rolls-back-and-retry-succeeds start_failure
bypass_failure() (
 export NFT_TABLE='ip rb_review' NFT_TABLE_DNSMASQ='4#ip#rb_review' NFTSET_BYPASS_IP=bi NFTSET_BYPASS_FQDN=bd
 export NFTSET_BYPASS_IP_STRING='set bi {type ipv4_addr;flags interval;'
 export BYPASS_ENTRIES_FILE="$DATA_DIR/entries" BYPASS_MODE=1
 NFTSET_CLEAR_SETS=0; ENABLE_TMP_DOWNLOADS=1
 FlushNftSets() { echo flushed > "$WORK/flush"; }
 for entry in '300.1.1.1' '192.0.2.1/99' 'test.example 192.0.2.53#99999'; do
   printf '%s\n' "$entry" > "$BYPASS_ENTRIES_FILE"
   AddBypassEntries; rc=$?
   test "$rc" != 0 && test ! -e "$WORK/flush" || exit 1
 done
 printf '192.0.2.1/24\ntest.example 192.0.2.53#65535\n' > "$BYPASS_ENTRIES_FILE"
 AddBypassEntries && grep -q '192.0.2.1/24' "$IP_DATA_FILE_BYPASS"
)
check invalid-bypass-rejected-before-flush bypass_failure
publish_failure() (
 : > "$DNSMASQ_DATA_FILE"
 printf 'server=/new.example/192.0.2.54\n' > "$DNSMASQ_DATA_FILE_BYPASS"
 printf 'server=/old.example/192.0.2.53\n' > "$DNSMASQ_CONFIG_FILE_BYPASS"
 mv() { if [ "$3" = "$DNSMASQ_CONFIG_FILE_USER_INSTANCES" ]; then return 1; fi; command mv "$@"; }
 MergeDnsmasqNftsets >/dev/null 2>&1; rc=$?
 test "$rc" != 0 && grep -q old.example "$DNSMASQ_CONFIG_FILE_BYPASS"
)
check failed-publication-restores-generation publish_failure
selection() (
 eval "$(sed -n '/^get_dnsmasq_confdir() {/,/^}/p' "$ROOT/etc/init.d/ruantiblock")"
 VAR_DIR="$WORK/var"; UBUS_ATTEMPTS=1; mkdir -p "$VAR_DIR/dnsmasq.d"
 ubus() { printf '{}'; }; jsonfilter() { printf '/tmp/dnsmasq.selected\n'; }
 test "$(get_dnsmasq_confdir /tmp/dnsmasq.selected)" = /tmp/dnsmasq.selected
)
check selected-dnsmasq-wins-over-generic-directory selection
echo "FAILED=$FAILED"
test "$FAILED" = 0
