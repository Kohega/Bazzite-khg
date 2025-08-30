# Define build arguments with default values
ARG IMAGE_VARIANT="default"
ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite:stable"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Bazzite KDE
FROM ${BASE_IMAGE} AS base
RUN rm /usr/share/ublue-os/bazzite/flatpak/install
COPY system_files /
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \

    ostree container commit

# Bazzite KDE
FROM ${BASE_IMAGE} AS base-gnome
RUN rm /usr/share/ublue-os/bazzite/flatpak/install
COPY system_files /
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-gnome.sh && \

    ostree container commit

RUN bootc container lint