#!/bin/sh
# This script try to schedule a check for update if the check have not run after 24 hours
#

#ENV
HOME_DIR="/home/eip"
#HOME_DIR="/home/eip/prg/docker/eip-docker-testing"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/logs/upgrade"
CRONS_DIR="$HOME_DIR/cron"
SCHEDULE_LOG="$LOG_DIR/schedule.log"
LAST_UPDATE_CHECK_REPORT="$LOG_DIR/last_update_check_report"
SCHEDULE=0
UPDATE_CHECK_PERIOD=3
RUN_UPDATE_CRON="$CRONS_DIR/run_updates.sh"

. $SCRIPTS_DIR/commons.sh

logToScreenAndFile "Trying to schedule update check..." $SCHEDULE_LOG

if [ ! -f "$LAST_UPDATE_CHECK_REPORT" ]; then
        SCHEDULE=1
        #logToScreenAndFile "Last update check report not found! The update check will be scheduled now..." $SCHEDULE_LOG
else
        lastUpdateCheckOn=$(getFileAge $LAST_UPDATE_CHECK_REPORT 'd')

        if [ $lastUpdateCheckOn -ge $UPDATE_CHECK_PERIOD ]; then
                SCHEDULE=1
                #logToScreenAndFile "Last update check report done $lastUpdateCheckOn days ago! The update check will be scheduled now..." $SCHEDULE_LOG
        else
                #logToScreenAndFile "Last update check report was done $lastUpdateCheckOn days ago! The update check will be posponed!" $SCHEDULE_LOG

        fi
fi

logToScreenAndFile "SCHEDULE = $SCHEDULE" $SCHEDULE_LOG

if [ $SCHEDULE -eq 1 ]; then
        #logToScreenAndFile "Starting schedule update check..." $SCHEDULE_LOG

        echo "*/5       *       *       *       *       $SCRIPTS_DIR/run_updates.sh" > ${RUN_UPDATE_CRON}

        $SCRIPTS_DIR/install_crons.sh

        #logToScreenAndFile "Update check scheduleded!" $SCHEDULE_LOG
fi
