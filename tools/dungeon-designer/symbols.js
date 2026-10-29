/* Original SVG linework for this editor, not traced or copied chart artwork. */
(function(root){
  const symbols = {
    door:['Doors & barriers','Door','M0 14H9 M19 14H28 M9 9H19V19H9Z'],
    open_doorway:['Doors & barriers','Open doorway','M0 14H8 M20 14H28 M8 10V18 M20 10V18'],
    locked_door:['Doors & barriers','Locked door','M0 14H8 M20 14H28 M8 8H20V20H8Z M12 13V11A2 2 0 0 1 16 11V13 M11 13H17V17H11Z'],
    secret_door:['Doors & barriers','Secret door','M0 14H8 M20 14H28 M18 9C8 4 7 14 14 14S20 24 10 19'],
    bars:['Doors & barriers','Bars / portcullis','M0 10H28 M0 18H28 M4 8V20 M10 8V20 M16 8V20 M22 8V20'],
    window:['Doors & barriers','Window','M0 14H8 M20 14H28 M8 9H20V19H8Z M14 9V19'],
    railing:['Doors & barriers','Railing','M0 14H28 M4 10V18 M10 10V18 M16 10V18 M22 10V18'],
    stairs_up:['Travel','Stairs up','M6 23H22 M7 19H21 M8 15H20 M9 11H19 M10 7H18 M14 6V1 M11 4L14 1L17 4'],
    stairs_down:['Travel','Stairs down','M6 5H22 M7 9H21 M8 13H20 M9 17H19 M10 21H18 M14 22V27 M11 24L14 27L17 24'],
    ladder:['Travel','Ladder','M8 3V25 M20 3V25 M8 6H20 M8 11H20 M8 17H20 M8 22H20'],
    trapdoor:['Travel','Trapdoor','M5 5H23V23H5Z M5 5L21 21 M17 19H20'],
    chest:['Room objects','Chest','M5 10Q14 2 23 10V23H5Z M5 13H23 M12 11H16V16H12Z'],
    bed:['Room objects','Bed','M6 3H22V25H6Z M8 5H20V10H8Z M6 13H22'],
    table:['Room objects','Table','M4 6H24V22H4Z M7 9V19 M21 9V19'],
    cage:['Room objects','Cage','M4 5H24V24H4Z M8 5V24 M14 5V24 M20 5V24 M4 11H24 M4 18H24'],
    altar:['Room objects','Altar','M4 7H24V22H4Z M9 11V17 M6 14H12 M19 11V17 M16 14H22'],
    pillar:['Room objects','Pillar','M23 14A9 9 0 1 1 5 14A9 9 0 1 1 23 14 M19 14A5 5 0 1 1 9 14A5 5 0 1 1 19 14'],
    trap:['Room objects','Trap','M4 14L14 4L24 14L14 24Z M14 9V16 M14 19V20'],
    boulder:['Room objects','Boulder','M4 11L9 4L20 6L25 16L17 24L7 21Z M9 4L11 11L4 11 M20 6L17 14L25 16'],
    stalagmite:['Room objects','Stalagmite','M3 23L9 7L14 23Z M13 23L20 3L25 23Z'],
    water:['Natural features','Water / pool','M2 7Q5 3 9 7T17 7T26 7 M2 14Q5 10 9 14T17 14T26 14 M2 21Q5 17 9 21T17 21T26 21'],
    stream:['Natural features','Stream','M7 0Q19 7 9 14T13 28 M13 0Q25 7 15 14T19 28'],
    waterfall:['Natural features','Waterfall','M2 5H26 M4 5V18 M9 5V22 M14 5V19 M19 5V23 M24 5V18 M3 25Q7 20 11 25T25 25'],
    rubble:['Natural features','Rubble','M3 4L8 3L9 8L4 9Z M17 3L23 5L21 10L16 8Z M11 12L16 14L13 19L8 17Z M2 20L6 19L8 25L3 25Z M20 18L25 21L23 26L18 23Z'],
    chasm:['Natural features','Chasm','M8 0L12 5L7 10L10 16L6 22L9 28 M19 0L16 6L21 12L17 18L22 24L18 28 M12 5L16 6 M10 16L17 18 M9 28L18 28'],
    ledge:['Natural features','Ledge','M0 10Q14 17 28 10 M3 11V19 M8 13V21 M14 14V22 M20 13V21 M25 11V19']
  };
  if(typeof module!=='undefined')module.exports=symbols;else root.DungeonSymbols=symbols;
})(globalThis);
