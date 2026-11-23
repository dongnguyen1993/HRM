const fs = require('fs');
const data = fs.readFileSync('d:/HRM/scripts/test_api_preview.pdf');
const str = data.toString('latin1');
const pageMatches = str.match(/\/Type\s*\/Page[^s]/g) || [];
console.log('API Preview PDF Page count:', pageMatches.length);
const mediaBoxes = str.match(/\/MediaBox\s*\[\s*([\d\.\s]+)\s*\]/g) || [];
console.log('MediaBoxes:', mediaBoxes);
