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
  const schema = {$schema: 'https://json-schema.org/draft/2020-12/schema', title: 'Azure Mines dungeon authoring v2',
    ...object({schema_version: {const: 2}, document_type: {const: 'dungeon'}, id: ID, name, author_notes: text,
      width: integer(8, 64), height: integer(8, 64),
      areas: array(object({id: ID, name, description: text, author_notes: text}), 256),
      cells: array(object({x: integer(0, 63), y: integer(0, 63),
        tile: {enum: ['floor', 'corridor', 'door', 'secret_door', 'wall']}, area_id: optionalID}), 4096),
      markers: array(object({id: ID, name, type: {enum: markerTypes}, x: integer(0, 63), y: integer(0, 63),
        description: text, author_notes: text, reference: text,
        target_document: optionalID, target_location: optionalID}), 1024)})};
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
  function validate(doc, region = null) {
    const errors = [], warnings = [];
    shape(doc, schema, 'dungeon', errors);
    if (errors.length) return {errors, warnings};
    for (const list of ['areas', 'markers']) {
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
    for (const marker of doc.markers) {
      if (!walkable(cells.get(key(marker.x, marker.y)))) errors.push(`marker ${marker.id}: must be on a floor, corridor, door or secret door`);
      if (!!marker.target_document !== !!marker.target_location) errors.push(`marker ${marker.id}: provide both destination IDs or neither`);
      if (!linkTypes.includes(marker.type) && (marker.target_document || marker.target_location)) errors.push(`marker ${marker.id}: only entrance, exit, stairs and passage markers may have destinations`);
      if (marker.target_document === doc.id && !areas.has(marker.target_location)) errors.push(`marker ${marker.id}: missing local destination area ${marker.target_location}`);
      else if (marker.target_document) {
        if (region && marker.target_document === region.id) {
          if (!region.locations.some(l => l.id === marker.target_location)) warnings.push(`marker ${marker.id}: location not found in loaded overland reference`);
        } else if (marker.target_document !== doc.id) warnings.push(`marker ${marker.id}: external destination not verified (load its overland region to check it)`);
      }
      if (linkTypes.includes(marker.type) && !marker.target_document) warnings.push(`marker ${marker.id}: destination not set`);
      if (['npc', 'encounter', 'conversation'].includes(marker.type) && !marker.reference.trim()) warnings.push(`marker ${marker.id}: content reference not set`);
    }
    if (errors.length) return {errors, warnings};
    for (const area of doc.areas) if (!doc.cells.some(c => c.area_id === area.id)) warnings.push(`area ${area.id}: no cells assigned`);
    const traversable = new Map([...cells].filter(([,cell]) => walkable(cell)));
    if (!traversable.size) warnings.push('No walkable layout drawn yet.');
    else {
      // Four-way adjacency, ignoring locks, secrets, and transitions to other maps.
      const unseen = new Set(traversable.keys()); let components = 0;
      while (unseen.size) {
        components++; const first = unseen.values().next().value, queue = [cells.get(first)]; unseen.delete(first);
        for (let i = 0; i < queue.length; i++) {
          const c = queue[i];
          for (const [x, y] of [[c.x-1,c.y],[c.x+1,c.y],[c.x,c.y-1],[c.x,c.y+1]]) {
            const k = key(x,y); if (unseen.delete(k)) queue.push(cells.get(k));
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
    });
  }
  function area(doc, item, previousId = null) {
    return change(doc, next => {
      const index = previousId === null ? -1 : next.areas.findIndex(a => a.id === previousId);
      if (previousId !== null && index < 0) throw new Error('Area not found');
      if (index < 0) next.areas.push(clone(item)); else next.areas[index] = clone(item);
      if (previousId !== null && previousId !== item.id) {
        next.cells.forEach(c => {if (c.area_id === previousId) c.area_id = item.id;});
        next.markers.forEach(m => {if (m.target_document === next.id && m.target_location === previousId) m.target_location = item.id;});
      }
    });
  }
  function removeArea(doc, id) {
    return change(doc, next => {
      next.areas = next.areas.filter(a => a.id !== id);
      next.cells.forEach(c => {if (c.area_id === id) c.area_id = '';});
      next.markers.forEach(m => {if (m.target_document === next.id && m.target_location === id) {m.target_document = ''; m.target_location = '';}});
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
      if (doc.id !== next.id) next.markers.forEach(m => {if (m.target_document === doc.id) m.target_document = next.id;});
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
  const api = {schema, markerTypes, linkTypes, validate, change, paint, area, removeArea, marker, metadata, rectangle, line,
    parse: source => {
      const doc = JSON.parse(source);
      // v2 adds wall and secret-door tiles; all v1 records otherwise map directly.
      if (doc && doc.schema_version === 1) doc.schema_version = 2;
      return assert(doc);
    }, serialize: doc => JSON.stringify(assert(doc),null,2)+'\n',
    empty: () => ({schema_version:2,document_type:'dungeon',id:'new_dungeon',name:'Untitled dungeon',author_notes:'',width:32,height:24,areas:[],cells:[],markers:[]})};
  if (typeof module !== 'undefined') module.exports = api; else root.DungeonModel = api;
})(globalThis);
