#!/bin/bash

# Auto-clean script for server
# Run as: sudo /usr/local/bin/clean-server

if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script as root: sudo $0"
  exit 1
fi

LOGFILE="/var/log/clean-server.log"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

echo "======================================" | tee -a "$LOGFILE"
echo "🧹 Running clean-server at $DATE" | tee -a "$LOGFILE"
echo "======================================" | tee -a "$LOGFILE"

echo "📦 Disk usage BEFORE:" | tee -a "$LOGFILE"
df -h | tee -a "$LOGFILE"

echo "" | tee -a "$LOGFILE"
echo "▶ Step 1: APT cleanup..." | tee -a "$LOGFILE"
apt autoremove -y >>"$LOGFILE" 2>&1 || true
apt clean >>"$LOGFILE" 2>&1 || true
apt autoclean >>"$LOGFILE" 2>&1 || true

echo "✅ APT cleanup done." | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

echo "▶ Step 2: Journal logs cleanup..." | tee -a "$LOGFILE"
if command -v journalctl >/dev/null 2>&1; then
  journalctl --vacuum-size=100M >>"$LOGFILE" 2>&1 || true
  echo "✅ journalctl vacuum done (100M max)." | tee -a "$LOGFILE"
else
  echo "ℹ journalctl not found, skipping." | tee -a "$LOGFILE"
fi
echo "" | tee -a "$LOGFILE"

echo "▶ Step 3: Docker cleanup..." | tee -a "$LOGFILE"
if command -v docker >/dev/null 2>&1; then
  # Remove unused containers, networks, images, and build cache
  docker system prune -af >>"$LOGFILE" 2>&1 || true
  # Remove unused volumes
  docker volume prune -f >>"$LOGFILE" 2>&1 || true
  echo "✅ Docker prune done." | tee -a "$LOGFILE"
else
  echo "ℹ Docker not installed, skipping." | tee -a "$LOGFILE"
fi
echo "" | tee -a "$LOGFILE"

echo "▶ Step 4: Cleaning /tmp and /var/tmp..." | tee -a "$LOGFILE"
rm -rf /tmp/* /var/tmp/* 2>>"$LOGFILE" || true
echo "✅ Temp folders cleaned." | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

echo "▶ Step 5: Cleaning user cache (~tamer/.cache)..." | tee -a "$LOGFILE"
if [ -d "/home/tamer/.cache" ]; then
  rm -rf /home/tamer/.cache/* 2>>"$LOGFILE" || true
  echo "✅ /home/tamer/.cache cleaned." | tee -a "$LOGFILE"
else
  echo "ℹ /home/tamer/.cache not found, skipping." | tee -a "$LOGFILE"
fi
echo "" | tee -a "$LOGFILE"

echo "▶ Step 6: Removing old backups (>14 days)..." | tee -a "$LOGFILE"
if [ -d "/var/backups" ]; then
  find /var/backups -type f -name "*.tar.gz" -mtime +14 -print -delete >>"$LOGFILE" 2>&1 || true
  echo "✅ Old backups cleanup done (older than 14 days)." | tee -a "$LOGFILE"
else
  echo "ℹ /var/backups not found, skipping." | tee -a "$LOGFILE"
fi
echo "" | tee -a "$LOGFILE"

echo "📦 Disk usage AFTER:" | tee -a "$LOGFILE"
df -h | tee -a "$LOGFILE"

echo "✅ clean-server finished." | tee -a "$LOGFILE"
echo "Log saved to: $LOGFILE"
