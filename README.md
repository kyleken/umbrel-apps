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
- openGym: `http://<umbrel-tailscale-name>:18090`, after setting `ORIGIN` (below)

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

openGym runs here over plain http, and you sign in with your profile name and a password.
Use it over Tailscale, which encrypts the traffic between your devices. Nothing is opened to
the internet.

What the package sets up:

- Images pinned to openGym `1.4.5`; data in `data/opengym` of the app's folder.
- The first profile becomes the admin and owner. It needs a **setup code**: the password
  umbrelOS shows on the app's page. Once that profile exists the code is gone, and new
  profiles need an invite code from the admin dashboard (`INVITE_ONLY=1`).
- Password sign-in on (`PASSWORD_LOGIN=1`), guest mode off (`ALLOW_GUEST=0`), AI Coach off.
- The icon is openGym's own logo (`frontend/public/icon-512.png` from openGym v1.4.5, © Duarte
  Santos, AGPL-3.0). This package is not made or endorsed by the openGym project.
- Umbrel's own login is off for this app. It would block the phone app, and openGym has its
  own sign-in.

Over plain http you don't get passkeys, offline use, push notifications, or the iPhone app
(the Android app can connect over http). Those need HTTPS, which can be added later without
losing data.

### 1. Pick one address and set ORIGIN

openGym accepts sign-ins from exactly one http address, the one in `ORIGIN`. Use your
Umbrel's Tailscale name, so the same address works on the laptop and the phone, at home and
away:

- `ORIGIN=http://umbrel.tail1234.ts.net:18090` (your Umbrel's MagicDNS name from the
  Tailscale admin console; or its `100.x` Tailscale IP if MagicDNS is off)
- `RP_ID=umbrel.tail1234.ts.net` (the same host, no `http://`, no port)

Type the address exactly like that on every device. `http://umbrel.local:18090`, the
Umbrel dashboard tile, or a short name like `http://umbrel:18090` will open the page but
refuse to sign in.

On umbrelOS 2.x, set both in the app's settings in umbrelOS, then restart the app. On
umbrelOS 1.x, put the two lines in `~/umbrel/app-data/kyle-opengym/data/settings/opengym.env`
(with `sudo`) and restart the app. That file, if present, wins over everything else.

### 2. Create your admin profile

1. Copy the password from openGym's page in umbrelOS.
2. Open your `ORIGIN` address, choose **Create new profile**, pick a name and a long
   password (10+ characters; a passphrase is best), and paste the copied password as the
   invite code. The field keeps the first 40 characters; that's expected.
3. Check **Settings → Account → Admin dashboard** is there.

### 3. Phone and laptop

Install Tailscale on each device and connect it to the same tailnet. Open the `ORIGIN`
address and sign in with your profile name and password. On a phone you can add it to the
home screen as a shortcut. Tailscale has to be connected to use openGym, at home too.

On Android you can also use the openGym app: choose **Connect to my server**, type the
`ORIGIN` address including `http://`, and enter the code from **Settings → Account → Pair
the mobile app** in a signed-in browser. The app then works offline and syncs when Tailscale
reconnects.

### 4. Back up

Everything is in `~/umbrel/app-data/kyle-opengym/data/opengym` (accounts, workouts,
uploads, and `secret`, which signs sessions). Umbrel's own backups include it. For a manual
copy, stop the app in umbrelOS, then:

```sh
sudo tar czf ~/opengym-$(date +%F).tar.gz -C ~/umbrel/app-data/kyle-opengym/data opengym
```

Restore by stopping the app, extracting that archive into the same folder, and starting it.
Each person can also export their own data in **Settings → Data & backup**. The archive holds
password hashes and the activity log, so keep it private.

### Forgot the password?

Admins can't reset their own password from the dashboard. Keep it in a password manager.
If it's lost anyway, see "Recovery codes" in openGym's `docs/SELF_HOSTING.md`.

### Updating

Change both image tags in `kyle-opengym/docker-compose.yml` and `version` in
`umbrel-app.yml`, push, then remove and re-add the store in umbrelOS and click **Update**.
