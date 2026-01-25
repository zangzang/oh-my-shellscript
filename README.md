# My Shell Script

Automated environment setup scripts for Linux and Windows.

To install **Oh My Shell Script**, simply run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/zangzang/oh-my-shellscript/main/install.sh | bash
```

### Manual Installation

1. Ensure `git` and `python3` are installed.
2. Clone this repository to `~/oh-my-shellscript`.
   ```bash
   git clone https://github.com/zangzang/oh-my-shellscript.git ~/oh-my-shellscript
   cd ~/oh-my-shellscript
   ./install.sh
   ```
3. Run the setup assistant.
   ```bash
   omss
   ```

## 🐧 Supported Linux Distros

- **Debian/Ubuntu Based**: Ubuntu, Debian, Pop!_OS, Linux Mint, etc.
- **Fedora**: Fedora 39, 40, 41.
- *Note: Other distributions will show a compatibility error message upon execution.*

## 📂 Project Structure

- **linux-setup/**: Python-based TUI setup assistant for Linux.
- **windows-setup/**: (Planned) Setup scripts for Windows.
- **bash/**: (Planned) Useful bash aliases and utilities.
- **pwsh/**: (Planned) PowerShell scripts.
