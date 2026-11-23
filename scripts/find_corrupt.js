const fs = require('fs');

function checkFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  const corrupt = [];
  lines.forEach((line, i) => {
    if (line.includes('\ufffd') || /[ÃÂÄ][¡-ÿ]|Ã|Ä‘|Äƒ|Æ°|á»|áº/.test(line)) {
      corrupt.push({ lineNum: i + 1, text: line.trim() });
    }
  });
  return corrupt;
}

const files = [
  'd:/HRM/HRM.Frontend/src/pages/ESS/MyPayslip/index.tsx',
  'd:/HRM/HRM.Frontend/src/pages/ESS/MyPayslip/service.ts',
  'd:/HRM/HRM.Frontend/src/pages/HR/Payroll/index.tsx',
  'd:/HRM/HRM.Frontend/src/pages/HR/Payroll/service.ts'
];

files.forEach(f => {
  const res = checkFile(f);
  console.log(`${f}: ${res.length} potential mojibake lines`);
  if (res.length > 0 && res.length < 20) {
    res.forEach(r => console.log(`  Line ${r.lineNum}: ${r.text.substring(0, 80)}`));
  }
});
