#!/bin/bash

# Check if the .env file is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_env_file>"
  echo "Please provide the path to the .env file."
  exit 1
fi

# Load environment variables from the specified .env file
if [ -f "$1" ]; then
  source "$1"
else
  echo ".env file not found! Exiting."
  exit 1
fi

# Check if the .env file has the correct permissions (600)
env_permissions=$(stat -c "%a" "$1")
if [ "$env_permissions" != "600" ]; then
  echo ".env file has incorrect permissions ($env_permissions)."
  echo "Please set the correct permissions using the following command:"
  echo "chmod 600 $1"
  exit 1
fi

# Export the password to avoid prompting
export PGPASSWORD=$PGPASSWORD

# Create a timestamp for the backup directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

# Create the timestamped backup directory if it doesn't exist
mkdir -p "$BACKUP_PATH"

# Get a list of all databases
databases=$(psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

# Backup each database
for db in $databases; do
  echo "Backing up database: $db"
  pg_dump -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -F c "$db" >"$BACKUP_PATH/${db}_backup.dump"
done

# Backup user permissions
echo "Backing up user permissions"
pg_dumpall -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" --roles-only >"$BACKUP_PATH/user_permissions_backup.sql"

# Backup PostgreSQL configuration files
echo "Backing up PostgreSQL configuration files"
CONFIG_FILES=(
  "/etc/postgresql/${PGVERSION}/${PGCLUSTER}/postgresql.conf"
  "/etc/postgresql/${PGVERSION}/${PGCLUSTER}/pg_hba.conf"
  "/etc/postgresql/${PGVERSION}/${PGCLUSTER}/pg_ident.conf"
)

for config in "${CONFIG_FILES[@]}"; do
  if sudo cp "$config" "$BACKUP_PATH/"; then
    echo "Successfully backed up $config to $BACKUP_PATH"
  else
    echo "Error: Unable to back up $config. Check your permissions."
  fi
done

# Clean up
unset PGPASSWORD

echo "Backup completed successfully! All backups stored in: $BACKUP_PATH"
