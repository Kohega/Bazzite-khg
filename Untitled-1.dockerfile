
        
        atim/heroic-games-launcher \
        zeno/scrcpy \
        codifryed/CoolerControl \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable "$copr"; \
    done && \
    # dnf5 -y install \
    #     https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    #     https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


# Install packages
RUN dnf5 -y install --setopt=install_weak_deps=False \
    syncthing \
    filezilla \
    firefox \
    firefox-langpacks \
    lact \
    SDL2_ttf \
    SDL2_image \
    inih \
    heroic-games-launcher-bin \
    kodi \
    kodi-inputstream-adaptive \
    audacity \
    bleachbit \
    scrcpy \
    virt-manager \
    gh \
    qbittorrent \
    discord \
    coolercontrold \
    usbmuxd

# Perform cleanup
RUN dnf5 clean all && \
    rm -rf /tmp/* && \
    find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \; && \
    find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \; && \
    mkdir -p /tmp && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp && \
    echo "Cleanup completed"

# Install KDE and GNOME apps conditionally
RUN if grep -q "bazzite" <<< "${BASE_IMAGE_NAME:-}"; then \
        dnf5 install --setopt=install_weak_deps=False --allowerasing --skip-unavailable --enable-repo="*rpmfusion*" -y \
            kcalc \
            konsole \
            kate \
            krename \
            haruna \
            okular \
            gwenview \
            ark \
            filelight \
            kget; \
    #; else \
    #    dnf5 install --setopt=install_weak_deps=False --allowerasing --skip-unavailable --enable-repo="*rpmfusion*" -y \
    #        nemo \
    #        ulauncher \
    #        clapper; \
    #; fi \


# Install ZeroTier
RUN log "Starting ZeroTier installation" && \
    curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | tee /etc/pki/rpm-gpg/RPM-GPG-KEY-zerotier && \
    cat << 'EOF' > /etc/yum.repos.d/zerotier.repo && \
[zerotier] \
name=ZeroTier, Inc. RPM Release Repository \
baseurl=http://download.zerotier.com/redhat/fc/42 \
enabled=1 \
gpgcheck=0 \
EOF \
    dnf install -y zerotier-one && \
    rm /etc/yum.repos.d/zerotier.repo -f \

# SELinux configurations
RUN setsebool -P samba_enable_home_dirs=1 && \
    setsebool -P domain_kernel_load_modules on

# Enable services
RUN systemctl enable podman.socket syncthing@kohega.service zerotier-one.service lactd.service smb.service

# Add personal just recipes
RUN echo "Adding personal just recipes" && \
    echo "import \"/usr/share/kohega/just/kohega.just\"" >> /usr/share/ublue-os/justfile

# Rebuild initramfs
RUN KERNEL_VERSION="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel)" && \
    /usr/bin/dracut \
      --no-hostonly \
      --kver "$KERNEL_VERSION" \
      --reproducible \
      --zstd \
      -v \
      --add ostree \
      -f "/usr/lib/modules/$KERNEL_VERSION/initramfs.img" && \
    chmod 0600 "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"
