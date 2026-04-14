#!/bin/bash

# Set paths
ODOO_PATH="/var/lib/odoo"
PYTHON_BIN="/usr/bin/python3"
ODOO_CONF="/etc/odoo/odoo.conf"
ODOO_BIN="/usr/bin/odoo"
# DB as parameter
DB_NAME=

if [ -z "$DB_NAME" ]; then
    echo "Usage: $0 <database_name>"
    exit 1
fi

$PYTHON_BIN /mnt/extra-addons/dd_autoupdate/scripts/auto_update.py --db_name=$DB_NAME --odoo_bin="$ODOO_BIN"
