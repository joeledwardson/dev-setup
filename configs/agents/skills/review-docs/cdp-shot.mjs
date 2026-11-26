#!/usr/bin/env node
// cdp-shot.mjs <url> <out.png> [waitMs]
//
// Full-page screenshot via Chrome DevTools Protocol. Use this instead of
// `chromium --headless --screenshot`, which hangs on never-idle pages (mkdocs-material
// with navigation.instant + a search Web Worker + mermaid keeps the page busy, and the
// one-shot flag waits for load/idle that never comes — --virtual-time-budget doesn't
// rescue it on this Chromium build). CDP lets us navigate, wait an explicit amount, then
// capture regardless of idle — which is exactly why mmdc works here too.
//
// Needs only Node 22 stdlib (global fetch + WebSocket) and a chromium-family browser.
// Browser override: CDP_BROWSER=brave node cdp-shot.mjs ...
import { spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';
import { setTimeout as sleep } from 'node:timers/promises';

const [url, out, waitMs = '3500'] = process.argv.slice(2);
if (!url || !out) {
  console.error('usage: cdp-shot.mjs <url> <out.png> [waitMs]');
  process.exit(2);
}

const PORT = 9777;
const BROWSER = process.env.CDP_BROWSER || 'chromium';
const proc = spawn(BROWSER, [
  '--headless', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
  '--hide-scrollbars', `--remote-debugging-port=${PORT}`,
  '--user-data-dir=/tmp/cdp-shot-profile', '--window-size=1440,2000', 'about:blank',
], { stdio: 'ignore', detached: false });

const fail = (msg) => { try { proc.kill('SIGKILL'); } catch {} console.error(msg); process.exit(1); };

// wait for the CDP page target to come up
let pageWs;
for (let i = 0; i < 60; i++) {
  try {
    const list = await fetch(`http://localhost:${PORT}/json/list`).then((r) => r.json());
    const page = list.find((t) => t.type === 'page');
    if (page?.webSocketDebuggerUrl) { pageWs = page.webSocketDebuggerUrl; break; }
  } catch { /* not up yet */ }
  await sleep(150);
}
if (!pageWs) fail('CDP: page target never appeared');

const ws = new WebSocket(pageWs);
let id = 0;
const pending = new Map();
ws.addEventListener('message', (e) => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); }
});
await new Promise((r, j) => { ws.addEventListener('open', r); ws.addEventListener('error', j); });
const send = (method, params = {}) =>
  new Promise((res) => { const i = ++id; pending.set(i, res); ws.send(JSON.stringify({ id: i, method, params })); });

await send('Page.enable');
await send('Page.navigate', { url });
await sleep(Number(waitMs)); // explicit wait — do NOT depend on network-idle

// size the emulated viewport to the full content so captureBeyondViewport gets everything
const { result } = await send('Runtime.evaluate', {
  expression: 'JSON.stringify({w: document.documentElement.scrollWidth, h: document.documentElement.scrollHeight})',
  returnByValue: true,
});
const { w, h } = JSON.parse(result.value);
const height = Math.min(h, 16000); // Chrome single-shot height ceiling
await send('Emulation.setDeviceMetricsOverride', { width: w, height, deviceScaleFactor: 1, mobile: false });
const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
if (!shot?.data) fail('CDP: captureScreenshot returned no data');
writeFileSync(out, Buffer.from(shot.data, 'base64'));

ws.close();
proc.kill('SIGKILL');
console.log(`captured ${out} (${w}x${h}${h > height ? `, clipped to ${height}` : ''})`);
process.exit(0);
