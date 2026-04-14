#!/bin/bash

# Script to load a PostgreSQL database dump
# Usage: ./load_postgres_dump.sh <dump_file> <database_name> [-u <user>] [-p <password>]

# Default values
DB_USER=""
DB_PASSWORD=""

# Parse command line arguments (accept options anywhere)
POS_ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    -u|--user)
      if [ -n "$2" ] && [[ "$2" != -* ]]; then
        DB_USER="$2"
        shift 2
      else
        echo "Error: Missing argument for $1" >&2
        echo "Usage: $0 <dump_file> <database_name> [-u <user>] [-p <password>]"
        exit 1
      fi
      ;;
    -p|--password)
      if [ -n "$2" ] && [[ "$2" != -* ]]; then
        DB_PASSWORD="$2"
        shift 2
      else
        echo "Error: Missing argument for $1" >&2
        echo "Usage: $0 <dump_file> <database_name> [-u <user>] [-p <password>]"
        exit 1
      fi
      ;;
    -h|--help)
      echo "Usage: $0 <dump_file> <database_name> [-u <user>] [-p <password>]"
      exit 0
      ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        POS_ARGS+=("$1"); shift
      done
      ;;
    -*)
      echo "Invalid option: $1" >&2
      echo "Usage: $0 <dump_file> <database_name> [-u <user>] [-p <password>]"
      exit 1
      ;;
    *)
      POS_ARGS+=("$1"); shift
      ;;
  esac
done

if [ "${#POS_ARGS[@]}" -ne 2 ]; then
    echo "Usage: $0 <dump_file> <database_name> [-u <user>] [-p <password>]"
    exit 1
fi

DUMP_FILE="${POS_ARGS[0]}"
DB_NAME="${POS_ARGS[1]}"

# Check if dump file exists
if [ ! -f "$DUMP_FILE" ]; then
    echo "Error: Dump file '$DUMP_FILE' not found."
    exit 1
fi

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo "Error: psql is not installed or not in PATH."
    exit 1
fi

# Check if dropdb command is available
if ! command -v dropdb &> /dev/null; then
    echo "Error: dropdb is not installed or not in PATH."
    exit 1
fi

# Check if createdb command is available
if ! command -v createdb &> /dev/null; then
    echo "Error: createdb is not installed or not in PATH."
    exit 1
fi

# Check if pg_restore command is available
if ! command -v pg_restore &> /dev/null; then
    echo "Error: pg_restore is not installed or not in PATH."
    exit 1
fi

echo "Starting database load process..."

# Drop the database if it exists
echo "Dropping database '$DB_NAME' if it exists..."
if [ -n "$DB_USER" ]; then
    dropdb -h localhost -U "$DB_USER" "$DB_NAME" 2>/dev/null
else
    dropdb -h localhost "$DB_NAME" 2>/dev/null
fi
if [ $? -eq 0 ]; then
    echo "Database '$DB_NAME' dropped successfully."
else
    echo "Database '$DB_NAME' did not exist or could not be dropped."
fi

# Create a new database
echo "Creating database '$DB_NAME'..."
if [ -n "$DB_USER" ]; then
    createdb -h localhost -U "$DB_USER" "$DB_NAME"
else
    createdb -h localhost "$DB_NAME"
fi
if [ $? -ne 0 ]; then
    echo "Error: Failed to create database '$DB_NAME'."
    exit 1
fi
echo "Database '$DB_NAME' created successfully."

# Load the dump file
echo "Loading dump file '$DUMP_FILE' into database '$DB_NAME'..."

# Set PGPASSWORD environment variable for authentication if password is provided
if [ -n "$DB_PASSWORD" ]; then
    export PGPASSWORD="$DB_PASSWORD"
fi

# Determine if it's a custom format dump or plain SQL
if [[ "$DUMP_FILE" == *.dump ]] || [[ "$DUMP_FILE" == *.backup ]]; then
    # Custom format dump
    if [ -n "$DB_USER" ]; then
        pg_restore -h localhost -U "$DB_USER" -d "$DB_NAME" "$DUMP_FILE"
    else
        pg_restore -h localhost -d "$DB_NAME" "$DUMP_FILE"
    fi
else
    # Assume it's a plain SQL dump
    if [ -n "$DB_USER" ]; then
        psql -h localhost -U "$DB_USER" -d "$DB_NAME" < "$DUMP_FILE"
    else
        psql -h localhost -d "$DB_NAME" < "$DUMP_FILE"
    fi
fi

if [ $? -eq 0 ]; then
    echo "Database dump loaded successfully into '$DB_NAME'."
else
    echo "Error: Failed to load database dump."
    exit 1
fi

echo "Database load process completed."