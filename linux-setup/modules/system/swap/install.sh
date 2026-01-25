#!/bin/bash
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../lib/core.sh"

detect_os

ui_log_info "Configuring Hybrid Swap (ZRAM + Disk Swap)..."

# -----------------------------------------------------------------------------
# 1. Calculate Sizes
# -----------------------------------------------------------------------------
# Total RAM in MB
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')

# ZRAM Size: 1/3 of RAM
ZRAM_SIZE_MB=$((TOTAL_RAM_MB / 3))

# Disk Swap Size: 1/2 of RAM (Min 1GB, Max 8GB cap recommended, but sticking to 1/2 request)
SWAPFILE_SIZE_MB=$((TOTAL_RAM_MB / 2))

ui_log_info "Total RAM: ${TOTAL_RAM_MB}MB"
ui_log_info "Target ZRAM Size (1/3): ${ZRAM_SIZE_MB}MB"
ui_log_info "Target Swapfile Size (1/2): ${SWAPFILE_SIZE_MB}MB"

# -----------------------------------------------------------------------------
# 2. Configure ZRAM (Priority 100 - Higher used first)
# -----------------------------------------------------------------------------
ui_log_info "Setting up ZRAM..."

if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" || "$OS_ID" == "pop" || "$OS_ID" == "linuxmint" ]]; then
    install_packages zram-tools

    # Configure zram-tools
    # PERCENT is simpler for zram-tools, approx 33%
    sudo sed -i 's/^#*PERCENT=.*/PERCENT=33/' /etc/default/zram-tools
    sudo sed -i 's/^#*PRIORITY=.*/PRIORITY=100/' /etc/default/zram-tools
    
    # Reload service
    sudo systemctl restart zramswap || echo "Warning: Failed to restart zramswap"

elif [[ "$OS_ID" == "fedora" ]]; then
    install_packages zram-generator

    # Configure zram-generator
    # zram-fraction = 0.33
    sudo bash -c "cat > /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = ram / 3
compression-algorithm = zstd
swap-priority = 100
EOF"
    
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-zram-setup@zram0.service
else
    ui_log_warn "ZRAM auto-configuration not supported for this OS ($OS_ID). Skipping ZRAM."
fi

# -----------------------------------------------------------------------------
# 3. Configure Disk Swapfile (Priority 50 - Lower used later)
# -----------------------------------------------------------------------------
SWAPFILE="/swapfile"

if grep -q "$SWAPFILE" /proc/swaps; then
    ui_log_info "Swapfile already active at $SWAPFILE"
else
    ui_log_info "Creating Swapfile ($SWAPFILE_SIZE_MB MB)..."
    
    # Disable old swap if exists but incorrect size (Advanced logic omitted for safety, just creating if missing)
    if [ -f "$SWAPFILE" ]; then
        ui_log_warn "$SWAPFILE exists but not active. Recreating..."
        sudo swapoff "$SWAPFILE" 2>/dev/null || true
        sudo rm "$SWAPFILE"
    fi

    # Create file
    ui_log_info "Allocating swapfile (this may take a moment)..."
    sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count="$SWAPFILE_SIZE_MB" status=progress
    
    sudo chmod 600 "$SWAPFILE"
    sudo mkswap "$SWAPFILE"
    sudo swapon "$SWAPFILE" --priority 50
    
    # Add to fstab
    if ! grep -q "$SWAPFILE" /etc/fstab; then
        echo "$SWAPFILE none swap sw,pri=50 0 0" | sudo tee -a /etc/fstab
        ui_log_success "Added $SWAPFILE to /etc/fstab"
    fi
fi

# -----------------------------------------------------------------------------
# 4. Verification
# -----------------------------------------------------------------------------
echo ""
ui_log_info "Current Swap Status:"
sudo swapon --show
free -h
ui_log_success "Swap configuration complete."
