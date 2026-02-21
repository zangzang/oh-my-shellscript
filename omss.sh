#!/bin/bash
#
# OMSS (Oh My Shell Script) - Linux Launcher
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Execute the Go binary with linux-setup directory as an environment variable
export SETUP_BASE_DIR="${SCRIPT_DIR}/linux-setup"
exec "${SCRIPT_DIR}/linux-setup/omss/bin/setup" "$@"
