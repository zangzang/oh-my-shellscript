# 📋 Project Improvements TODO

## 1. Dependency Management
- [ ] Add `dev.node` as a mandatory requirement for all modules using `npm` (claude-code, gemini-cli, mcp-servers, etc.)
- [ ] Ensure `system.update` is a top-priority dependency for essential system bundles.
- [ ] Add `system.update` as a requirement for major runtimes (java, python, node, rust, etc.) to ensure a clean install environment.

## 2. Docker & Permissions
- [ ] Fix `dev.docker` installation to automatically add the current user to the `docker` group (requires shell restart or `newgrp`).
- [ ] Update `dev.docker-stack` to check for and handle permission issues more gracefully.

## 3. UI/UX (Setup Assistant)
- [ ] (Optional) Add a "System Preparation" phase that always runs `system.update` before anything else.

## 4. Module Fixes
- [ ] Standardize `install.sh` headers across all modules.
- [ ] Fix potential `sudo` permission prompts in headless mode.
