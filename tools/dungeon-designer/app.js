'use strict';
const M = DungeonModel, $ = id => document.getElementById(id), grid = $('grid'), form = $('details');
const size = 28;
const badges = {entrance:'E',exit:'X',stairs:'S',passage:'P',npc:'N',encounter:'!',secret:'?',conversation:'C'};
let doc = M.empty(), saved = M.serialize(doc), selection = {type:'map'}, pending = false;
let undo = [], redo = [], cursor = {x:0,y:0}, stroke = null, roomStart = null, reference = null;
const say = text => { $('status').textContent = text; };
const attempt = action => {try {action();} catch(error) {say(error.message);}};
const dirty = () => pending || M.serialize(doc) !== saved;
function mark() {$('dirty').textContent = dirty() ? 'Unsaved changes' : 'No unsaved changes';}
function guard() {if (!pending) return true; say('Apply or discard inspector edits first.'); return false;}
function commit(next, message) {
  if (M.serialize(next) !== M.serialize(doc)) {undo.push(doc); if (undo.length > 100) undo.shift(); redo = []; doc = next;}
  pending = false; render(); if (message) say(message);
}
function replace(next, message) {
  if (dirty() && !confirm('Discard unsaved dungeon changes and unapplied inspector edits?')) return;
  doc = next; saved = M.serialize(doc); selection = {type:'map'}; undo = []; redo = []; pending = false;
  cursor = {x:0,y:0}; stroke = null; roomStart = null; $('paint-area').value = ''; render(); say(message);
}
function select(type,id) {if (!guard()) return; selection = {type,id}; render();}
function option(select,value,label) {select.add(new Option(label,value));}
M.markerTypes.forEach(type => option($('marker-type'),type,type));
const value = name => form.elements.namedItem(name).value;
function input(name,label,initial,kind='text',choices=null) {
  const wrapper = document.createElement('label'); wrapper.textContent = label;
  const element = document.createElement(kind === 'textarea' ? 'textarea' : choices ? 'select' : 'input');
  element.name = name;
  if (choices) choices.forEach(choice => option(element,choice,choice));
  else if (kind === 'textarea') element.rows = 3;
  else {element.type = kind; if (kind === 'number') {element.required = true; element.step = '1'; element.min = '0'; element.max = '63';}}
  if (name === 'id') {element.required = true; element.pattern = '[a-z0-9_]+'; element.maxLength = 100;}
  if (name === 'name') {element.required = true; element.maxLength = 200;}
  if (['width','height'].includes(name)) {element.min='8';element.max='64';}
  element.value = initial; wrapper.append(element); form.append(wrapper);
}
function inspector() {
  form.replaceChildren();
  let item = doc;
  if (selection.type !== 'map') item = doc[selection.type === 'area' ? 'areas' : 'markers'].find(i => i.id === selection.id);
  if (!item) {selection = {type:'map'}; item = doc;}
  $('inspector-title').textContent = selection.type === 'map' ? 'Dungeon details' : selection.type === 'area' ? 'Area details' : 'Marker details';
  input('id','ID',item.id); input('name','Name',item.name);
  if (selection.type === 'map') {
    input('width','Grid width (8–64 cells)',doc.width,'number'); input('height','Grid height (8–64 cells)',doc.height,'number');
  } else {
    if (selection.type === 'marker') {
      input('type','Marker type',item.type,'text',M.markerTypes);
      input('x','Grid X (zero-based)',item.x,'number'); input('y','Grid Y (zero-based)',item.y,'number');
      input('reference','Content reference (NPC / encounter ID or Ink entry)',item.reference);
      input('target_document','Destination document ID (links only)',item.target_document);
      input('target_location','Destination location / area ID (links only)',item.target_location);
    }
    input('description','Description',item.description,'textarea');
  }
  input('author_notes','Author notes',item.author_notes,'textarea');
  const actions = document.createElement('div'); actions.className = 'form-actions';
  const apply = document.createElement('button'); apply.textContent='Apply details';apply.className='primary'; actions.append(apply);
  const discard = document.createElement('button');discard.type='button';discard.textContent='Discard edits';
  discard.onclick=()=>{pending=false;render();say('Unapplied inspector edits discarded.');};actions.append(discard);
  if (selection.type !== 'map') {
    const del=document.createElement('button');del.type='button';del.textContent='Delete';del.className='danger';
    del.onclick=()=>{
      if (!confirm(selection.type==='area' ? 'Delete area details? Floor remains; area assignments and local links to this area will be cleared. Undo can restore them.' : 'Delete this marker? Undo can restore it.')) return;
      const next=selection.type==='area' ? M.removeArea(doc,selection.id) : M.change(doc,d=>{d.markers=d.markers.filter(m=>m.id!==selection.id);});
      selection={type:'map'};commit(next,'Deleted.');
    };actions.append(del);
  }
  form.append(actions);
  $('use-reference').disabled=!(reference?.locations.length && selection.type==='marker' && M.linkTypes.includes(item.type));
}
form.oninput=()=>{pending=true;mark();};
form.onsubmit=event=>{
  event.preventDefault();attempt(()=>{
    let next;
    const item={id:value('id'),name:value('name'),author_notes:value('author_notes')};
    if (selection.type==='map') next=M.metadata(doc,{...item,width:Number(value('width')),height:Number(value('height'))});
    else if (selection.type==='area') next=M.area(doc,{...item,description:value('description')},selection.id);
    else next=M.marker(doc,{...item,description:value('description'),type:value('type'),x:Number(value('x')),y:Number(value('y')),
      reference:value('reference'),target_document:value('target_document'),target_location:value('target_location')},selection.id);
    if (selection.type==='area' && $('paint-area').value===selection.id) {
      option($('paint-area'),item.id,item.name); $('paint-area').value=item.id;
    }
    if (selection.type!=='map') selection.id=item.id;
    commit(next,'Details applied. Save JSON to keep your work.');
  });
};
function svg(tag,attrs={},text) {
  const el=document.createElementNS('http://www.w3.org/2000/svg',tag);
  Object.entries(attrs).forEach(([k,v])=>el.setAttribute(k,v)); if (text!==undefined) el.textContent=text; return el;
}
function draw() {
  grid.replaceChildren();
  grid.setAttribute('viewBox',`0 0 ${doc.width*size} ${doc.height*size}`);
  const zoom=Number($('zoom').value);grid.style.width=`${doc.width*size*zoom}px`;grid.style.height=`${doc.height*size*zoom}px`;
  const cells=new Map(doc.cells.map(c=>[`${c.x},${c.y}`,c]));
  for (let y=0;y<doc.height;y++) for (let x=0;x<doc.width;x++) {
    const c=cells.get(`${x},${y}`);
    const attrs={x:x*size,y:y*size,width:size,height:size,class:`cell ${c?.tile || 'void'}`,'data-x':x,'data-y':y};
    grid.append(svg('rect',attrs));
    if (c?.tile==='secret_door') grid.append(svg('text',{x:x*size+14,y:y*size+19,class:'secret-door-symbol'},'S'));
    if (c?.tile==='door') grid.append(svg('path',{d:`M ${x*size+6} ${y*size+14} H ${x*size+22}`,class:'door-bar'}));
  }
  // One short label per area, anchored to a real assigned cell.
  for (const area of doc.areas) {
    const first=doc.cells.find(c=>c.area_id===area.id);if (!first) continue;
    grid.append(svg('text',{x:first.x*size+3,y:first.y*size+11,class:'area-label'},area.name.length>20 ? area.name.slice(0,19)+'…' : area.name));
  }
  const counts=new Map();
  for (const m of doc.markers) {const k=`${m.x},${m.y}`;counts.set(k,(counts.get(k)||0)+1);}
  const drawn=new Set();
  for (const m of doc.markers) {
    const k=`${m.x},${m.y}`;if (drawn.has(k)) continue;drawn.add(k);
    const group=svg('g');group.append(svg('title',{},doc.markers.filter(i=>i.x===m.x&&i.y===m.y).map(i=>i.name).join(', ')));
    group.append(svg('circle',{cx:m.x*size+14,cy:m.y*size+14,r:10,class:`badge ${m.type}`}));
    group.append(svg('text',{x:m.x*size+14,y:m.y*size+19,class:'badge-text'},counts.get(k)>1 ? String(counts.get(k)) : badges[m.type]));grid.append(group);
  }
  if (stroke) for (const p of stroke.tool==='room' ? M.rectangle(stroke.start,stroke.last) : stroke.points.values())
    grid.append(svg('rect',{x:p.x*size,y:p.y*size,width:size,height:size,class:'preview'}));
  if (roomStart) for (const p of M.rectangle(roomStart,cursor)) grid.append(svg('rect',{x:p.x*size,y:p.y*size,width:size,height:size,class:'preview'}));
  grid.append(svg('rect',{x:cursor.x*size+1,y:cursor.y*size+1,width:size-2,height:size-2,class:'cursor'}));
  $('cursor').textContent=`Cell ${cursor.x}, ${cursor.y}`;
}
function render() {
  $('title').textContent=doc.name;mark(); $('undo').disabled=!undo.length; $('redo').disabled=!redo.length;
  cursor={x:Math.min(cursor.x,doc.width-1),y:Math.min(cursor.y,doc.height-1)};
  const paint=$('paint-area').value;$('paint-area').replaceChildren();option($('paint-area'),'','Unassigned');
  doc.areas.forEach(a=>option($('paint-area'),a.id,a.name));$('paint-area').value=doc.areas.some(a=>a.id===paint)?paint:'';
  for (const [collection,type] of [['areas','area'],['markers','marker']]) {
    $(collection).replaceChildren();
    for (const item of doc[collection]) {
      const button=document.createElement('button');button.textContent=type==='area'?item.name:`${badges[item.type]} · ${item.name}`;
      if (selection.type===type&&selection.id===item.id) button.className='selected';
      button.onclick=()=>{if(!guard())return;selection={type,id:item.id};if(type==='marker'){cursor={x:item.x,y:item.y};} render();};$(collection).append(button);
    }
  }
  inspector();draw();validation();help();
}
function validation() {
  const result=M.validate(doc,reference);$('validation').replaceChildren();
  $('validation-summary').textContent=`Validation · ${result.errors.length} errors · ${result.warnings.length} warnings`;
  for(const type of ['errors','warnings']) for(const message of result[type]) {
    const p=document.createElement('p');p.className=type==='errors'?'error':'warning';p.textContent=message;$('validation').append(p);
  }
  if(!result.errors.length&&!result.warnings.length){const p=document.createElement('p');p.className='ok';p.textContent='No issues found.';$('validation').append(p);}
}
function help() {
  const tool=$('tool').value;
  const hints={select:'Click a cell to inspect its area or marker. Use the lists to select stacked markers.',room:'Drag from one corner to the opposite corner. Keyboard: Enter at each corner.',
    floor:'Drag to paint floor cells. Choose a paint area to group them into a named room.',corridor:'Drag to draw a connected, one-cell-wide passage.',door:'Click or drag to place walkable door cells. Door states and locks are author notes only.',
    wall:'Drag to place solid wall blocks. Markers on replaced cells are removed; Undo restores them.',
    secret_door:'Drag to place secret doors (purple S). Connectivity assumes they can be discovered and opened; no discovery simulation is included.',
    assign:'Drag over existing floor to assign the chosen area; choose Unassigned to clear it.',erase:'Drag to remove cells and any markers on them. Undo restores the whole stroke.',marker:'Click a floor cell to place the chosen marker type, then edit its details.'};
  $('tool-help').textContent=hints[tool]+' Arrow keys move the grid cursor; Enter uses the tool. Escape cancels drawing.';
}
function unique(list,prefix) {let n=1;while(doc[list].some(i=>i.id===`${prefix}_${n}`))n++;return `${prefix}_${n}`;}
function useCell(point) {
  if(!guard())return;
  const tool=$('tool').value;
  if(tool==='select') {
    const markers=doc.markers.filter(m=>m.x===point.x&&m.y===point.y),cell=doc.cells.find(c=>c.x===point.x&&c.y===point.y);
    if(markers.length) {select('marker',markers[0].id);if(markers.length>1)say(`${markers.length} markers here; use the marker list to select each one.`);}
    else if(cell?.area_id)select('area',cell.area_id);else select('map');
  } else if(tool==='marker') attempt(()=>{
    const type=$('marker-type').value,id=unique('markers',type);
    const next=M.marker(doc,{id,name:`New ${type}`,type,x:point.x,y:point.y,description:'',author_notes:'',reference:'',target_document:'',target_location:''});
    selection={type:'marker',id};commit(next,'Marker placed. Add its name, notes and references in the inspector.');
  });
  else if(tool==='room') {
    if(!roomStart){roomStart={...point};draw();say('Room first corner set. Move to the opposite corner and press Enter.');}
    else {const start=roomStart;roomStart=null;attempt(()=>commit(M.paint(doc,M.rectangle(start,point),'floor',$('paint-area').value),'Room drawn.'));}
  } else attempt(()=>commit(M.paint(doc,[point],tool,$('paint-area').value),'Cell updated.'));
}
function point(event) {
  const p=new DOMPoint(event.clientX,event.clientY).matrixTransform(grid.getScreenCTM().inverse());
  const x=Math.floor(p.x/size),y=Math.floor(p.y/size);
  return x>=0&&y>=0&&x<doc.width&&y<doc.height?{x,y}:null;
}
grid.onpointerdown=event=>{
  if(event.button!==0||!guard())return;
  const p=point(event);if(!p)return;event.preventDefault();grid.focus();cursor=p;roomStart=null;
  if(['select','marker'].includes($('tool').value)){useCell(p);return;}
  stroke={tool:$('tool').value,area:$('paint-area').value,start:p,last:p,points:new Map([[`${p.x},${p.y}`,p]])};grid.setPointerCapture(event.pointerId);draw();
};
grid.onpointermove=event=>{
  const p=point(event);if(!p)return;cursor=p;
  if(stroke){for(const cell of M.line(stroke.last,p))stroke.points.set(`${cell.x},${cell.y}`,cell);stroke.last=p;draw();}
  else {
    const outline=grid.querySelector('.cursor');
    if(outline){outline.setAttribute('x',p.x*size+1);outline.setAttribute('y',p.y*size+1);}
    $('cursor').textContent=`Cell ${p.x}, ${p.y}`;
  }
};
grid.onpointerup=event=>{
  if(!stroke)return;
  const current=stroke;stroke=null;
  if(grid.hasPointerCapture(event.pointerId))grid.releasePointerCapture(event.pointerId);
  attempt(()=>{
    const points=current.tool==='room'?M.rectangle(current.start,current.last):[...current.points.values()];
    const next=M.paint(doc,points,current.tool==='room'?'floor':current.tool,current.area);
    const removed=doc.markers.length-next.markers.length;
    commit(next,removed?`Removed ${removed} marker(s) from erased or blocked cells. Undo restores them.`:'Drawing applied.');
  });draw();
};
grid.onpointercancel=()=>{stroke=null;draw();};
grid.onkeydown=event=>{
  const moves={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
  if(moves[event.key]){event.preventDefault();const [x,y]=moves[event.key];cursor={x:Math.max(0,Math.min(doc.width-1,cursor.x+x)),y:Math.max(0,Math.min(doc.height-1,cursor.y+y))};draw();}
  if(event.key==='Enter'||event.key===' '){event.preventDefault();useCell(cursor);}
  if(event.key==='Escape'){stroke=null;roomStart=null;draw();say('Drawing cancelled.');}
};
for (const type of ['entrance','exit']) $('place-'+type).onclick=()=>{
  if(!guard())return;stroke=null;roomStart=null;$('tool').value='marker';$('marker-type').value=type;help();draw();say(`Click a walkable cell to place the dungeon ${type}.`);
};
$('tool').onchange=()=>{stroke=null;roomStart=null;help();draw();};$('zoom').onchange=draw;
$('map-details').onclick=()=>select('map');
$('add-area').onclick=()=>{if(!guard())return;attempt(()=>{const id=unique('areas','area');const next=M.area(doc,{id,name:'New area',description:'',author_notes:''});selection={type:'area',id};commit(next,'Area added. Name it, apply the details, then draw its floor.');$('paint-area').value=id;});};
function history(back) {
  if(!guard())return;const source=back?undo:redo,target=back?redo:undo;if(!source.length)return;
  target.push(doc);doc=source.pop();stroke=null;roomStart=null;render();say(back?'Undone.':'Redone.');
}
$('undo').onclick=()=>history(true);$('redo').onclick=()=>history(false);
document.addEventListener('keydown',event=>{
  if(['INPUT','TEXTAREA','SELECT'].includes(event.target.tagName))return;
  if((event.ctrlKey||event.metaKey)&&event.key.toLowerCase()==='z'){event.preventDefault();history(!event.shiftKey);}
});
$('new').onclick=()=>replace(M.empty(),'New dungeon. Add an area and draw its floor.');
$('practice').onclick=()=>replace(DungeonSamples.practice(),'Practice map loaded. This example is not campaign canon.');
$('hideout').onclick=()=>replace(DungeonSamples.hideout(),'Goblin starter loaded. Area notes are provided; draw the layout yourself.');
$('load').onclick=()=>{$('file').value='';$('file').click();};
$('file').onchange=async()=>{const file=$('file').files[0];if(!file)return;try{if(file.size>5*1024*1024)throw new Error('Maximum file size is 5 MB.');const next=M.parse(await file.text());replace(next,`Loaded ${file.name}.`);}catch(error){say(`Load rejected; current dungeon kept.\n${error.message}`);}};
$('save').onclick=()=>{if(!guard())return;attempt(()=>{
  const source=M.serialize(doc),url=URL.createObjectURL(new Blob([source],{type:'application/json'}));
  const a=document.createElement('a');a.href=url;a.download=`${doc.id}.json`;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
  saved=source;mark();say('JSON download requested. Check your downloads folder; existing files are not overwritten.');
});};
$('reference-load').onclick=()=>{$('reference-file').value='';$('reference-file').click();};
$('reference-file').onchange=async()=>{
  const file=$('reference-file').files[0];if(!file)return;
  try {
    if(file.size>5*1024*1024)throw new Error('Maximum file size is 5 MB.');
    const next=AdventureModel.parse(await file.text());reference=next;
    $('reference-location').replaceChildren();next.locations.forEach(l=>option($('reference-location'),l.id,l.name));
    $('reference-status').textContent=`Reference: ${next.name} (${next.id}). Read-only; not included in dungeon export.`;
    // Do not redraw the inspector: an external reference must not erase form edits.
    const selected=doc.markers.find(m=>m.id===selection.id);
    $('use-reference').disabled=!(selection.type==='marker'&&selected&&M.linkTypes.includes(selected.type)&&next.locations.length);
    validation();say(`Loaded overland reference ${file.name}.`);
  }catch(error){say(`Reference rejected; previous reference kept.\n${error.message}`);}
};
$('use-reference').onclick=()=>{
  if(!reference||selection.type!=='marker'||!$('reference-location').value)return;
  form.elements.namedItem('target_document').value=reference.id;form.elements.namedItem('target_location').value=$('reference-location').value;
  pending=true;mark();say('Destination filled in. Apply details to save it to the marker.');
};
window.addEventListener('beforeunload',event=>{if(dirty()){event.preventDefault();event.returnValue='';}});
render();
