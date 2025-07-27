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

echo "Local database updated with latest backup"
# Start rails development server if argument "start_server" is present
[ "$1" = "start_server" ] && echo "Starting development server..." && rails s
