#!/bin/bash -e
# Backup Nginx Proxy Manager (NPM) - Raspberry Pi
# Keeps only the last 8 backups

trap sendError 1 2 3 6 14 15

sendError() {
  echo "[ERROR] Backup failed at $(date)" >&2
}

# Timestamp
now=$(date +"%m%d%Y_%H%M%S")

# Paths
rootdir="/homelab"
appdata="${rootdir}/npm-app-data"
backupdir="${rootdir}/backups/nginx_${now}_backup.d"
tarball="${rootdir}/backups/nginx_${now}_backup.tar.gz"
onedrive="/homelab/backups"

echo "[INFO] Creating backup directory..."
mkdir -p "$backupdir"

echo "[INFO] Backing up all NPM app data..."
cp -rp "$appdata" "$backupdir/app-data"

# If using MySQL
if docker ps --format '{{.Names}}' | grep -q '^nginx-db-1$'; then
    echo "[INFO] Exporting the MySQL database..."
    docker exec nginx-db-1 \
      mysqldump --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" "$MYSQL_DATABASE" -h 127.0.0.1 \
      > "$backupdir/npm-export.sql"
else
    echo "[INFO] Copying SQLite database..."
    cp -p "${appdata}/database.sqlite" "$backupdir/database.sqlite"
fi

echo "[INFO] Creating tarball..."
mkdir -p "${rootdir}/backups"
tar -czvf "$tarball" -C "$backupdir" .

echo "[INFO] Cleaning up temporary copied files..."
rm -rf "$backupdir"

echo "[INFO] Copying tarball to backup folder..."
cp "$tarball" "$onedrive"

# Automatic cleanup: keep only the last 8 backups
echo "[INFO] Cleaning up old backups (keeping last 8)..."
find "$onedrive" -type f -name "nginx_*_backup.tar.gz" \
    | sort -r \
    | tail -n +9 \
    | xargs -r rm -v

echo "[SUCCESS] Backup completed: ${onedrive}/$(basename "$tarball")"