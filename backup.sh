#!/bin/bash

# Load environment variables from .env file
if [ -f ".env" ]; then
  source .env
else
  echo ".env file not found! Exiting."
  exit 1
fi

# Export the password to avoid prompting
export PGPASSWORD=$PGPASSWORD

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Get a list of all databases
databases=$(psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

# Backup each database
for db in $databases; do
  echo "Backing up database: $db"
  pg_dump -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -F c "$db" >"$BACKUP_DIR/${db}_backup_$(date +"%Y%m%d_%H%M%S").dump"
done

# Backup user permissions
echo "Backing up user permissions"
pg_dumpall -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" --roles-only >"$BACKUP_DIR/user_permissions_backup_$(date +"%Y%m%d_%H%M%S").sql"

# Clean up
unset PGPASSWORD

echo "Backup completed successfully!"
