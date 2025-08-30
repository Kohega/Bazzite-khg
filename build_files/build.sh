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
log "Install layered applications"

# KDE Applications
LAYERED_PACKAGES=(
  kget
  kate
  okular
  gwenview
  haruna
  ark
  kcalc
  konsole
  krename
)
dnf5 install -y \
    --setopt=install_weak_deps=False \
    --allowerasing \
    --skip-unavailable \
    "${LAYERED_PACKAGES[@]}"

echo_group /ctx/install_packages.sh

dnf5 install -y ctx/rpm/kde/kvantum-1.1.5-1.fc42.x86_64.rpm

log "Allow Samba on home dirs"
setsebool -P samba_enable_home_dirs=1

log "Enable loading kernel modules"
setsebool -P domain_kernel_load_modules on

log "Enabling system services"
systemctl enable sshd.service podman.socket syncthing@kohega.service zerotier-one.service lactd.service smb.service coolercontrold.service

log "Adding personal just recipes"
echo "import \"/usr/share/kohega/just/kohega.just\"" >> /usr/share/ublue-os/justfile

#log "Rebuild initramfs"
#echo_group /ctx/build-initramfs.sh

log "Post build cleanup"
echo_group /ctx/cleanup.sh

log "Build complete"
