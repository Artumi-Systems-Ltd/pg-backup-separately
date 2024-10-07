#!/bin/bash

# Usage function to display help
usage() {
  echo "Usage: $0 <path_to_env_file> <older_than_days>"
  echo "Arguments:"
  echo "  path_to_env_file    Path to the .env file containing BACKUP_DIR."
  echo "  older_than_days      Number of days to consider for deletion."
  exit 1
}

# Check for the correct number of arguments
if [ $# -ne 2 ]; then
  usage
fi

# Load environment variables from the provided .env file
if [ ! -f "$1" ]; then
  echo "Error: .env file $1 does not exist."
  exit 1
fi

source "$1"

# Ensure BACKUP_DIR is set
if [ -z "$BACKUP_DIR" ]; then
  echo "Error: BACKUP_DIR is not set in the .env file."
  exit 1
fi

TARGET_DIR="$BACKUP_DIR"
OLDER_THAN="$2"

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory $TARGET_DIR does not exist."
  exit 1
fi

# Prevent deletion if there are no directories
if [[ "$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 0 ]]; then
  echo "No directories to delete in $TARGET_DIR."
  exit 0
fi

# Get the current date in YYMMDD format
current_date=$(date +%Y%m%d)

# Calculate the threshold date
threshold_date=$(date -d "$current_date - $OLDER_THAN days" +%Y%m%d)

# Find the most recent backup directory based on name
latest_backup=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)

# Iterate through directories and delete those older than the threshold date
for dir in "$TARGET_DIR"/*; do
  dir_name=$(basename "$dir")

  # Ensure the directory name matches the expected format
  if [[ $dir_name =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
    dir_date=${dir_name:0:8} # Extract date part (YYMMDD)

    # Compare dates and delete if older than the threshold
    if [[ "$dir_date" < "$threshold_date" ]] && [[ "$dir" != "$latest_backup" ]]; then
      echo "Deleting directory: $dir"
      rm -rf "$dir"
    fi
  else
    echo "Skipping directory with invalid format: $dir_name"
  fi
done

echo "Cleaned up directories older than $OLDER_THAN days in $TARGET_DIR, while retaining the latest backup."
