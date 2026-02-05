# STORY-004: Implement Python Preset

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Scanner |
| **Complexity** | Small (1 file, already exists) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Python Developer**,  
> I want **the scanner to understand my project structure**,  
> So that **it correctly categorizes files and extracts docstrings**.

### 1.2 Detailed Requirements
- [ ] Exclude __pycache__, .venv, venv, .env, .pytest_cache, dist, build
- [ ] Exclude *.pyc, *.pyo, *.egg, *.whl
- [ ] Identify entry points: main.py, app.py, manage.py, src/main.py
- [ ] Extract Python docstrings (triple quotes)
- [ ] Categorize files via DOC_SIGNALS:
  - api_routes: **/api/**, **/routes/**, **/views/**
  - models: **/models/**, **/schemas/**
  - utils: **/utils/**, **/helpers/**
  - services: **/services/**
  - config: **/config/**, settings.py

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Python Preset

  Scenario: Excludes __pycache__
    Given python.conf is loaded
    Then EXCLUDE_DIRS contains "__pycache__"

  Scenario: Excludes .pyc files
    Given python.conf is loaded
    Then EXCLUDE_FILES contains "*.pyc"

  Scenario: Categorizes API routes
    Given file path is "src/api/users.py"
    When categorize_file is called
    Then category is "api_routes"

  Scenario: Categorizes models
    Given file path is "app/models/user.py"
    When categorize_file is called
    Then category is "models"

  Scenario: Docstring pattern matches
    Given DOCSTRING_PATTERN from python.conf
    And file starts with '"""User service module."""'
    When extract_docstring is called
    Then result is "User service module."
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/presets/python.conf` - Already exists, verify completeness

### 3.2 Python Preset (Verify/Update)
```bash
# vdoc Language Preset: Python
# Detection: requirements.txt, pyproject.toml, setup.py

PRESET_NAME="python"
PRESET_VERSION="1.0.0"

# Directories to exclude
EXCLUDE_DIRS="__pycache__ .venv venv env .env .pytest_cache .mypy_cache dist build *.egg-info .tox .nox htmlcov"

# File patterns to exclude
EXCLUDE_FILES="*.pyc *.pyo *.egg *.whl *.so"

# Entry point patterns
ENTRY_PATTERNS="main.py app.py manage.py run.py src/main.py src/app.py wsgi.py asgi.py"

# Python docstring pattern (triple quotes)
DOCSTRING_PATTERN='^\s*"""'
DOCSTRING_END='"""'

# Also support single-quote docstrings
DOCSTRING_PATTERN_ALT="^\s*'''"
DOCSTRING_END_ALT="'''"

# Category signals
DOC_SIGNALS="
api_routes:**/api/**
api_routes:**/routes/**
api_routes:**/views/**
api_routes:**/endpoints/**
models:**/models/**
models:**/schemas/**
models:**/entities/**
utils:**/utils/**
utils:**/helpers/**
utils:**/common/**
services:**/services/**
services:**/handlers/**
config:**/config/**
config:settings.py
config:**/settings/**
config:config.py
tests:**/tests/**
tests:test_*.py
tests:**/test/**
"
```

---

## 4. Notes
- Python preset already exists - verify and enhance
- Python uses triple-quote docstrings (both """ and ''')
- Common frameworks: Flask, Django, FastAPI have similar structures
- Test files should be categorized but may be excluded from docs
