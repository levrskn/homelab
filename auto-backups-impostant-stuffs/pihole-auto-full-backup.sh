#!/bin/bash -e
# Backup Pi-hole container data - Raspberry Pi
# Keeps only the last 8 backups

trap sendError 1 2 3 6 14 15

sendError() {
  echo "[ERROR] Backup failed at $(date)" >&2
}

# Timestamp
now=$(date +"%m%d%Y_%H%M%S")

# Paths
rootdir="/homelab"
pihole_etc="${rootdir}/pihole/etc-pihole"
dnsmasq_etc="${rootdir}/etc-dnsmasq.d"
env_file="/homelab/pihole/.env"
backupdir="${rootdir}/backups/pihole_${now}_backup.d"
tarball="${rootdir}/backups/pihole_${now}_backup.tar.gz"
onedrive="/homelab/backups"

echo "[INFO] Creating backup directory..."
mkdir -p "$backupdir"

echo "[INFO] Backing up Pi-hole configuration..."
cp -rp "$pihole_etc" "$backupdir/etc-pihole"
cp -rp "$dnsmasq_etc" "$backupdir/etc-dnsmasq.d"

echo "[INFO] Backing up .env file..."
cp -p "$env_file" "$backupdir/.env"

echo "[INFO] Creating tarball..."
mkdir -p "${rootdir}/backups"
tar -czvf "$tarball" -C "$backupdir" .

echo "[INFO] Cleaning up temporary copied files..."
rm -rf "$backupdir"

echo "[INFO] Copying tarball to backup folder..."
cp "$tarball" "$onedrive"

# Automatic cleanup: keep only the last 8 backups
echo "[INFO] Cleaning up old backups (keeping last 8)..."
find "$onedrive" -type f -name "pihole_*_backup.tar.gz" \
    | sort -r \
    | tail -n +9 \
    | xargs -r rm -v

echo "[SUCCESS] Backup completed: ${onedrive}/$(basename "$tarball")"