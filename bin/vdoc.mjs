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
      { src: 'claude/references/init-workflow.md', dest: '.claude/skills/vdoc/references/init-workflow.md' },
      { src: 'claude/references/audit-workflow.md', dest: '.claude/skills/vdoc/references/audit-workflow.md' },
    ],
  },
  cursor: {
    files: [
      { src: 'cursor/RULE.md', dest: '.cursor/rules/vdoc/RULE.md' },
      { src: 'cursor/references/init-workflow.md', dest: '.cursor/rules/vdoc/references/init-workflow.md' },
      { src: 'cursor/references/audit-workflow.md', dest: '.cursor/rules/vdoc/references/audit-workflow.md' },
      { src: 'cursor/references/doc-template.md', dest: '.cursor/rules/vdoc/references/doc-template.md' },
      { src: 'cursor/references/manifest-schema.json', dest: '.cursor/rules/vdoc/references/manifest-schema.json' },
      { src: 'cursor/vdoc-command.md', dest: '.cursor/commands/vdoc.md' },
    ],
  },
  windsurf: {
    files: [
      { src: 'windsurf/SKILL.md', dest: '.windsurf/skills/vdoc/SKILL.md' },
      { src: 'windsurf/resources/init-workflow.md', dest: '.windsurf/skills/vdoc/resources/init-workflow.md' },
      { src: 'windsurf/resources/audit-workflow.md', dest: '.windsurf/skills/vdoc/resources/audit-workflow.md' },
      { src: 'windsurf/resources/doc-template.md', dest: '.windsurf/skills/vdoc/resources/doc-template.md' },
      { src: 'windsurf/resources/manifest-schema.json', dest: '.windsurf/skills/vdoc/resources/manifest-schema.json' },
      { src: 'windsurf/vdoc-workflow.md', dest: '.windsurf/workflows/vdoc.md' },
    ],
  },
  vscode: {
    files: [
      { src: 'vscode/SKILL.md', dest: '.github/skills/vdoc/SKILL.md' },
      { src: 'vscode/references/init-workflow.md', dest: '.github/skills/vdoc/references/init-workflow.md' },
      { src: 'vscode/references/audit-workflow.md', dest: '.github/skills/vdoc/references/audit-workflow.md' },
      { src: 'vscode/references/doc-template.md', dest: '.github/skills/vdoc/references/doc-template.md' },
      { src: 'vscode/references/manifest-schema.json', dest: '.github/skills/vdoc/references/manifest-schema.json' },
      { src: 'vscode/vdoc.instructions.md', dest: '.github/instructions/vdoc.instructions.md' },
      { src: 'vscode/vdoc.prompt.md', dest: '.github/prompts/vdoc.prompt.md' },
      { src: 'vscode/copilot-instructions.md', dest: '.github/copilot-instructions.md', inject: true },
    ],
  },
  continue: {
    files: [
      { src: 'continue/vdoc.md', dest: '.continue/rules/vdoc.md' },
      { src: 'continue/vdoc-command.md', dest: '.continue/prompts/vdoc-command.md' },
      { src: 'continue/references/init-workflow.md', dest: '.continue/references/vdoc/init-workflow.md' },
      { src: 'continue/references/audit-workflow.md', dest: '.continue/references/vdoc/audit-workflow.md' },
      { src: 'continue/references/doc-template.md', dest: '.continue/references/vdoc/doc-template.md' },
      { src: 'continue/references/manifest-schema.json', dest: '.continue/references/vdoc/manifest-schema.json' },
    ],
  },
  cline: {
    files: [
      { src: 'cline/vdoc.md', dest: '.clinerules/vdoc.md' },
      { src: 'cline/vdoc-workflow.md', dest: '.clinerules/workflows/vdoc.md' },
      { src: 'cline/references/init-workflow.md', dest: '.clinerules/vdoc/init-workflow.md' },
      { src: 'cline/references/audit-workflow.md', dest: '.clinerules/vdoc/audit-workflow.md' },
      { src: 'cline/references/doc-template.md', dest: '.clinerules/vdoc/doc-template.md' },
      { src: 'cline/references/manifest-schema.json', dest: '.clinerules/vdoc/manifest-schema.json' },
    ],
  },
  gemini: {
    files: [
      { src: 'gemini/vdoc.toml', dest: '.gemini/commands/vdoc.toml' },
      { src: 'gemini/GEMINI.md', dest: 'GEMINI.md', inject: true },
      { src: 'gemini/references/init-workflow.md', dest: '.gemini/vdoc/init-workflow.md' },
      { src: 'gemini/references/audit-workflow.md', dest: '.gemini/vdoc/audit-workflow.md' },
      { src: 'gemini/references/doc-template.md', dest: '.gemini/vdoc/doc-template.md' },
      { src: 'gemini/references/manifest-schema.json', dest: '.gemini/vdoc/manifest-schema.json' },
    ],
  },
  jetbrains: {
    files: [
      { src: 'jetbrains-ai/vdoc.md', dest: '.aiassistant/rules/vdoc.md' },
      { src: 'jetbrains-ai/references/init-workflow.md', dest: '.aiassistant/vdoc/init-workflow.md' },
      { src: 'jetbrains-ai/references/audit-workflow.md', dest: '.aiassistant/vdoc/audit-workflow.md' },
      { src: 'jetbrains-ai/references/doc-template.md', dest: '.aiassistant/vdoc/doc-template.md' },
      { src: 'jetbrains-ai/references/manifest-schema.json', dest: '.aiassistant/vdoc/manifest-schema.json' },
    ],
  },
  junie: {
    files: [
      { src: 'junie/guidelines.md', dest: '.junie/guidelines.md', inject: true },
      { src: 'junie/references/init-workflow.md', dest: '.junie/vdoc/init-workflow.md' },
      { src: 'junie/references/audit-workflow.md', dest: '.junie/vdoc/audit-workflow.md' },
      { src: 'junie/references/doc-template.md', dest: '.junie/vdoc/doc-template.md' },
      { src: 'junie/references/manifest-schema.json', dest: '.junie/vdoc/manifest-schema.json' },
    ],
  },
  agents: {
    files: [
      { src: 'agents/AGENTS.md', dest: 'AGENTS.md', inject: true },
      { src: 'agents/references/init-workflow.md', dest: '.agents/vdoc/init-workflow.md' },
      { src: 'agents/references/audit-workflow.md', dest: '.agents/vdoc/audit-workflow.md' },
      { src: 'agents/references/doc-template.md', dest: '.agents/vdoc/doc-template.md' },
      { src: 'agents/references/manifest-schema.json', dest: '.agents/vdoc/manifest-schema.json' },
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

  // Clean skill directories that may have nested files
  const skillDirs = [
    join(CWD, '.claude', 'skills', 'vdoc'),
    join(CWD, '.cursor', 'rules', 'vdoc'),
    join(CWD, '.windsurf', 'skills', 'vdoc'),
    join(CWD, '.github', 'skills', 'vdoc'),
    join(CWD, '.continue', 'references', 'vdoc'),
    join(CWD, '.clinerules', 'vdoc'),
    join(CWD, '.gemini', 'vdoc'),
    join(CWD, '.aiassistant', 'vdoc'),
    join(CWD, '.junie', 'vdoc'),
    join(CWD, '.agents', 'vdoc'),
  ];
  for (const dir of skillDirs) {
    if (existsSync(dir)) {
      rmSync(dir, { recursive: true });
      console.log(`  ✓ removed ${dir.slice(CWD.length + 1)}/`);
      cleanEmptyDirs(dirname(dir));
    }
  }

  // Clean legacy files from previous versions
  const legacyFiles = ['.cursor/rules/vdoc.mdc', '.windsurf/rules/vdoc.md'];
  for (const f of legacyFiles) {
    if (removeFile(f)) removed++;
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
