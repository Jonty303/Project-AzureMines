const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const M=require('../model.js'), samples=require('../samples.js');
const mark=(overrides={})=>({id:'test_marker',name:'Test',type:'secret',x:2,y:6,description:'',author_notes:'',reference:'',target_document:'',target_location:'',...overrides});

test('v1 and v2 files upgrade without losing authored content',()=>{
  for(const version of [1,2]) {
    const old=M.paint(M.empty(),[{x:1,y:1}],'floor');old.schema_version=version;delete old.features;
    old.author_notes='Preserve my notes';
    assert.deepEqual(M.parse(JSON.stringify(old)),{...old,schema_version:3,features:[]});
  }
});

test('every supported feature has original symbol artwork and sensible defaults',()=>{
  const symbols=require('../symbols.js');assert.deepEqual(Object.keys(symbols).sort(),[...M.featureTypes].sort());
  let doc=M.paint(M.empty(),[{x:1,y:1}],'floor');
  for(const kind of M.featureTypes) {
    const next=M.feature(doc,M.featureDefaults(kind,1,1,'symbol'));assert.equal(M.validate(next).errors.length,0);
    assert.deepEqual(M.parse(M.serialize(next)),next);
  }
});
test('features preserve floor and painting terrain preserves object layers and notes',()=>{
  let doc=M.paint(M.empty(),[{x:1,y:1},{x:2,y:1}],'floor');
  doc=M.feature(doc,M.featureDefaults('chest',1,1,'chest'));
  const cells=JSON.stringify(doc.cells);doc=M.terrain(doc,[{x:1,y:1}],'water');
  assert.equal(doc.features.length,2);assert.equal(JSON.stringify(doc.cells),cells);
  const water=doc.features.find(f=>f.kind==='water');
  doc=M.feature(doc,{...water,author_notes:'Deep pool'},water.id);
  assert.equal(M.terrain(doc,[{x:1,y:1}],'water').features.find(f=>f.kind==='water').author_notes,'Deep pool');
  doc=M.terrain(doc,[{x:1,y:1}],'rubble');assert.ok(doc.features.some(f=>f.kind==='chest'));assert.equal(doc.features.length,2);
  doc=M.terrain(doc,[{x:1,y:1}],'clear_features');assert.equal(doc.features.length,0);assert.equal(JSON.stringify(doc.cells),cells);
});
test('opposing edges share a slot; movement-blocking edges affect connectivity',()=>{
  let doc=M.paint(M.empty(),[{x:1,y:1},{x:2,y:1}],'floor');
  doc=M.feature(doc,{...M.featureDefaults('bars',1,1,'bars'),edge:'east'});
  assert.ok(M.validate(doc).warnings.some(w=>w.includes('2 disconnected')));
  assert.throws(()=>M.feature(doc,{...M.featureDefaults('door',2,1,'duplicate'),edge:'west'}),/occupied/);
  doc=M.feature(doc,{...doc.features[0],blocks_movement:false},'bars');
  assert.ok(!M.validate(doc).warnings.some(w=>w.includes('disconnected')));
});
test('objects can rotate; invalid placement, rotation and duplicate IDs rejected atomically',()=>{
  const doc=M.paint(M.empty(),[{x:1,y:1},{x:2,y:1}],'floor'),before=M.serialize(doc);
  for(const change of [{rotation:45},{edge:'north'},{x:9},{locked:'yes'}])
    assert.throws(()=>M.feature(doc,{...M.featureDefaults('chest',1,1,'chest'),...change}));
  assert.throws(()=>M.feature(doc,{...M.featureDefaults('door',1,1,'door'),rotation:90}));
  const rotated=M.feature(doc,{...M.featureDefaults('chest',1,1,'chest'),rotation:270});
  assert.equal(rotated.features[0].rotation,270);
  assert.throws(()=>M.feature(rotated,M.featureDefaults('bed',2,1,'chest')),/duplicate/);
  assert.equal(M.serialize(doc),before);
});
test('terrain paints fail atomically on missing ground; chasms block routes',()=>{
  let doc=M.paint(M.empty(),M.line({x:1,y:1},{x:3,y:1}),'floor');const before=M.serialize(doc);
  assert.throws(()=>M.terrain(doc,[{x:1,y:1},{x:0,y:0}],'water'));assert.equal(M.serialize(doc),before);
  doc=M.terrain(doc,[{x:2,y:1}],'chasm');assert.ok(M.validate(doc).warnings.some(w=>w.includes('2 disconnected')));
  doc=M.paint(doc,[{x:2,y:1}],'wall');assert.equal(doc.features.length,0);
});
test('feature links follow local renames and area deletion',()=>{
  let doc=M.area(M.paint(M.empty(),[{x:1,y:1}],'floor'),{id:'entry',name:'Entry',description:'',author_notes:''});
  doc=M.feature(doc,{...M.featureDefaults('stairs_up',1,1,'stairs'),target_document:doc.id,target_location:'entry'});
  doc=M.area(doc,{...doc.areas[0],id:'entry_new'},'entry');assert.equal(doc.features[0].target_location,'entry_new');
  doc=M.metadata(doc,{id:'map_new'});assert.equal(doc.features[0].target_document,'map_new');
  doc=M.removeArea(doc,'entry_new');assert.equal(doc.features[0].target_document,'');
});
test('walls block connectivity and markers; secret doors connect',()=>{
  let doc=M.paint(M.empty(),M.line({x:1,y:1},{x:3,y:1}),'floor');
  doc=M.paint(doc,[{x:2,y:1}],'wall');
  assert.ok(M.validate(doc).warnings.some(w=>w.includes('2 disconnected')));
  assert.throws(()=>M.marker(doc,mark({x:2,y:1})));
  doc=M.paint(doc,[{x:2,y:1}],'secret_door');
  assert.ok(!M.validate(doc).warnings.some(w=>w.includes('disconnected')));
  doc=M.marker(doc,mark({x:2,y:1}));
  const blocked=M.paint(doc,[{x:2,y:1}],'wall');assert.equal(blocked.markers.length,0);
  assert.equal(doc.markers.length,1);
  assert.deepEqual(M.parse(M.serialize(blocked)),blocked);
});

test('practice sample validates, round-trips and has no warnings',()=>{
  const doc=samples.practice();assert.deepEqual(M.validate(doc),{errors:[],warnings:[]});
  assert.deepEqual(M.parse(M.serialize(doc)),doc);
});
test('generated schema and both JSON samples match source',()=>{
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(__dirname,'../dungeon.schema.json'),'utf8')),M.schema);
  for(const [name,build] of Object.entries(samples))assert.deepEqual(M.parse(fs.readFileSync(path.join(__dirname,`../samples/${name}.json`),'utf8')),build());
});
test('goblin starter preserves unknown geometry and family-area direction',()=>{
  const doc=samples.hideout();assert.equal(doc.cells.length,0);assert.equal(doc.markers.length,0);
  assert.equal(M.validate(doc).errors.length,0);assert.ok(M.validate(doc).warnings.length);
  assert.match(doc.areas.find(a=>a.id==='family_area').author_notes,/non-combatants/);
});
test('room and diagonal corridor strokes remain four-way connected',()=>{
  let doc=M.paint(M.empty(),M.rectangle({x:1,y:1},{x:3,y:3}),'floor');
  assert.equal(doc.cells.length,9);
  doc=M.paint(doc,M.line({x:3,y:3},{x:7,y:6}),'corridor');
  assert.ok(!M.validate(doc).warnings.some(w=>w.includes('disconnected')));
  doc=M.paint(doc,[{x:15,y:15}],'floor');
  assert.ok(M.validate(doc).warnings.some(w=>w.includes('2 disconnected')));
});
test('area rename updates cells and local destination links',()=>{
  const doc=samples.practice();const next=M.area(doc,{...doc.areas[0],id:'renamed'},'entry');
  assert.ok(next.cells.some(c=>c.area_id==='renamed'));assert.equal(next.markers[0].target_location,'renamed');
  assert.equal(doc.areas[0].id,'entry');
  const renamed=M.metadata(next,{id:'renamed_dungeon'});assert.equal(renamed.markers[0].target_document,'renamed_dungeon');
});
test('area deletion retains geometry and clears assignments and local links',()=>{
  const doc=samples.practice(),next=M.removeArea(doc,'entry');assert.equal(next.cells.length,doc.cells.length);
  assert.ok(!next.cells.some(c=>c.area_id==='entry'));assert.equal(next.markers[0].target_document,'');
});
test('erase removes markers; assign preserves tile types',()=>{
  let doc=M.marker(samples.practice(),mark());
  doc=M.paint(doc,[{x:2,y:6}],'assign','hall');assert.equal(doc.cells.find(c=>c.x===2&&c.y===6).tile,'floor');
  doc=M.paint(doc,[{x:2,y:6}],'erase');assert.ok(!doc.markers.some(m=>m.id==='test_marker'));
});
test('reject malformed imports, unsupported versions, extra fields and bad types',()=>{
  for(const value of ['{','null','[]','{}'])assert.throws(()=>M.parse(value));
  for(const mutate of [d=>d.schema_version=99,d=>d.document_type='region',d=>d.width=7,d=>d.height=65,
    d=>d.cells[0].x=.5,d=>d.cells[0].tile='lava',d=>d.areas[0].id='../bad',d=>d.extra=true,d=>d.name='  ',d=>delete d.cells]) {
    const doc=samples.practice();mutate(doc);assert.ok(M.validate(doc).errors.length);assert.throws(()=>M.parse(JSON.stringify(doc)));
  }
});
test('duplicate IDs, cells, missing areas and off-floor markers are rejected',()=>{
  for(const mutate of [d=>d.areas.push(d.areas[0]),d=>d.markers.push(d.markers[0]),d=>d.cells.push(d.cells[0]),
    d=>d.cells[0].area_id='missing',d=>d.markers[0].x=0,d=>d.cells[0].x=30]) {
    const doc=samples.practice();mutate(doc);assert.ok(M.validate(doc).errors.length);
  }
});
test('invalid edits and shrinking grid are atomic',()=>{
  const doc=samples.practice(),before=M.serialize(doc);
  assert.throws(()=>M.metadata(doc,{width:8}));assert.throws(()=>M.paint(doc,[{x:-1,y:0}],'floor'));
  assert.throws(()=>M.area(doc,{...doc.areas[0],id:'hall'},'entry'));
  assert.throws(()=>M.marker(doc,mark({x:0,y:0})));
  assert.equal(M.serialize(doc),before);
});
test('links require pairs, local targets and suitable marker type',()=>{
  const doc=samples.practice();
  assert.throws(()=>M.marker(doc,mark({target_document:'region'})));
  assert.throws(()=>M.marker(doc,mark({target_document:doc.id,target_location:'entry'})));
  assert.throws(()=>M.marker(doc,mark({type:'stairs',target_document:doc.id,target_location:'missing'})));
});
test('external reference verification is optional and reports missing destinations',()=>{
  const doc=M.marker(samples.practice(),mark({type:'exit',target_document:'dales_road',target_location:'cave_approach'}));
  assert.ok(M.validate(doc).warnings.some(w=>w.includes('external destination')));
  assert.ok(!M.validate(doc,{id:'dales_road',locations:[{id:'cave_approach'}]}).warnings.length);
  assert.ok(M.validate(doc,{id:'dales_road',locations:[]}).warnings.some(w=>w.includes('not found')));
});
test('stairs do not silently connect separated floor groups',()=>{
  let doc=samples.practice();doc=M.paint(doc,[{x:22,y:16}],'floor','hall');
  doc=M.marker(doc,mark({type:'stairs',x:22,y:16,target_document:doc.id,target_location:'entry'}));
  assert.ok(M.validate(doc).warnings.some(w=>w.includes('disconnected')));
});
