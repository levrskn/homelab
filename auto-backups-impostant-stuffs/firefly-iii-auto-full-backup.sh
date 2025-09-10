#!/bin/bash -e
# Backup Firefly III (Uploads + MySQL DB + .env file)

trap sendError 1 2 3 6 14 15

sendError() {
  echo "[ERROR] Backup failed at $(date)" >&2
}

# Timestamp
now=$(date +"%m%d%Y_%H%M%S")

# Paths
app_uploads="/homelab/firefly-app"
backup_root="/homelab/backups"
backup_dir="${backup_root}/firefly_${now}_backup.d"
tarball="${backup_root}/firefly_${now}_backup.tar.gz"
onedrive="/home/${$User}/backups"
env_file="/homelab/firefly/.env"


echo "[INFO] Creating backup directory..."
mkdir -p "$backup_dir"

echo "[INFO] Backing up uploads..."
cp -rp "$app_uploads" "$backup_dir/uploads"

echo "[INFO] Backing up .env file..."
cp -p "$env_file" "$backup_dir/.env"

echo "[INFO] Backing up .db.env file..."
cp -p "$env_file" "$backup_dir/.db.env"

# Backup MySQL database
if docker ps --format '{{.Names}}' | grep -q '^firefly-db$'; then
    echo "[INFO] Exporting MySQL database from container..."
    docker exec firefly-db \
      mysqldump --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" "$MYSQL_DATABASE" -h 127.0.0.1 \
      > "$backup_dir/firefly-db.sql"
else
    echo "[WARNING] MySQL container 'firefly-db' not found — skipping DB dump."
fi

echo "[INFO] Creating tarball..."
mkdir -p "$backup_root"
tar -czvf "$tarball" -C "$backup_dir" .

echo "[INFO] Cleaning up temporary files..."
rm -rf "$backup_dir"

echo "[INFO] Copying tarball to backup folder..."
cp "$tarball" "$onedrive"

# Keep last 8 backups
echo "[INFO] Cleaning up old backups (keeping last 8)..."
find "$onedrive" -type f -name "firefly_*_backup.tar.gz" \
    | sort -r \
    | tail -n +9 \
    | xargs -r rm -v

echo "[SUCCESS] Firefly III backup completed: ${onedrive}/$(basename "$tarball")"