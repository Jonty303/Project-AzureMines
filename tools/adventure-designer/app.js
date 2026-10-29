'use strict';
const M = AdventureModel;
const $ = id => document.getElementById(id);
const regionForm = $('region-form'), itemForm = $('item-form'), graph = $('graph');
let region = M.empty(), selection = null, dirty = false, drag = null;
const pendingForms = new Set();
const field = (form, name) => form.elements.namedItem(name);
const say = message => { $('status').textContent = message; };
const unsaved = () => dirty || pendingForms.size > 0;
const discard = () => !unsaved() || confirm('Discard unsaved changes, including unapplied form edits?');
function mark() { $('dirty').textContent = unsaved() ? 'Unsaved changes' : 'No unsaved changes'; }
for (const form of [regionForm, itemForm]) form.addEventListener('input', () => { pendingForms.add(form); mark(); });
function options(select, entries, empty = false) {
  select.replaceChildren();
  if (empty) select.add(new Option('Not set', ''));
  entries.forEach(item => select.add(new Option(item.name, item.id)));
}
function svg(tag, attributes = {}, text) {
  const element = document.createElementNS('http://www.w3.org/2000/svg', tag);
  Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));
  if (text !== undefined) element.textContent = text;
  return element;
}
function choose(collection, id) {
  if (pendingForms.size && !confirm('Discard unapplied form edits?')) return;
  selection = {collection, id}; pendingForms.clear(); render();
}
function renderGraph() {
  graph.replaceChildren();
  const defs = svg('defs'), marker = svg('marker', {id: 'arrow', viewBox: '0 0 10 10', refX: 9, refY: 5,
    markerWidth: 7, markerHeight: 7, orient: 'auto-start-reverse'});
  marker.append(svg('path', {d: 'M 0 0 L 10 5 L 0 10 z', fill: '#81a6b9'})); defs.append(marker); graph.append(defs);
  for (const route of region.routes) {
    const a = region.locations.find(l => l.id === route.from).position;
    const b = region.locations.find(l => l.id === route.to).position;
    const dx = b.x - a.x, dy = b.y - a.y;
    const scale = Math.min(0.45, 1 / Math.max(Math.abs(dx) / 78, Math.abs(dy) / 32));
    const coords = {x1: a.x + dx * scale, y1: a.y + dy * scale, x2: b.x - dx * scale, y2: b.y - dy * scale};
    const group = svg('g');
    group.append(svg('title', {}, `${route.name}: ${route.from} ${route.bidirectional ? '↔' : '→'} ${route.to}`));
    group.append(svg('line', {...coords, class: `edge ${route.discovery} ${selection?.collection === 'routes' && selection.id === route.id ? 'selected' : ''}`,
      ...(!route.bidirectional ? {'marker-end': 'url(#arrow)'} : {})}));
    group.append(svg('line', {...coords, class: 'edge-hit'}));
    group.addEventListener('click', () => choose('routes', route.id)); graph.append(group);
  }
  for (const location of region.locations) {
    const {x, y} = location.position;
    const group = svg('g', {class: `node ${location.discovery} ${selection?.collection === 'locations' && selection.id === location.id ? 'selected' : ''}`, transform: `translate(${x},${y})`});
    group.append(svg('title', {}, location.name));
    group.append(svg('rect', {x: -76, y: -30, width: 152, height: 60, rx: 8}));
    group.append(svg('text', {'text-anchor': 'middle', y: -2}, location.name.length > 17 ? location.name.slice(0, 16) + '…' : location.name));
    group.append(svg('text', {'text-anchor': 'middle', y: 18, class: 'kind'}, `${location.id === region.starting_location ? 'START · ' : ''}${location.discovery}`));
    group.addEventListener('pointerdown', event => {
      if (event.button !== 0 || pendingForms.size) {if (pendingForms.size) say('Apply or discard form edits before dragging.'); return;}
      event.preventDefault();
      const point = graphPoint(event);
      drag = {id: location.id, x: point.x, y: point.y, original: {...location.position}, moved: false};
      graph.setPointerCapture(event.pointerId);
    });
    graph.append(group);
  }
}
function graphPoint(event) {
  return new DOMPoint(event.clientX, event.clientY).matrixTransform(graph.getScreenCTM().inverse());
}
graph.addEventListener('pointermove', event => {
  if (!drag) return;
  const point = graphPoint(event), location = region.locations.find(l => l.id === drag.id);
  if (Math.hypot(point.x - drag.x, point.y - drag.y) > 3) drag.moved = true;
  if (!drag.moved) return;
  location.position = {x: Math.round(Math.max(80, Math.min(1120, drag.original.x + point.x - drag.x))),
    y: Math.round(Math.max(50, Math.min(750, drag.original.y + point.y - drag.y)))};
  renderGraph();
});
function finishDrag(cancelled) {
  if (!drag) return;
  if (cancelled) region.locations.find(l => l.id === drag.id).position = drag.original;
  else {if (drag.moved) dirty = true; selection = {collection: 'locations', id: drag.id};}
  drag = null; render();
}
graph.addEventListener('pointerup', () => finishDrag(false));
graph.addEventListener('pointercancel', () => finishDrag(true));
function render() {
  $('region-title').textContent = region.name; mark();
  if (!pendingForms.has(regionForm)) {
    options(field(regionForm, 'starting_location'), region.locations, true);
    for (const key of ['id', 'name', 'author_notes', 'starting_location']) field(regionForm, key).value = region[key] ?? '';
  }
  for (const collection of ['locations', 'routes']) {
    $(collection).replaceChildren();
    for (const item of region[collection]) {
      const button = document.createElement('button');
      button.textContent = collection === 'routes' ? `${item.name} · ${item.bidirectional ? '↔' : '→'}` : item.name;
      if (selection?.collection === collection && selection.id === item.id) button.className = 'selected';
      button.addEventListener('click', () => choose(collection, item.id)); $(collection).append(button);
    }
  }
  $('add-route').disabled = region.locations.length < 2;
  $('hint').hidden = !!selection; itemForm.hidden = !selection;
  if (selection) {if (!pendingForms.has(itemForm)) fillInspector();}
  else $('editor-title').textContent = 'Inspector';
  renderGraph();
  const report = M.validate(region); $('validation').replaceChildren();
  for (const type of ['errors', 'warnings']) for (const message of report[type]) {
    const p = document.createElement('p'); p.className = type === 'errors' ? 'error' : 'warning'; p.textContent = message; $('validation').append(p);
  }
  if (!report.errors.length && !report.warnings.length) {
    const p = document.createElement('p'); p.className = 'ok'; p.textContent = 'No issues found.'; $('validation').append(p);
  }
}
function fillInspector() {
  const {collection, id} = selection;
  const item = region[collection].find(i => i.id === id);
  $('editor-title').textContent = collection === 'locations' ? 'Location details' : 'Route details';
  for (const group of itemForm.querySelectorAll('[data-fields]')) {
    group.hidden = group.dataset.fields !== collection;
    for (const input of group.querySelectorAll('input,select')) input.disabled = group.hidden;
  }
  for (const key of ['from', 'to']) options(field(itemForm, key), region.locations);
  for (const key of ['id', 'name', 'description', 'author_notes', 'discovery']) field(itemForm, key).value = item[key];
  if (collection === 'locations') {
    field(itemForm, 'kind').value = item.kind;
    for (const axis of ['x', 'y']) field(itemForm, axis).value = item.position[axis];
  } else {
    for (const key of ['from', 'to']) field(itemForm, key).value = item[key];
    field(itemForm, 'bidirectional').checked = item.bidirectional;
  }
}
function attempt(action) { try {action();} catch (error) {say(error.message);} }
regionForm.addEventListener('submit', event => {
  event.preventDefault(); attempt(() => {
    const data = new FormData(regionForm);
    region = M.change(region, next => {
      for (const key of ['id', 'name', 'author_notes']) next[key] = data.get(key);
      next.starting_location = data.get('starting_location') || null;
    });
    dirty = true; pendingForms.delete(regionForm); render(); say('Region updated. Save JSON to keep your changes.');
  });
});
itemForm.addEventListener('submit', event => {
  event.preventDefault(); attempt(() => {
    const data = new FormData(itemForm), item = {};
    for (const key of ['id', 'name', 'description', 'author_notes', 'discovery']) item[key] = data.get(key);
    if (selection.collection === 'locations') {
      item.kind = data.get('kind');
      item.position = {x: data.get('x') === '' ? NaN : Number(data.get('x')), y: data.get('y') === '' ? NaN : Number(data.get('y'))};
    } else {item.from = data.get('from'); item.to = data.get('to'); item.bidirectional = field(itemForm, 'bidirectional').checked;}
    region = M.upsert(region, selection.collection, item, selection.id);
    selection.id = item.id; dirty = true; pendingForms.delete(itemForm); render(); say('Item updated. Save JSON to keep your changes.');
  });
});
function unique(collection, prefix) {let i = 1; while (region[collection].some(item => item.id === `${prefix}_${i}`)) i++; return `${prefix}_${i}`;}
function add(collection) {
  if (pendingForms.size && !confirm('Discard unapplied form edits?')) return;
  attempt(() => {
    const item = {id: unique(collection, collection === 'locations' ? 'location' : 'route'), name: collection === 'locations' ? 'New location' : 'New route', description: '', author_notes: '', discovery: 'known'};
    if (collection === 'locations') Object.assign(item, {kind: 'wilderness', position: {x: 200 + (region.locations.length % 5) * 180, y: 200 + (Math.floor(region.locations.length / 5) % 4) * 140}});
    else {
      const from = selection?.collection === 'locations' ? selection.id : region.locations[0].id;
      const to = region.locations.find(l => l.id !== from && !region.routes.some(r =>
        (r.from === from && r.to === l.id) || (r.bidirectional && r.from === l.id && r.to === from)));
      if (!to) throw new Error('No unused connection from this location. Select a different source location, or edit an existing route.');
      Object.assign(item, {from, to: to.id,
        bidirectional: !region.routes.some(r => r.from === to.id && r.to === from)});
    }
    region = M.upsert(region, collection, item); selection = {collection, id: item.id}; dirty = true; pendingForms.clear(); render();
    say('Added. Edit the details, then Apply item.');
  });
}
$('add-location').onclick = () => add('locations'); $('add-route').onclick = () => add('routes');
$('delete').onclick = () => {
  if (!selection || !confirm(selection.collection === 'locations' ? 'Delete this location and all its connected routes? Unapplied edits will be discarded.' : 'Delete this route? Unapplied edits will be discarded.')) return;
  region = M.remove(region, selection.collection, selection.id); selection = null; dirty = true; pendingForms.clear(); render(); say('Deleted.');
};
$('new').onclick = () => {if (discard()) {region = M.empty(); selection = null; dirty = false; pendingForms.clear(); render(); say('New region.');}};
$('load').onclick = () => {$('file').value = ''; $('file').click();};
$('file').onchange = async () => {
  const file = $('file').files[0]; if (!file) return;
  try {
    if (file.size > 5 * 1024 * 1024) throw new Error('File exceeds the 5 MB editor limit.');
    const next = M.parse(await file.text());
    if (!discard()) return;
    region = next; selection = null; dirty = false; pendingForms.clear(); render(); say(`Loaded ${file.name}.`);
  } catch (error) {say(`Load rejected; current region kept.\n${error.message}`);}
};
$('save').onclick = () => attempt(() => {
  if (pendingForms.size) throw new Error('Apply form edits before saving, or reselect an item to discard them.');
  const url = URL.createObjectURL(new Blob([M.serialize(region)], {type: 'application/json'}));
  const anchor = document.createElement('a'); anchor.href = url; anchor.download = `${region.id}.json`;
  document.body.append(anchor); anchor.click(); anchor.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  dirty = false; mark(); say('JSON download requested. Check your downloads folder; existing files are not overwritten automatically.');
});
window.addEventListener('beforeunload', event => {if (unsaved()) {event.preventDefault(); event.returnValue = '';}});
render();
