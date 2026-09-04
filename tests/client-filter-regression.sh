#!/bin/sh
# Synthetic rule-generation checks; optional isolated nft table with no hooks.
ROOT="$1"
WORK="$2"
REAL="${3:-0}"
mkdir -p "$WORK" || exit 1
FAILED=0
check() {
    label="$1"; shift
    if "$@"; then echo "PASS $label"; else echo "FAIL $label"; FAILED=$((FAILED + 1)); fi
}
load_function() { eval "$(sed -n "/^${2}() {/,/^}/p" "$1")"; }
CORE="$ROOT/usr/bin/ruantiblock"
load_function "$CORE" MakeInstanceNftSets
load_function "$CORE" FormatNftSetElemsList
load_function "$CORE" DeleteInstancesNftSets
load_function "$CORE" FlushInstancesNftSets
load_function "$CORE" FlushNftSets
load_function "$ROOT/usr/share/ruantiblock/user_instances_common" ClearUserInstanceVars
DEBUG=0
AWK_CMD=awk
NFT_TABLE='ip rb_clients_test'
NFTSET_CIDR=c NFTSET_IP=i NFTSET_DNSMASQ=d NFTSET_ONION=o
NFTSET_FPROXY=fproxy NFTSET_BLLIST_PROXY=bproxy
NFTSET_CIDR_TYPE=ipv4_addr NFTSET_IP_TYPE=ipv4_addr NFTSET_DNSMASQ_TYPE=ipv4_addr
NFTSET_FPROXY_TYPE=ipv4_addr NFTSET_BLLIST_PROXY_TYPE=ipv4_addr
NFTSET_MAXELEM_CIDR=100 NFTSET_MAXELEM_IP=100 NFTSET_MAXELEM_DNSMASQ=100
NFTSET_POLICY_CIDR=performance NFTSET_POLICY_IP=performance NFTSET_POLICY_DNSMASQ=performance
NFTSET_DNSMASQ_TIMEOUT=60s NFTSET_DNSMASQ_TIMEOUT_UPDATE=0
. "$ROOT/usr/share/ruantiblock/nft_functions"
NftRouteAdd() { :; }
MakeLogRecord() { :; }
record() { printf '%s\n' "$*" >> "$WORK/commands"; }
NFT_CMD=record
: > "$WORK/commands"
MakeInstanceNftSets test '' '192.0.2.1 192.0.2.2'
check source-set-created grep -q 'add set ip rb_clients_test clients.test' "$WORK/commands"
check multiple-clients-loaded grep -q 'clients.test { 192.0.2.1,192.0.2.2 }' "$WORK/commands"
: > "$WORK/commands"
NftInstanceAdd test 0 3 9040 0 lo 1 1604 1604 1 1 1 '' 1
check restricted-dns-rule grep -q 'blacklist ip saddr @clients.test ip daddr @d.test' "$WORK/commands"
check restricted-cidr-rule grep -q 'blacklist ip saddr @clients.test ip daddr @c.test' "$WORK/commands"
check restricted-ip-rule grep -q 'blacklist ip saddr @clients.test ip daddr @i.test' "$WORK/commands"
check restricted-full-proxy grep -q 'fproxy_chain ip saddr @clients.test ip saddr @fproxy.test' "$WORK/commands"
check download-proxy-independent grep -q 'local_clients ip daddr @bproxy.test' "$WORK/commands"
check selected-tproxy-port-preserved grep -q 'tproxy to :1604' "$WORK/commands"
: > "$WORK/commands"
NftInstanceAdd test 0 1 9040 0 lo 0 1604 1604 0 0 0 '' 1
check restricted-onion-rule grep -q 'blacklist ip saddr @clients.test ip daddr @o.test' "$WORK/commands"
: > "$WORK/commands"
NftInstanceAdd test 0 2 9040 0 lo 0 1604 1604 0 0 0 ''
check existing-list-unrestricted grep -q 'blacklist ip daddr @d.test' "$WORK/commands"
no_source() { ! grep -q 'ip saddr' "$WORK/commands"; }
check missing-option-backwards-compatible no_source
: > "$WORK/commands"
USER_INSTANCES_CFG=test
DeleteInstancesNftSets
check source-set-deleted grep -q 'delete set ip rb_clients_test clients.test' "$WORK/commands"
USER_INSTANCES_ALL=test
: > "$WORK/commands"
FlushInstancesNftSets
check source-set-flushed grep -q 'flush set ip rb_clients_test clients.test' "$WORK/commands"
USER_INSTANCE_VARS='U_CLIENT_FILTER U_CLIENT_IPS'
U_CLIENT_FILTER=1 U_CLIENT_IPS=192.0.2.1
ClearUserInstanceVars
check per-list-options-cleared test -z "$U_CLIENT_FILTER$U_CLIENT_IPS"

if [ "$REAL" != 0 ]; then
    NFT_CMD=nft
    if nft list table $NFT_TABLE >/dev/null 2>&1; then
        echo 'FAIL test-table-already-exists'; exit 1
    fi
    nft add table $NFT_TABLE || exit 1
    trap 'nft delete table $NFT_TABLE' EXIT HUP INT TERM
    for chain in blacklist fproxy_chain local_clients action_filter action_nat action_nat_local; do
        nft add chain $NFT_TABLE "$chain" || exit 1
    done
    MakeInstanceNftSets test '' '192.0.2.1 192.0.2.2'
    NftInstanceAdd test 0 3 9040 0 lo 1 1604 1604 1 1 1 '' 1
    check kernel-accepted-source-rule sh -c 'nft list chain ip rb_clients_test blacklist | grep -q "ip saddr @clients.test ip daddr @d.test"'
    # Rules for other transports must compile with the same source restriction.
    MakeInstanceNftSets tor '' ''
    NftInstanceAdd tor 0 1 9040 0 lo 0 1604 1604 0 0 0 '' 1
    MakeInstanceNftSets vpn '' ''
    NftInstanceAdd vpn 0 2 9040 0 lo 0 1604 1604 0 0 0 '' 1
    check kernel-accepted-tor-rule sh -c 'nft list chain ip rb_clients_test blacklist | grep -q "ip saddr @clients.tor ip daddr @o.tor"'
    check kernel-accepted-vpn-rule sh -c 'nft list chain ip rb_clients_test blacklist | grep -q "ip saddr @clients.vpn ip daddr @d.vpn"'
    if [ "$REAL" = packets ]; then
        # Only loopback TCP port 9 enters this test hook; no production chains
        # or routes are modified. A refused connection still sends a SYN.
        nft flush chain $NFT_TABLE blacklist
        nft flush set $NFT_TABLE clients.test
        nft add element $NFT_TABLE clients.test '{ 127.0.0.2 }'
        nft add element $NFT_TABLE d.test '{ 127.0.0.1 }'
        NftInstanceMatchRule 1 .test blacklist ip daddr @d.test counter goto mark_chain.test
        NftInstanceMatchRule 0 .vpn blacklist ip daddr @d.test counter goto mark_chain.vpn
        nft add chain $NFT_TABLE test_output '{ type filter hook output priority 0; policy accept; }'
        nft add rule $NFT_TABLE test_output ip daddr 127.0.0.0/8 tcp dport 9 jump blacklist
        packets() {
            nft list chain $NFT_TABLE blacklist | awk -v target="$1" 'index($0, "goto mark_chain." target) {for(i=1;i<=NF;i++) if($i=="packets") print $(i+1)}'
        }
        request() { curl --noproxy '*' --interface "$1" --max-time 2 -s "http://${2:-127.0.0.1}:9" >/dev/null 2>&1 || :; }
        request 127.0.0.2
        selected=$(packets test)
        check selected-client-matched test "$selected" -gt 0
        check selected-client-not-fallback test "$(packets vpn)" = 0
        request 127.0.0.3
        check other-client-not-matched test "$(packets test)" = "$selected"
        fallback=$(packets vpn)
        check other-client-reached-next-list test "$fallback" -gt 0
        request 127.0.0.2 127.0.0.4
        check unlisted-destination-not-matched test "$(packets test)" = "$selected"
        nft flush set $NFT_TABLE clients.test
        request 127.0.0.2
        check empty-clients-match-nobody test "$(packets test)" = "$selected"
        check empty-clients-continue-to-next-list test "$(packets vpn)" -gt "$fallback"
    fi
fi
echo "FAILED=$FAILED"
test "$FAILED" -eq 0
