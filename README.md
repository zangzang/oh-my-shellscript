# My Shell Script

Automated development environment setup system for Linux and Windows.

## 🚀 Quick Start

### Linux
```bash
# Clone repository
git clone https://github.com/zangzang/my-shell-script.git
cd my-shell-script

# Run setup
./setup-linux.sh

# With preset
./setup-linux.sh --preset fullstack-dev --execute

# Or use Python directly
python3 linux-setup.py --preset java-dev --dry-run
```

### Windows
```powershell
# Clone repository
git clone https://github.com/zangzang/my-shell-script.git
cd my-shell-script

# Run setup (PowerShell launcher)
.\setup-windows.ps1

# With preset
.\setup-windows.ps1 -Preset fullstack-dev -Execute

# Or use Python directly
python windows-setup.py --preset node-dev --dry-run
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
├── setup-linux.sh          # Linux entry point (shell)
├── setup-windows.ps1       # Windows entry point (PowerShell)
├── linux-setup.py          # Linux setup launcher
├── windows-setup.py        # Windows setup launcher
├── linux-setup/            # Linux setup system
│   ├── setup.py           # Main TUI application
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
./setup-linux.sh

# Windows
.\setup-windows.ps1
```

### Preset Installation
```bash
# Linux
python3 linux-setup.py --preset fullstack-dev --execute

# Windows
python windows-setup.py --preset dotnet-dev --execute
```

### Module Selection
```bash
# Linux
python3 linux-setup.py --modules dev.docker,dev.nodejs --execute

# Windows
python windows-setup.py --modules dev.git,dev.vscode --dry-run
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
