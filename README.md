# Homelab app store for Umbrel: MailCraft

An Umbrel community app store for [MailCraft](https://github.com/UCS-Care-Group/mailcraft). The
MailCraft desktop program runs once on your Umbrel and its window is streamed to your browser.
Every computer you open it from, on your LAN or your tailnet, sees the same mailbox.

There are two versions of the app. Install one (each keeps its own mailbox):

| App | Streams with | Best for |
|---|---|---|
| **MailCraft (HTTPS)** | [Selkies](https://docs.linuxserver.io/selkies/) | Sharper picture that follows your browser window's size. Needs umbrelOS 2 and opens over HTTPS. |
| **MailCraft (Neko)** | [Neko](https://github.com/m1k1o/neko) | Works over plain HTTP on any umbrelOS, but needs two extra ports (52480, 52481) and a fixed screen size. |

## What's here

| Path | Purpose |
|---|---|
| `umbrel-app-store.yml` | The store's id (`homelab`) and name |
| `homelab-mailcraft-https/` | The Selkies app: its listing (`umbrel-app.yml`) and container (`docker-compose.yml`) |
| `homelab-mailcraft/` | The Neko app |
| `images/selkies/`, `images/neko/` | The two container images: MailCraft compiled from source on each streamer's base image |
| `images/common/` | What both images share: the script that starts MailCraft with its keyring and file chooser |
| `.github/workflows/build-mailcraft.yml` | Builds both images for x86 and ARM, publishes them, and points the apps at them |

Umbrel only reads folders that contain an `umbrel-app.yml`, so `images/` doesn't show up as an
app.

## Setup

1. **Make a public GitHub repository** (for example `umbrel-apps`) and push this folder's
   contents to it. It has to be public so your Umbrel can read it.
2. **Build the images:** in the repository, go to **Actions › Build MailCraft images › Run
   workflow**. The first run compiles MailCraft for x86 and for ARM (side by side) and takes
   roughly 30 to 45 minutes. When it finishes, it commits the new images and version into both
   app folders.
3. **Make the images public:** on your GitHub profile, go to **Packages**, and for both
   **mailcraft-selkies** and **mailcraft-neko** open **Package settings › Change visibility ›
   Public**. GitHub makes new images private, and Umbrel can't download a private one. You only
   do this once.
4. **Add the store to Umbrel:** **App Store › ⋯ (top right) › Community App Stores**, paste the
   repository's URL, and add it. Open the **Homelab** store and install one of the two apps.
5. **Open it** from the Umbrel home screen. MailCraft opens on **Add Account**.
   - **MailCraft (HTTPS):** your browser opens it at `https://`. The first time on each computer
     you'll get a certificate warning, because the certificate comes from your Umbrel. To get rid
     of it, install Umbrel's certificate from **Settings › Advanced › HTTPS access** (it walks
     you through each kind of device), or accept the warning for this address. The Umbrel's
     certificate covers its LAN and Tailscale addresses.
   - **MailCraft (Neko):** Umbrel shows the app's password. Sign in with any name and that
     password.

## Using it (both apps)

- **Accounts:** Microsoft 365 and Outlook.com sign in on Microsoft's page, which opens in a
  Chromium window inside the stream (switch to Firefox with `MAILCRAFT_SIGNIN_BROWSER` in the
  app's settings). For Gmail, use an app password (Google Account › Security ›
  App passwords). IMAP/SMTP servers work as usual. "Remember password" stores passwords in a
  keyring inside the app's data, encrypted with a key only this Umbrel app has.
- **Several computers:** everyone sees and controls the same screen, like screen sharing.
- **Closing MailCraft's window:** it reopens by itself after a few seconds.
- **Time zone:** set `TZ` in the app's settings in Umbrel (they apply after the app restarts).
- **Updates:** every Monday the workflow checks for a new MailCraft release. If there is one, it
  builds it and Umbrel offers the update for both apps. Run the workflow by hand to build sooner,
  or to build a particular version (a tag such as `v0.12.0`, a branch, or a commit).

## MailCraft (HTTPS) notes

- **Login:** Umbrel's own login protects it, as with other Umbrel apps.
- **Attachments:** use the file panel in the Selkies sidebar. Uploads land in the **Files**
  folder, which MailCraft's Attach dialog can open; save attachments there to download them.
- **Copy and paste** between your computer and MailCraft works through the browser's clipboard
  (allow it when the browser asks), or the clipboard section of the sidebar.
- No terminal or command running is offered in the browser (`HARDEN_DESKTOP`).

## MailCraft (Neko) notes

- **Login:** any name and the password Umbrel shows for the app.
- **Control:** the first person in gets control; Neko's controls let another person take it.
- **Attachments:** upload files with the file transfer panel in Neko's sidebar. They land in the
  **Files** folder, which MailCraft's Attach dialog can open. Attachments you save to Files can
  be downloaded from the same panel.
- **Settings** besides `TZ`:
  - `NEKO_DESKTOP_SCREEN`: the stream's size. Smaller is easier on the Umbrel's processor.
  - `MAILCRAFT_EXTRA_ADDRESSES`: more addresses browsers reach the Umbrel on (see below).

### How the Neko connection works

The page itself goes through Umbrel's normal app proxy. The video uses WebRTC, which browsers
connect to directly:

- `52480/tcp`: Neko's web server (also reachable directly at `http://<umbrel>:52480`).
- `52481/udp` and `52481/tcp`: the video stream.

The container uses the host's network, so it can see the Umbrel's addresses. At startup it tells
Neko the Umbrel's LAN address, plus its Tailscale address when Umbrel's **Tailscale** app is
running. If the Tailscale address appears or changes later, Neko restarts by itself within 30
seconds (MailCraft keeps running). If you reach the Umbrel some other way, add that address in
`MAILCRAFT_EXTRA_ADDRESSES`.

## Optional: Sign in with Google

Builds from source don't include MailCraft's own Google registration. To get **Sign in with
Google**, create a Google OAuth client of type "Desktop app", then add
`MAILCRAFT_GOOGLE_CLIENT_ID` and `MAILCRAFT_GOOGLE_CLIENT_SECRET` as repository secrets (Settings
› Secrets and variables › Actions) and run the workflow.

## Changing the store or app id

If you rename `homelab`, change it consistently in `umbrel-app-store.yml`, both app folders'
names, `id:` in each `umbrel-app.yml`, `APP_HOST` in each `docker-compose.yml`
(`<app-id>_server_1` for HTTPS, `<app-id>_relay_1` for Neko) and `APP_DIR` / `HTTPS_APP_DIR` in
the workflow.

## Troubleshooting

- **HTTPS app shows a blank page or keeps reconnecting:** make sure it opened at `https://`.
  Selkies' video only works on secure pages.
- **HTTPS app won't install:** it needs umbrelOS 2 or later (it declares manifest version 2.0).
  Update the Umbrel, or use the Neko app.
- **Neko app loads but stays black or says it's connecting:** the browser can't reach port 52481.
  Check that it's the address you opened the app on (LAN or Tailscale), and add any other address
  to `MAILCRAFT_EXTRA_ADDRESSES`.
- **Install fails pulling the image:** the image is still private (setup step 3), or the
  workflow hasn't finished yet.
- **Logs:** Umbrel's app troubleshooting view. For the Neko app, also
  `docker exec homelab-mailcraft_server_1 tail -n 50 /var/log/neko/mailcraft.log` on the Umbrel
  (and `neko.log`, `address-watch.log`). MailCraft's own log is in its settings folder:
  `.config/mailcraft/logs/mailcraft.log` in the app's data.
