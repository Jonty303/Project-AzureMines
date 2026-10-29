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
    await page.locator('#tool').selectOption('marker');await page.locator('#marker-type').selectOption('exit');await clickCell(3,3);
    await field('name').fill('Return outside');await field('description').fill('<img src=x onerror=alert(1)>');
    await page.locator('#reference-file').setInputFiles(path.resolve(__dirname,'../../adventure-designer/samples/dales_road.json'));
    await page.waitForFunction(()=>document.querySelector('#reference-status').textContent.includes('dales_road'));
    assert.equal(await field('name').inputValue(),'Return outside'); // reference load retains pending edits
    await page.locator('#reference-location').selectOption('cave_approach');await page.locator('#use-reference').click();await apply();
    const saved=await download(),doc=M.parse(saved);assert.equal(doc.areas[0].id,'test_room');assert.equal(doc.markers[0].target_location,'cave_approach');
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
    await page.locator('#zoom').selectOption('2');
    assert.equal(await page.locator('#grid').evaluate(el=>el.style.width),'1792px');
  } finally {await browser.close();}
});
