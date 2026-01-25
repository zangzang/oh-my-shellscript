# Developer Guide

This project is a **modular setup management system** designed to automate repetitive development environment configuration tasks for **Windows and Linux environments**.

## 📌 Project Configuration
- **Linux Automation**: `linux-setup/` - Python TUI-based installation automation.
- **Windows Automation**: `pwsh/` - PowerShell-based environment setup (refer to `dev` branch).
- **Bash Utilities**: `bash/` - Shared Bash scripts and configuration files (refer to `dev` branch).

## 🎯 Project Overview

- **Purpose**: Automatically install software and configurations required when reinstalling an OS or setting up a new environment.
- **Approach**: Modular installation scripts + Python Textual-based TUI (Text User Interface).
- **Key Technologies**: Python, Bash, JSON.

## 📁 Project Structure

```
my-shell-script/
├── install.sh                  # One-line installation script
├── linux-setup/                # Linux Automation System ⭐
│   ├── setup.py                # Main Entry Point (Python TUI)
│   ├── bootstrap.sh            # Python Environment Bootstrap
│   ├── README.md               # Linux Setup Guide
│   ├── config/                 # Configuration Files
│   │   ├── categories.json     # Category and Module Order Definitions
│   │   └── ui.json             # UI Strings/Icons Definitions
│   ├── lib/                    # Common Function Libraries
│   │   ├── core.sh             # Logging, Permission Management, etc.
│   │   ├── distro.sh           # Distribution Detection
│   │   └── validate.sh         # JSON Validation
│   ├── modules/                # Installation Module Repository
│   │   ├── dev/                # Development Tools (Docker, Java, Node, etc.)
│   │   ├── gui/                # GUI Applications (VSCode, Chrome, etc.)
│   │   ├── system/             # System Essentials
│   │   └── tools/              # CLI Utilities
│   ├── presets/                # Pre-defined Installation Combinations
│   └── test/                   # Installation Test Results Directory
```

### Core Components

1. **setup.py**: A Python Textual-based TUI application.
   - Provides UI for module selection and preset management.
   - Manages automatic dependency resolution and installation script execution.

2. **modules/{category}/{name}/**: Isolated units for each feature.
   - `meta.json`: Defines module metadata and dependencies.
   - `install.sh`: Contains the actual installation/configuration logic.

3. **presets/*.json**: Defines collections of modules for specific purposes.

## ✅ Module Creation Rules

### 1. Directory Structure

New features **must be separated into modules**.

```bash
linux-setup/modules/<category>/<name>/
├── meta.json      # [Required] Module Metadata
└── install.sh     # [Required] Installation Script
```

**Categories**:
- `dev`: Development environments (Docker, Node.js, Python, etc.)
- `gui`: GUI applications (Chrome, VSCode, DBeaver, etc.)
- `system`: System essentials (Build tools, libraries, etc.)
- `tools`: CLI utilities (fastfetch, fzf, etc.)

### 2. Writing meta.json

```json
{
  "id": "category.name",              // [Required] Unique ID (Format: category.name)
  "name": "Display Name",             // [Required] Name displayed in TUI
  "description": "What it does",      // [Optional] Description
  "category": "dev",                  // [Required] Category (Must match folder name)
  "requires": ["system.update"],      // [Optional] Array of dependent module IDs
  "variants": {                       // [Optional] Version/Variant support
    "latest": { "version": "latest" },
    "lts": { "version": "20.x" }
  }
}
```

**Field Description**:
- `id`: Must follow `category.name` format (e.g., `dev.docker`, `gui.chrome`).
- `requires`: Other modules required before this module runs.
- `variants`: Defined if multiple versions are supported (selected in presets as `id:variant`).

### 3. Writing install.sh

#### Basic Template

```bash
#!/bin/bash
set -e  # Stop immediately on error

# 1. Check if already installed (Idempotency)
if command -v <tool> &>/dev/null; then
    echo "<Tool> is already installed ($(which <tool>))"
    exit 0
fi

# 2. Installation Logic
echo "Installing <Tool>..."
# ... Actual installation commands ...

# 3. Verification (Optional)
if command -v <tool> &>/dev/null; then
    echo "<Tool> installed successfully"
    exit 0
else
    echo "<Tool> installation failed"
    exit 1
fi
```

### 4. Writing test.sh (Optional)

Adding `test.sh` to a module allows automatic "Hello World" testing after installation.
Test files must save results in `linux-setup/test/{module_id}/`.

#### Test Template

```bash
#!/bin/bash
set -e

echo "🧪 Testing <Tool> installation..."

if ! command -v <tool> &>/dev/null; then
    echo "❌ <tool> command not found."
    exit 1
fi

echo "✅ <Tool> Version: $(<tool> --version)"

# Return 0 on success
exit 0
```

#### Essential Principles

1. **Idempotency**: Must be safe to run multiple times.
   - Skip if already installed.
   - Backup and overwrite if configuration files exist.

2. **Clear Output**: Users should know what is happening.
   ```bash
   echo "Installing Docker..."
   ```

3. **Exit Code Management**:
   - Success: `exit 0`
   - Failure: `exit 1` or higher

## 🔧 Coding Conventions

### Bash Scripts

```bash
#!/bin/bash
set -e  # Stop on error (Required)

# Variables: UPPER_CASE for globals, lower_case for locals
INSTALL_DIR="/opt/myapp"

# Function Definitions
install_package() {
    local pkg_name=$1
    echo "Installing ${pkg_name}..."
    sudo apt-get install -y "$pkg_name"
}

# Check command existence
if command -v docker &>/dev/null; then
    echo "Docker is available"
fi
```

### JSON Files

- **Indentation**: 2 Spaces
- **Quotes**: Double quotes only
- **No Comments**: JSON does not support comments.

## 🔗 Dependency Management

### Principles

- **Explicit Declaration**: Declare all dependencies in the `requires` field of `meta.json`.
- **No Circular References**: Dependencies like A → B → A are not allowed.
- **Auto Resolution**: `setup.py` automatically resolves the dependency graph.

## 📦 Creating Presets

Presets are combinations of modules for specific purposes. (Located in `linux-setup/presets/`)

```json
{
  "name": "Full Stack Developer Setup",
  "description": "Node.js, Python, Docker, VSCode",
  "modules": [
    { "id": "system.build-tools" },
    { "id": "dev.nvm" },
    { "id": "dev.python" },
    { "id": "dev.docker" },
    { "id": "gui.vscode" }
  ]
}
```

## 🚨 Guidelines

### ❌ What NOT to do

1. **Hardcoding installation logic in Python code.**
   - All installation logic must be separated into modules (`install.sh`).

2. **Directly calling other modules from `install.sh`.**
   - You must use the `"requires"` field in `meta.json`.

3. **Using hardcoded paths.**
   - Use environment variables like `$HOME`.

4. **Using interactive prompts.**
   - Installation scripts must run without user input (use `-y` flags, etc.).