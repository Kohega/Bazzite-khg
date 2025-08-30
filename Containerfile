# Define build arguments with default values
ARG IMAGE_VARIANT="default"
ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite:stable"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /build_files

# Bazzite KDE
FROM ${BASE_IMAGE} AS bazzite-khg
RUN rm /usr/share/ublue-os/bazzite/flatpak/install
COPY system_files/shared system_files/${BASE_IMAGE_NAME} /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \

    ostree container commit
# LINTING
# Verify final image and contents are correct.   
RUN bootc container lint

# Bazzite GNOME
FROM ${BASE_IMAGE} AS bazzite-gnome-khg
RUN rm /usr/share/ublue-os/bazzite/flatpak/install
COPY system_files/shared system_files/${BASE_IMAGE_NAME} /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build-gnome.sh && \

    ostree container commit

# LINTING
# Verify final image and contents are correct.
RUN bootc container lint