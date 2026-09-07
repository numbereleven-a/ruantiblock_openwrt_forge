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
    process.exitCode = failures ? 1 : 0;
})();
