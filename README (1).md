# clean-server Maintenance Script

## Overview

This repository contains a single Bash script, `clean-server.sh`, which automates common disk cleanup and maintenance tasks on a Linux server. It is intended to be installed as a root-level utility (for example at `/usr/local/bin/clean-server`) and run manually, via cron, or via a systemd unit.

The script performs the following actions:

1. APT package cleanup (`autoremove`, `clean`, `autoclean`)
2. Systemd journal log cleanup (using `journalctl --vacuum-size`)
3. Docker cleanup (`docker system prune` and `docker volume prune`)
4. Cleanup of `/tmp` and `/var/tmp`
5. Cleanup of a user cache directory (currently `/home/tamer/.cache`)
6. Deletion of old backup archives in `/var/backups` (older than 14 days)
7. Logging of all actions and disk usage before and after cleanup to `/var/log/clean-server.log`

> **Note:** The user cache path (`/home/tamer/.cache`) is hard-coded and may need to be adjusted to match your actual username and home directory.

---

## Requirements

### Supported Operating Systems

- Linux distributions that use `apt` for package management (e.g. Debian, Ubuntu, and derivatives).

### Required Tools / Commands

The script assumes the presence of:

- `/bin/bash`
- `apt` (for APT cleanup steps)
- `df`, `rm`, `find`, `date`, `tee`
- `journalctl` (optional; used if available)
- `docker` (optional; used if available)
- `sudo` (for non-root users to run the script as root)

The script **must** be run as root. If it is not executed as root, it will exit with a message.

---

## Local Installation (Development / Testing)

You can test and run the script locally on your machine before deploying it to a production server.

1. **Clone or download the script**

   ```bash
   mkdir -p ~/clean-server-script
   cd ~/clean-server-script
   # Copy clean-server.sh into this directory
   ```

2. **Make the script executable**

   ```bash
   chmod +x clean-server.sh
   ```

3. **(Optional) Adjust the user cache path**

   Edit the script if needed to change the hard-coded user cache directory:

   ```bash
   nano clean-server.sh
   ```

   Look for this block and adjust `/home/tamer` to your actual user (e.g. `/home/ubuntu`):

   ```bash
   echo "▶ Step 5: Cleaning user cache (~tamer/.cache)..."
   if [ -d "/home/tamer/.cache" ]; then
     rm -rf /home/tamer/.cache/* 2>>"$LOGFILE" || true
   fi
   ```

4. **Run locally with sudo (for testing)**

   ```bash
   sudo ./clean-server.sh
   ```

   Logs will be written to:

   ```text
   /var/log/clean-server.log
   ```

---

## Uploading the Script to a Linux Server

You can upload the script to your server using `scp` or any other secure file transfer method.

Assuming:

- Local file: `clean-server.sh`
- Remote user: `ubuntu`
- Remote host: `your-server.example.com`

1. **Copy the script to the server**

   ```bash
   scp clean-server.sh ubuntu@your-server.example.com:/home/ubuntu/
   ```

2. **SSH into the server**

   ```bash
   ssh ubuntu@your-server.example.com
   ```

3. **Move the script to `/usr/local/bin` and rename it**

   ```bash
   sudo mv /home/ubuntu/clean-server.sh /usr/local/bin/clean-server
   sudo chmod +x /usr/local/bin/clean-server
   ```

4. **(Optional) Adjust user cache path on the server**

   Edit `/usr/local/bin/clean-server` and update the user cache directory according to the primary user on that server.

   ```bash
   sudo nano /usr/local/bin/clean-server
   ```

---

## Installing Dependencies on the Server

On a typical Debian/Ubuntu server, most requirements should already be present. To ensure the necessary tools are installed:

```bash
sudo apt update
sudo apt install -y sudo apt-utils systemd docker.io
```

> **Note:** `journalctl` is part of `systemd` and is usually present by default. `docker.io` is installed here only if you plan to use Docker; otherwise, you can omit it.

---

## Running the Script

### Manual Run (Ad-hoc cleanup)

Run the script manually as needed:

```bash
sudo /usr/local/bin/clean-server
```

Disk usage, steps performed, and any errors will be logged to:

```text
/var/log/clean-server.log
```

### Scheduled Run with cron (Production Usage)

You can configure a cron job to run the cleanup regularly (e.g. daily at 03:00).

1. Edit the root crontab:

   ```bash
   sudo crontab -e
   ```

2. Add a line like this:

   ```cron
   0 3 * * * /usr/local/bin/clean-server >/dev/null 2>&1
   ```

This will run the server cleanup every day at 03:00 server time.

---

## Optional: systemd Service / Timer Setup

Instead of cron, you can use `systemd` to run the script on a schedule.

### 1. Create a systemd service unit

Create `/etc/systemd/system/clean-server.service`:

```ini
[Unit]
Description=Run clean-server maintenance script

[Service]
Type=oneshot
ExecStart=/usr/local/bin/clean-server
User=root
Group=root
```

### 2. Create a systemd timer unit

Create `/etc/systemd/system/clean-server.timer`:

```ini
[Unit]
Description=Schedule clean-server maintenance script

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

### 3. Reload systemd and enable the timer

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now clean-server.timer
```

You can check the status with:

```bash
systemctl status clean-server.timer
systemctl status clean-server.service
```

---

## Optional: Nginx Reverse Proxy

This script does **not** provide a network service or web application; it simply performs maintenance tasks and writes logs. Therefore, **no reverse proxy (Nginx) configuration is required** for normal usage.

If you later build a web dashboard or API around the log file (`/var/log/clean-server.log`), you could then place that web application behind Nginx, but that is outside the scope of this script.

---

## Troubleshooting

### 1. “❌ Please run this script as root: sudo ...”

The script must be executed with root privileges. Use:

```bash
sudo /usr/local/bin/clean-server
```

### 2. APT errors

If `apt` commands fail (e.g. due to locked database), they are logged and ignored (`|| true` in the script). Check the log file:

```bash
sudo tail -n 100 /var/log/clean-server.log
```

If the APT lock is held by another process, wait for that process to finish or investigate using:

```bash
ps aux | grep apt
```

### 3. Docker not installed

If Docker is not installed, the script will log:

```text
ℹ Docker not installed, skipping.
```

This is expected and not an error. Install Docker only if you actually use Docker on the server.

### 4. journalctl not found

On systems without `systemd` or where `journalctl` is not available, the script will log that it is skipping journal cleanup. This is safe to ignore if your system uses a different logging mechanism.

### 5. User cache directory not found

If the configured user cache directory (default `/home/tamer/.cache`) does not exist, the script will log that it is skipping that step. To clean a different user cache, edit the path in the script.

### 6. Permissions on log file

The log file is written to `/var/log/clean-server.log`. If you cannot read it as a normal user, use `sudo`:

```bash
sudo less /var/log/clean-server.log
```

You can also adjust file permissions if needed:

```bash
sudo chmod 640 /var/log/clean-server.log
```

---

## Security Considerations

- The script performs recursive deletions (`rm -rf`) in specific directories (`/tmp`, `/var/tmp`, and a user cache directory). Review the script and paths carefully before running it in production.
- Always keep backups of critical data in `/var/backups` and validate that the `find` command’s pattern matches only the files you intend to remove (currently `*.tar.gz` older than 14 days).
- Consider testing on a staging server first.

---

## License

No specific license has been provided. If you plan to distribute or share this script, consider adding an appropriate open-source or internal-use license file.
