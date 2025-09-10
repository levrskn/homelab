#!/bin/bash -e
# Backup Nextcloud settings (config + database), no user uploaded data

trap sendError 1 2 3 6 14 15

sendError() {
  echo "[ERROR] Backup failed at $(date)" >&2
}

# Timestamp
now=$(date +"%m%d%Y_%H%M%S")

# Paths
backup_root="/homelab/backups"
backup_dir="${backup_root}/nextcloud_${now}_backup.d"
tarball="${backup_root}/nextcloud_${now}_backup.tar.gz"
onedrive="/homelab/backups"

echo "[INFO] Creating backup directory..."
mkdir -p "$backup_dir"

echo "[INFO] Backing up Nextcloud config directory..."
docker cp nextcloud-app:/var/www/html/config "$backup_dir/config"

echo "[INFO] Exporting Nextcloud database..."
docker exec nextcloud-db \
  mysqldump --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" "$MYSQL_DATABASE" -h 127.0.0.1 \
  > "$backup_dir/nextcloud-db.sql"

echo "[INFO] Creating tarball..."
mkdir -p "$backup_root"
tar -czvf "$tarball" -C "$backup_dir" .

echo "[INFO] Cleaning up temporary files..."
rm -rf "$backup_dir"

echo "[INFO] Copying tarball to backup folder..."
cp "$tarball" "$onedrive"

# Keep last 8 backups
echo "[INFO] Cleaning up old backups (keeping last 8)..."
find "$onedrive" -type f -name "nextcloud_*_backup.tar.gz" \
    | sort -r \
    | tail -n +9 \
    | xargs -r rm -v

echo "[SUCCESS] Nextcloud backup completed: ${onedrive}/$(basename "$tarball")"
