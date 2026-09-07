# Regression checks

Run the shell checks with Bash and an AWK implementation supporting interval expressions:

```sh
bash tests/runtime-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)" 0
node tests/cron-regression.cjs luci-app-ruantiblock/htdocs/luci-static/resources/view/ruantiblock/cron.js
bash tests/routing-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)"
node tests/luci-regression.cjs
bash tests/client-filter-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)"
bash tests/dnsmasq-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)"
bash tests/failure-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)"
bash tests/application-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)"
bash tests/workflow-regression.sh "$PWD"
node tests/statistics-regression.cjs luci-app-ruantiblock/htdocs/luci-static/resources/view/ruantiblock/info.js
```

The runtime shell script takes a package filesystem root, a fresh writable fixture directory, and an optional `1` to enable kernel nftables checks. For installed OpenWrt files, the filesystem root is `/` and the script runs with BusyBox ash. Runtime kernel checks require root and create only the `inet rb_review_217` test table, without hook chains; an existing table with that name causes the test to stop. The test table is removed on exit. Fixture files remain available for inspection.

Runtime checks exercise the package functions with synthetic list entries and substituted external services. They cover cached startup, failed downloads, input parsing, delayed restart, UCI whitespace, hotplug defaults, and update failures. With kernel checks enabled, both valid-list loading and preservation of existing IP entries after a rejected transaction are checked.

The cron checks execute the supplied LuCI module in Node.js with DOM and filesystem substitutes. They cover missing files, permission and timeout failures, blocked writes after failed reads, preservation of unrelated jobs, and failed writes without restarting cron. These checks do not replace an end-to-end browser test.

The routing checks exercise the VPN monitor with synthetic interfaces and a substituted reload command. They verify recovery when another VPN is disconnected, list-order independence, full-proxy route checks, and suppression of unnecessary reloads. They also verify dnsmasq instance selection with a substituted ubus response. No routing tables or network interfaces are changed.

The additional LuCI checks cover both file editors and service status polling: failed reads must block saves, missing optional files remain editable, failed writes preserve edits, and interrupted status queries must not stop subsequent polling. All filesystem and service calls in these checks are substitutes.

The application checks inject failures into set and chain creation and check that setup returns an error immediately. Their optional third argument `1` also checks a real nft batch: an invalid user-list file must leave both existing test sets unchanged, while a subsequent valid batch updates them together. A file without a final newline is included in the successful case. These kernel checks exclusively create and remove the `ip rb_batch_review` table, with no hook chains, and refuse an existing table. On Linux, run them in a disposable network namespace:

```sh
sudo unshare -n bash tests/application-regression.sh "$PWD/ruantiblock/files" "$(mktemp -d)" 1
```

The statistics checks run the packaged LuCI view in Node.js with RPC, DOM and polling substitutes. They cover missing update metadata, incomplete nft and user-list entries, preserved valid counters, continued global polling after an error or disabled status, and notification suppression until a successful response. They do not establish browser rendering or live RPC compatibility.

The release workflow runs the failure, application (without kernel access) and statistics checks before building packages. Kernel checks must be run separately; they are not router end-to-end tests.
