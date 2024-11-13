#!/bin/sh
# description: This shell is intended re-sync the clinicalsummary_usage_report table
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
CONF_FILE="$HOME_DIR/conf/re_sync_clinicalsummary_usage_report.json"


$SCRIPTS_DIR/db_re_sync.sh "1975-01-01" "$CONF_FILE" 


