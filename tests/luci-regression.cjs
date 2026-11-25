const fs = require('fs');
const assert = require('assert/strict');
const path = require('path');
const root = process.argv[2] || 'luci-app-ruantiblock/htdocs/luci-static/resources/view/ruantiblock';
const classes = { extend: value => value };
const elements = {};
function E(tag, attrs, children) {
    const element = { style: {}, append() {}, ...(attrs || {}) };
    if (element.id) elements[element.id] = element;
    return element;
}
global.document = { head: { append() {} }, getElementById: id => elements[id] };
global.L = { env: { pollinterval: 5 }, resolveDefault: (promise, fallback) => promise.catch(() => fallback) };
String.prototype.format = function(...args) {
    let i = 0;
    return this.replace(/%s/g, () => args[i++]);
};
function load(name, dependencies) {
    return new Function(...Object.keys(dependencies), fs.readFileSync(path.join(root, name), 'utf8'))(
        ...Object.values(dependencies));
}
const ui = { addNotification() {}, hideModal() {}, showModal() {}, createHandlerFn() {} };
const common = { E, _: s => s, ui, baseclass: classes, view: classes, rpc: { declare: () => () => {} } };
let failed = 0;
async function check(name, callback) {
    try { await callback(); console.log('PASS ' + name); }
    catch (error) { failed++; console.error('FAIL ' + name + ': ' + error.message); }
}
async function editorScenario(kind, errorName, writeFails = false, required = false, emptyFile = false) {
    let disk = emptyFile ? '' : 'retained.example\n';
    let writes = 0, hidden = 0, callbacks = 0;
    const io = {
        read: () => Promise.reject(Object.assign(new Error('No data received'), { name: 'NoDataError' })),
        read_direct: () => errorName ? Promise.reject(Object.assign(new Error('read failed'), { name: errorName })) : Promise.resolve(disk),
        write: (file, data) => {
            writes++;
            if (writeFails) return Promise.reject(new Error('write failed'));
            disk = data;
            return Promise.resolve();
        }
    };
    const dependencies = { ...common, fs: io, ui: { ...ui, hideModal: () => { hidden++; } } };
    const tools = load('tools.js', dependencies);
    let editor;
    if (kind === 'dialog') {
        editor = Object.create(tools.fileEditDialog);
        editor.__init__('/fixture/list', 'List', '', () => { callbacks++; }, required);
    } else {
        const page = load('settings.js', { ...dependencies, tools, form: { Value: classes, GridSection: classes } });
        editor = Object.create(page.CBIBlockFileEdit);
        editor.__init__({}, {}, {}, 'list1', '/fixture/list', 'List', '', () => { callbacks++; });
    }
    let readError, content;
    try { content = await editor.load(); } catch (e) { readError = e; }
    if (errorName && (errorName !== 'NotFoundError' || required)) {
        // A failed read must not become a blank editor that overwrites the file.
        if (!readError) {
            elements['widget.modal_content'] = { value: 'new.example' };
            if (kind === 'dialog') await editor.handleSave();
            else await editor.write('list1', 'new.example\n');
        }
        assert.equal(writes, 0);
        assert.equal(disk, 'retained.example\n');
        assert(readError, 'read error was hidden');
        // Even a stale/direct save event must not bypass the failed load.
        const save = kind === 'dialog' ? editor.handleSave() : editor.write('list1', 'new.example\n');
        await assert.rejects(save);
        assert.equal(writes, 0);
    } else {
        assert.equal(readError, undefined);
        if (emptyFile) assert.equal(kind === 'inline' ? editor.content : content, '');
        elements['widget.modal_content'] = { value: 'new.example' };
        if (kind === 'dialog') await editor.handleSave();
        else if (writeFails) await assert.rejects(editor.write('list1', 'new.example\n'));
        else await editor.write('list1', 'new.example\n');
        assert.equal(writes, 1);
        assert.equal(disk, writeFails ? 'retained.example\n' : 'new.example\n');
        assert.equal(callbacks, writeFails ? 0 : 1);
        if (kind === 'dialog') assert.equal(hidden, writeFails ? 0 : 1);
    }
}
async function pollingScenario(mode) {
    let reads = 0, renders = 0, running = true;
    const poll = { stop: () => { running = false; }, start: () => { running = true; }, add() {} };
    const page = load('service.js', { ...common, fs: { read: () => Promise.resolve('42'), exec_direct: () => Promise.reject(new Error('action failed')) },
        poll, uci: { get: () => ({}) }, tools: { normalizeValue: v => typeof v === 'string' ? v.trim() : v, handleServiceAction: () => Promise.resolve() } });
    page.statusTokenValue = '41';
    page.getAppStatus = async () => { reads++; return reads === 1 ? null : ['status']; };
    page.setAppStatus = () => { renders++; };
    if (mode === 'poll') {
        await page.statusPoll();
        await page.statusPoll();
        assert.equal(reads, 2, 'failed status fetch consumed the token');
        assert.equal(renders, 1);
        assert.equal(page.statusTokenValue, '42');
    } else if (mode === 'initial-token') {
        page.dialogDestroy = function() {};
        L.bind = fn => fn;
        page.render([{}, {}, true, '42', ['ruantiblock'], '2.1.17-r1', 'OK']);
        assert.equal(page.statusTokenValue, '42');
    } else if (mode === 'service') {
        await page.serviceAction('enable');
        assert.equal(running, true, 'polling stayed stopped after an unavailable status');
        assert.equal(page.statusTokenValue, null);
    } else {
        await page.appAction('start').catch(() => {});
        assert.equal(running, true, 'polling stayed stopped after an action failure');
        assert.equal(page.statusTokenValue, null);
    }
}
(async () => {
    for (const kind of ['dialog', 'inline']) {
        for (const error of ['PermissionError', 'TimeoutError', 'NoDataError', 'Error', 'NotFoundError', null])
            await check(`${kind}-${error || 'successful-read'}`, () => editorScenario(kind, error));
        await check(`${kind}-failed-write`, () => editorScenario(kind, null, true));
        await check(`${kind}-empty-file`, () => editorScenario(kind, null, false, false, true));
    }
    await check('dialog-missing-required-file', () => editorScenario('dialog', 'NotFoundError', false, true));
    for (const mode of ['poll', 'service', 'action', 'initial-token']) await check('status-' + mode, () => pollingScenario(mode));
    await check('tools-disabled-status-independent-nodes', () => {
        const makeDomNode = (tag, attrs, children) => {
            const node = { tag, attrs: attrs || {}, children: [], parent: null, append(item) {
                if (item == null || item === '') return;
                if (Array.isArray(item)) { item.forEach(c => this.append(c)); return; }
                if (typeof item === 'object' && 'parent' in item) {
                    if (item.parent) item.parent.children = item.parent.children.filter(c => c !== item);
                    item.parent = this;
                }
                this.children.push(item);
            } };
            node.append(children);
            return node;
        };
        const domE = (tag, attrs, children) => Array.isArray(tag) ? makeDomNode('#frag', {}, tag) : (arguments.length === 2 ? makeDomNode(tag, {}, attrs) : makeDomNode(tag, attrs, children));
        const tools = load('tools.js', { ...common, E: domE, fs: {} });
        const table = tools.makeStatusString(2, '', '', 0, '');
        assert.equal(table.children[0].children[1].children.length, 1);
        assert.equal(table.children[2].children[1].children.length, 1);
        assert.notEqual(table.children[0].children[1].children[0], table.children[2].children[1].children[0]);
    });
    await check('service-restart-button-and-update-return', async () => {
        const execCalls = [];
        const poll = { stop() {}, start() {}, add() {}, active: () => true };
        const handlerUi = {
            ...ui,
            createHandlerFn: (ctx, fn, ...args) => () => {
                let target = null;
                const res = fn.apply(ctx, args);
                return Promise.resolve(res).finally(() => {
                    if (target) target.disabled = false;
                });
            }
        };
        let statusCode = 0;
        const notifications = [];
        const page = load('service.js', {
            ...common,
            ui: { ...handlerUi, addNotification: (_t, msg) => notifications.push(msg) },
            fs: {
                exec: () => Promise.resolve({ code: statusCode }),
                exec_direct: (cmd, args) => { execCalls.push(args); return Promise.resolve(''); },
                read: () => Promise.resolve('1'),
            },
            poll,
            uci: { get: () => ({}), load: () => Promise.resolve() },
            tools: {
                appName: 'ruantiblock',
                execPath: '/usr/bin/ruantiblock',
                tokenFile: '/var/run/ruantiblock.token',
                versionFile: '/usr/share/ruantiblock/version',
                normalizeValue: v => typeof v === 'string' ? v.trim() : v,
                makeStatusString: () => E('div'),
                getInitStatus: () => Promise.resolve(true),
            },
        });
        page.dialogDestroy = function() {};
        L.bind = fn => fn;
        page.render([{ code: 0 }, { code: 0 }, true, '1', ['ruantiblock'], '2.3.0-r1', 'OK']);
        assert(elements.btn_restart, 'missing btn_restart');
        assert.equal(elements.btn_restart.disabled, false);
        const restartPromise = elements.btn_restart.onclick();
        assert(restartPromise && typeof restartPromise.then === 'function', 'btn_restart handler did not return Promise');
        await restartPromise;
        assert.deepEqual(execCalls[0], ['restart']);
        const updatePromise = elements.btn_update.onclick();
        assert(updatePromise && typeof updatePromise.then === 'function', 'btn_update handler did not return Promise');
        await updatePromise;
        // Failed restart leaving service disabled must notify and keep btn_restart disabled even if createHandlerFn re-enables it.
        statusCode = 2;
        await page.appAction('restart', 'btn_restart');
        elements.btn_restart.disabled = false; // Simulate ui.createHandlerFn .finally()
        await new Promise(r => setTimeout(r, 10));
        assert.equal(elements.btn_restart.disabled, true);
        assert.equal(notifications.length, 1);
    });
    await check('settings-remove-defers-user-list-wipe-until-apply', async () => {
        const writes = [];
        const listeners = {};
        const prevAdd = global.document.addEventListener;
        const prevRemove = global.document.removeEventListener;
        global.document.addEventListener = (ev, fn) => { listeners[ev] = fn; };
        global.document.removeEventListener = (ev, fn) => { if (listeners[ev] === fn) delete listeners[ev]; };
        try {
            const page = load('settings.js', {
                ...common,
                form: { Value: classes, GridSection: classes },
                fs: {
                    write: (p, data) => { writes.push([p, data]); return Promise.resolve(); },
                    exec: () => Promise.resolve({ code: 2 }),
                    exec_direct: () => Promise.resolve(''),
                },
                tools: { appName: 'ruantiblock', execPath: '/usr/bin/ruantiblock', userListsDir: '/etc/ruantiblock/user_lists' },
                ui: { ...ui, changes: { apply: () => Promise.resolve() } },
            });
            page.pendingRemovedUserLists = new Set();
            page.onUciReverted = () => page.pendingRemovedUserLists.clear();
            global.document.addEventListener('uci-reverted', page.onUciReverted);
            page.appStatusCode = 2;
            page.handleSave = () => Promise.resolve();
            const grid = Object.create(page.CBIUserInstancesGrid);
            grid.ownerView = page;
            grid.super = () => Promise.resolve('removed');
            await grid.handleRemove('list1', {});
            assert.equal(writes.length, 0, 'file was wiped before Save & Apply');
            assert(page.pendingRemovedUserLists.has('list1'));
            // uci-reverted clears pending list without touching disk.
            listeners['uci-reverted']();
            assert.equal(page.pendingRemovedUserLists.size, 0);
            assert.equal(writes.length, 0);
            // Remove + Save & Apply clears disk file.
            await grid.handleRemove('list1', {});
            await page.handleSaveApply({}, '0');
            assert.deepEqual(writes, [['/etc/ruantiblock/user_lists/list1', '']]);
            page.remove();
            assert.equal(listeners['uci-reverted'], undefined);
        } finally {
            global.document.addEventListener = prevAdd;
            global.document.removeEventListener = prevRemove;
        }
    });
    await check('acl-grants-cgi-io-download', () => {
        const acl = JSON.parse(fs.readFileSync(path.join(root, '../../../../../root/usr/share/rpcd/acl.d/luci-app-ruantiblock.json'), 'utf8'));
        const cgiIo = acl['luci-app-ruantiblock'].read['cgi-io'];
        assert(cgiIo.includes('exec') && cgiIo.includes('download'), JSON.stringify(cgiIo));
    });
    await check('log-highlight-preserves-html-entities', () => {
        const logBase = load('log-base.js', { ...common, poll: {} }).view;
        logBase.filterHighlightFunc = m => `<span class="log-highlight-item">${m}</span>`;
        const entries = [[1, 'Wed Nov 25 10:00:00 2026', null, 'user', 'err', logBase.htmlEntities('a < b & "60"')]];
        assert.equal(logBase.setStringFilter(entries, 5, '60')[0][5], 'a &#60; b &#38; &#34;<span class="log-highlight-item">60</span>&#34;');
        assert.equal(logBase.setRegexpFilter(entries, 5, '60')[0][5], 'a &#60; b &#38; &#34;<span class="log-highlight-item">60</span>&#34;');
    });
    process.exitCode = failed ? 1 : 0;
})();
