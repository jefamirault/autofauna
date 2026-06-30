# Environment variables:
# AUTOFAUNA_SERVER = myapp.com
# AUTOFAUNA_USER = devops_user

ssh $AUTOFAUNA_USER@$AUTOFAUNA_SERVER << 'EOF'
    mkdir -p /home/deploy/autofauna/db_backups

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    # Create backup with timestamp
    pg_dump -Fc -h 127.0.0.1 -U deploy autofauna -f /home/deploy/autofauna/db_backups/autofauna_db_${TIMESTAMP}.dump

    # Create/update symlink to latest backup
    cd /home/deploy/autofauna/db_backups
    ln -sf autofauna_db_${TIMESTAMP}.dump autofauna_db.dump

    # Clean up old backups (keep last 3 weeks)
    find /home/deploy/autofauna/db_backups -name "autofauna_db_*.dump" -mtime +21 -delete
EOF

echo "Backup completed on $AUTOFAUNA_SERVER"
echo "Downloading latest database backup"
scp $AUTOFAUNA_USER@$AUTOFAUNA_SERVER:/home/deploy/autofauna/db_backups/autofauna_db.dump /home/jef/autofauna/db/backup

echo "Populating local database with latest backup..."
rails db:environment:set RAILS_ENV=development
rails db:drop
rails db:create
pg_restore --no-owner --role=autofauna_development -d autofauna_development -h 127.0.0.1 -U autofauna_development db/backup/autofauna_db.dump
rails db:environment:set RAILS_ENV=development
rails db:migrate

echo "Local database updated with latest backup"

# Production stores uploads on the Disk service in shared/storage (a Capistrano
# linked_dir). The DB clone brings over the blob records (with their keys) but not
# the files, so rsync the storage tree to match. Keys line up, so attachments resolve.
REMOTE_STORAGE="$AUTOFAUNA_USER@$AUTOFAUNA_SERVER:/home/deploy/autofauna/shared/storage/"
if [ -n "$AUTOFAUNA_SYNC_USER_EMAIL" ]; then
  # Bandwidth-saving mode: sync only the target user's plant images. We compute the
  # relative disk paths from the just-restored local DB (no extra load on production)
  # and hand them to rsync --files-from, which transfers exactly those files.
  echo "Syncing Active Storage files for $AUTOFAUNA_SYNC_USER_EMAIL..."
  STORAGE_LIST=$(mktemp)
  rails runner util/list_user_storage_paths.rb "$AUTOFAUNA_SYNC_USER_EMAIL" > "$STORAGE_LIST"
  rsync -avz --files-from="$STORAGE_LIST" "$REMOTE_STORAGE" /home/jef/autofauna/storage/
  rm -f "$STORAGE_LIST"
else
  echo "Syncing all Active Storage files from production..."
  rsync -avz "$REMOTE_STORAGE" /home/jef/autofauna/storage/
fi
echo "Active Storage files synced"

# Start rails development server if argument "start_server" is present
[ "$1" = "-s" ] && echo "Starting development server..." && rails s
