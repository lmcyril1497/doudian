var fs = require('fs');
var h = fs.readFileSync('D:/demo/index.html', 'utf8');

// Replace login logo SVG div with img
h = h.replace(/<div class="ls-logo">[\s\S]*?<\/div><\/div><\/div>/, '<img class="ls-logo" src="logo.png" alt="信拓"></div></div>');

// Replace header logo SVG div with img
h = h.replace(/<div class="header-logo">[\s\S]*?<\/div>/, '<img class="header-logo" src="logo.png" alt="信拓">');

fs.writeFileSync('D:/demo/index.html', h);
console.log('Done');
console.log('ls-logo img:', h.includes('class="ls-logo" src="logo.png"'));
console.log('header-logo img:', h.includes('class="header-logo" src="logo.png"'));
