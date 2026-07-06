// Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
const fs = require('fs');
const path = require('path');

const hookDir = path.resolve(__dirname, '..', '.git', 'hooks');
const hookFile = path.resolve(hookDir, 'pre-commit');

const hookContent = `#!/bin/sh
# Git pre-commit hook to validate EMF generated edits
node scripts-spp/check-generated-edits.js
`;

if (!fs.existsSync(path.resolve(__dirname, '..', '.git'))) {
  console.error('Error: Not a git repository or root folder mismatch.');
  process.exit(1);
}

if (!fs.existsSync(hookDir)) {
  fs.mkdirSync(hookDir, { recursive: true });
}

try {
  fs.writeFileSync(hookFile, hookContent, { mode: 0o755 });
  try {
    fs.chmodSync(hookFile, '755');
  } catch (chmodErr) {
    // Ignore on Windows if chmod fails
  }
  console.log('Successfully installed git pre-commit hook at:', hookFile);
} catch (e) {
  console.error('Failed to write git pre-commit hook:', e.message);
  process.exit(1);
}
