# Regression checks

Run the shell checks with Bash and an AWK implementation supporting interval expressions:

```sh
bash tests/runtime-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)" 0
node tests/cron-regression.cjs luci-app-ruantiblock/htdocs/luci-static/resources/view/ruantiblock/cron.js
bash tests/routing-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)"
node tests/luci-regression.cjs
```

The shell script takes a package filesystem root, a fresh writable fixture directory, and an optional `1` to enable kernel nftables checks. For installed OpenWrt files, the filesystem root is `/` and the script runs with BusyBox ash. Kernel checks require root and create only the `inet rb_review_217` test table, without hook chains; an existing table with that name causes the test to stop. The test table is removed on exit. Fixture files remain available for inspection.

Runtime checks exercise the package functions with synthetic list entries and substituted external services. They cover cached startup, failed downloads, input parsing, delayed restart, UCI whitespace, hotplug defaults, and update failures. With kernel checks enabled, both valid-list loading and preservation of existing IP entries after a rejected transaction are checked.

The cron checks execute the supplied LuCI module in Node.js with DOM and filesystem substitutes. They cover missing files, permission and timeout failures, blocked writes after failed reads, preservation of unrelated jobs, and failed writes without restarting cron. These checks do not replace an end-to-end browser test.

The routing checks exercise the VPN monitor with synthetic interfaces and a substituted reload command. They verify recovery when another VPN is disconnected, list-order independence, full-proxy route checks, and suppression of unnecessary reloads. They also verify dnsmasq instance selection with a substituted ubus response. No routing tables or network interfaces are changed.

The additional LuCI checks cover both file editors and service status polling: failed reads must block saves, missing optional files remain editable, failed writes preserve edits, and interrupted status queries must not stop subsequent polling. All filesystem and service calls in these checks are substitutes.
