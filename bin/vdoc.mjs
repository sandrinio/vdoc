#!/usr/bin/env node

import { readFileSync, writeFileSync, mkdirSync, unlinkSync, rmSync, existsSync, readdirSync, statSync } from 'fs';
import { join, dirname, resolve } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SKILLS = resolve(__dirname, '..', 'skills');
const CWD = process.cwd();

// ── Platform mappings ──────────────────────────────────────────────

const PLATFORMS = {
  claude: {
    files: [
      { src: 'claude/SKILL.md', dest: '.claude/skills/vdoc/SKILL.md' },
      { src: 'claude/references/doc-template.md', dest: '.claude/skills/vdoc/references/doc-template.md' },
      { src: 'claude/references/manifest-schema.json', dest: '.claude/skills/vdoc/references/manifest-schema.json' },
    ],
  },
  cursor: {
    files: [
      { src: 'cursor/vdoc.mdc', dest: '.cursor/rules/vdoc.mdc' },
      { src: 'cursor/vdoc-command.md', dest: '.cursor/commands/vdoc.md' },
    ],
  },
  windsurf: {
    files: [
      { src: 'windsurf/vdoc.md', dest: '.windsurf/rules/vdoc.md' },
      { src: 'windsurf/vdoc-workflow.md', dest: '.windsurf/workflows/vdoc.md' },
    ],
  },
  vscode: {
    files: [
      { src: 'vscode/vdoc.instructions.md', dest: '.github/instructions/vdoc.instructions.md' },
      { src: 'vscode/vdoc.prompt.md', dest: '.github/prompts/vdoc.prompt.md' },
      { src: 'vscode/copilot-instructions.md', dest: '.github/copilot-instructions.md', inject: true },
    ],
  },
  continue: {
    files: [
      { src: 'continue/vdoc.md', dest: '.continue/rules/vdoc.md' },
      { src: 'continue/vdoc-command.md', dest: '.continue/prompts/vdoc-command.md' },
    ],
  },
  cline: {
    files: [
      { src: 'cline/vdoc.md', dest: '.clinerules/vdoc.md' },
      { src: 'cline/vdoc-workflow.md', dest: '.clinerules/workflows/vdoc.md' },
    ],
  },
  gemini: {
    files: [
      { src: 'gemini/vdoc.toml', dest: '.gemini/commands/vdoc.toml' },
      { src: 'gemini/GEMINI.md', dest: 'GEMINI.md', inject: true },
    ],
  },
  jetbrains: {
    files: [
      { src: 'jetbrains-ai/vdoc.md', dest: '.aiassistant/rules/vdoc.md' },
    ],
  },
  junie: {
    files: [
      { src: 'junie/guidelines.md', dest: '.junie/guidelines.md', inject: true },
    ],
  },
  agents: {
    files: [
      { src: 'agents/AGENTS.md', dest: 'AGENTS.md', inject: true },
    ],
  },
};

const MARKER_START = '<!-- vdoc:start -->';
const MARKER_END = '<!-- vdoc:end -->';

// ── Helpers ────────────────────────────────────────────────────────

function copyFile(src, dest) {
  const srcPath = join(SKILLS, src);
  const destPath = join(CWD, dest);
  mkdirSync(dirname(destPath), { recursive: true });
  writeFileSync(destPath, readFileSync(srcPath));
  console.log(`  ✓ ${dest}`);
}

function injectFile(src, dest) {
  const srcPath = join(SKILLS, src);
  const destPath = join(CWD, dest);
  const content = readFileSync(srcPath, 'utf8');

  // Ensure content has markers
  const injection = content.includes(MARKER_START)
    ? content
    : `${MARKER_START}\n${content}\n${MARKER_END}`;

  if (existsSync(destPath)) {
    const existing = readFileSync(destPath, 'utf8');
    const startIdx = existing.indexOf(MARKER_START);
    const endIdx = existing.indexOf(MARKER_END);

    if (startIdx !== -1 && endIdx !== -1) {
      // Replace between markers
      const before = existing.slice(0, startIdx);
      const after = existing.slice(endIdx + MARKER_END.length);
      writeFileSync(destPath, before + injection + after);
    } else {
      // Append
      writeFileSync(destPath, existing.trimEnd() + '\n\n' + injection + '\n');
    }
  } else {
    mkdirSync(dirname(destPath), { recursive: true });
    writeFileSync(destPath, injection.endsWith('\n') ? injection : injection + '\n');
  }
  console.log(`  ✓ ${dest} (injected)`);
}

function removeFile(dest) {
  const destPath = join(CWD, dest);
  if (existsSync(destPath)) {
    unlinkSync(destPath);
    console.log(`  ✓ removed ${dest}`);
    cleanEmptyDirs(dirname(destPath));
    return true;
  }
  return false;
}

function uninjectFile(dest) {
  const destPath = join(CWD, dest);
  if (!existsSync(destPath)) return false;

  const content = readFileSync(destPath, 'utf8');
  const startIdx = content.indexOf(MARKER_START);
  const endIdx = content.indexOf(MARKER_END);

  if (startIdx === -1 || endIdx === -1) return false;

  const before = content.slice(0, startIdx);
  const after = content.slice(endIdx + MARKER_END.length);
  const remaining = (before + after).trim();

  if (remaining.length === 0) {
    unlinkSync(destPath);
    console.log(`  ✓ removed ${dest}`);
    cleanEmptyDirs(dirname(destPath));
  } else {
    writeFileSync(destPath, remaining + '\n');
    console.log(`  ✓ cleaned vdoc section from ${dest}`);
  }
  return true;
}

function cleanEmptyDirs(dir) {
  // Don't clean above CWD
  if (!dir.startsWith(CWD) || dir === CWD) return;
  try {
    const entries = readdirSync(dir);
    if (entries.length === 0) {
      rmSync(dir);
      cleanEmptyDirs(dirname(dir));
    }
  } catch { /* ignore */ }
}

function isDirEmpty(dir) {
  try {
    return readdirSync(dir).length === 0;
  } catch { return true; }
}

// ── Commands ───────────────────────────────────────────────────────

function install(platform) {
  const config = PLATFORMS[platform];
  if (!config) {
    console.error(`Unknown platform: ${platform}`);
    console.error(`Supported: ${Object.keys(PLATFORMS).join(', ')}`);
    process.exit(1);
  }

  console.log(`\nvdoc → installing for ${platform}\n`);

  for (const file of config.files) {
    if (file.inject) {
      injectFile(file.src, file.dest);
    } else {
      copyFile(file.src, file.dest);
    }
  }

  console.log(`\nDone. Open your AI tool and type: /vdoc init\n`);
}

function uninstall() {
  console.log(`\nvdoc → removing all skill files\n`);

  let removed = 0;

  for (const [, config] of Object.entries(PLATFORMS)) {
    for (const file of config.files) {
      if (file.inject) {
        if (uninjectFile(file.dest)) removed++;
      } else {
        if (removeFile(file.dest)) removed++;
      }
    }
  }

  // Also clean .claude/skills/vdoc/ directory if it exists
  const claudeSkillDir = join(CWD, '.claude', 'skills', 'vdoc');
  if (existsSync(claudeSkillDir)) {
    rmSync(claudeSkillDir, { recursive: true });
    cleanEmptyDirs(dirname(claudeSkillDir));
  }

  if (removed === 0) {
    console.log('  No vdoc files found.');
  }

  console.log(`\nDone. Your vdocs/ documentation folder was kept intact.\n`);
}

// ── Main ───────────────────────────────────────────────────────────

const [,, command, platform] = process.argv;

if (command === 'install' && platform) {
  install(platform);
} else if (command === 'uninstall') {
  uninstall();
} else {
  console.log(`
vdoc v3.0.0 — Documentation skills for AI coding agents

Usage:
  npx vdoc install <platform>   Install skill files for a platform
  npx vdoc uninstall             Remove all vdoc skill files (keeps vdocs/)

Platforms:
  ${Object.keys(PLATFORMS).join(', ')}
`);
}
