// Copyright (c) 2026 CEA LIST / Kunal Suri. All rights reserved.
const childProcess = require('child_process');
const fs = require('fs');
const path = require('path');

// Determine base and head SHAs if running in GitHub Actions PR context
const workspace = process.env.GITHUB_WORKSPACE || process.cwd();
const eventPath = process.env.GITHUB_EVENT_PATH;

let gitDiffCommand = 'git diff HEAD --name-only';

if (eventPath && fs.existsSync(eventPath)) {
  try {
    const event = JSON.parse(fs.readFileSync(eventPath, { encoding: 'utf8' }));
    if (event.pull_request && event.pull_request.base && event.pull_request.head) {
      const baseSHA = event.pull_request.base.sha;
      const headSHA = event.pull_request.head.sha;
      gitDiffCommand = `git diff --name-only ${baseSHA}...${headSHA}`;
    }
  } catch (e) {
    console.warn('Failed to parse GitHub event file. Defaulting to local HEAD diff.', e);
  }
}

// 1. Get modified files
let modifiedFiles = [];
try {
  const result = childProcess.execSync(gitDiffCommand, { encoding: 'utf8' });
  modifiedFiles = result.split(/\r?\n/).filter(f => f.trim().length > 0);
} catch (e) {
  console.error('Failed to run git diff command:', e.message);
  process.exit(1);
}

// 2. Check if EMF metamodel source schemas (.ecore or .genmodel) are modified.
// If they are, we assume a legitimate EMF code regeneration has run.
const hasModelChanges = modifiedFiles.some(f => f.endsWith('.ecore') || f.endsWith('.genmodel'));
if (hasModelChanges) {
  console.log('Metamodel schema changes detected (.ecore/.genmodel). Skipping @generated safety checks.');
  process.exit(0);
}

// 3. Scan modified Java files
const javaFiles = modifiedFiles.filter(f => f.endsWith('.java') && fs.existsSync(path.resolve(workspace, f)));
if (javaFiles.length === 0) {
  console.log('No modified Java files detected.');
  process.exit(0);
}

let violations = [];

for (const filePath of javaFiles) {
  const absolutePath = path.resolve(workspace, filePath);
  const fileContent = fs.readFileSync(absolutePath, { encoding: 'utf8' });

  // Only check files that contain @generated annotations
  if (!fileContent.includes('@generated')) {
    continue;
  }

  // Get the diff for this file to know which lines changed
  let diffOutput = '';
  try {
    const diffCmd = gitDiffCommand.includes('...') 
      ? `${gitDiffCommand.replace('--name-only', '')} -- "${filePath}"`
      : `git diff HEAD -U0 -- "${filePath}"`;
    diffOutput = childProcess.execSync(diffCmd, { encoding: 'utf8' });
  } catch (e) {
    console.error(`Failed to get diff for ${filePath}:`, e.message);
    continue;
  }

  // Parse modified line numbers from unified diff hunks (e.g. @@ -12,3 +15,5 @@)
  const modifiedLines = [];
  const lines = diffOutput.split(/\r?\n/);
  for (const line of lines) {
    if (line.startsWith('@@')) {
      const match = line.match(/@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@/);
      if (match) {
        const startLine = parseInt(match[1], 10);
        const count = match[2] ? parseInt(match[2], 10) : 1;
        for (let i = 0; i < count; i++) {
          modifiedLines.push(startLine + i);
        }
      }
    }
  }

  if (modifiedLines.length === 0) {
    continue;
  }

  // Check the nearest preceding comment block for each modified line in the file
  const fileLines = fileContent.split(/\r?\n/);
  for (const lineNum of modifiedLines) {
    const idx = lineNum - 1; // 0-indexed line index
    if (idx >= fileLines.length) continue;

    // Check if the modified line itself is a comment or blank line (we ignore modifications to comments)
    const trimmedLine = fileLines[idx].trim();
    if (trimmedLine.startsWith('*') || trimmedLine.startsWith('/*') || trimmedLine.startsWith('//') || trimmedLine === '') {
      continue;
    }

    // Scan upwards to find the nearest preceding javadoc or comment block
    let commentLines = [];
    let insideJavadoc = false;
    let foundPrecedingJavadoc = false;

    for (let scanIdx = idx - 1; scanIdx >= 0; scanIdx--) {
      const scanLine = fileLines[scanIdx].trim();
      
      // Stop searching if we hit another class declaration or method definition body closing brace
      // to avoid scanning across method boundaries.
      if (scanLine.includes('}') && !insideJavadoc) {
        break;
      }

      if (scanLine.endsWith('*/')) {
        insideJavadoc = true;
        commentLines.unshift(scanLine);
        continue;
      }
      if (scanLine.startsWith('/**') || scanLine.startsWith('/*')) {
        commentLines.unshift(scanLine);
        foundPrecedingJavadoc = true;
        break;
      }
      if (insideJavadoc) {
        commentLines.unshift(scanLine);
      } else if (scanLine.startsWith('//')) {
        commentLines.unshift(scanLine);
        foundPrecedingJavadoc = true;
        // Keep scanning consecutive single-line comments
      } else if (scanLine !== '' && !scanLine.startsWith('@')) {
        // We hit actual code before a comment block. Stop.
        break;
      }
    }

    if (foundPrecedingJavadoc && commentLines.length > 0) {
      const commentText = commentLines.join('\n');
      if (commentText.includes('@generated') && !commentText.includes('@generated NOT')) {
        violations.push({
          file: filePath,
          line: lineNum,
          content: trimmedLine,
          comment: commentLines.map(c => c.trim()).join(' ')
        });
      }
    }
  }
}

if (violations.length > 0) {
  console.error('\x1b[31m%s\x1b[0m', 'ERROR: Direct modifications to @generated EMF blocks detected!');
  console.error('\x1b[33m%s\x1b[0m', 'Manual changes inside generated methods/classes will be overwritten.');
  console.error('To resolve this, change the preceding comment Javadoc from "@generated" to "@generated NOT".\n');
  
  for (const v of violations) {
    console.error(`- \x1b[36m${v.file}:${v.line}\x1b[0m`);
    console.error(`  Code:    ${v.content}`);
    console.error(`  Javadoc: ${v.comment}\n`);
  }
  process.exit(1);
}

console.log('All @generated checks passed successfully.');
process.exit(0);
