# Kyle's Umbrel App Store

Community app store for umbrelOS.

| App | What it does |
| --- | --- |
| **MS Mail** (`kyle-ms-mail`) | Recommended. Windows 11 Enterprise LTSC VM with the new Outlook, plus Apache Guacamole, so Outlook opens in any browser with clipboard and audio. |
| **Outlook Box** (`kyle-outlook-box`) | Just the Windows VM with the new Outlook, viewed with the basic built-in web viewer or RDP on port 3389. |
| **openGym** (`kyle-opengym`) | Self-hosted gym tracker ([openGym](https://github.com/DuarteSantos8/openGym) 1.4.5, AGPL-3.0). Port 18090. See [openGym](#opengym) below. |

Install MS Mail or Outlook Box, not both: each one runs its own Windows VM.

## Add to Umbrel

In umbrelOS: **App Store → ⋯ (top right) → Community App Stores**, paste
`https://github.com/kyleken/umbrel_outlook_box`, click **Add**, then **Open**.

## Reach it over Tailscale

Install the official **Tailscale** app from the Umbrel App Store and sign in.
Then from any device on your tailnet open:

- MS Mail: `http://<umbrel-tailscale-name>:18080`
- Outlook Box: `http://<umbrel-tailscale-name>:18006`, or RDP to `<umbrel-tailscale-name>:3389`
- openGym: use its HTTPS address from Tailscale Serve (below)

## Notes (MS Mail and Outlook Box)

- Needs an x86 Umbrel with VT-x / AMD-V enabled. About 4-4.5 GB RAM and up to 64 GB disk.
- First boot downloads and installs Windows unattended (20-40 min).
- `windows-setup/setup.ps1` runs once at the end of the Windows install. It
  installs the new Outlook, allows RemoteApp, and turns off automatic sign-in. Its log
  is at `C:\OEM\setup-log.txt`. To re-run it by hand, open PowerShell as
  Administrator in Windows and run:
  `iwr -UseBasicParsing https://raw.githubusercontent.com/kyleken/umbrel_outlook_box/main/windows-setup/setup.ps1 | iex`
- Both apps install the full Windows 11 Enterprise LTSC 2024 image (the
  `11l` evaluation image expires and shuts down every hour). Activate it with
  your own key inside Windows: Settings → System → Activation → Change
  product key. Never put your key in this public repo.
- If your key is for **IoT** Enterprise LTSC, change `VERSION` to
  `win11x64-enterprise-iot` in the app's `docker-compose.yml` before installing.
- This repo must stay **public**: the Windows VM downloads `setup.ps1` from it.

## openGym

openGym signs in with passkeys, which browsers allow only over HTTPS. The package runs fine
over plain `http://umbrel.local:18090` with a name and password, but passkeys, the iPhone
app, offline use and notifications need HTTPS. The private way to get that is Tailscale
Serve: a `https://<umbrel>.<tailnet>.ts.net` address with a real certificate, reachable only
from your tailnet. Nothing here uses Tailscale Funnel or opens anything to the internet.

What the package sets up:

- Images pinned to openGym `1.4.5`; data in `data/opengym` of the app's folder.
- The first profile becomes the admin and owner. It needs a **setup code**: the password
  umbrelOS shows on the app's page. Once that profile exists the code is gone, and new
  profiles need an invite code from the admin dashboard (`INVITE_ONLY=1`).
- Password sign-in on (`PASSWORD_LOGIN=1`), guest mode off (`ALLOW_GUEST=0`), AI Coach off.
- Umbrel's own login is off for this app. It would block the Tailscale Serve address and the
  phone app, and openGym has its own sign-in.

### 1. Turn on Tailscale Serve

1. Install the **Tailscale** app on Umbrel and sign in.
2. In the Tailscale admin console, on the **DNS** page, turn on **MagicDNS** and
   **HTTPS Certificates**.
3. SSH in (`ssh umbrel@umbrel.local`) and run:

   ```sh
   sudo docker exec tailscale_web_1 tailscale serve --bg --https=443 http://127.0.0.1:18090
   sudo docker exec tailscale_web_1 tailscale serve status
   ```

   The first command may print a link to approve Serve for your tailnet; open it, then run it
   again. `status` shows the address, such as `https://umbrel.tail1234.ts.net`. If port 443
   is already used by another Serve setup, use `--https=8443` and add `:8443` to `ORIGIN`.
   To undo: `sudo docker exec tailscale_web_1 tailscale serve --https=443 off`.

### 2. Point openGym at that address

Set these, then restart the app:

- `ORIGIN=https://umbrel.tail1234.ts.net` (your address, no trailing slash)
- `RP_ID=umbrel.tail1234.ts.net` (the same host, no `https://`)

On umbrelOS 2.x, set them in the app's settings in umbrelOS. On umbrelOS 1.x, put the two
lines in `~/umbrel/app-data/kyle-opengym/data/settings/opengym.env` (with `sudo`). That file,
if present, wins over everything else.

Do this before you register: passkeys are bound to `RP_ID`, so changing it later makes
existing passkeys stop working (passwords keep working).

### 3. Create your admin profile

1. Copy the password from openGym's page in umbrelOS.
2. Open your `https://…ts.net` address, choose **Create new profile**, and paste it as the
   invite code (the field keeps the first 40 characters; that's expected).
3. Use a passkey. Then, as a fallback, set a long password in **Settings → Account →
   Password**.
4. Check **Settings → Account → Admin dashboard** is there.

Skipping Tailscale for now? Create the profile at `http://umbrel.local:18090` with a
password instead, and switch `ORIGIN`/`RP_ID` later; then add a passkey from Settings.

### 4. Phone

Install Tailscale on the phone and connect it to the same tailnet, then either:

- open the `https://…ts.net` address, sign in, and add it to the home screen; or
- install the openGym app (App Store, or the APK on Android), choose **Connect to my
  server**, enter the address, and enter the code from **Settings → Account → Pair the
  mobile app** on a signed-in browser.

Both keep working offline and sync when Tailscale reconnects.

After switching to HTTPS, the Umbrel dashboard tile opens `http://umbrel.local:18090`,
where sign-in is refused. Use the `ts.net` address (on umbrelOS 2.x,
`https://umbrel.local:18090` also works for password sign-in).

### 5. Back up

Everything is in `~/umbrel/app-data/kyle-opengym/data/opengym` (accounts, passkeys,
workouts, uploads, and `secret`, which signs sessions). Umbrel's own backups include it. For
a manual copy, stop the app in umbrelOS, then:

```sh
sudo tar czf ~/opengym-$(date +%F).tar.gz -C ~/umbrel/app-data/kyle-opengym/data opengym
```

Restore by stopping the app, extracting that archive into the same folder, and starting it.
Each person can also export their own data in **Settings → Data & backup**. The archive holds
password hashes and the activity log, so keep it private.

### Updating

Change both image tags in `kyle-opengym/docker-compose.yml` and `version` in
`umbrel-app.yml`, push, then remove and re-add the store in umbrelOS and click **Update**.
