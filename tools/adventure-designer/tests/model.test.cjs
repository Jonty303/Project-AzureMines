const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const M = require('../model.js');
const sample = () => M.parse(fs.readFileSync(path.join(__dirname, '../samples/dales_road.json'), 'utf8'));

test('sample validates and round-trips every field without warnings', () => {
  const region = sample();
  assert.deepEqual(M.validate(region), {errors: [], warnings: []});
  assert.deepEqual(M.parse(M.serialize(region)), region);
});
test('published JSON schema matches validator source', () => {
  assert.deepEqual(JSON.parse(fs.readFileSync(path.join(__dirname, '../region.schema.json'))), M.schema);
});
test('add, edit, connect, rename, delete, save and load', () => {
  let r = sample();
  r = M.upsert(r, 'locations', {...r.locations[0], id: 'new_place', name: 'New place'});
  r = M.upsert(r, 'routes', {...r.routes[0], id: 'new_route', from: 'seabrook', to: 'new_place'});
  r = M.upsert(r, 'locations', {...r.locations[0], id: 'seabrook_renamed'}, 'seabrook');
  assert.equal(r.starting_location, 'seabrook_renamed');
  assert.equal(r.routes[0].from, 'seabrook_renamed');
  assert.equal(r.routes.at(-1).from, 'seabrook_renamed');
  r = M.remove(r, 'locations', 'seabrook_renamed');
  assert.equal(r.starting_location, null);
  assert.ok(!r.routes.some(route => route.from === 'seabrook_renamed' || route.to === 'seabrook_renamed'));
  assert.deepEqual(M.parse(M.serialize(r)), r);
});
test('invalid updates are atomic', () => {
  const r = sample(), before = M.serialize(r);
  assert.throws(() => M.upsert(r, 'locations', {...r.locations[0], id: 'harrowford'}, 'seabrook'), /duplicate id/);
  assert.equal(M.serialize(r), before);
});
test('reject malformed imports, versions, missing fields, unknown fields and bad types', () => {
  for (const source of ['{', 'null', '[]', '{}']) assert.throws(() => M.parse(source));
  for (const mutate of [r => r.schema_version = 2, r => delete r.name, r => r.extra = 1,
    r => r.locations[0].id = '../bad', r => r.locations[0].name = '  ',
    r => r.locations[0].position.x = 2000, r => r.routes[0].bidirectional = 'false',
    r => r.locations[0].discovery = 'public', r => r.locations = null]) {
    const r = sample(); mutate(r); assert.ok(M.validate(r).errors.length); assert.throws(() => M.parse(JSON.stringify(r)));
  }
});
test('reject dangling refs, duplicate IDs, self routes and overlapping directions', () => {
  for (const mutate of [r => r.starting_location = 'missing', r => r.routes[0].to = 'missing',
    r => r.locations.push(r.locations[0]), r => r.routes.push(r.routes[0]),
    r => r.routes[0].to = r.routes[0].from,
    r => r.routes.push({...r.routes[0], id: 'reverse', from: r.routes[0].to, to: r.routes[0].from})]) {
    const r = sample(); mutate(r); assert.ok(M.validate(r).errors.length);
  }
});
test('reachability respects direction and disclosure is a warning', () => {
  const r = sample(); r.routes[0].bidirectional = false; r.starting_location = 'harrowford';
  assert.ok(M.validate(r).warnings.some(w => w.includes('seabrook: unreachable')));
  r.routes[2].discovery = 'known';
  assert.ok(M.validate(r).warnings.some(w => w.includes('hidden location')));
  assert.equal(M.validate(r).errors.length, 0);
});
test('opposite one-way routes allowed; removing route preserves locations', () => {
  let r = sample(); r.routes[0].bidirectional = false;
  r = M.upsert(r, 'routes', {...r.routes[0], id: 'return', from: r.routes[0].to, to: r.routes[0].from});
  r = M.remove(r, 'routes', 'return');
  assert.equal(r.locations.length, 5);
  assert.equal(M.validate(r).errors.length, 0);
});
test('nonfinite coordinates rejected', () => {
  const r = sample(); r.locations[0].position.x = Infinity;
  assert.ok(M.validate(r).errors.length);
});
