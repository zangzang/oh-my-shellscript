#!/bin/bash

# OS Detection
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="$VERSION_ID"
    else
        OS_ID="unknown"
        OS_VERSION=""
    fi
}

detect_os

# Package Manager Abstraction
install_packages() {
    local pkgs=("$@")
    if [ ${#pkgs[@]} -eq 0 ]; then
        return 0
    fi

    case "$OS_ID" in
        ubuntu|debian|pop|linuxmint)
            # Update apt cache if it's been a while (optional optimization could be added here)
            # sudo apt update -y >/dev/null 2>&1
            sudo apt install -y "${pkgs[@]}"
            ;;
        fedora)
            local fedora_pkgs=()
            for pkg in "${pkgs[@]}"; do
                local mapped
                mapped="$(map_package_name_fedora "$pkg")"
                if [[ -n "$mapped" ]]; then
                    fedora_pkgs+=("$mapped")
                fi
            done
            if [ ${#fedora_pkgs[@]} -gt 0 ]; then
                sudo dnf install -y --setopt=strict=0 "${fedora_pkgs[@]}"
            fi
            ;;
        *)
            echo "Unsupported OS for automatic package installation: $OS_ID"
            return 1
            ;;
    esac
}

# Add Repository Abstraction
add_repository() {
    local name="$1"
    local url="$2"   # For Fedora: repo file URL, For Ubuntu: PPA or GPG/Repo logic needed
    local key_url="$3" # For Ubuntu GPG key

    case "$OS_ID" in
        ubuntu|debian|pop|linuxmint)
            # This is a simplified handler. 
            # Complex repo setups (like charm.sh) might still need custom logic in their specific install scripts,
            # or we can expand this function later.
            if [[ "$name" == "ppa:"* ]]; then
                sudo add-apt-repository -y "$name"
            else
                # Generic handling for deb repos is complex; handled individually for now
                :
            fi
            ;;
        fedora)
            if [[ -n "$url" ]]; then
                sudo dnf config-manager --add-repo "$url"
            fi
            ;;
    esac
}

# Package Name Mapping for Fedora
map_package_name_fedora() {
    local pkg="$1"
    case "$pkg" in
        build-essential) echo "@development-tools" ;;
        libssl-dev)      echo "openssl-devel" ;;
        pkg-config)      echo "pkgconf-pkg-config" ;;
        python3-venv)    echo "python3" ;; # Often included or python3-devel
        python3-dev)     echo "python3-devel" ;;
        libbz2-dev)      echo "bzip2-devel" ;;
        libreadline-dev) echo "readline-devel" ;;
        libsqlite3-dev)  echo "sqlite-devel" ;;
        libncurses5-dev) echo "ncurses-devel" ;;
        libncursesw5-dev) echo "ncurses-devel" ;;
        xz-utils)        echo "xz" ;;
        tk-dev)          echo "tk-devel" ;;
        libffi-dev)      echo "libffi-devel" ;;
        liblzma-dev)     echo "xz-devel" ;;
        zlib1g-dev)      echo "zlib-devel" ;;
        libxml2-dev)     echo "libxml2-devel" ;;
        libxmlsec1-dev)  echo "xmlsec1-devel" ;;
        libgdbm-dev)     echo "gdbm-devel" ;;
        libnss3-dev)     echo "nss-devel" ;;
        libwebkit2gtk-4.1-dev) echo "webkit2gtk4.1-devel" ;; # Fedora 39+ name usually, or webkit2gtk3-devel depending on version
        libgtk-3-dev)    echo "gtk3-devel" ;;
        libglib2.0-dev)  echo "glib2-devel" ;;
        librsvg2-dev)    echo "librsvg2-devel" ;;
        libsoup2.4-dev)  echo "libsoup-devel" ;;
        libjavascriptcoregtk-4.1-dev) echo "javascriptcoregtk4.1-devel" ;;
        libcanberra-gtk-module) echo "libcanberra-gtk3" ;;
        libxcb-shape0-dev) echo "libxcb-devel" ;;
        libxcb-xfixes0-dev) echo "libxcb-devel" ;;
        libxdo-dev)      echo "libxdo-devel" ;;
        libappindicator3-dev) echo "libappindicator-gtk3-devel" ;;
        libglu1-mesa)    echo "mesa-libGLU" ;;
        software-properties-common) echo "dnf-plugins-core" ;;
        apt-transport-https) echo "" ;; # Not needed for dnf
        # Add more mappings as needed
        *)               echo "$pkg" ;;
    esac
}
