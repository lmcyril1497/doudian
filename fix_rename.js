const fs = require('fs');
const p = 'D:/demo/index.html';
let c = fs.readFileSync(p, 'utf8');
c = c.replace("'单个体➕备案', '单个独➕备案'", "'个体备案', '个独备案'");
fs.writeFileSync(p, c, 'utf8');
console.log('Done');