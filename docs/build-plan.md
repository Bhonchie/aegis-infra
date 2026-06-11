# 🏠 Aegis — Home Infrastructure Build Plan

**Server:** GEEKOM A7 MAX AI Mini PC
**Hostname:** `aegis`
**Static IP:** `192.168.1.100`
**OS:** Ubuntu Server LTS
**Stack:** Docker + Docker Compose + Portainer
**Last Updated:** 2026-04-30

---

## 📦 Hardware Inventory

### Compute
| Item | Detail |
|---|---|
| Machine | GEEKOM A7 MAX |
| CPU | AMD Ryzen 9 7940HS — 8-core/16-thread, 4.0–5.2 GHz |
| RAM | 16GB DDR5 5600MHz (expandable to 96GB — upgrade later) |
| Internal SSD | 1TB NVMe PCIe 4.0 — OS + Docker + app configs |
| GPU | AMD Radeon 780M (integrated) |
| NPU | 16 TOPS — local AI inference |
| Network | Dual 2.5GbE + Wi-Fi 6E |
| PCIe x4 | Available for future HBA/expansion |

### Storage (DAS — in transit)
| Item | Detail |
|---|---|
| Enclosure | Terramaster D4-320 (4-bay, USB-C 3.2 Gen 2x2, 20Gbps) |
| Drives | 4× WD Red Plus 6TB CMR |
| Raw capacity | 24TB |
| Usable (SnapRAID) | ~18TB (1 parity drive) |
| Software | mergerfs (pooling) + SnapRAID (nightly parity) |

### Network
| Device | Model | Notes |
|---|---|---|
| ISP Gateway | AT&T BGW320-500 | Admin: 192.168.1.254 — IP Passthrough ready for Phase 3 |
| Main Switch | Netgear GS316 | 16-port Gigabit, **unmanaged** — upgrade needed for Phase 3 VLANs |
| PoE Switch | POE-SW501 (poedepot.com) | 40 PoE+ ports, 1 uplink → feeds IP cameras to Frigate |

### Peripherals
| Item | Status |
|---|---|
| Setup machine | Windows desktop |
| Bootable USB | Available (8GB+) |
| Temp monitor/KB/mouse | Available for initial install |
| TV | Samsung Smart TV (Jellyfin app or browser at :8096) |

---

## 🗺️ Full Service Map

```
Ubuntu Server LTS (bare metal — 1TB internal SSD)
└── Docker Engine
      ├── Portainer              — container management web UI
      ├── Jellyfin               — media server + photo/art gallery on Samsung TV (free, no account, HW transcoding)
      ├── Immich                 — self-hosted Google Photos (AI tagging, face recognition)
      ├── AdGuard Home           — DNS ad blocking + whole-house parental controls
      ├── Home Assistant         — smart home hub
      │     ├── Ecobee           — thermostat (HomeKit Device integration — local)
      │     └── Samsung          — fridge + oven (SmartThings OAuth integration)
      ├── Frigate                — AI camera NVR (NPU/iGPU object detection)
      ├── Ollama                 — local LLM inference (offline ChatGPT)
      ├── Whisper                — local speech-to-text (voice assistant backend)
      ├── Nginx Proxy Manager    — internal reverse proxy + pretty URLs
      ├── Tailscale              — zero-config remote access VPN
      ├── Uptime Kuma            — service uptime dashboard
      ├── Grafana + Prometheus   — system metrics and dashboards
      └── [Local Company App]    — TBD spec
```

---

## 📸 Photos Migration Plan

- **Source:** Google Photos (~100GB)
- **Export:** Google Takeout → download zip archives
- **Import:** Into Immich (preserves metadata, dates, GPS, albums)
- **Going forward:** Immich app on phone → auto-backup directly to Aegis
- **Jellyfin:** Also indexes the photo/art folder for TV gallery (http://192.168.1.100:8096)

---

## 🏡 Smart Home Devices

| Device | Brand | Integration | Notes |
|---|---|---|---|
| Thermostat | Ecobee | HomeKit Device (local) | ⚠️ Do NOT use Ecobee API — no new keys since 2024. Use HomeKit path for local control. |
| Fridge | Samsung | SmartThings → HA (OAuth) | Works well in 2025 HA integration |
| Oven | Samsung | SmartThings → HA (OAuth) | Same as above |
| Lighting | TBD | Recommend Zigbee (Philips Hue, IKEA) | Zigbee = local, no cloud |
| Cameras | TBD | Frigate NVR via POE-SW501 | 40 PoE ports available |
| Sprinklers | TBD | HA integration TBD | |

---

## 🤖 Local AI Roadmap

| Tool | Purpose | Phase |
|---|---|---|
| Immich | Photo face recognition + object tagging | 1 |
| Frigate | Camera AI (person/car/animal detection via NPU) | 2 |
| Ollama | Local LLMs — Llama 3, Mistral (private offline AI) | 2 |
| Whisper | Speech-to-text for HA voice assistant | 2 |
| Home Assistant AI | Local voice assistant (Wyoming + Whisper) | 2 |
| Stable Diffusion | Local image generation (optional) | 4 |

---

## 🌐 Phase 3 Network Target Architecture

```
[AT&T Fiber ONT]
      |
[BGW320-500] ← IP Passthrough mode
      |
[pfSense/OPNsense mini PC]  ← real firewall/router
      |
[Managed Switch]  ← upgrade from Netgear GS316
      |
      ├── VLAN 10: Main       — trusted personal devices
      ├── VLAN 20: IoT        — Samsung appliances, Ecobee, smart devices (isolated)
      ├── VLAN 30: Kids       — filtered DNS (AdGuard), time-based cutoffs
      ├── VLAN 40: Servers    — Aegis + services (internal only)
      └── VLAN 50: Work       — work laptops, strict egress rules
```

**Remote access:** Tailscale on Aegis (installed Phase 1, works across all phases)

---

---

# PHASE 1 — Foundation

**Goal:** Aegis is online, hardened, remotely accessible, and delivering the first two family-visible wins.

**You'll have at the end:**
- Ubuntu Server running on Aegis
- SSH access from your Windows desktop (no monitor needed ever again)
- Docker + Portainer web UI
- Plex streaming photos to your Samsung TV
- AdGuard Home filtering ads + parental controls for whole house
- Tailscale giving you remote access from anywhere
- DAS mounted and protected (when it arrives)

---

## Step 1 — Create the Ubuntu Bootable USB

**On your Windows desktop:**

1. Download **Ubuntu Server 24.04 LTS** ISO:
   → https://ubuntu.com/download/server
   (Click "Download Ubuntu Server 24.04 LTS" — it's a ~2.5GB `.iso` file)

2. Download **Rufus** (free USB flashing tool):
   → https://rufus.ie
   (Download the standard `.exe`, no install needed)

3. Plug in your USB flash drive.

4. Open Rufus:
   - **Device:** select your USB drive
   - **Boot selection:** click SELECT → choose the Ubuntu `.iso` you downloaded
   - **Partition scheme:** GPT
   - **Target system:** UEFI (non CSM)
   - Leave everything else default
   - Click **START**
   - If it asks about "Write in ISO Image mode" → choose that option
   - Wait ~5 minutes. Done.

> ✅ Your USB is now a bootable Ubuntu installer.

---

## Step 2 — Install Ubuntu Server on Aegis

**Plug into Aegis:** monitor, keyboard, USB drive. Power it on.

**Get into the boot menu:**
- Spam `F7` or `Delete` as soon as it powers on (GEEKOM uses F7 for boot menu)
- Select your USB drive from the list

**Ubuntu installer — follow these choices:**

1. **Language:** English
2. **Keyboard:** English (US)
3. **Type of install:** Ubuntu Server *(not minimized)*
4. **Network:** it will detect your ethernet — leave as-is for now (DHCP is fine during install, we set static IP after)
5. **Proxy:** leave blank, hit Done
6. **Mirror:** leave default, hit Done
7. **Storage:**
   - Choose **"Use an entire disk"**
   - Select the 1TB NVMe drive (will show as something like `nvme0n1`)
   - **Uncheck** "Set up this disk as an LVM group" (keep it simple)
   - Confirm and **continue** — this wipes Windows, no going back
8. **Profile setup:**
   - Your name: `Josh`
   - Server name: `aegis`
   - Username: `josh` (all lowercase)
   - Password: something strong — write it down
9. **SSH:** ✅ Check **"Install OpenSSH server"** — this is critical
10. **Snaps / Featured server snaps:** skip all, hit Done
11. Install runs (~5 minutes). When it says **"Installation Complete"** → hit **Reboot Now**
12. Remove the USB when it tells you to, press Enter

> ✅ Aegis boots into Ubuntu. You'll see a login prompt. Log in with `josh` / your password.

---

## Step 3 — Find Aegis's Current IP

At the Aegis terminal, run:

```bash
ip a
```

Look for the ethernet interface (will be named something like `enp2s0` or `eth0`). Under it you'll see a line like:

```
inet 192.168.1.XXX/24
```

That `192.168.1.XXX` is Aegis's current IP — write it down. We'll make it permanent in the next step.

---

## Step 4 — Set a Static IP

We'll give Aegis the permanent address `192.168.1.100`.

```bash
ls /etc/netplan/
```

You'll see a file like `00-installer-config.yaml`. Edit it:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Replace everything in the file with this (adjust the interface name if yours isn't `enp2s0` — use whatever `ip a` showed you):

```yaml
network:
  version: 2
  ethernets:
    enp2s0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

> **Note:** AT&T BGW320-500 gateway is at `192.168.1.254`, but its default route for clients is `192.168.1.1`. If you can't reach the internet after this step, change `192.168.1.1` to `192.168.1.254`.

Save: `Ctrl+O` → Enter → `Ctrl+X`

Apply it:

```bash
sudo netplan apply
```

Verify:

```bash
ip a
```

You should now see `192.168.1.100` on the ethernet interface.

> ✅ Aegis always lives at `192.168.1.100` from now on.

---

## Step 5 — Switch to SSH From Your Windows Desktop

From your **Windows desktop**, open PowerShell or Command Prompt:

```powershell
ssh josh@192.168.1.100
```

Type `yes` when asked about the fingerprint. Enter your password.

> ✅ You're now inside Aegis from your desktop. You can unplug the monitor and keyboard from Aegis — you'll never need them again for normal use. Every command from here runs in this SSH window.

---

## Step 6 — Update Everything

```bash
sudo apt update && sudo apt upgrade -y
```

This pulls all security patches and package updates. Takes 2–5 minutes.

Then install a few essentials:

```bash
sudo apt install -y curl wget git htop ufw
```

---

## Step 7 — Configure the Firewall (ufw)

We lock down Aegis so only the ports we explicitly open are accessible:

```bash
# Allow SSH (critical — do this first or you'll lock yourself out)
sudo ufw allow OpenSSH

# Allow Portainer web UI
sudo ufw allow 9000/tcp
sudo ufw allow 9443/tcp

# Allow Jellyfin
sudo ufw allow 8096/tcp

# Allow AdGuard Home
sudo ufw allow 3000/tcp
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

Verify:

```bash
sudo ufw status
```

> ✅ Firewall is on. Only the ports you've opened are reachable.

---

## Step 8 — Install Docker

```bash
# Add Docker's official GPG key and repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add your user to the docker group (so you don't need sudo every time)
sudo usermod -aG docker josh

# Apply group change (log out and back in, or run:)
newgrp docker
```

Verify Docker works:

```bash
docker --version
docker compose version
```

> ✅ Docker is installed. You should see version numbers for both.

---

## Step 9 — Create the Docker Folder Structure

We keep everything organized in one place:

```bash
mkdir -p ~/docker/{portainer,jellyfin,adguard,tailscale,immich}/{config,data}
```

This creates a clean home for every service's config and data files.

---

## Step 10 — Deploy Portainer (Your Control Center)

```bash
docker volume create portainer_data

docker run -d \
  --name portainer \
  --restart=always \
  -p 9000:9000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Now open a browser on your Windows desktop and go to:

```
http://192.168.1.100:9000
```

You'll be prompted to create an admin account. **Do it immediately** — Portainer times out this setup window after a few minutes.

> ✅ Portainer is live. This is your Docker dashboard. Every future service can be managed here.

---

## Step 11 — Deploy Jellyfin ✅ COMPLETE (2026-04-30)

> **Why Jellyfin over Plex:** 100% free and open source. No account required. Free hardware transcoding (Plex charges for this). Local-first — exactly what this build is about.

Create the Jellyfin compose file:

```bash
mkdir -p ~/docker/jellyfin/config
nano ~/docker/jellyfin/docker-compose.yml
```

Paste this in:

```yaml
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Chicago
    volumes:
      - ~/docker/jellyfin/config:/config
      - /mnt/media/photos:/data/photos
    ports:
      - 8096:8096
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
```

> **`/dev/dri`** passes through Aegis's AMD Radeon 780M iGPU for hardware-accelerated transcoding — completely free with Jellyfin.

```bash
sudo mkdir -p /mnt/media/photos/art
sudo chown josh:josh /mnt/media/photos /mnt/media/photos/art
docker compose -f ~/docker/jellyfin/docker-compose.yml up -d
```

Open Jellyfin in your browser:

```
http://192.168.1.100:8096
```

- Follow the setup wizard
- **Add Library → Home Videos and Photos → point it at `/data/photos`**
- On your Samsung TV: use the browser or install an unofficial Jellyfin client
- Art gallery auto-refreshes when new images are added to `/mnt/media/photos/art`

**Art download script** (`~/download_art.py` on Aegis) — downloads wife's 16 chosen masterworks from the Art Institute of Chicago public domain collection. Run with:

```bash
python3 ~/download_art.py
```

> ✅ **Quick Win #1 done.** Art gallery on the TV.

---

## Step 12 — Deploy AdGuard Home

```bash
nano ~/docker/adguard/docker-compose.yml
```

Paste:

```yaml
services:
  adguard:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    restart: unless-stopped
    volumes:
      - ~/docker/adguard/config:/opt/adguardhome/conf
      - ~/docker/adguard/data:/opt/adguardhome/work
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "3000:3000/tcp"
      - "80:80/tcp"
      - "443:443/tcp"
```

```bash
docker compose -f ~/docker/adguard/docker-compose.yml up -d
```

Open setup wizard:

```
http://192.168.1.100:3000
```

Follow the setup wizard. When complete, AdGuard is your DNS server.

**Point your whole house at it:**

1. Log into your AT&T gateway: `http://192.168.1.254`
2. Go to **Home Network → IP Allocation** (or DNS settings)
3. Change the DNS server to `192.168.1.100`
4. Save

Every device on your network now runs through AdGuard. Add blocklists, set per-device rules, and see all DNS queries from one dashboard.

> ✅ **Quick Win #2 done.** Whole-house ad blocking and parental control foundation.

---

## Step 13 — Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

It will print a URL. Open it in your browser, log in with Google/GitHub/email, and Aegis joins your Tailscale network.

Then install Tailscale on your phone and laptop from tailscale.com. All your devices find each other automatically, from anywhere.

> ✅ Phase 1 complete. Aegis is fully operational.

---

## Step 14 — When the DAS Arrives

When the Terramaster D4-320 + drives show up, run this to set them up:

```bash
# See connected drives
lsblk

# Install mergerfs and SnapRAID
sudo apt install -y mergerfs snapraid
```

*(Full DAS setup guide goes here once it arrives — drives, format, fstab, SnapRAID config)*

---

---

# PHASE 2 — Automation & AI

**Goal:** Smart home hub, local AI, camera NVR, photo management.

*(Detailed step-by-step added when Phase 1 is complete)*

## Services to deploy (in order):
1. Home Assistant + Ecobee (HomeKit) + Samsung SmartThings
2. Immich (Google Photos replacement — import 100GB from Takeout)
3. Frigate (AI camera NVR via POE-SW501 → NPU detection)
4. Ollama (local LLM — Llama 3 / Mistral)
5. Whisper (speech-to-text for HA voice)

---

---

# PHASE 3 — Network Hardening

**Goal:** VLANs, pfSense, full network segmentation.

**Prerequisites before starting:**
- [ ] Purchase managed switch (replaces Netgear GS316 — needs VLAN support)
  - Recommended: Netgear GS308E or GS316EP (if PoE needed)
- [ ] Purchase pfSense/OPNsense box (cheap mini PC with 2+ NICs, or Protectli vault)

## Plan:
1. Configure AT&T BGW320-500 → IP Passthrough mode
2. Install pfSense/OPNsense on dedicated hardware
3. Configure VLANs on managed switch
4. Set up AdGuard Home per-VLAN DNS rules
5. Parental controls: kids VLAN → filtered DNS + time schedules
6. IoT VLAN: Samsung appliances, Ecobee isolated from Main
7. Add Nginx Proxy Manager → internal hostnames (jellyfin.home, ha.home, etc.)

---

---

# PHASE 4 — App Hosting & Polish

**Goal:** Company app hosting, full monitoring, hardened stack.

*(Detailed when Phase 3 is complete)*

## Plan:
1. Define and deploy local company app (spec TBD)
2. Grafana + Prometheus monitoring stack
3. Crowdsec + Fail2Ban hardening
4. RAM upgrade assessment (16GB → 32 or 64GB DDR5)
5. Stable Diffusion (local image generation — optional)

---

---

# 📋 Master Checklist

## Phase 1
- [x] Download Ubuntu Server 26.04 LTS ISO ✅ 2026-04-29
- [x] Flash USB with Rufus (GPT + UEFI) ✅ 2026-04-29
- [x] Install Ubuntu Server on Aegis (Windows wiped) ✅ 2026-04-29
- [x] First login to Aegis confirmed ✅ 2026-04-29
- [ ] Find current IP (`ip a`) and set static IP: 192.168.1.100
- [ ] SSH in from Windows desktop (monitor unplugged after this)
- [ ] Run apt update + upgrade
- [ ] Configure ufw firewall
- [ ] Install Docker + Docker Compose
- [ ] Create ~/docker folder structure
- [ ] Deploy Portainer → http://192.168.1.100:9000
- [x] Deploy Jellyfin → Art Gallery on Samsung TV 🎯 ✅ 2026-04-30
- [ ] Deploy AdGuard Home → point BGW320 DNS to 192.168.1.100 🎯
- [ ] Install Tailscale → remote access from anywhere
- [ ] *(DAS)* Mount drives, configure mergerfs + SnapRAID

## Phase 2
- [ ] Deploy Home Assistant
- [ ] Integrate Ecobee via HomeKit Device
- [ ] Integrate Samsung via SmartThings OAuth
- [ ] Deploy Immich, import Google Takeout archive
- [ ] Configure Immich phone auto-backup
- [ ] Deploy Frigate, connect cameras via POE-SW501
- [ ] Deploy Ollama (Llama 3 or Mistral)
- [ ] Deploy Whisper

## Phase 3
- [ ] Buy managed switch
- [ ] Buy pfSense/OPNsense hardware
- [ ] Configure BGW320-500 IP Passthrough
- [ ] Deploy pfSense/OPNsense
- [ ] Configure VLANs
- [ ] Configure AdGuard per-VLAN rules
- [ ] Deploy Nginx Proxy Ma