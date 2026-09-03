const fs = require('fs');
const assert = require('assert/strict');
const source = fs.readFileSync(process.argv[2], 'utf8');
String.prototype.format = function(...args) { let i=0; return this.replace(/%s/g, () => args[i++]); };
const elements = {};
function E(tag, attrs, children) {
    const e = {style:{}, children:[], append(...items) { this.children.push(...items); }, ...(attrs || {})};
    if(e.id) elements[e.id]=e;
    return e;
}
global.document = {getElementById: id => elements[id] || {value:''}};
const factory = new Function('fs','ui','view','tools','E','_', source);
const results = [];
async function scenario(name, error, lines, writeError) {
    let writes=[], restarts=[];
    const page = factory({
        lines: () => error ? Promise.reject(Object.assign(new Error(name), {name:error})) : Promise.resolve(lines),
        write: (path, data) => { writes.push(data); return writeError ? Promise.reject(new Error('write failed')) : Promise.resolve(); }
    }, {addNotification(){}, createHandlerFn(){ return () => {}; }}, {extend:x=>x}, {
        execPath:'/usr/bin/ruantiblock', crontabFile:'/etc/crontabs/root',
        getInitStatus:()=>Promise.resolve(true), handleServiceAction:(svc,action)=> {restarts.push(action); return Promise.resolve();}
    }, E, x=>x);
    const loaded = await page.load();
    assert(Array.isArray(loaded));
    page.render(loaded);
    if(error && error !== 'NotFoundError') {
        assert.equal(elements.btn_cron_add.disabled, true);
        await page.writeCronFile(); await page.delCronSchedule(); await page.setCronSchedule();
        assert.equal(writes.length,0);
    } else {
        assert.equal(elements.btn_cron_add.disabled,false);
        await page.delCronSchedule();
        assert.equal(writes.length,1);
        const retained = (lines || []).filter(l=>!page.isRuantiblockTask(l));
        assert.equal(writes[0], retained.length ? retained.join('\n')+'\n' : '');
        assert.deepEqual(restarts, writeError ? [] : ['restart']);
    }
    results.push('PASS '+name);
}
(async()=>{
    await scenario('missing-crontab','NotFoundError');
    await scenario('permission-error-blocked','PermissionError');
    await scenario('timeout-error-blocked','TimeoutError');
    await scenario('generic-read-error-blocked','Error');
    await scenario('empty-crontab',null,[]);
    await scenario('other-jobs-preserved',null,['# retained','0 1 * * * /usr/bin/other-job','0 2 * * * /usr/bin/ruantiblock update']);
    await scenario('failed-write-no-restart',null,[],true);
    console.log(results.join('\n'));
})().catch(e=>{ console.error(e); process.exit(1); });
