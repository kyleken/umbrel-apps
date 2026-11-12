# syntax=docker/dockerfile:1
#
# Build context: images/ (the folder above this one).
#
# MailCraft (https://github.com/UCS-Care-Group/mailcraft) streamed to the browser with Selkies
# (linuxserver.io's browser desktop). Selkies' video needs HTTPS; on Umbrel, umbrelOS provides
# it (requiresHttps in the app's manifest).

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

# ---- Runtime stage: Selkies desktop with MailCraft as its only app ------------------------
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

ENV TITLE=MailCraft \
    PIXELFLUX_WAYLAND=true

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      # MailCraft's own runtime libraries (from its .deb packaging)
      libxkbcommon0 libxkbcommon-x11-0 libwayland-client0 libx11-6 libx11-xcb1 \
      libxcursor1 libxi6 libxrandr2 \
      # Drawing without a GPU: Mesa's software OpenGL/Vulkan
      libegl1 libgl1-mesa-dri libvulkan1 mesa-vulkan-drivers \
      # Session bus, password storage and the file chooser used by Open/Save/Attach
      dbus dbus-bin gnome-keyring xdg-desktop-portal xdg-desktop-portal-gtk xdg-utils \
      # TLS certificates, a browser for Microsoft sign-in pages, fonts for HTML mail
      ca-certificates firefox-esr fonts-dejavu-core fonts-liberation2 \
 && apt-get autoclean \
 && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

COPY --from=build /out/mailcraft /usr/local/bin/mailcraft
COPY common/root/ /
COPY selkies/root/ /
RUN chmod 755 /usr/local/bin/mailcraft-session

EXPOSE 3000
VOLUME /config
