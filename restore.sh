#!/bin/bash

# Check if .env file exists
if [ -f ".env" ]; then
  # Check if the .env file has the correct permissions (600)
  env_permissions=$(stat -c "%a" .env)
  if [ "$env_permissions" != "600" ]; then
    echo ".env file has incorrect permissions ($env_permissions)."
    echo "Please set the correct permissions using the following command:"
    echo "chmod 600 .env"
    exit 1
  fi
else
  echo ".env file not found! Exiting."
  exit 1
fi

# Load environment variables from .env file
source .env

# Export the password to avoid prompting
export PGPASSWORD=$PGPASSWORD

# Restore user permissions
echo "Restoring user permissions"
if [ -f "$BACKUP_DIR/user_permissions_backup_*.sql" ]; then
  psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -f "$BACKUP_DIR/user_permissions_backup_*.sql"
else
  echo "User permissions backup file not found!"
fi

# Restore each database
echo "Restoring databases..."
for backup in "$BACKUP_DIR"/*_backup_*.dump; do
  dbname=$(basename "$backup" | cut -d'_' -f1) # Extract database name from the file name
  echo "Restoring database: $dbname from $backup"

  # Create the database if it doesn't exist
  createdb -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" "$dbname"

  # Restore the database
  pg_restore -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d "$dbname" "$backup"
done

# Clean up
unset PGPASSWORD

echo "Restore completed successfully!"
