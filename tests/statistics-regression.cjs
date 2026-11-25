const fs = require('fs');
const assert = require('assert/strict');
const source = fs.readFileSync(process.argv[2], 'utf8');
let failures = 0;
String.prototype.format = function(...args) { let n = 0; return this.replace(/%s/g, () => args[n++]); };
function E(tag, attrs, children) { return { tag, attrs, children, append() {}, insertAdjacentHTML() {} }; }
global.document = { head: { append() {} }, getElementById: () => null };
global.L = { env: { pollinterval: 5 }, bind: (fn, obj) => fn.bind(obj) };
let answer, stopped = 0, notifications = 0;
const page = new Function('fs', 'poll', 'ui', 'view', 'tools', 'E', '_', source)(
    { exec_direct: () => answer instanceof Error ? Promise.reject(answer) : Promise.resolve(answer) },
    { add() {}, active: () => true, stop: () => stopped++ },
    { addNotification() { notifications++; } }, { extend: obj => obj }, { execPath: '/usr/bin/ruantiblock' }, E, s => s);
async function check(label, fn) {
    try { await fn(); console.log('PASS ' + label); }
    catch(error) { failures++; console.log('FAIL ' + label + ': ' + error.message); }
}
(async () => {
    await check('statistics-render-without-update-metadata', () => page.render({ status: 'enabled' }));
    await check('statistics-poll-without-update-metadata', async () => { answer = { status: 'enabled' }; await page.pollInfo(); });
    await check('statistics-tolerates-null-nft-entries', () => page.formatNftJson({ rules: { nftables: [{ metainfo: {} }, null] }, dnsmasq: { nftables: [{ metainfo: {} }, null] } }));
    await check('statistics-tolerates-incomplete-user-entries', () => page.render({ status: 'enabled', last_blacklist_update: {}, user_entries: [null, {}, { id: 7 }] }));
    await check('statistics-error-keeps-global-polling', async () => { stopped = 0; answer = new Error('temporary read failure'); await page.pollInfo(); assert.equal(stopped, 0); });
    await check('statistics-repeated-error-and-recovery', async () => {
        answer = { status: 'enabled' }; await page.pollInfo();
        notifications = 0;
        answer = new Error('temporary read failure');
        await page.pollInfo(); await page.pollInfo();
        assert.equal(notifications, 1);
        answer = { status: 'enabled' }; await page.pollInfo();
        answer = new Error('new read failure'); await page.pollInfo();
        assert.equal(notifications, 2);
    });
    await check('statistics-disabled-keeps-global-polling', async () => { stopped = 0; answer = { status: 'disabled' }; await page.pollInfo(); assert.equal(stopped, 0); });
    await check('statistics-valid-rule-retained', () => assert.deepEqual(page.formatNftJson({ rules: { nftables: [{ metainfo: {} }, { rule: { expr: [{ match: { left: { payload: {} }, right: '@d.list1' } }, { counter: { bytes: 42 } }] } }] } }).rules, [['d.list1', 42]]));
    await check('statistics-protocol-rules-distinct', () => {
        const parsed = page.formatNftJson({
            rules: {
                nftables: [
                    { metainfo: {} },
                    { rule: { expr: [{ match: { left: { payload: { field: 'saddr' } }, right: '@clients.list5' } }, { match: { left: { meta: { key: 'l4proto' } }, right: 'tcp' } }, { match: { left: { payload: { field: 'daddr' } }, right: '@c.list5' } }, { counter: { bytes: 100 } }] } },
                    { rule: { expr: [{ match: { left: { meta: { key: 'l4proto' } }, right: 'udp' } }, { match: { left: { payload: { field: 'daddr' } }, right: '@c.list5' } }, { counter: { bytes: 25 } }] } }
                ]
            }
        });
        assert.deepEqual(parsed.rules, [['c.list5', 100, 'tcp'], ['c.list5', 25, 'udp']]);
        assert.notEqual(page.ruleElementId('c.list5', 'tcp'), page.ruleElementId('c.list5', 'udp'));
        assert.equal(page.formatRuleDescription('c.list5', 'tcp'), 'list5 CIDR (TCP)');
        assert.equal(page.formatRuleDescription('c.list5', 'udp'), 'list5 CIDR (UDP)');
    });
    await check('statistics-disabled-enabled-transitions-clear-stale-dom', async () => {
        const domMap = {};
        function domE(tag, attrs, children) {
            if (Array.isArray(tag)) return { tag: '#frag', children: tag };
            if (arguments.length === 2) { children = attrs; attrs = {}; }
            const el = {
                tag, attrs: attrs || {}, children: [], _innerHTML: '', textContent: '',
                append(...items) {
                    for (const item of items) {
                        if (item == null || item === '') continue;
                        if (Array.isArray(item)) this.append(...item);
                        else this.children.push(item);
                    }
                },
                insertAdjacentHTML() {},
                get innerHTML() { return this._innerHTML; },
                set innerHTML(v) { this._innerHTML = v; if (v === '') this.children = []; },
            };
            if (el.attrs.id) domMap[el.attrs.id] = el;
            if (children !== undefined) el.append(children);
            return el;
        }
        const prevGet = global.document.getElementById;
        global.document.getElementById = id => domMap[id] || null;
        try {
            let pollAdds = 0, pollCallback = null, resp = null;
            const p = new Function('fs', 'poll', 'ui', 'view', 'tools', 'E', '_', source)(
                { exec_direct: () => Promise.resolve(resp) },
                { add(fn) { pollAdds++; pollCallback = fn; }, active: () => true, stop() {} },
                { addNotification() {} }, { extend: obj => obj }, { execPath: '/usr/bin/ruantiblock' }, domE, s => s);
            p.render({ status: 'disabled' });
            assert.equal(pollAdds, 1);
            assert(JSON.stringify(domMap.statsContentWrapper).includes('disabled'));
            resp = {
                status: 'enabled',
                last_blacklist_update: { status: true, date: '25.11.2026', cidr: '1', ip: '2', fqdn: '3' },
                user_entries: [{ id: 'list1:local', cidr: '1', ip: '2', fqdn: '3' }],
                rules: { nftables: [{},
                    { rule: { expr: [{ match: { left: { payload: { field: 'daddr' } }, right: '@c' } }, { counter: { bytes: 99 } }] } },
                    { rule: { expr: [{ match: { left: { payload: { field: 'daddr' } }, right: '@c.list1' } }, { counter: { bytes: 10 } }] } }
                ] },
                dnsmasq: { nftables: [{}, { set: { elem: [{ elem: { val: '1.2.3.4', expires: 60 } }] } }] }
            };
            await pollCallback();
            assert(JSON.stringify(domMap.statsContentWrapper).includes('c.list1'));
            assert(JSON.stringify(domMap.statsContentWrapper).includes('CIDR: 1, IP: 2, FQDN: 3'));
            // Removing a rule or updating user_entries while staying enabled must re-render.
            resp = {
                status: 'enabled',
                last_blacklist_update: { status: true, date: '25.11.2026', cidr: '1', ip: '2', fqdn: '3' },
                user_entries: [{ id: 'list1:local', cidr: '4', ip: '5', fqdn: '6' }],
                rules: { nftables: [{}, { rule: { expr: [{ match: { left: { payload: { field: 'daddr' } }, right: '@c' } }, { counter: { bytes: 120 } }] } }] },
                dnsmasq: { nftables: [{}, { set: { elem: [{ elem: { val: '1.2.3.4', expires: 60 } }] } }] }
            };
            await pollCallback();
            const updatedHtml = JSON.stringify(domMap.statsContentWrapper);
            assert(!updatedHtml.includes('c.list1'));
            assert(updatedHtml.includes('CIDR: 4, IP: 5, FQDN: 6'));
            resp = { status: 'disabled' };
            await pollCallback();
            const serialized = JSON.stringify(domMap.statsContentWrapper);
            assert(serialized.includes('disabled'));
            assert(!serialized.includes('Nftables rules'));
            assert(!serialized.includes('Dnsmasq'));
        } finally {
            global.document.getElementById = prevGet;
        }
    });
    process.exitCode = failures ? 1 : 0;
})();
