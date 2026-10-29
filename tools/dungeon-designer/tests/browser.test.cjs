const {test}=require('node:test'),assert=require('node:assert/strict');
const fs=require('node:fs/promises'),path=require('node:path');
const {pathToFileURL}=require('node:url');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const M=require('../model.js');

test('offline drawing, details, linking, undo and JSON round trip',async()=>{
  const browser=await chromium.launch({headless:true,...(process.env.BROWSER_CHANNEL?{channel:process.env.BROWSER_CHANNEL}:{})});
  try {
    const page=await browser.newPage({viewport:{width:1600,height:1100}}),errors=[];
    page.on('pageerror',error=>errors.push(error.message));page.on('dialog',dialog=>dialog.accept());
    await page.goto(pathToFileURL(path.resolve(__dirname,'../index.html')).href);
    const cell=(x,y)=>page.locator(`.cell[data-x="${x}"][data-y="${y}"]`);
    const clickCell=async(x,y)=>{await cell(x,y).scrollIntoViewIfNeeded();const box=await cell(x,y).boundingBox();await page.mouse.click(box.x+box.width/2,box.y+box.height/2);};
    const field=name=>page.locator(`#details [name="${name}"]`);
    const apply=()=>page.getByRole('button',{name:'Apply details',exact:true}).click();
    const download=async()=>{const promise=page.waitForEvent('download');await page.locator('#save').click();return fs.readFile(await(await promise).path(),'utf8');};
    const drag=async(a,b)=>{
      await cell(...a).scrollIntoViewIfNeeded();const first=await cell(...a).boundingBox(),last=await cell(...b).boundingBox();
      await page.mouse.move(first.x+first.width/2,first.y+first.height/2);await page.mouse.down();
      await page.mouse.move(last.x+last.width/2,last.y+last.height/2,{steps:5});await page.mouse.up();
    };
    await page.locator('#add-area').click();await field('id').fill('test_room');await field('name').fill('Test room');await apply();
    await page.locator('#tool').selectOption('room');await drag([2,2],[5,5]);
    assert.equal(await page.locator('.cell.floor').count(),16);
    await page.locator('#undo').click();assert.equal(await page.locator('.cell.floor').count(),0);
    await page.locator('#redo').click();assert.equal(await page.locator('.cell.floor').count(),16);
    await page.locator('#paint-area').selectOption('');await page.locator('#tool').selectOption('corridor');await drag([5,4],[10,4]);
    await page.locator('#tool').selectOption('door');await clickCell(8,4);assert.equal(await page.locator('.cell.door').count(),1);
    await page.locator('#tool').selectOption('wall');await clickCell(8,4);assert.equal(await page.locator('.cell.wall').count(),1);
    await page.locator('#tool').selectOption('secret_door');await clickCell(8,4);assert.equal(await page.locator('.cell.secret_door').count(),1);
    const floorColour=await page.locator('.cell.floor').first().evaluate(el=>getComputedStyle(el).fill);
    const corridorColour=await page.locator('.cell.corridor').first().evaluate(el=>getComputedStyle(el).fill);
    assert.notEqual(floorColour,corridorColour);
    await page.locator('#place-exit').click();await clickCell(3,3);
    await field('name').fill('Return outside');await field('description').fill('<img src=x onerror=alert(1)>');
    await page.locator('#reference-file').setInputFiles(path.resolve(__dirname,'../../adventure-designer/samples/dales_road.json'));
    await page.waitForFunction(()=>document.querySelector('#reference-status').textContent.includes('dales_road'));
    assert.equal(await field('name').inputValue(),'Return outside'); // reference load retains pending edits
    await page.locator('#reference-location').selectOption('cave_approach');await page.locator('#use-reference').click();await apply();
    const saved=await download(),doc=M.parse(saved);assert.equal(doc.areas[0].id,'test_room');assert.equal(doc.markers[0].target_location,'cave_approach');
    assert.ok(doc.cells.some(c=>c.tile==='secret_door'));assert.equal(await page.locator('.badge.exit').count(),1);
    assert.equal(doc.markers[0].description,'<img src=x onerror=alert(1)>');
    await page.locator('#tool').selectOption('erase');await clickCell(3,3);assert.equal(await page.locator('#markers button').count(),0);
    await page.locator('#undo').click();assert.equal(await page.locator('#markers button').count(),1);
    await page.locator('#file').setInputFiles({name:'bad.json',mimeType:'application/json',buffer:Buffer.from('{"schema_version":9}')});
    await page.waitForFunction(()=>document.querySelector('#status').textContent.includes('Load rejected'));
    assert.equal(await page.locator('#markers button').count(),1);
    await page.locator('#file').setInputFiles({name:'roundtrip.json',mimeType:'application/json',buffer:Buffer.from(saved)});
    await page.waitForFunction(()=>document.querySelector('#status').textContent.includes('Loaded roundtrip'));
    assert.deepEqual(M.parse(await download()),doc);
    await page.locator('#areas button').click();await field('name').fill('Unapplied name');
    await page.locator('#tool').selectOption('floor');await clickCell(12,4);
    assert.match(await page.locator('#status').innerText(),/Apply or discard/);
    await page.getByRole('button',{name:'Discard edits',exact:true}).click();
    await page.locator('#map-details').click();await field('width').fill('8');await apply();
    assert.match(await page.locator('#status').innerText(),/outside grid/);await page.getByRole('button',{name:'Discard edits',exact:true}).click();
    await page.locator('#hideout').click();assert.equal(await page.locator('.cell.floor').count(),0);assert.equal(await page.locator('#areas button').count(),5);
    await page.locator('#practice').click();assert.equal(await page.locator('#areas button').count(),3);
    assert.match(await page.locator('#validation-summary').innerText(),/0 errors · 0 warnings/);
    assert.equal(await page.locator('#file').isVisible(),false);
    assert.equal(await page.locator('#reference-file').isVisible(),false);
    assert.deepEqual(errors,[]);
    if(process.env.EDITOR_SCREENSHOT)await page.screenshot({path:process.env.EDITOR_SCREENSHOT,fullPage:true});
  } finally {await browser.close();}
});

test('keyboard room drawing, cancellation and protected replacement',async()=>{
  const browser=await chromium.launch({headless:true,...(process.env.BROWSER_CHANNEL?{channel:process.env.BROWSER_CHANNEL}:{})});
  try {
    const page=await browser.newPage({viewport:{width:1400,height:1000}});
    await page.goto(pathToFileURL(path.resolve(__dirname,'../index.html')).href);
    await page.locator('#tool').selectOption('room');await page.locator('#grid').focus();
    await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowDown');await page.keyboard.press('Enter');
    await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowDown');await page.keyboard.press('Enter');
    assert.equal(await page.locator('.cell.floor').count(),4);
    await page.keyboard.press('Enter');await page.keyboard.press('ArrowRight');await page.keyboard.press('Escape');
    assert.equal(await page.locator('.cell.floor').count(),4);
    page.once('dialog',dialog=>dialog.dismiss());await page.locator('#new').click();
    assert.equal(await page.locator('.cell.floor').count(),4);
    await page.locator('#undo').click();assert.equal(await page.locator('.cell.floor').count(),0);
    await page.locator('#redo').click();assert.equal(await page.locator('.cell.floor').count(),4);
    await page.locator('#place-entrance').click();await page.locator('#grid').focus();await page.keyboard.press('ArrowLeft');await page.keyboard.press('Enter');
    assert.equal(await page.locator('.badge.entrance').count(),1);
    await page.locator('#zoom').selectOption('2');
    assert.equal(await page.locator('#grid').evaluate(el=>el.style.width),'1848px');
  } finally {await browser.close();}
});

test('symbol placement, edge orientation, property edits, terrain and legacy import',async()=>{
  const browser=await chromium.launch({headless:true,...(process.env.BROWSER_CHANNEL?{channel:process.env.BROWSER_CHANNEL}:{})});
  try {
    const page=await browser.newPage({viewport:{width:1600,height:1200}}),errors=[];
    page.on('pageerror',e=>errors.push(e.message));page.on('dialog',d=>d.accept());
    await page.goto(pathToFileURL(path.resolve(__dirname,'../index.html')).href);await page.locator('#practice').click();
    const click=async(x,y)=>{const cell=page.locator(`.cell[data-x="${x}"][data-y="${y}"]`);await cell.scrollIntoViewIfNeeded();const b=await cell.boundingBox();await page.mouse.click(b.x+b.width/2,b.y+b.height/2);};
    const field=name=>page.locator(`#details [name="${name}"]`),apply=()=>page.getByRole('button',{name:'Apply details',exact:true}).click();
    const download=async()=>{const p=page.waitForEvent('download');await page.locator('#save').click();return M.parse(await fs.readFile(await(await p).path(),'utf8'));};
    const initial=await download();
    await page.locator('#symbol-group').selectOption('Room objects');await page.locator('[data-symbol="chest"]').click();
    await page.locator('#feature-rotation').selectOption('90');await click(4,9);
    assert.match(await page.locator('#inspector-title').innerText(),/Feature/);
    await field('name').fill('Test chest');await field('rotation').selectOption('180');
    await field('locked').check();await field('concealed').check();await field('provides_cover').check();await apply();
    assert.match(await page.locator('.map-feature.chosen').getAttribute('transform'),/rotate\(180\)/);
    await page.locator('#symbol-group').selectOption('Natural features');await page.locator('[data-symbol="water"]').click();await click(4,9);
    let data=await download();assert.deepEqual(data.cells,initial.cells);
    const chest=data.features.find(f=>f.name==='Test chest');assert.equal(chest.rotation,180);assert.equal(chest.locked,true);assert.equal(chest.concealed,true);
    assert.ok(data.features.some(f=>f.kind==='water'&&f.x===4&&f.y===9));
    await page.locator('#tool').selectOption('clear_features');await click(4,9);
    data=await download();assert.ok(!data.features.some(f=>f.x===4&&f.y===9));assert.deepEqual(data.cells,initial.cells);
    await page.locator('#undo').click();assert.ok((await download()).features.some(f=>f.name==='Test chest'));
    await page.locator('#symbol-group').selectOption('Doors & barriers');await page.locator('[data-symbol="bars"]').click();
    await page.locator('#feature-edge').selectOption('west');await click(12,9);assert.equal(await field('edge').inputValue(),'west');
    assert.match(await page.locator('.map-feature.chosen').getAttribute('transform'),/rotate\(90\)/);
    await field('edge').selectOption('east');await apply();
    await page.locator('#symbol-group').selectOption('Travel');await page.locator('[data-symbol="stairs_up"]').click();await click(16,9);
    await field('target_document').fill('practice_dungeon');await field('target_location').fill('hall');await apply();
    data=await download();assert.equal(data.features.find(f=>f.kind==='stairs_up').target_location,'hall');
    await page.locator('#appearance').selectOption('mono');assert.equal(await page.locator('#grid').getAttribute('class'),'mono');
    assert.equal(await page.locator('.cell.floor').first().evaluate(el=>getComputedStyle(el).fill),'rgb(250, 247, 237)');
    const old={...initial,schema_version:2};delete old.features;
    await page.locator('#file').setInputFiles({name:'old_v2.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(old))});
    await page.waitForFunction(()=>document.querySelector('#status').textContent.includes('Loaded old_v2'));
    data=await download();assert.equal(data.schema_version,3);assert.deepEqual(data.cells,old.cells);assert.deepEqual(data.features,[]);
    assert.deepEqual(errors,[]);
    await page.locator('#practice').click();await page.locator('#symbol-group').selectOption('Room objects');
    if(process.env.EDITOR_SCREENSHOT)await page.screenshot({path:process.env.EDITOR_SCREENSHOT.replace('.png','-mono.png'),fullPage:true});
  }finally{await browser.close();}
});
