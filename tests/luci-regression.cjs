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
global.L = { resolveDefault: (promise, fallback) => promise.catch(() => fallback) };
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
async function editorScenario(kind, errorName, writeFails = false, required = false) {
    let disk = 'retained.example\n';
    let writes = 0, hidden = 0, callbacks = 0;
    const io = {
        read: () => errorName ? Promise.reject(Object.assign(new Error('read failed'), { name: errorName })) : Promise.resolve(disk),
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
    let readError;
    try { await editor.load(); } catch (e) { readError = e; }
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
        for (const error of ['PermissionError', 'TimeoutError', 'Error', 'NotFoundError', null])
            await check(`${kind}-${error || 'successful-read'}`, () => editorScenario(kind, error));
        await check(`${kind}-failed-write`, () => editorScenario(kind, null, true));
    }
    await check('dialog-missing-required-file', () => editorScenario('dialog', 'NotFoundError', false, true));
    for (const mode of ['poll', 'service', 'action', 'initial-token']) await check('status-' + mode, () => pollingScenario(mode));
    process.exitCode = failed ? 1 : 0;
})();
