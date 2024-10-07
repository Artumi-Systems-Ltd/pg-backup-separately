#!/bin/bash

# Usage information
usage() {
  echo "Usage: $0 <path_to_env_file> <restore_directory> [filter_pattern]"
  echo "Arguments:"
  echo "  path_to_env_file   Path to the .env file containing configuration."
  echo "  restore_directory   Directory containing the backup files."
  echo "  filter_pattern      (Optional) Pattern to match database names."
  exit 1
}

FILTER_PATTERN="$3"

# Check if the correct number of arguments is provided
if [ $# -lt 2 ]; then
  usage
fi

# Load environment variables from the specified .env file
if [ -f "$1" ]; then
  source "$1"
else
  echo ".env file not found! Exiting."
  exit 1
fi

# Check if the restore directory is provided as the second argument
if [ -z "$2" ]; then
  echo "Usage: $0 <path_to_env_file> <path_to_backup_directory>"
  echo "Please provide the path to the backup directory (e.g., /path/to/backup/YYYYMMDD_HHMMSS)."
  exit 1
fi

# Check for existing non-template databases
existing_databases=$(psql -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false and datname!='postgres';")

if [ -n "$existing_databases" ]; then
  echo "Error: The following non-template databases already exist in the cluster:"
  echo "$existing_databases"
  echo "Please drop these databases before proceeding with the restore."
  exit 1
else
  echo "No non-template databases found. Proceeding with the restore."
fi

# Assign the second command line argument to RESTORE_DIR
RESTORE_DIR="$2"

# Check if the backup directory exists
if [ ! -d "$RESTORE_DIR" ]; then
  echo "Backup directory not found! Exiting."
  exit 1
fi

# Restore PostgreSQL configuration files
echo "Restoring PostgreSQL configuration files"
CONFIG_FILES=(
  "/etc/postgresql/${PGVERSION}/${PGCLUSTER}/postgresql.conf"
  "/etc/postgresql/${PGVERSION}/${PGCLUSTER}/pg_hba.conf"
  "/etc/postgresql/${PGVERSION}/${PGCLUSTER}/pg_ident.conf"
)

PGDATA="/var/lib/postgresql/${PGVERSION}/${PGCLUSTER}"
HBA_FILE="/etc/postgresql/${PGVERSION}/${PGCLUSTER}/pg_hba.conf"
IDENT_FILE="/etc/postgresql/${PGVERSION}/${PGCLUSTER}/pg_ident.conf"
EXTERNAL_PID_FILE="/var/run/postgresql/${PGCLUSTER}.pid" # Adjust this if the path is different

for config in "${CONFIG_FILES[@]}"; do
  if [ -f "$RESTORE_DIR/$(basename "$config")" ]; then
    echo "Restoring $config"
    sudo cp "$RESTORE_DIR/$(basename "$config")" "$config"

    # If it's the postgresql.conf file, edit it to match PGPORT
    if [[ "$config" == *"postgresql.conf" ]]; then
      echo "Updating port in $config to match PGPORT ($PGPORT)..."
      sudo sed -i "s/^#port = .*/port = $PGPORT/" "$config" # Uncomment and set port
      sudo sed -i "s/^port = .*/port = $PGPORT/" "$config"  # Just set port if already uncommented
      echo "Port updated successfully."
      # Update directories (assuming you have these environment variables defined)
      sudo sed -i "s|^data_directory = .*|data_directory = '$PGDATA'|" "$config"

      sudo sed -i "s|^hba_file = .*|hba_file = '$HBA_FILE'|" "$config"

      sudo sed -i "s|^ident_file = .*|ident_file = '$IDENT_FILE'|" "$config"

      sudo sed -i "s|^#cluster_name = .*|cluster_name = '$PGVERSION/$PGCLUSTER'|" "$config" # Uncomment and set cluster_name
      sudo sed -i "s|^cluster_name = .*|cluster_name = '$PGVERSION/$PGCLUSTER'|" "$config"  # Just set cluster_name if already uncommented

      # Update the external_pid_file
      sudo sed -i "s|^#external_pid_file = .*|external_pid_file = '$EXTERNAL_PID_FILE'|" "$config" # Uncomment and set external_pid_file
      sudo sed -i "s|^external_pid_file = .*|external_pid_file = '$EXTERNAL_PID_FILE'|" "$config"  # Just set external_pid_file if already uncommented
    fi
  else
    echo "Warning: Configuration file $(basename "$config") not found in backup directory!"
  fi
done

sudo pg_ctlcluster ${PGVERSION} ${PGCLUSTER} reload

# Export the password to avoid prompting
export PGPASSWORD=$PGPASSWORD

# Restore user permissions
echo "Restoring user permissions"

# Define a directory for roles backup accessible by the postgres user
POSTGRES_BACKUP_DIR="/var/lib/postgresql/roles_backup"

# Create the directory if it does not exist
if [ ! -d "$POSTGRES_BACKUP_DIR" ]; then
  sudo mkdir -p "$POSTGRES_BACKUP_DIR"
  sudo chown postgres:postgres "$POSTGRES_BACKUP_DIR"
fi

sudo cp $RESTORE_DIR/user_permissions_backup.sql $POSTGRES_BACKUP_DIR/user_permissions_backup.sql
sudo chown postgres:postgres $POSTGRES_BACKUP_DIR/user_permissions_backup.sql

if [ -f "$RESTORE_DIR/user_permissions_backup.sql" ]; then
  sudo -u postgres psql -U postgres -h "$PGHOST" -p "$PGPORT" -f "$POSTGRES_BACKUP_DIR/user_permissions_backup.sql"
  sudo rm $POSTGRES_BACKUP_DIR/user_permissions_backup.sql
else
  echo "User permissions backup file not found!"
fi

# Restore each database
echo "Restoring databases..."
for backup in "$RESTORE_DIR"/*_backup.dump; do

  db_name=$(basename "$backup" .dump)

  # Check if a filter is provided and skip if it doesn't match
  if [ -n "$FILTER_PATTERN" ] && [[ ! "$db_name" == $FILTER_PATTERN ]]; then
    echo "Skipping database $db_name (does not match filter pattern)"
    continue
  fi

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
