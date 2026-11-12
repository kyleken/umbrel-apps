# syntax=docker/dockerfile:1
#
# Build context: images/ (the folder above this one).
#
# MailCraft (https://github.com/UCS-Care-Group/mailcraft) streamed to the browser with Neko
# (https://github.com/m1k1o/neko). Neko sends the screen over WebRTC, which works over plain
# HTTP, as Umbrel serves its apps.

# ---- Build stage: compile MailCraft from source --------------------------------------------
FROM rust:1-trixie AS build

ARG MAILCRAFT_REPO=https://github.com/UCS-Care-Group/mailcraft
# A branch, a tag (e.g. v0.12.0) or a commit.
ARG MAILCRAFT_REF=main
# Optional: your own Google OAuth "Desktop app" client, for Add Account > Sign in with Google.
# Builds from source have none; without it, Gmail works with an app password.
ARG MAILCRAFT_GOOGLE_CLIENT_ID=
ARG MAILCRAFT_GOOGLE_CLIENT_SECRET=

RUN apt-get update \
 && apt-get install -y --no-install-recommends git pkg-config libxkbcommon-dev libwayland-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git init -q mailcraft \
 && cd mailcraft \
 && git remote add origin "$MAILCRAFT_REPO" \
 && git fetch -q --depth 1 origin "$MAILCRAFT_REF" \
 && git checkout -q FETCH_HEAD

WORKDIR /src/mailcraft
RUN if [ -n "$MAILCRAFT_GOOGLE_CLIENT_ID" ]; then \
      export MAILCRAFT_GOOGLE_CLIENT_ID MAILCRAFT_GOOGLE_CLIENT_SECRET; \
    else \
      unset MAILCRAFT_GOOGLE_CLIENT_ID MAILCRAFT_GOOGLE_CLIENT_SECRET; \
    fi \
 && cargo build --release --locked -p mailcraft \
 && install -Dm755 target/release/mailcraft /out/mailcraft

# ---- Runtime stage: Neko's desktop with MailCraft as its app -------------------------------
FROM ghcr.io/m1k1o/neko/base:3.2.0

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      openbox \
      libxkbcommon0 libxkbcommon-x11-0 libx11-6 libx11-xcb1 libxcursor1 libxi6 libxrandr2 \
      libegl1 libgl1-mesa-dri libvulkan1 mesa-vulkan-drivers \
      dbus dbus-bin gnome-keyring xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils \
      ca-certificates firefox-esr fonts-dejavu-core fonts-liberation2 \
      iproute2 socat; \
    apt-get clean -y; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*; \
    # Folders the data volumes are mounted into: create them owned by the neko user, so that
    # Docker doesn't create their parents as root.
    install -d -o neko -g neko /home/neko/.config /home/neko/.config/mailcraft \
      /home/neko/.local /home/neko/.local/share /home/neko/.local/share/keyrings \
      /home/neko/.mozilla /home/neko/Files

COPY --from=build /out/mailcraft /usr/local/bin/mailcraft
COPY common/root/ /
COPY neko/root/ /

# Run Neko's server through neko-serve, which gives it this machine's LAN and Tailscale
# addresses for the video stream.
RUN set -eux; \
    chmod 755 /usr/local/bin/*; \
    sed -i 's#^command=/usr/bin/neko serve#command=/usr/local/bin/neko-serve#' /etc/neko/supervisord.conf; \
    grep -q '^command=/usr/local/bin/neko-serve' /etc/neko/supervisord.conf

ENV NEKO_DESKTOP_SCREEN=1920x1080@30 \
    NEKO_SESSION_IMPLICIT_HOSTING=true \
    NEKO_FILETRANSFER_ENABLED=true \
    NEKO_FILETRANSFER_DIR=/home/neko/Files \
    BROWSER=firefox-esr \
    XDG_CURRENT_DESKTOP=openbox

CMD ["/usr/local/bin/mailcraft-neko-start"]
