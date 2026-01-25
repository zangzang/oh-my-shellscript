# Permission Management Guide

## Overview
Moving projects via archives (tar, zip) may cause loss of execution permissions.

## Solutions

### ✅ Method 1: Auto Recovery (Recommended)
`bootstrap.sh` and `setup.py` automatically check and restore permissions for `install.sh` files when they run.

### ✅ Method 2: Manual Fix
You can manually apply permissions to all module scripts:

```bash
# Example command to fix all modules
chmod +x modules/**/install.sh
```

## Archive Tips

### Using tar (Recommended)
`tar` preserves Unix permissions by default.
```bash
# Compress
tar -cvf project.tar ./project

# Extract
tar -xvf project.tar
```

### Using zip
`zip` might not perfectly maintain Unix permissions. Use the `-y` flag to preserve symbolic links and ensure your zip tool supports Unix attributes.

## Git
Git tracks execution permissions automatically. If a file should be executable but isn't:
```bash
git update-index --chmod=+x install.sh
git commit -m "Fix permission"
```

## Sudo & Automation
To run scripts automatically without password prompts, use **NOPASSWD** in your sudoers file as described in the [REMOTE_SETUP_GUIDE.md](REMOTE_SETUP_GUIDE.md).