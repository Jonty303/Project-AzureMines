// Optional browser integration test: npm install --no-save playwright in a
// separate directory, then set PLAYWRIGHT_MODULE to that module's absolute path.
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const M = require('../model.js');

test('offline editor authoring workflow and safe import', async () => {
  const browser = await chromium.launch({headless: true, ...(process.env.BROWSER_CHANNEL ? {channel: process.env.BROWSER_CHANNEL} : {})});
  try {
    const page = await browser.newPage({viewport: {width: 1500, height: 1000}});
    const errors = []; page.on('pageerror', error => errors.push(error.message));
    page.on('dialog', dialog => dialog.accept());
    await page.goto(pathToFileURL(path.resolve(__dirname, '../index.html')).href);
    await page.locator('#file').setInputFiles(path.resolve(__dirname, '../samples/dales_road.json'));
    await page.waitForFunction(() => document.querySelectorAll('#locations button').length === 5);
    assert.equal(await page.locator('.node').count(), 5);
    assert.equal(await page.locator('.edge').count(), 4);
    await page.getByRole('button', {name: 'Seabrook', exact: true}).click();
    await page.locator('#item-form [name=id]').fill('seabrook_port');
    // Edits in both forms must survive applying either form first.
    await page.locator('#region-form [name=name]').fill('Edited Dales');
    await page.getByRole('button', {name: 'Apply region', exact: true}).click();
    assert.equal(await page.locator('#item-form [name=id]').inputValue(), 'seabrook_port');
    await page.getByRole('button', {name: 'Apply item', exact: true}).click();
    assert.equal(await page.locator('#region-form [name=starting_location]').inputValue(), 'seabrook_port');
    await page.locator('#add-location').click();
    await page.locator('#item-form [name=name]').fill('Test location');
    await page.locator('#item-form [name=description]').fill('<img src=x onerror=alert(1)>');
    await page.getByRole('button', {name: 'Apply item', exact: true}).click();
    await page.locator('#add-route').click();
    await page.locator('#item-form [name=bidirectional]').uncheck();
    await page.getByRole('button', {name: 'Apply item', exact: true}).click();
    assert.equal(await page.locator('.edge[marker-end]').count(), 1);
    await page.getByRole('button', {name: 'Test location', exact: true}).click();
    const node = page.locator('.node.selected'), box = await node.boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await page.mouse.down(); await page.mouse.move(box.x + box.width / 2 + 30, box.y + box.height / 2 + 20, {steps: 4}); await page.mouse.up();
    const downloadPromise = page.waitForEvent('download'); await page.locator('#save').click();
    const download = await downloadPromise;
    const saved = await fs.readFile(await download.path(), 'utf8');
    const region = M.parse(saved);
    assert.equal(region.locations.length, 6); assert.equal(region.routes.length, 5);
    assert.equal(region.name, 'Edited Dales'); assert.equal(region.routes[0].from, 'seabrook_port');
    assert.notEqual(region.locations.at(-1).position.x, 200);
    await page.locator('#file').setInputFiles({name: 'invalid.json', mimeType: 'application/json', buffer: Buffer.from('{"schema_version":99}')});
    await page.waitForFunction(() => document.querySelector('#status').textContent.includes('Load rejected'));
    assert.equal(await page.locator('.node').count(), 6);
    await page.locator('#file').setInputFiles({name: 'roundtrip.json', mimeType: 'application/json', buffer: Buffer.from(saved)});
    await page.waitForFunction(() => document.querySelector('#status').textContent.includes('Loaded roundtrip'));
    await page.getByRole('button', {name: 'Test location', exact: true}).click();
    assert.equal(await page.locator('#item-form [name=description]').inputValue(), '<img src=x onerror=alert(1)>');
    await page.locator('#delete').click();
    assert.equal(await page.locator('.node').count(), 5); assert.equal(await page.locator('.edge').count(), 4);
    assert.equal(await page.locator('#item-form').isHidden(), true);
    assert.ok(!(await page.locator('body').innerText()).includes('Â'));
    assert.deepEqual(errors, []);
    if (process.env.EDITOR_SCREENSHOT) await page.screenshot({path: process.env.EDITOR_SCREENSHOT, fullPage: true});
  } finally {await browser.close();}
});
