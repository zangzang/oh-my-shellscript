# Linux Setup Assistant

A **modular setup tool** for Kubuntu 25.04 (Plasma 6 + Wayland) and various Linux environments.
It provides an intuitive tree view to select modules and save/load presets via a **Python Textual**-based TUI.

## ✨ Key Features

*   **🖥️ Python TUI**: Fast and responsive interface based on the `textual` library.
*   **🌳 Structured Tree**: Segregated menus for **Presets** and **Modules** for easy navigation.
*   **📦 Multi-Preset Support**: Combine multiple presets by selecting them simultaneously.
*   **🔗 Auto Dependency Resolution**: Automatically tracks dependencies via `requires` in `meta.json`.
*   **💾 Save Presets**: Save your current selection as a preset for future reuse.
*   **📊 Detailed Summary Report**: Displays Success, Failed, and **Skipped (Already installed)** status with duration.
*   **🔍 Detailed Simulation**: Preview actual Bash commands and environment variables before execution.
*   **⚡ Fast Stop**: Cleanly abort at any time with Ctrl+C.

## 🚀 Quick Start

### 1. Prerequisites (First time only)

The `bootstrap.sh` script automatically:
- Checks/installs Python3
- Installs/upgrades pip
- Installs the `textual` library
- Creates the config directory

### 2. Run

```bash
# In the linux-setup directory
./bootstrap.sh
```

### 3. Key Bindings

| Key | Function |
| :--- | :--- |
| **↑↓** | Navigate tree |
| **Enter** | Expand/Collapse node |
| **Space** | Toggle selection (Presets & Modules) |
| **Tab** | Switch focus between panels (Tree ↔ Selected List ↔ Info) |
| **F5** | Start Installation |
| **d** | Simulation (Dry Run) |
| **s** | Save current selection as a preset |
| **p** | Cycle through preset list |
| **q / ESC** | Quit |

### 4. Command Line Options

```bash
# Load a preset and launch TUI
python3 setup.py --preset java-dev

# Install a preset directly (skip TUI)
python3 setup.py --preset base --execute

# Simulation only
python3 setup.py --preset full-dev --dry-run
```

## 📂 Project Structure

```
linux-setup/
├── setup.py            # Main execution script (Python TUI)
├── bootstrap.sh        # Pre-installation bootstrap script
├── config/             # Configuration files
│   └── categories.json # Category tree definition
├── lib/                # Bash common function library
├── modules/            # Installation modules directory
│   ├── system/         # System settings (update, essentials, etc.)
│   ├── dev/            # Development tools (docker, java, node, etc.)
│   ├── tools/          # CLI utilities
│   └── gui/            # GUI applications
├── presets/            # Preset JSON files
├── docs/               # Additional guide documents
└── test/               # Module test results directory
```

## 🛠️ How to Add a Module

To add new software or configuration, create a directory under `modules/` and create two files:

1. **meta.json**: Define module ID, name, description, and dependencies.
2. **install.sh**: Write the Bash script for actual installation. (Must be idempotent)

Example `install.sh`:
```bash
if command -v my-tool &>/dev/null; then
    echo "my-tool already installed"
    exit 0
fi

# Installation logic
sudo apt install my-tool
```

## 📦 Variants Support

Modules supporting multiple versions can add a `variants` array:
```json
"variants": ["17", "21"]
```
These will appear as a sub-tree in the TUI. The selected version is passed as the `VERSION` environment variable to `install.sh`.

## 📚 Guide Documents

- **[REMOTE_SETUP_GUIDE.md](docs/REMOTE_SETUP_GUIDE.md)** - Remote server setup and automation.
- **[PERMISSIONS.md](docs/PERMISSIONS.md)** - Local permission management.
- **[JAVA_GUIDE.md](docs/JAVA_GUIDE.md)** - Java development environment configuration.
- **[VSCODE_EXTENSIONS_GUIDE.md](docs/VSCODE_EXTENSIONS_GUIDE.md)** - VSCode extension configuration.

**Version**: 4.0 (Python TUI)
**Last Updated**: 2026-01-25