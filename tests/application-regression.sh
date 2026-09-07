#!/bin/sh
# Regression checks for errors crossing setup and multi-file apply boundaries.
ROOT="$1"
WORK="$2"
REAL="${3:-0}"
for source in "$ROOT/usr/bin/ruantiblock" "$ROOT/usr/share/ruantiblock/nft_functions"; do
 [ -f "$source" ] || { echo "Missing source: $source" >&2; exit 2; }
done
mkdir -p "$WORK"
FAILED=0
check() { label="$1"; shift; if "$@"; then echo "PASS $label"; else echo "FAIL $label"; FAILED=$((FAILED + 1)); fi; }
load() { eval "$(sed -n "/^${1}() {/,/^}/p" "$ROOT/usr/bin/ruantiblock")"; }
MakeLogRecord() { :; }
AWK_CMD=awk

setup_failure() (
 load SetNetConfig
 NFT_CMD=true
 AddBaseNftSets() { return 1; }
 AddInstancesNftSets() { echo sets >> "$WORK/setup-later"; }
 AddNftRules() { echo rules >> "$WORK/setup-later"; }
 SetNetConfig >/dev/null 2>&1
 test "$?" != 0 && test ! -e "$WORK/setup-later"
)
check setup-stops-after-base-set-failure setup_failure

instance_failure() (
 . "$ROOT/usr/share/ruantiblock/nft_functions"
 DEBUG=0; NFT_CMD=reject_chain; NFT_TABLE='ip r'
 reject_chain() { if [ "$1 $2" = 'add chain' ]; then return 1; fi; return 0; }
 NftRouteAdd() { return 0; }
 NftInstanceAdd test 100 2 9040 149 tun0 0 1604 1604 0 0 0 '' 0 >/dev/null 2>&1
 test "$?" != 0
)
check instance-reports-chain-creation-failure instance_failure

clients_failure() (
 load MakeInstanceNftSets
 load FormatNftSetElemsList
 NFT_CMD=reject_clients; NFT_TABLE='ip r'
 reject_clients() { if [ "$1 $2" = 'add element' ] && [ "$5" = clients.test ]; then return 1; fi; return 0; }
 MakeInstanceNftSets test '' '192.0.2.1' >/dev/null 2>&1
 test "$?" != 0
)
check instance-reports-client-set-load-failure clients_failure

if [ "$REAL" = 1 ]; then
 load UpdateBllistSets
 DATA_DIR="$WORK"
 NFT_CMD=nft
 IP_DATA_FILE_BYPASS="$WORK/bypass.nft"
 IP_DATA_FILE_USER_INSTANCES="$WORK/users.nft"
 IP_DATA_FILE="$WORK/main.nft"
 nft create table ip rb_batch_review || exit 1
 trap 'nft delete table ip rb_batch_review' EXIT HUP INT TERM
 nft 'add set ip rb_batch_review bi {type ipv4_addr;}'
 nft 'add set ip rb_batch_review users {type ipv4_addr;}'
 nft 'add element ip rb_batch_review bi {192.0.2.1}'
 nft 'add element ip rb_batch_review users {192.0.2.2}'
 printf 'flush set ip rb_batch_review bi\nadd element ip rb_batch_review bi {198.51.100.1}\n' > "$IP_DATA_FILE_BYPASS"
 printf 'flush set ip rb_batch_review users\nadd element ip rb_batch_review users {300.1.1.1}\n' > "$IP_DATA_FILE_USER_INSTANCES"
 UpdateBllistSets > "$WORK/rejected.log" 2>&1
 check invalid-second-file-reported test "$?" != 0
 nft list table ip rb_batch_review > "$WORK/after-reject"
 check invalid-second-file-preserves-first-set grep -q 192.0.2.1 "$WORK/after-reject"
 check invalid-second-file-preserves-second-set grep -q 192.0.2.2 "$WORK/after-reject"
 printf 'flush set ip rb_batch_review users\nadd element ip rb_batch_review users {198.51.100.2}' > "$IP_DATA_FILE_USER_INSTANCES"
 printf 'add element ip rb_batch_review bi {198.51.100.3}\n' > "$IP_DATA_FILE"
 UpdateBllistSets > "$WORK/accepted.log" 2>&1
 check valid-generation-applied test "$?" = 0
 nft list table ip rb_batch_review > "$WORK/after-apply"
 check valid-generation-first-set grep -q 198.51.100.1 "$WORK/after-apply"
 check valid-generation-second-set grep -q 198.51.100.2 "$WORK/after-apply"
 check input-without-final-newline-loaded grep -q 198.51.100.3 "$WORK/after-apply"
fi
echo "FAILED=$FAILED"
test "$FAILED" = 0
