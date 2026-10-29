/* Built-in starters also exported as ordinary JSON by generate-samples.cjs. */
(function(root) {
  const M = typeof module !== 'undefined' ? require('./model.js') : root.DungeonModel;
  function practice() {
    let d = {...M.empty(),id:'practice_dungeon',name:'Practice dungeon — not campaign canon',width:24,height:18,
      author_notes:'A disposable drawing exercise. This layout is not the goblin hideout or any canonical Azure Mines location.'};
    for (const [id,name] of [['entry','Entry room'],['hall','Practice hall'],['side_room','Side room']])
      d = M.area(d,{id,name,description:'',author_notes:'Practice area only.'});
    d = M.paint(d,M.rectangle({x:2,y:6},{x:6,y:10}),'floor','entry');
    d = M.paint(d,M.rectangle({x:12,y:5},{x:18,y:11}),'floor','hall');
    d = M.paint(d,M.rectangle({x:13,y:1},{x:17,y:3}),'floor','side_room');
    d = M.paint(d,M.line({x:7,y:8},{x:11,y:8}),'corridor');
    d = M.paint(d,[{x:9,y:8}],'door');
    d = M.paint(d,[{x:15,y:4}],'secret_door');
    d = M.paint(d,M.line({x:12,y:12},{x:18,y:12}),'wall');
    d = M.marker(d,{id:'entry_marker',name:'Practice entrance',type:'entrance',x:2,y:8,description:'',author_notes:'Local return link demonstrates destination IDs.',reference:'',target_document:d.id,target_location:'entry'});
    d = M.marker(d,{id:'practice_conversation',name:'Conversation placeholder',type:'conversation',x:15,y:8,description:'',author_notes:'Reference is a placeholder, not a supplied Ink story.',reference:'practice.ink#hello',target_document:'',target_location:''});
    d = M.feature(d,{...M.featureDefaults('locked_door',12,8,'hall_door'),edge:'west'});
    d = M.feature(d,{...M.featureDefaults('chest',17,6,'practice_chest'),rotation:90});
    d = M.feature(d,M.featureDefaults('table',14,10,'practice_table'));
    d = M.feature(d,{...M.featureDefaults('stairs_down',16,2,'practice_stairs'),target_document:d.id,target_location:'entry'});
    d = M.terrain(d,M.rectangle({x:3,y:6},{x:4,y:7}),'water');
    d = M.terrain(d,[{x:17,y:10},{x:18,y:10}],'rubble');
    return d;
  }
  function hideout() {
    let d = {...M.empty(),id:'goblin_hideout_draft',name:'Goblin hideout — layout to author',
      author_notes:'AUTHOR-ONLY starter from docs/world-bible.md v0.2. No geometry or connections supplied: the 29 October hand-drawn map is not in this repository. Draw the agreed layout yourself. Names below are area labels, not newly named NPCs. The former rubbish area is now the family area; shaft and Midden Grub placement remain unresolved.'};
    for (const [id,name,notes] of [
      ['entrance','Cave entrance','Place an entrance and link it to dales_road / cave_approach after drawing.'],
      ['patrol_corridor','Patrol corridor','New non-loyal goblin patrol; a social bypass is possible. Exact connections remain to be authored.'],
      ['family_area','Goblin family area','Women and children are non-combatants. Two bugbear-aligned loyalists are combatants. This replaces the former rubbish-tip area.'],
      ['common_cave','Common cave','Shared kitchen / sleeping area; displaced former chief lives among ordinary goblins.'],
      ['bugbear_chamber','Bugbear chamber','Bugbear overlord; captive human mage needs rescue and care. No personal names invented.']])
      d = M.area(d,{id,name,description:'',author_notes:notes});
    return d;
  }
  const api = {practice,hideout};
  if (typeof module !== 'undefined') module.exports = api; else root.DungeonSamples = api;
})(globalThis);
