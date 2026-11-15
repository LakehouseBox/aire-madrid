// Runs the artifact page's script in Node against the real catalog: every panel's queries and rendering, no browser.
// tools/check_page.sh extracts the script to /tmp/page_check.mjs and runs this; each panel prints ok or FAIL.
import { execFileSync } from 'node:child_process';
const els = {};
function el(id) {
  return els[id] ??= { id, _html: '', set innerHTML(v) { this._html = v; }, get innerHTML() { return this._html; },
    textContent: '', classList: { add() {} }, lastChild: { textContent: '' }, dataset: {},
    addEventListener() {}, querySelector(sel) { return el(id + ' ' + sel); } };
}
globalThis.document = { getElementById: el };
const lit = (v) => typeof v === 'number' ? String(v) : "'" + String(v).replace(/'/g, "''") + "'";
const panels = [];
globalThis.lhbox = {
  async query(sql, opts) {
    let i = 0; const p = opts?.params ?? [];
    const s = sql.replace(/\?/g, () => lit(p[i++]));
    const out = execFileSync('lhbox', ['duckdb', '--catalog', 'aire_madrid', '--', '-json', '-c', s], { cwd: '/private/tmp', encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], timeout: 300000 });
    const j = out.slice(out.indexOf('['));
    return { rows: JSON.parse(j.trim() || '[]') };
  },
  panel(e, fn) { panels.push(Promise.resolve().then(() => fn(e)).then(() => console.log('ok  ', e.id, e.innerHTML.length + ' chars'), (err) => console.log('FAIL', e.id, err.stack.split('\n').slice(0, 2).join(' | ')))); },
  setState() {}, onState() {}, open() {}, download() {}, ready: async () => ({ state: '' }),
};
await import(process.env.PAGE_SCRIPT);
await new Promise((r) => setTimeout(r, 1000));
await Promise.all(panels);
