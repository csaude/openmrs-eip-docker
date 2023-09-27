#!/bin/sh
# This script creates a file ([EIP_HOME]/shared/logs/cron/test_cron.log) if it doesn't exist, just to verify if the cron is up and running.
# To do the test, just delete the above file and wait ~5min
# If a new file is created, cron is up and running.
HOME_DIR="/home/eip"
LOG_DIR="$HOME_DIR/logs/cron"

if [ ! -d "$LOG_DIR" ]; then
       mkdir -p $LOG_DIR
fi

if [ ! -f "$LOG_DIR/test_cron.log" ]; then
	echo "Cron is working." > $LOG_DIR/test_cron.log
fi
