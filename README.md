# ☁️ CloudBox

> **Spin up cloud server environments locally on Windows — AWS, Azure, GCP and more.**

CloudBox lets you run cloud Linux environments on your local Windows machine using WSL — identical to your real cloud instances, with zero cloud cost during development and testing.

---

## ⭐ If this tool saves you time, please give it a star on GitHub!
### 👉 [github.com/surinderlohat/cloudbox](https://github.com/surinderlohat/cloudbox)

---

## Use Case

When working on AWS EC2 deployments, the typical workflow of **spinning up an EC2 instance → making code changes → committing → deploying** is slow and costly. Every small change requires a full deploy cycle just to test.

CloudBox solves this by running **Amazon Linux 2023 (AL2023) directly on your local Windows machine using WSL**. Same OS, same package manager (`dnf`), same runtime — zero cloud cost.

**Benefits:**
- ✅ Test deployment scripts locally before pushing to cloud
- ✅ No cloud instance running costs during development/testing
- ✅ Edit code in VS Code on Windows, run and deploy from WSL instantly
- ✅ Eliminates the slow edit → commit → deploy → check cycle
- ✅ Reusable setup — generate the tar once, use it on any Windows machine
- ✅ Future-proof — supports AWS, Azure, GCP and custom images

---

## Supported Providers

| Provider | OS | Status |
|---|---|---|
| AWS | Amazon Linux 2023 | ✅ Available |
| Azure | Azure Linux / Ubuntu Server | 🔜 Coming Soon |
| GCP | Container-Optimized OS | 🔜 Coming Soon |
| Custom | Any WSL image | 🔜 Coming Soon |

---

## Prerequisites

- Windows 10/11 with WSL 2 supported
- Docker Desktop installed and **running** (only needed if no tar file available)
- Windows Terminal or CMD **run as Administrator**

---

## Getting Started — AWS (Amazon Linux 2023)

### Step 1 — Download CloudBox Installer

📥 [Download setup-wsl-al2023.exe](https://github.com/surinderlohat/cloudbox/releases/latest/download/setup-wsl-al2023.exe)

---

### Step 2 — Run the Installer

Right-click `setup-wsl-al2023.exe` → **Run as Administrator**

> **Note:** Windows may show a SmartScreen warning on first run — click **"More info" → "Run anyway"**. This is normal for new unsigned executables.

The installer will guide you through everything interactively:

```
=========================================
   Amazon Linux 2023 WSL Setup
=========================================

[*] Found: C:\WSL\al2023-wsl.tar         ← auto-detected if exists

  Enter server name (default: AmazonLinux2023):

[1/5] Setting WSL default version to 2...
[2/5] Removing existing server (if any)...
[3/5] Importing AL2023 into WSL...
[4/5] Configuring server (wsl.conf + ec2-user)...
[5/5] Package Installation...

  Install packages? [y/n] (default: y):
```

---

### Step 3 — Launch the Server

```bash
# Start
wsl -d AmazonLinux2023 --cd ~

# Stop
wsl -t AmazonLinux2023

# Check status
wsl --list --verbose
```

---

### Step 4 — SSH Into the Server (Optional)

> SSH is **optional** — skip this step if you just want to use `wsl -d AmazonLinux2023` to access the server directly.

If you want to SSH into the server just like a real EC2 instance, follow these steps:

**Inside AL2023, install and start SSH:**
```bash
# Install OpenSSH server
sudo dnf install -y openssh-server

# Generate SSH host keys
sudo ssh-keygen -A

# Start SSH service
sudo systemctl start sshd

# Enable SSH to auto-start on boot
sudo systemctl enable sshd

# Set a password for ec2-user (required for SSH login)
sudo passwd ec2-user

# Verify SSH is running
sudo systemctl status sshd
```

**Now SSH from Windows Terminal:**
```bash
ssh ec2-user@localhost -p 22
```

**Optional — Use SSH keys instead of password (same as real EC2):**
```bash
# Generate key pair on Windows Terminal
ssh-keygen -t rsa -b 4096

# Copy public key into AL2023
cat /mnt/c/Users/<your-username>/.ssh/id_rsa.pub >> /home/ec2-user/.ssh/authorized_keys
chmod 600 /home/ec2-user/.ssh/authorized_keys
chmod 700 /home/ec2-user/.ssh
```

---

### Step 5 — Access Windows Project Files

```bash
# Windows C: drive is accessible at
cd /mnt/c/Users/<your-username>/<your-project>
```

If `/mnt/c/` is not accessible, mount manually:
```bash
mkdir -p /mnt/c
mount -t drvfs C: /mnt/c
```

---

## What the Installer Does Automatically

| Task | Details |
|---|---|
| TAR detection | Looks for `C:\WSL\al2023-wsl.tar` automatically |
| Docker fallback | If no TAR found, pulls `amazonlinux:2023` from Docker and exports it |
| Server naming | Asks for a custom server name (default: `AmazonLinux2023`) |
| Override check | Warns if server already exists before overwriting |
| WSL config | Writes `/etc/wsl.conf` — disables Windows PATH bleed, enables systemd |
| ec2-user | Creates `ec2-user` with sudo, no password — identical to real EC2 |
| Packages | Installs git, wget, curl, python3, pip, unzip, openssh-server, AWS CLI v2 |
| SSH | Generates host keys and enables `sshd` on boot |
| Shell | Sets AWS-style prompt `[ec2-user@servername ~]$` and common aliases |
| Hostname | Sets hostname to match the server name |
| Verification | Checks git, python3, curl, aws-cli after install |

---

## Fresh Instance

To start clean or set up on a new machine, just **double-click `setup-wsl-al2023.exe`** again — it detects the existing instance, asks if you want to override, and reimports automatically.

Or manually from Windows Terminal:
```bash
wsl --unregister AmazonLinux2023
```
Then re-run the `.exe`.

---

## File Locations

| File | Path |
|---|---|
| `setup-wsl-al2023.exe` | Download from GitHub releases |
| `al2023-wsl.tar` | `C:\WSL\al2023-wsl.tar` (auto-generated if not present) |
| Distro install directory | `C:\WSL\AmazonLinux2023\` |

---

## Full Flow Summary

```
[Double-click setup-wsl-al2023.exe]
        │
        ▼
  TAR found at C:\WSL\ ──────────────────┐
                                          │
  No TAR → Docker pull amazonlinux:2023   │
          → docker export → al2023-wsl.tar┘
        │
        ▼
wsl --import <ServerName>
        │
        ▼
Write wsl.conf + Create ec2-user
        │
        ▼
Install packages + AWS CLI + SSH
        │
        ▼
wsl --shutdown (apply systemd + wsl.conf)
        │
        ▼
    ✅ AL2023 WSL Ready
    [ec2-user@AmazonLinux2023 ~]$
```

---

## License

Licensed under the **Apache License 2.0** — free to use, modify and distribute.
See [LICENSE](https://github.com/surinderlohat/cloudbox/blob/main/LICENSE) for full details.

---

## Credits

Built and maintained by [**@surinderlohat**](https://github.com/surinderlohat)

Contributions, issues and feature requests are welcome!
Feel free to open a [GitHub Issue](https://github.com/surinderlohat/cloudbox/issues) or submit a PR.

---

## ⭐ Support

If CloudBox saved you time or helped your workflow, please consider giving it a **star on GitHub** — it helps others discover the project!

### 👉 [github.com/surinderlohat/cloudbox](https://github.com/surinderlohat/cloudbox) ⭐
