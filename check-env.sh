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

# Define required environment variables
REQUIRED_VARS=(
  "PGUSER"
  "PGHOST"
  "PGPORT"
  "BACKUP_DIR"
  "PGVERSION"
  "PGCLUSTER"
)

missing_vars=false

# Check for the presence of each required variable
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: Required variable $var is not set in the .env file."
    missing_vars=true
  fi
done

# If no errors were found, print success message
if [ "$missing_vars" = true ]; then
  echo "Please correct the above issues before proceeding."
  exit 1
else
  echo "All required variables are set correctly!"
fi

# Define required environment variables
MAYBE_VARS=(
  "PGPASSWD"
)

# Check for the presence of each required variable
for var in "${MAYBE_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Warning: Variable $var is not set in the .env file, it may be required"
    missing_vars=true
  fi
done

# If no errors were found, print success message
if [ "$missing_vars" = false ]; then
  echo "All required variables are set correctly!"
fi
