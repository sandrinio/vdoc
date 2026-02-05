# STORY-025: Implement User-Added Section Handling

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-003 |

---

## User Story
**As a** developer customizing my documentation
**I want** to add custom sections that vdoc maintains
**So that** I can document things beyond auto-detected categories

---

## Acceptance Criteria

### AC1: Explicit paths mode
- [ ] User specifies exact files: `covers: ["src/auth/oauth.ts", "src/auth/jwt.ts"]`
- [ ] AI reads only these files
- [ ] Documentation generated for specified files only

### AC2: Auto mode
- [ ] User specifies: `covers: "auto"`
- [ ] AI searches source_index for semantically related files
- [ ] Present candidates to user for confirmation
- [ ] User approves which files to include

### AC3: None mode
- [ ] User specifies: `covers: "none"`
- [ ] AI generates template structure
- [ ] User fills in content manually
- [ ] vdoc never overwrites this section

### AC4: Add via manifest
- [ ] User can edit `_manifest.json` to add sections
- [ ] Next update recognizes new documentation entries
- [ ] Clear documentation on how to add sections

---

## Technical Notes

**Manifest Entry for User Section:**
```json
{
  "documentation": [
    {
      "path": "vdocs/deployment-guide.md",
      "title": "Deployment Guide",
      "covers": ["src/config/docker.ts", "src/config/k8s.ts"],
      "audience": "DevOps engineers",
      "description": "How to deploy the application",
      "user_added": true
    }
  ]
}
```

**Mode: Explicit Paths**
```json
{
  "covers": ["src/auth/oauth.ts", "src/auth/jwt.ts"]
}
```
AI behavior:
1. Read exactly these files
2. Generate documentation covering their functionality
3. Update when these specific files change

**Mode: Auto**
```json
{
  "covers": "auto"
}
```
AI behavior:
1. Parse section title: "Authentication Guide"
2. Search source_index for related files:
   - Files in `auth/` directory
   - Files with `auth` in name
   - Files with category `auth` or `middleware`
3. Present candidates:
   ```
   For "Authentication Guide", I found these related files:
   - src/auth/oauth.ts (auth middleware)
   - src/auth/jwt.ts (token handling)
   - src/middleware/session.ts (session management)

   Include all of these? [Y/n]
   ```
4. Generate documentation for confirmed files

**Mode: None**
```json
{
  "covers": "none"
}
```
AI behavior:
1. Generate template:
   ```markdown
   # Deployment Guide

   > Add your deployment documentation here.

   ## Overview

   {Describe your deployment process}

   ## Prerequisites

   {List requirements}

   ## Steps

   {Step-by-step instructions}
   ```
2. Never overwrite - user owns this content
3. On update: skip entirely, just verify file exists

**Adding Section via Conversation:**
```
User: Add a new section for our deployment process

AI: I'll add a "Deployment Guide" section. How would you like me to handle it?

1. **Explicit files** - You tell me which files document deployment
2. **Auto-detect** - I'll search for deployment-related files
3. **Manual** - I'll create a template you fill in yourself

User: Auto-detect

AI: I found these deployment-related files:
- docker-compose.yml
- Dockerfile
- src/config/environment.ts

Include these in the Deployment Guide? [Y/n]
```

---

## Definition of Done
- [ ] Three modes documented in instructions.md
- [ ] Manifest supports `covers` field variations
- [ ] `user_added: true` flag prevents auto-regeneration
- [ ] Auto mode searches semantically
- [ ] None mode creates template only
- [ ] Tested all three modes
