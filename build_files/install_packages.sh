#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

# Remove pre-installed flatpak apps
log "Remove pre-installed Flatpaks"

# flatpak remove --delete-data -y io.github.pwr_solaar.solaar org.mozilla.Thunderbird org.mozilla.firefoxorg.kde.kcalc org.kde.skanpage org.kde.kontact org.kde.gwenview org.kde.kontact org.kde.okular org.kde.kweather org.kde.kclock org.fkoehler.KTailctl org.kde.haruna io.github.input_leap.input-leap org.gustavoperedo.FontDownloader

log "Enable Copr repos"

COPR_REPOS=(
    ilyaz/LACT
    zliced13/YACR
    atim/heroic-games-launcher
)
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

log "Install layered applications"

# Layered Applications
LAYERED_PACKAGES=(
    aria2c
    kcalc
    konsole
    kate
    krename
    haruna
    okular
    syncthing
    filezilla
    firefox
    firefox-langpacks
    lact
    SDL2_ttf
    SDL2_image
    inih
    kget
    heroic-games-launcher-bin
    v4l2loopback
    v4l2loopback-kmod
    gamescope.x86_64
    gamescope-libs.x86_64
    gamescope-libs.i686
    gamescope-shaders
    umu-launcher
    dbus-x11
    xdg-user-dirs
    gobject-introspection
    libFAudio.x86_64
    libFAudio.i686
    vkBasalt.x86_64
    vkBasalt.i686
    mangohud.x86_64
    mangohud.i686
    libobs_vkcapture.x86_64
    libobs_glcapture.x86_64
    libobs_vkcapture.i686
    libobs_glcapture.i686
    VK_hdr_layer
    steam
    lutris
)
dnf5 install --setopt=install_weak_deps=False --allowerasing --skip-unavailable -y "${LAYERED_PACKAGES[@]}"

/ctx/ghcurl "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" --retry 3 -Lo /usr/bin/winetricks && \
    chmod +x /usr/bin/winetricks && \

log "Disable Copr repos as we do not need it anymore"

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done

log "Installing RPM packages"

# Install RPMs
for rpm_file in ctx/rpm/*.rpm; do
    if [ -f "$rpm_file" ]; then
        dnf5 install -y "$rpm_file"
    fi
done

log "Installing ZeroTier"
# Add ZeroTier GPG key
curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | tee /etc/pki/rpm-gpg/RPM-GPG-KEY-zerotier

# Add ZeroTier repository
cat << 'EOF' | tee /etc/yum.repos.d/zerotier.repo
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=http://download.zerotier.com/redhat/fc/42
enabled=1
gpgcheck=0
EOF

# Install ZeroTier
dnf install -y zerotier-one

# Remove repos
rm /etc/yum.repos.d/zerotier.repo -f


