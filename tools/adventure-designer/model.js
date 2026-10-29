/* Shared by the offline editor and Node tests. No game dependencies. */
(function (root) {
  'use strict';
  const id = {type: 'string', pattern: '^[a-z0-9_]+$'};
  const text = {type: 'string'};
  const name = {type: 'string', minLength: 1, pattern: '\\S'};
  const object = properties => ({type: 'object', properties,
    required: Object.keys(properties), additionalProperties: false});
  const schema = {
    $schema: 'https://json-schema.org/draft/2020-12/schema',
    title: 'Azure Mines authoring region v1',
    ...object({schema_version: {const: 1}, id, name, author_notes: text,
      starting_location: {anyOf: [id, {type: 'null'}]},
      locations: {type: 'array', items: object({id, name,
        kind: {enum: ['settlement', 'wilderness', 'dungeon', 'interior']},
        description: text, author_notes: text,
        discovery: {enum: ['known', 'hidden']},
        position: object({x: {type: 'number', minimum: 80, maximum: 1120},
          y: {type: 'number', minimum: 50, maximum: 750}})})},
      routes: {type: 'array', items: object({id, name, from: id, to: id,
        bidirectional: {type: 'boolean'}, description: text, author_notes: text,
        discovery: {enum: ['known', 'hidden']}})}
    })
  };
  // Deliberately implements only keywords used above. JSON Schema tools can use
  // the generated region.schema.json; graph semantics are checked below.
  function shape(value, rule, path, errors) {
    const fail = message => errors.push(`${path}: ${message}`);
    if (rule.anyOf) {
      if (!rule.anyOf.some(r => {const e = []; shape(value, r, path, e); return !e.length;})) fail('invalid value');
      return;
    }
    if ('const' in rule && value !== rule.const) fail(`must equal ${rule.const}`);
    if (rule.enum && !rule.enum.includes(value)) fail(`must be one of ${rule.enum.join(', ')}`);
    if (rule.type) {
      const ok = rule.type === 'array' ? Array.isArray(value) : rule.type === 'null' ? value === null :
        rule.type === 'object' ? value !== null && typeof value === 'object' && !Array.isArray(value) :
        typeof value === rule.type && (rule.type !== 'number' || Number.isFinite(value));
      if (!ok) {fail(`must be ${rule.type}`); return;}
    }
    if (rule.type === 'object') {
      for (const key of rule.required) if (!Object.hasOwn(value, key)) fail(`missing ${key}`);
      for (const key of Object.keys(value)) {
        if (!Object.hasOwn(rule.properties, key)) fail(`unknown field ${key}`);
        else shape(value[key], rule.properties[key], `${path}.${key}`, errors);
      }
    }
    if (rule.type === 'array') value.forEach((v, i) => shape(v, rule.items, `${path}[${i}]`, errors));
    if (rule.pattern && !new RegExp(rule.pattern).test(value)) fail('invalid text format');
    if (rule.minLength && value.length < rule.minLength) fail('must not be empty');
    if (rule.minimum !== undefined && value < rule.minimum) fail(`minimum ${rule.minimum}`);
    if (rule.maximum !== undefined && value > rule.maximum) fail(`maximum ${rule.maximum}`);
  }
  function validate(region) {
    const errors = [], warnings = [];
    shape(region, schema, 'region', errors);
    if (errors.length) return {errors, warnings};
    for (const key of ['locations', 'routes']) {
      const seen = new Set();
      for (const item of region[key]) {
        if (seen.has(item.id)) errors.push(`${key}: duplicate id ${item.id}`);
        seen.add(item.id);
      }
    }
    const ids = new Set(region.locations.map(l => l.id));
    if (region.starting_location !== null && !ids.has(region.starting_location)) errors.push('starting_location: missing location');
    const edges = new Set();
    for (const r of region.routes) {
      if (!ids.has(r.from) || !ids.has(r.to)) errors.push(`route ${r.id}: missing endpoint`);
      if (r.from === r.to) errors.push(`route ${r.id}: self connection`);
      for (const [a, b] of r.bidirectional ? [[r.from, r.to], [r.to, r.from]] : [[r.from, r.to]]) {
        const key = `${a}:${b}`;
        if (edges.has(key)) errors.push(`route ${r.id}: duplicate connection ${a} to ${b}`);
        edges.add(key);
      }
      if (r.discovery === 'known' && region.locations.some(l => [r.from, r.to].includes(l.id) && l.discovery === 'hidden'))
        warnings.push(`route ${r.id}: known route touches a hidden location; review disclosure`);
    }
    if (!region.locations.length) warnings.push('Region has no locations.');
    else if (!region.starting_location) warnings.push('Choose a starting location to check reachability.');
    else {
      const reached = new Set([region.starting_location]);
      let size;
      do {
        size = reached.size;
        for (const r of region.routes) {
          if (reached.has(r.from)) reached.add(r.to);
          if (r.bidirectional && reached.has(r.to)) reached.add(r.from);
        }
      } while (size !== reached.size);
      for (const l of region.locations) if (!reached.has(l.id)) warnings.push(`${l.id}: unreachable from start (ignoring discovery)`);
    }
    return {errors, warnings};
  }
  function assertValid(region) {
    const result = validate(region);
    if (result.errors.length) throw new Error(result.errors.join('\n'));
    return region;
  }
  const clone = value => JSON.parse(JSON.stringify(value));
  function change(region, action) {
    const next = clone(region);
    action(next);
    return assertValid(next);
  }
  function upsert(region, collection, item, previousId = null) {
    if (!['locations', 'routes'].includes(collection)) throw new Error('Unknown collection');
    return change(region, next => {
      const index = previousId === null ? -1 : next[collection].findIndex(i => i.id === previousId);
      if (previousId !== null && index === -1) throw new Error('Selection no longer exists');
      if (index === -1) next[collection].push(clone(item));
      else next[collection][index] = clone(item);
      if (collection === 'locations' && previousId !== null && previousId !== item.id) {
        for (const route of next.routes) for (const end of ['from', 'to']) if (route[end] === previousId) route[end] = item.id;
        if (next.starting_location === previousId) next.starting_location = item.id;
      }
    });
  }
  function remove(region, collection, id) {
    if (!['locations', 'routes'].includes(collection)) throw new Error('Unknown collection');
    return change(region, next => {
      next[collection] = next[collection].filter(i => i.id !== id);
      if (collection === 'locations') {
        next.routes = next.routes.filter(r => r.from !== id && r.to !== id);
        if (next.starting_location === id) next.starting_location = null;
      }
    });
  }
  const api = {schema, validate, upsert, remove, change,
    parse: source => assertValid(JSON.parse(source)),
    serialize: region => JSON.stringify(assertValid(region), null, 2) + '\n',
    empty: () => ({schema_version: 1, id: 'new_region', name: 'Untitled region', author_notes: '',
      starting_location: null, locations: [], routes: []})};
  if (typeof module !== 'undefined') module.exports = api;
  else root.AdventureModel = api;
})(globalThis);
