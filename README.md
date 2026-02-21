# My Shell Script

Automated development environment setup system for Linux and Windows.

## 🚀 Quick Start

### Linux
```bash
# Clone repository
git clone https://github.com/zangzang/my-shell-script.git
cd my-shell-script

# Run setup
./omss.sh

# With preset
./omss.sh --preset fullstack-dev --execute

# Dry run
./omss.sh --preset java-dev --dry-run
```

### Windows
```powershell
# Clone repository
git clone https://github.com/zangzang/my-shell-script.git
cd my-shell-script

# Run setup (PowerShell launcher)
.\omss.ps1

# With preset
.\omss.ps1 -Preset fullstack-dev -Execute
```

## 🐧 Supported Platforms

### Linux
- **Debian/Ubuntu Based**: Ubuntu, Debian, Pop!_OS, Linux Mint
- **Fedora**: Fedora 39, 40, 41
- **Arch** (partial support)

### Windows
- **Windows 11** or later
- **PowerShell 7.0+** recommended

## 📂 Project Structure

```
.
├── omss.sh                 # Linux entry point (shell)
├── omss.ps1                # Windows entry point (PowerShell)
├── windows-setup/omss/windows-setup.py  # Windows setup launcher
├── linux-setup/            # Linux setup system
│   ├── omss/              # Go setup implementation
│   ├── modules/           # Installation modules
│   ├── presets/           # Preset configurations
│   └── config/            # Settings and categories
└── windows-setup/          # Windows setup system
    ├── modules/           # Installation modules
    ├── presets/           # Preset configurations
    ├── config/            # Settings
    └── core/              # Core libraries
```

## 📖 Usage Examples

### Interactive TUI Mode
```bash
# Linux
./omss.sh

# Windows
.\omss.ps1
```

### Preset Installation
```bash
# Linux
./omss.sh --preset fullstack-dev --execute

# Linux (Go setup, post-module policy)
./omss.sh --post-module-mode selected --preset java-dev --dry-run
OMSS_POST_MODULE_MODE=always ./omss.sh --preset full-dev --dry-run

# Windows
.\omss.ps1 -Preset dotnet-dev -Execute
```

### Module Selection
```bash
# Linux
./omss.sh --preset node-dev --execute

# Windows
.\omss.ps1 -Modules dev.git,dev.vscode -DryRun
```

## 🎯 Available Presets

### Linux
- `base` - Essential system tools
- `java-dev` - Java development environment
- `node-dev` - Node.js development
- `python-dev` - Python development
- `fullstack-dev` - Complete development stack

### Windows
- `base` - Essential development tools
- `dotnet-dev` - .NET development
- `java-dev` - Java development
- `node-dev` - Node.js development
- `fullstack-dev` - Complete development stack
