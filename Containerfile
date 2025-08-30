# Define build arguments with default values
ARG IMAGE_VARIANT="default"
ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite:stable"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /build_files

FROM ${BASE_IMAGE} AS base
RUN dnf install -y bash coreutils

# Prepare directories and files
RUN mkdir -p /data /videos /games /usr/share/kohega/just

# Remove unnecessary files
RUN rm -f /usr/share/ublue-os/bazzite/flatpak/install

# Copy system files
COPY system_files/shared system_files/${BASE_IMAGE_NAME} /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-initramfs && \
    /ctx/finalize

# LINTING
# Verify final image and contents are correct.
RUN bootc container lint