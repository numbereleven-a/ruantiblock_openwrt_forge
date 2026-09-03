#!/bin/sh
# Isolated regression checks. No production configuration is sourced.
ROOT="$1"
WORK="$2"
USE_NFT="${3:-0}"
CORE="${ROOT}/usr/bin/ruantiblock"
PARSER="${ROOT}/usr/libexec/ruantiblock/ruab_parser_user_entries"
NFT_FUNCTIONS="${ROOT}/usr/share/ruantiblock/nft_functions"
mkdir -p "$WORK/data" "$WORK/dns" "$WORK/lists" "$WORK/bin" || exit 1
FAILED=0
check() {
    label="$1"; shift
    if "$@"; then printf 'PASS %s\n' "$label"; else printf 'FAIL %s\n' "$label"; FAILED=$((FAILED + 1)); fi
}
load_function() { eval "$(sed -n "/^${2}() {/,/^}/p" "$1")"; }
for name in AddUserEntries ClearDataFiles DownloadNativeBlacklist PidFileActive Update UpdateBllistSets Start; do
    load_function "$CORE" "$name"
done
load_function "$NFT_FUNCTIONS" NftCmdWrapper
export NAME=review-fixture DEBUG=0 DATA_DIR="$WORK/data" DNSMASQ_CONFDIR="$WORK/dns"
export AWK_CMD=awk WGET_CMD="$WORK/bin/fetch" WGET_PARAMS='' LOGGER_CMD=true LOGGER_PARAMS=''
export ENABLE_LOGGING=0 ENABLE_TMP_DOWNLOADS=1
export USER_ENTRIES_REMOTE_DOWNLOAD_TIMEOUT=0 USER_ENTRIES_REMOTE_DOWNLOAD_ATTEMPTS=3
export NFT_TABLE='inet rb_review_217' NFT_TABLE_DNSMASQ='4#inet#rb_review_217'
export USER_LISTS_DIR="$WORK/lists" USER_ENTRIES_PARSER="$PARSER"
export IP_DATA_FILE_USER_INSTANCES="$DATA_DIR/user.ip" IP_DATA_FILE_USER_INSTANCES_TMP="$DATA_DIR/user.ip.tmp"
export DNSMASQ_DATA_FILE_USER_INSTANCES="$DNSMASQ_CONFDIR/user.dns" DNSMASQ_DATA_FILE_USER_INSTANCES_TMP="$DNSMASQ_CONFDIR/user.dns.tmp"
export USER_ENTRIES_STATUS_FILE="$DATA_DIR/status" USER_ENTRIES_STATUS_FILE_TMP="$DATA_DIR/status.tmp"
export NFTSET_CIDR_PATTERN='set %s { type ipv4_addr; flags interval;' NFTSET_IP_PATTERN='set %s { type ipv4_addr;'
export NFTSET_CIDR=cidr NFTSET_IP=ip NFTSET_DNSMASQ=dns
export USER_INSTANCES_ALL_FNAMES='list1 list2' CALL_LOG="$WORK/fetch.log"
TEST_URL='https://example.invalid/list'
MakeLogRecord() { :; }
ClearUserInstanceVars() { :; }
FlushNftSets() { :; }
UpdateBllistProxySet() { printf 'proxy lookup\n' >> "$CALL_LOG"; }
IncludeUserInstanceVars() {
    U_NAME="$1"; U_PROXY_MODE=2; U_ENTRIES_DNS=''; U_ENABLE_ENTRIES_REMOTE_PROXY=1
    U_ENTRIES_REMOTE=''
    [ "$1" = list1 ] && U_ENTRIES_REMOTE="$TEST_URL"
    return 0
}
printf '#!/bin/sh\nprintf "fetch\\n" >> "$CALL_LOG"\nprintf "203.0.113.7\\nREMOTE.EXAMPLE\\n"\n' > "$WGET_CMD"
chmod +x "$WGET_CMD"
printf '198.51.100.1\n300.1.1.1\n198.51.100.0/99\nLOCAL.EXAMPLE\n' > "$WORK/lists/list1"
printf '192.0.2.7\n' > "$WORK/lists/list2"
AddUserEntries > "$WORK/parser.log" 2>&1
check parser-completed test "$?" -eq 0
check invalid-ip-rejected sh -c '! grep -q 300.1.1.1 "$1"' sh "$IP_DATA_FILE_USER_INSTANCES"
check invalid-prefix-rejected sh -c '! grep -q /99 "$1"' sh "$IP_DATA_FILE_USER_INSTANCES"
check uppercase-domain-normalized grep -q 'local.example' "$DNSMASQ_DATA_FILE_USER_INSTANCES"
check remote-cache-written test -s "$DATA_DIR/user_remote/list1"
cp "$IP_DATA_FILE_USER_INSTANCES" "$WORK/first-data.nft"
old_cache=$(sha256sum "$DATA_DIR/user_remote/list1" 2>/dev/null)
old_data=$(sha256sum "$IP_DATA_FILE_USER_INSTANCES")
printf '#!/bin/sh\nexit 1\n' > "$WGET_CMD"
AddUserEntries > "$WORK/failed-remote.log" 2>&1
check failed-download-reported test "$?" -ne 0
check failed-download-cache-preserved test "$(sha256sum "$DATA_DIR/user_remote/list1" 2>/dev/null)" = "$old_cache"
check failed-download-data-preserved test "$(sha256sum "$IP_DATA_FILE_USER_INSTANCES")" = "$old_data"
printf '198.51.100.2\nLOCAL.EXAMPLE\n' > "$WORK/lists/list1"
: > "$CALL_LOG"
AddUserEntries cached > "$WORK/cached.log" 2>&1
check cached-start-no-network test ! -s "$CALL_LOG"
check cached-remote-ip-preserved grep -q '203.0.113.7' "$IP_DATA_FILE_USER_INSTANCES"
check cached-remote-domain-preserved grep -q 'remote.example' "$DNSMASQ_DATA_FILE_USER_INSTANCES"
check local-changes-applied grep -q '198.51.100.2' "$IP_DATA_FILE_USER_INSTANCES"
check stale-local-ip-removed sh -c '! grep -q 198.51.100.1 "$1"' sh "$IP_DATA_FILE_USER_INSTANCES"
TEST_URL='https://example.invalid/changed'
: > "$CALL_LOG"
AddUserEntries cached > "$WORK/changed.log" 2>&1
check changed-source-no-network test ! -s "$CALL_LOG"
check changed-source-scheduled test "$USER_ENTRIES_REMOTE_PENDING" = 1
check changed-source-old-cache-not-used sh -c '! grep -q 203.0.113.7 "$1"' sh "$IP_DATA_FILE_USER_INSTANCES"

( Init() { :; }; CheckStatus() { return 1; }; ClearStalePidFile() { :; }
  DropNetConfig() { :; }; SetNetConfig() { :; }; PreStartCheck() { :; }
  MakeToken() { :; }; MakeInstancesCache() { :; }; RestartDnsmasq() { :; }
  UpdateBllistSets() { return 0; }
  export BG_LOG="$WORK/background.log"
  APP_EXEC="$WORK/bin/background"
  printf '#!/bin/sh\nprintf "%%s\\n" "$1" >> "$BG_LOG"\n' > "$APP_EXEC"
  chmod +x "$APP_EXEC"
  START_PID_FILE="$WORK/start.pid"; VPN_ROUTE_CHECK=0; PROXY_MODE=2
  RUAB_DEFER_REMOTE_UPDATE=0
  : > "$CALL_LOG"
  Start start > "$WORK/start.log" 2>&1
)
sleep 1
check actual-start-no-network test ! -s "$CALL_LOG"
check actual-start-background-refresh grep -q '^update$' "$WORK/background.log"
check actual-start-pid-cleared test ! -e "$WORK/start.pid"

capture() { [ "$#" -eq 1 ] && [ "$1" = 'two words' ]; }
check nft-wrapper-argument-boundaries NftCmdWrapper capture 'two words'
NftCmdWrapper false
check nft-wrapper-failure-status test "$?" -eq 1

( DownloadNativeBlacklist >/dev/null 2>&1; printf 'cleanup\n' > "$WORK/native-cleanup" )
check native-error-returned-to-caller test -s "$WORK/native-cleanup"

printf '#!/bin/sh\nif [ "$1" = show ]; then\nprintf "review-fixture.config.allowed_hosts_list=\047alpha  beta\\tgamma\047\\nreview-fixture.list1.u_entries_remote=\047alpha  beta\\tgamma\047\\n"\nelse\nexit 1\nfi\n' > "$WORK/bin/uci"
chmod +x "$WORK/bin/uci"
OLD_PATH="$PATH"
PATH="$WORK/bin:$PATH"
eval "$(sed '/^\. \/lib\/functions\/network.sh/,$d' "${ROOT}/usr/share/ruantiblock/config_script")"
expected=$(printf 'alpha  beta\tgamma')
check config-whitespace-preserved test "$ALLOWED_HOSTS_LIST" = "$expected"
. "${ROOT}/usr/share/ruantiblock/config_script_user_instances"
IncludeUserInstanceVars list1
check user-config-whitespace-preserved test "$U_ENTRIES_REMOTE" = "$expected"
unset VPN_ROUTE_CHECK
( eval "$(sed -n '/^    VPN_ROUTE_CHECK=/,/^    PROXY_MODE=/{ /^    PROXY_MODE=/!p; }' "${ROOT}/etc/hotplug.d/iface/40-ruantiblock")"; printf reached > "$WORK/hotplug-reached" )
check hotplug-missing-option-default test -s "$WORK/hotplug-reached"
PATH="$OLD_PATH"

# Exercise the real delayed dispatch with harmless Start/Stop replacements.
DELAY_HELPER="$WORK/delayed"
test_shell=$(command -v bash || command -v sh)
printf '#!%s\n' "$test_shell" > "$DELAY_HELPER"
printf 'APP_EXEC="$0"\nSTART_PID_FILE="$0.pid"\nInit() { :; }\nStop() { :; }\nStart() { touch "$0.done"; }\nStatusOutput() { :; }\ncase "$1" in\n' >> "$DELAY_HELPER"
sed -n '/^    restart|delayed-restart)/,/^    reload)/{ /^    reload)/!p; }' "$CORE" >> "$DELAY_HELPER"
printf 'esac\n' >> "$DELAY_HELPER"
chmod +x "$DELAY_HELPER"
"$DELAY_HELPER" delayed-restart 2
sleep 1
check delayed-restart-live-pid PidFileActive "$DELAY_HELPER.pid"
sleep 2
check delayed-restart-completed test -e "$DELAY_HELPER.done"

# Failed data application must not pre-flush IP sets in the safe/default mode.
( MakeToken() { :; }; PidFileActive() { return 1; }; ClearStalePidFile() { :; }
  ToggleUPIDFile() { :; }; RestartDnsmasq() { :; }
  GetBlacklistFiles() { :; }; UpdateBllistSets() { return 1; }
  FlushInstancesNftSets() { printf '%s\n' "$1" >> "$WORK/flush.log"; }
  NFTSET_CLEAR_SETS=0; Update update >/dev/null 2>&1
)
check failed-load-no-preflush test ! -s "$WORK/flush.log"

if [ "$USE_NFT" = 1 ]; then
    if nft list table inet rb_review_217 >/dev/null 2>&1; then
        printf 'FAIL test-table-already-exists\n'; exit 1
    fi
    nft add table inet rb_review_217 || exit 1
    trap 'nft delete table inet rb_review_217 >/dev/null 2>&1' EXIT
    nft 'add set inet rb_review_217 ip.list1 { type ipv4_addr; }'
    nft 'add set inet rb_review_217 cidr.list1 { type ipv4_addr; flags interval; }'
    nft 'add set inet rb_review_217 ip.list2 { type ipv4_addr; }'
    nft 'add set inet rb_review_217 cidr.list2 { type ipv4_addr; flags interval; }'
    check actual-nft-malformed-input-filtered nft -f "$WORK/first-data.nft"
    check actual-nft-load nft -f "$IP_DATA_FILE_USER_INSTANCES"
    nft list set inet rb_review_217 ip.list1 > "$WORK/nft-list1"
    nft list set inet rb_review_217 ip.list2 > "$WORK/nft-list2"
    check actual-nft-list1-populated grep -q '198.51.100.2' "$WORK/nft-list1"
    check actual-nft-list2-populated grep -q '192.0.2.7' "$WORK/nft-list2"
    nft flush set inet rb_review_217 ip.list1
    nft 'add element inet rb_review_217 ip.list1 { 198.51.100.2 }'
    printf 'flush set inet rb_review_217 ip.list1\nadd element inet rb_review_217 ip.list1 { 300.1.1.1 }\n' > "$WORK/bad.nft"
    nft -f "$WORK/bad.nft" > "$WORK/nft-rejection" 2>&1
    check actual-nft-invalid-file-rejected test "$?" -ne 0
    nft list set inet rb_review_217 ip.list1 > "$WORK/nft-after-failure"
    check actual-nft-transaction-preserved-old-ip grep -q '198.51.100.2' "$WORK/nft-after-failure"
    ( MakeToken() { :; }; PidFileActive() { return 1; }; ClearStalePidFile() { :; }
      ToggleUPIDFile() { :; }; RestartDnsmasq() { :; }; GetBlacklistFiles() { :; }
      load_function "$CORE" FlushInstancesNftSets
      load_function "$CORE" FlushNftSets
      NFT_CMD=nft; NFTSET_CLEAR_SETS=0; USER_INSTANCES_ALL='list1 list2'
      IP_DATA_FILE_USER_INSTANCES="$WORK/bad.nft"
      IP_DATA_FILE_BYPASS="$WORK/absent-bypass"; IP_DATA_FILE="$WORK/absent-main"
      Update update > "$WORK/real-update-failure.log" 2>&1
    )
    check actual-update-failure-returned test "$?" -ne 0
    nft list set inet rb_review_217 ip.list1 > "$WORK/nft-after-update"
    check actual-update-preserved-old-ip grep -q '198.51.100.2' "$WORK/nft-after-update"
fi
printf 'FAILED=%s\n' "$FAILED"
test "$FAILED" -eq 0
