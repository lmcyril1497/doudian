var fs = require('fs');
var h = fs.readFileSync('D:/demo/index.html', 'utf8');
var lines = h.split('\n');
for (var i = 0; i < lines.length; i++) {
  if (lines[i].includes('header-logo') && (lines[i].includes('svg') || lines[i].includes('img'))) {
    console.log('Line ' + (i+1) + ': ' + lines[i].trim().substring(0, 120));
  }
}
