#!/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

function echo_group() {
    local WHAT
    WHAT="$(
        basename "$1" .sh |
            tr "-" " " |
            tr "_" " "
    )"
    echo "::group:: == ${WHAT^^} =="
    "$1"
    echo "::endgroup::"
}

log() {
  echo "== $* =="
}

log "Starting building"
### Create root directory for hdd mount points 
mkdir /data /videos /games

### Install packages
log "Installing apps"

log "Install layered applications"

# Layered Applications
LAYERED_PACKAGES=(
    nemo
    totem
    cinnamon-translations
    nemo-fileroller
    nemo-extensions
    nemo-preview
    ulauncher
    clapper
    gnome-tweaks
    gnome-calendar
    gnome-calculator
    gnome-keyring
    gnome-shell
    gnome-session
    gnome-control-center
    gnome-extensions-app
    gdm
    file-roller
    xdg-user-dirs-gtk
    evince
    loupe
    gedit
    gnome-calculator
    gnome-online-accounts
)
dnf5 install -y \
    --setopt=install_weak_deps=False \
    --allowerasing \
    --skip-unavailable \
    "${LAYERED_PACKAGES[@]}"

echo_group /ctx/install_packages.sh

log "Allow Samba on home dirs"
setsebool -P samba_enable_home_dirs=1

log "Enable loading kernel modules"
setsebool -P domain_kernel_load_modules on

log "Enabling system services"
systemctl enable podman.socket syncthing@kohega.service zerotier-one.service lactd.service smb.service

log "Adding personal just recipes"
echo "import \"/usr/share/kohega/just/kohega.just\"" >> /usr/share/ublue-os/justfile

log "Rebuild initramfs"
echo_group /ctx/build-initramfs.sh

log "Post build cleanup"
echo_group /ctx/cleanup.sh

log "Build complete"
