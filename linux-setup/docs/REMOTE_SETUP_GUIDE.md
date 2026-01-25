# Remote Server Setup & Automation Guide

## Overview

This document explains how to install `linux-setup` on a remote server via SSH and automate the process without manual sudo password entry.

## 1. Initial Setup: NOPASSWD Configuration

### The Problem
During non-interactive remote execution, if `sudo` requires a password, the script will abort:
`[ERROR] Sudo password required for non-interactive execution. Cannot proceed.`

### ✅ Solution: sudoers NOPASSWD Setting

#### Method 1: Remote configuration from local (Recommended)

```bash
# Run on local machine
ssh user@remote "echo 'YOUR_PASSWORD' | sudo -S sh -c 'echo \"user ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/user-nopasswd' && sudo chmod 440 /etc/sudoers.d/user-nopasswd"
```

#### Method 2: Manual configuration on remote server

```bash
# Run on remote server
sudo visudo
# Add to the end of file:
# user ALL=(ALL) NOPASSWD: ALL
```

### Verification
```bash
ssh user@remote "sudo -v && echo '✅ NOPASSWD setup complete'"
```

## 2. Remote Execution Patterns

### Pattern A: Direct Command Execution
```bash
# Install a preset
ssh user@remote "cd ~/linux-setup && ./setup.py --preset java-dev --execute"
```

### Pattern B: File Transfer then Execute

```bash
# 1. Sync files from local to remote
scp -r ./linux-setup user@remote:~

# 2. Run on remote
ssh user@remote "cd ~/linux-setup && ./bootstrap.sh"
```

## 3. Full Automation Workflow

### Example: Setting up Tauri Dev Environment on Remote

1. **Step 1: Set NOPASSWD (Once)**
1. **Copy Repo to Remote:**
   ```bash
   scp -r . user@remote:~/oh-my-shellscript
   ```

2. **Run Setup on Remote:**
   ```bash
   ssh user@remote "cd ~/oh-my-shellscript/linux-setup && ./setup.py --preset tauri-dev --execute"
   ```

## 4. Troubleshooting

### Permission denied (publickey)
- Use password auth: `ssh -o PubkeyAuthentication=no user@remote`
- Or add your SSH key to the server.

### Host key verification failed
- Disable verification for testing: `ssh -o StrictHostKeyChecking=no user@remote`

### command not found
- Use login shell: `ssh user@remote "bash -l -c 'command'"
- This ensures PATH and environment variables are loaded.