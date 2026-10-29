const fs = require('node:fs');
const path = require('node:path');
const M = require('./model.js');
const samples = require('./samples.js');
fs.mkdirSync(path.join(__dirname,'samples'),{recursive:true});
fs.writeFileSync(path.join(__dirname,'dungeon.schema.json'),JSON.stringify(M.schema,null,2)+'\n');
for (const [name,build] of Object.entries(samples)) fs.writeFileSync(path.join(__dirname,'samples',`${name}.json`),M.serialize(build()));
