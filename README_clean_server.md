# clean-server Script

This script performs an automated cleanup of your server to free disk space and remove unnecessary files.

It is designed to be **safe**, **repeatable**, and **log everything** to `/var/log/clean-server.log`.

---

## Features

The script runs the following steps:

1. **Show disk usage BEFORE cleanup**
   - Uses `df -h` and writes output to the log file.

2. **APT cleanup**
   - Removes unused packages:
     ```bash
     apt autoremove -y
     ```
   - Cleans downloaded package files:
     ```bash
     apt clean
     apt autoclean
     ```

3. **Systemd journal logs cleanup**
   - If `journalctl` exists, it runs:
     ```bash
     journalctl --vacuum-size=100M
     ```
   - This limits system logs to a maximum of ~100 MB.

4. **Docker cleanup (if installed)**
   - Prunes unused Docker objects:
     ```bash
     docker system prune -af
     docker volume prune -f
     ```
   - This removes:
     - Stopped containers
     - Unused networks
     - Dangling images
     - Build cache
     - Unused volumes

5. **Temporary folders cleanup**
   - Deletes temporary files:
     ```bash
     rm -rf /tmp/* /var/tmp/*
     ```

6. **User cache cleanup**
   - Cleans cache for user `tamer`:
     ```bash
     rm -rf /home/tamer/.cache/*
     ```

7. **Old backup files cleanup**
   - If `/var/backups` exists, it deletes `.tar.gz` files older than 14 days:
     ```bash
     find /var/backups -type f -name "*.tar.gz" -mtime +14 -print -delete
     ```

8. **Show disk usage AFTER cleanup**
   - Runs `df -h` again and logs the result.

---

## Log File

All actions and outputs are logged to:

```bash
/var/log/clean-server.log
```

Each run starts with a timestamp like:

```text
🧹 Running clean-server at 2025-12-04 01:23:45
```

---

## Usage

Run the script as **root**:

```bash
sudo clean-server
```

Or, if saved as a full path:

```bash
sudo /usr/local/bin/clean-server
```

---

## Installation

1. Create the script file:

```bash
sudo nano /usr/local/bin/clean-server
```

2. Paste the script content into the file and save.

3. Make it executable:

```bash
sudo chmod +x /usr/local/bin/clean-server
```

---

## Optional: Run via cron (scheduled)

To run this cleanup automatically (e.g., once per week), edit root's crontab:

```bash
sudo crontab -e
```

Add a line like:

```cron
0 3 * * 0 /usr/local/bin/clean-server >/dev/null 2>&1
```

This will run `clean-server` every **Sunday at 03:00**.

---

## Safety Notes

- The script removes:
  - Temporary files under `/tmp` and `/var/tmp`
  - Cache files under `/home/tamer/.cache`
  - Old backup archives (`*.tar.gz`) older than **14 days** in `/var/backups`
- Make sure you are comfortable with deleting old backups before using this script in production.
