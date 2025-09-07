
install-system-flatpaks:
    #!/usr/bin/bash
    FLATPAK_LIST="$(curl https://raw.githubusercontent.com/kohega/bazzite-khg/refs/heads/main/system_files/usr/share/kohega/flatpaks | tr '\n' ' ')"
    flatpak --system -y install ${FLATPAK_LIST}

install-appimages:
    #!/usr/bin/env bash
    set -euo pipefail

    DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-${HOME}/Downloads}"
    [ ! -d "$DOWNLOAD_DIR" ] && DOWNLOAD_DIR="$HOME"

    # Install Gear Lever if not installed
    flatpak list | grep -q "it.mijorus.gearlever" || flatpak --system -y install it.mijorus.gearlever

    while IFS=, read -r name url; do
      [ -z "$name" -o -z "$url" ] && continue
      echo "Processing $name..."

      # Skip if installed
      if flatpak run it.mijorus.gearlever --list-installed | grep -qi "${name}.appimage"; then
        echo "$name already installed"
        continue
      fi

      # Handle GitHub wildcards
      if [[ "$url" =~ github.com/([^/]+/[^/]+)/releases/download/[^/]*/([^/]*) ]] && [[ "$url" == *"*"* ]]; then
        pattern="$(echo "${BASH_REMATCH[2]}" | sed 's/\./\\./g' | sed 's/\*/.*/g')"
        # Try each release until we find one with an AppImage
        url=""
        while read -r release_url; do
          if [[ "$release_url" =~ $pattern ]]; then
            url="$release_url"
            break
          fi
        done < <(curl --retry 3 -sL "https://api.github.com/repos/${BASH_REMATCH[1]}/releases" | jq -r ".[].assets[].browser_download_url")
        [ -z "$url" ] && {
          echo "No release found for $name"
          continue
        }
      fi

      # Handle JSON API responses (like cursor.com API)
      if [[ "$url" != http*github.com* ]]; then
        response=$(curl --retry 3 -sL "$url")
        if echo "$response" | jq -e '.downloadUrl' >/dev/null 2>&1; then
          url=$(echo "$response" | jq -r '.downloadUrl')
          echo "  Found download URL in JSON: $url"
        elif echo "$response" | jq -e '.download_url' >/dev/null 2>&1; then
          url=$(echo "$response" | jq -r '.download_url')
          echo "  Found download URL in JSON: $url"
        fi
      fi

      # Download and install
      appimage="$DOWNLOAD_DIR/${name}.appimage"
      if aria2c --dir="$(dirname "$appimage")" --out="$(basename "$appimage")" --max-tries=3 --connect-timeout=30 "$url" && chmod +x "$appimage" && flatpak run it.mijorus.gearlever --integrate "$appimage" -y; then
        echo "$name installed successfully"
      else
        echo "Failed to install $name"
      fi
      rm -f "$appimage"
    done < <(/usr/share/kohega/appimages)
    echo "AppImages installation complete."

# Restart Bluetooth to fix issues
fix-bt:
    #!/usr/bin/env bash
    set -euo pipefail
    trap '[[ $BASH_COMMAND != echo* ]] && echo "+ $BASH_COMMAND"' DEBUG

    echo "Fixing Bluetooth..."
    sudo rfkill unblock all
    sudo rmmod btusb
    sudo modprobe btusb
    echo "Bluetooth fix complete."

# Clean up old packages and Docker/Podman images and volumes
clean:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Cleaning up system..."
    docker system prune -af
    podman system prune -af
    flatpak uninstall --unused
    rpm-ostree cleanup -bm
    nix-collect-garbage -d
    sudo docker system prune -af
    sudo podman system prune -af
    sudo -i nix-collect-garbage -d

# Enable AMD GPU overclocking capability. This can then be changed in for example LACT.
enable-amdgpu-oc:
  #!/usr/bin/env bash
  set -euo pipefail

  echo "Enabling AMD GPU overclocking"

  if ! rpm-ostree kargs | grep -q "amdgpu.ppfeaturemask="; then
    echo "Updating rpm-ostree kernel arguments"
    sudo rpm-ostree kargs --append "amdgpu.ppfeaturemask=0xFFF7FFFF"
  else
    echo "Already enabled"
  fi

# Add a Virtual Display from a EDID file
virtual-display:
  #!/usr/bin/env bash
  set -euo pipefail

  echo "Enabling Virtual Dummy Display"

  if ! rpm-ostree kargs | grep -q "drm.edid_firmware="; then
    echo "Updating rpm-ostree kernel arguments"
    sudo rpm-ostree kargs --append "drm.edid_firmware=HDMI-A-1:edid/dummy-full.bin video=HDMI-A-1:e"
  else
    echo "Already enabled"
  fi

howdy-setup:
  #!/usr/bin/env bash
  sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
  sudo cp /etc/pam.d/kde /etc/pam.d/kde.bak
  sudo sed -i '2i\auth       sufficient   pam_howdy.so no_confirmation' /etc/pam.d/sudo  
  sudo sed -i '2i\auth       sufficient   pam_howdy.so no_confirmation' /etc/pam.d/sddm
  sudo sed -i '2i\auth       sufficient   pam_howdy.so no_confirmation' /etc/pam.d/kde
  sudo chmod o+rw /dev/video*
  sudo chmod 666 /dev/video*
  sudo chmod 755 /usr/lib64/security/pam_howdy.so
  sudo usermod -aG video gdm
  sudo checkmodule -M -m -o /etc/howdy/howdy.mod /etc/howdy/howdy.te
  sudo semodule_package -o /etc/howdy/howdy.pp -m /etc/howdy/howdy.mod
  sudo semodule -i /etc/howdy/howdy.pp
  PAM_FILES=(
  /etc/pam.d/sudo
  /etc/pam.d/gdm-password
  /etc/pam.d/gdm-fingerprint
  /etc/pam.d/login
  /etc/pam.d/system-auth
  /etc/pam.d/password-auth
  /etc/pam.d/su
)

for pam_file in "${PAM_FILES[@]}"; do
  if [[ -f "$pam_file" ]]; then
    if ! grep -q "pam_howdy.so" "$pam_file"; then
      echo "📌 Inserting into $pam_file"
      sudo sed -i '1i auth sufficient pam_howdy.so' "$pam_file"
    else
      echo "✅ Already present in $pam_file"
    fi
  else
    echo "⚠️  PAM file $pam_file not found — skipping"
  fi
  sudo howdy add
  sudo howdy test