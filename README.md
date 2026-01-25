# My Shell Script

Automated environment setup scripts for Linux and Windows.

To install **Oh My Shell Script**, run the following command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/zangzang/oh-my-shellscript/main/install.sh | bash
```

### Manual Installation (Without Git)

If you don't have `git` installed yet, you can download and run the installer directly:

1. Download the installer:
   ```bash
   curl -O https://raw.githubusercontent.com/zangzang/oh-my-shellscript/main/install.sh
   # or using wget
   # wget https://raw.githubusercontent.com/zangzang/oh-my-shellscript/main/install.sh
   ```
2. Run the installer:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
3. Once the installation is complete, you can run the setup assistant from anywhere:
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
