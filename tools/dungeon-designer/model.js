/* Authoring definitions only. Shared by the offline UI and Node tests. */
(function (root) {
  'use strict';
  const ID = {type: 'string', pattern: '^[a-z0-9_]+$', maxLength: 100};
  const optionalID = {type: 'string', pattern: '^[a-z0-9_]*$', maxLength: 100};
  const text = {type: 'string', maxLength: 20000};
  const name = {type: 'string', pattern: '\\S', maxLength: 200};
  const integer = (minimum, maximum) => ({type: 'integer', minimum, maximum});
  const object = properties => ({type: 'object', properties, required: Object.keys(properties), additionalProperties: false});
  const array = (items, maxItems) => ({type: 'array', items, maxItems});
  const markerTypes = ['entrance', 'exit', 'stairs', 'passage', 'npc', 'encounter', 'secret', 'conversation'];
  const linkTypes = ['entrance', 'exit', 'stairs', 'passage'];
  const edgeTypes = ['door', 'open_doorway', 'locked_door', 'secret_door', 'bars', 'window', 'railing'];
  const natureTypes = ['water', 'stream', 'waterfall', 'rubble', 'chasm', 'ledge'];
  const travelTypes = ['stairs_up', 'stairs_down', 'ladder', 'trapdoor'];
  const featureTypes = [...edgeTypes, ...travelTypes, 'chest', 'bed', 'table', 'cage', 'altar', 'pillar', 'trap', 'boulder', 'stalagmite', ...natureTypes];
  const schema = {$schema: 'https://json-schema.org/draft/2020-12/schema', title: 'Azure Mines dungeon authoring v3',
    ...object({schema_version: {const: 3}, document_type: {const: 'dungeon'}, id: ID, name, author_notes: text,
      width: integer(8, 64), height: integer(8, 64),
      areas: array(object({id: ID, name, description: text, author_notes: text}), 256),
      cells: array(object({x: integer(0, 63), y: integer(0, 63),
        tile: {enum: ['floor', 'corridor', 'door', 'secret_door', 'wall']}, area_id: optionalID}), 4096),
      markers: array(object({id: ID, name, type: {enum: markerTypes}, x: integer(0, 63), y: integer(0, 63),
        description: text, author_notes: text, reference: text,
        target_document: optionalID, target_location: optionalID}), 1024),
      features: array(object({id: ID, name, kind: {enum: featureTypes}, x: integer(0,63), y: integer(0,63),
        edge: {enum: ['center','north','east','south','west']}, rotation: {enum: [0,90,180,270]},
        locked: {type:'boolean'}, concealed: {type:'boolean'}, blocks_movement: {type:'boolean'}, provides_cover: {type:'boolean'},
        description: text, author_notes: text, target_document: optionalID, target_location: optionalID}), 4096)})};
  function shape(value, rule, path, errors) {
    const fail = message => errors.push(`${path}: ${message}`);
    if ('const' in rule && value !== rule.const) fail(`must be ${rule.const}`);
    if (rule.enum && !rule.enum.includes(value)) fail(`must be one of ${rule.enum.join(', ')}`);
    if (rule.type) {
      const valid = rule.type === 'array' ? Array.isArray(value) : rule.type === 'object' ?
        value !== null && typeof value === 'object' && !Array.isArray(value) : rule.type === 'integer' ?
          Number.isSafeInteger(value) : typeof value === rule.type;
      if (!valid) {fail(`must be ${rule.type}`); return;}
    }
    if (rule.type === 'object') {
      for (const key of rule.required) if (!Object.hasOwn(value, key)) fail(`missing ${key}`);
      for (const key of Object.keys(value)) {
        if (!Object.hasOwn(rule.properties, key)) fail(`unknown field ${key}`);
        else shape(value[key], rule.properties[key], `${path}.${key}`, errors);
      }
    }
    if (rule.type === 'array') {
      if (value.length > rule.maxItems) {fail(`maximum ${rule.maxItems} items`); return;}
      value.forEach((item, index) => shape(item, rule.items, `${path}[${index}]`, errors));
    }
    if (rule.pattern && !new RegExp(rule.pattern).test(value)) fail('invalid text format');
    if (rule.maxLength && value.length > rule.maxLength) fail(`maximum ${rule.maxLength} characters`);
    if (rule.minimum !== undefined && value < rule.minimum) fail(`minimum ${rule.minimum}`);
    if (rule.maximum !== undefined && value > rule.maximum) fail(`maximum ${rule.maximum}`);
  }
  const walkable = cell => !!cell && cell.tile !== 'wall';
  const key = (x, y) => `${x},${y}`;
  const clone = value => JSON.parse(JSON.stringify(value));
  function edgeKey(f) {
    if (f.edge === 'north') return `h:${f.x},${f.y}`;
    if (f.edge === 'south') return `h:${f.x},${f.y+1}`;
    if (f.edge === 'west') return `v:${f.x},${f.y}`;
    if (f.edge === 'east') return `v:${f.x+1},${f.y}`;
    return `${natureTypes.includes(f.kind)?'terrain':'object'}:${f.x},${f.y}`;
  }
  function featureDefaults(kind, x, y, id) {
    if (!featureTypes.includes(kind)) throw new Error('Unknown symbol');
    return {id,name:kind.replaceAll('_',' '),kind,x,y,edge:edgeTypes.includes(kind)?'north':'center',rotation:0,
      locked:kind==='locked_door',concealed:['secret_door','trap'].includes(kind),
      blocks_movement:['bars','window','railing','pillar','boulder','stalagmite','chasm'].includes(kind),
      provides_cover:['bars','window','railing','table','altar','pillar','boulder'].includes(kind),
      description:'',author_notes:'',target_document:'',target_location:''};
  }
  function validate(doc, region = null) {
    const errors = [], warnings = [];
    shape(doc, schema, 'dungeon', errors);
    if (errors.length) return {errors, warnings};
    for (const list of ['areas', 'markers', 'features']) {
      const ids = new Set();
      for (const item of doc[list]) {if (ids.has(item.id)) errors.push(`${list}: duplicate ID ${item.id}`); ids.add(item.id);}
    }
    const areas = new Set(doc.areas.map(a => a.id)), cells = new Map();
    for (const cell of doc.cells) {
      const k = key(cell.x, cell.y);
      if (cells.has(k)) errors.push(`duplicate cell ${k}`);
      cells.set(k, cell);
      if (cell.x >= doc.width || cell.y >= doc.height) errors.push(`cell ${k}: outside grid`);
      if (cell.area_id && !areas.has(cell.area_id)) errors.push(`cell ${k}: missing area ${cell.area_id}`);
    }
    const slots = new Set(), blockedCells = new Set(), blockedEdges = new Set();
    for (const f of doc.features) {
      if (!walkable(cells.get(key(f.x,f.y)))) errors.push(`feature ${f.id}: place on drawn walkable ground, or its edge`);
      if (edgeTypes.includes(f.kind) === (f.edge === 'center')) errors.push(`feature ${f.id}: incorrect center/edge placement`);
      if (f.edge !== 'center' && f.rotation !== 0) errors.push(`feature ${f.id}: use edge to orient an edge symbol; rotation must be 0`);
      const slot = edgeKey(f);
      if (slots.has(slot)) errors.push(`feature ${f.id}: occupied feature position ${slot}`);
      slots.add(slot);
      if (f.blocks_movement) {if (f.edge==='center') blockedCells.add(key(f.x,f.y)); else blockedEdges.add(slot);}
    }
    for (const marker of [...doc.markers, ...doc.features]) {
      const isFeature = Object.hasOwn(marker,'kind');
      if (!walkable(cells.get(key(marker.x, marker.y)))) errors.push(`marker ${marker.id}: must be on a floor, corridor, door or secret door`);
      if (!!marker.target_document !== !!marker.target_location) errors.push(`marker ${marker.id}: provide both destination IDs or neither`);
      if (!(isFeature ? travelTypes.includes(marker.kind) : linkTypes.includes(marker.type)) && (marker.target_document || marker.target_location)) errors.push(`item ${marker.id}: only travel symbols and link markers may have destinations`);
      if (marker.target_document === doc.id && !areas.has(marker.target_location)) errors.push(`marker ${marker.id}: missing local destination area ${marker.target_location}`);
      else if (marker.target_document) {
        if (region && marker.target_document === region.id) {
          if (!region.locations.some(l => l.id === marker.target_location)) warnings.push(`marker ${marker.id}: location not found in loaded overland reference`);
        } else if (marker.target_document !== doc.id) warnings.push(`marker ${marker.id}: external destination not verified (load its overland region to check it)`);
      }
      if (linkTypes.includes(marker.type) && !marker.target_document) warnings.push(`marker ${marker.id}: destination not set`);
      if (isFeature && travelTypes.includes(marker.kind) && !marker.target_document) warnings.push(`feature ${marker.id}: destination not set`);
      if (!isFeature && blockedCells.has(key(marker.x,marker.y))) warnings.push(`marker ${marker.id}: on movement-blocking content`);
      if (['npc', 'encounter', 'conversation'].includes(marker.type) && !marker.reference.trim()) warnings.push(`marker ${marker.id}: content reference not set`);
    }
    if (errors.length) return {errors, warnings};
    for (const area of doc.areas) if (!doc.cells.some(c => c.area_id === area.id)) warnings.push(`area ${area.id}: no cells assigned`);
    const traversable = new Map([...cells].filter(([k,cell]) => walkable(cell) && !blockedCells.has(k)));
    if (!traversable.size) warnings.push('No walkable layout drawn yet.');
    else {
      // Four-way adjacency, ignoring locks, secrets, and transitions to other maps.
      const unseen = new Set(traversable.keys()); let components = 0;
      while (unseen.size) {
        components++; const first = unseen.values().next().value, queue = [cells.get(first)]; unseen.delete(first);
        for (let i = 0; i < queue.length; i++) {
          const c = queue[i];
          for (const [x, y] of [[c.x-1,c.y],[c.x+1,c.y],[c.x,c.y-1],[c.x,c.y+1]]) {
            const boundary = x!==c.x ? `v:${Math.max(x,c.x)},${y}` : `h:${x},${Math.max(y,c.y)}`;
            const k = key(x,y); if (!blockedEdges.has(boundary) && unseen.delete(k)) queue.push(cells.get(k));
          }
        }
      }
      if (components > 1) warnings.push(`${components} disconnected floor groups; connect them or document intentional separation.`);
      if (!doc.markers.some(m => m.type === 'entrance')) warnings.push('No entrance marker placed.');
    }
    return {errors, warnings};
  }
  function assert(doc) {const {errors} = validate(doc); if (errors.length) throw new Error(errors.join('\n')); return doc;}
  function change(doc, action) {const next = clone(doc); action(next); return assert(next);}
  function paint(doc, points, tile, areaId = '') {
    if (!['floor', 'corridor', 'door', 'secret_door', 'wall', 'erase', 'assign'].includes(tile)) throw new Error('Unknown drawing tool');
    return change(doc, next => {
      const cells = new Map(next.cells.map(c => [key(c.x,c.y),c]));
      for (const {x,y} of points) {
        if (!Number.isInteger(x) || !Number.isInteger(y) || x < 0 || y < 0 || x >= doc.width || y >= doc.height) throw new Error('Drawing outside grid');
        const k = key(x,y);
        if (tile === 'erase') cells.delete(k);
        else if (tile === 'assign') {if (cells.has(k)) cells.get(k).area_id = areaId;}
        else cells.set(k, {x,y,tile,area_id: areaId});
      }
      next.cells = [...cells.values()].sort((a,b) => a.y-b.y || a.x-b.x);
      next.markers = next.markers.filter(m => walkable(cells.get(key(m.x,m.y))));
      next.features = next.features.filter(f => walkable(cells.get(key(f.x,f.y))));
    });
  }
  function area(doc, item, previousId = null) {
    return change(doc, next => {
      const index = previousId === null ? -1 : next.areas.findIndex(a => a.id === previousId);
      if (previousId !== null && index < 0) throw new Error('Area not found');
      if (index < 0) next.areas.push(clone(item)); else next.areas[index] = clone(item);
      if (previousId !== null && previousId !== item.id) {
        next.cells.forEach(c => {if (c.area_id === previousId) c.area_id = item.id;});
        [...next.markers,...next.features].forEach(m => {if (m.target_document === next.id && m.target_location === previousId) m.target_location = item.id;});
      }
    });
  }
  function removeArea(doc, id) {
    return change(doc, next => {
      next.areas = next.areas.filter(a => a.id !== id);
      next.cells.forEach(c => {if (c.area_id === id) c.area_id = '';});
      [...next.markers,...next.features].forEach(m => {if (m.target_document === next.id && m.target_location === id) {m.target_document = ''; m.target_location = '';}});
    });
  }
  function marker(doc, item, previousId = null) {
    return change(doc, next => {
      const index = previousId === null ? -1 : next.markers.findIndex(m => m.id === previousId);
      if (previousId !== null && index < 0) throw new Error('Marker not found');
      if (index < 0) next.markers.push(clone(item)); else next.markers[index] = clone(item);
    });
  }
  function metadata(doc, values) {
    return change(doc, next => {
      Object.assign(next, values);
      if (doc.id !== next.id) [...next.markers,...next.features].forEach(m => {if (m.target_document === doc.id) m.target_document = next.id;});
    });
  }
  function rectangle(a,b) {
    const points = [];
    for (let y=Math.min(a.y,b.y); y<=Math.max(a.y,b.y); y++) for (let x=Math.min(a.x,b.x); x<=Math.max(a.x,b.x); x++) points.push({x,y});
    return points;
  }
  // Join pointer samples with four-way steps, including fast diagonal drags.
  function line(a,b) {
    const points = [{...a}]; let {x,y} = a;
    while (x !== b.x || y !== b.y) {
      if (x !== b.x) {x += Math.sign(b.x-x); points.push({x,y});}
      if (y !== b.y) {y += Math.sign(b.y-y); points.push({x,y});}
    }
    return points;
  }
  function feature(doc, item, previousId = null) {
    return change(doc,next=>{
      const index = previousId===null ? -1 : next.features.findIndex(f=>f.id===previousId);
      if (previousId!==null && index<0) throw new Error('Feature not found');
      if (index<0) next.features.push(clone(item)); else next.features[index]=clone(item);
    });
  }
  function terrain(doc, points, kind) {
    if (kind!=='clear_features' && !natureTypes.includes(kind)) throw new Error('Unknown terrain');
    return change(doc,next=>{
      for (const p of points) {
        if (kind==='clear_features') {next.features=next.features.filter(f=>f.x!==p.x||f.y!==p.y);continue;}
        if (!walkable(next.cells.find(c=>c.x===p.x&&c.y===p.y))) throw new Error('Paint natural features on existing walkable ground.');
        const old=next.features.find(f=>f.x===p.x&&f.y===p.y&&natureTypes.includes(f.kind));
        if (old?.kind===kind) continue; // repainting must preserve authored notes
        if (old) next.features=next.features.filter(f=>f.id!==old.id);
        let id=`${kind}_${p.x}_${p.y}`,n=1;while(next.features.some(f=>f.id===id))id=`${kind}_${p.x}_${p.y}_${n++}`;
        next.features.push(featureDefaults(kind,p.x,p.y,id));
      }
    });
  }
  const api = {schema, markerTypes, linkTypes, edgeTypes, natureTypes, travelTypes, featureTypes, featureDefaults, feature, terrain, edgeKey, validate, change, paint, area, removeArea, marker, metadata, rectangle, line,
    parse: source => {
      const doc = JSON.parse(source);
      // Preserve old cells, markers and notes; new symbols live in a separate layer.
      if (doc && [1,2].includes(doc.schema_version)) {
        if (Object.hasOwn(doc,'features')) throw new Error('Legacy file has unexpected features field');
        doc.features=[];doc.schema_version=3;
      }
      return assert(doc);
    }, serialize: doc => JSON.stringify(assert(doc),null,2)+'\n',
    empty: () => ({schema_version:3,document_type:'dungeon',id:'new_dungeon',name:'Untitled dungeon',author_notes:'',width:32,height:24,areas:[],cells:[],markers:[],features:[]})};
  if (typeof module !== 'undefined') module.exports = api; else root.DungeonModel = api;
})(globalThis);
