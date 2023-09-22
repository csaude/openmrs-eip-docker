#!/bin/sh
# description: This shell is intended to performe action after update check
# ENV
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
LOG_DIR="$HOME_DIR/logs/upgrade"
CRONS_DIR="$HOME_DIR/cron"
SCHEDULE_LOG="$LOG_DIR/schedule.log"
LAST_UPDATE_CHECK_REPORT="$LOG_DIR/last_update_check_report"
RUN_UPDATE_CRON="$CRONS_DIR/run_updates.sh"


. $SCRIPTS_DIR/commons.sh

logToScreenAndFile "Finalizing scheduled operation" $SCHEDULE_LOG

#Check is the update was successifull performed. For that here we check the internet avaliability

isInternetConnectionAvaliable

internetAvaliable=$?

currDateTime=$(getCurrDateTime)

if [ "$internetAvaliable" = 1 ]; then
        logToScreenAndFile "The upted check operation was executed successifuly" $SCHEDULE_LOG

        echo "LAST UPDATE CHECK ON $currDateTime" > $LAST_UPDATE_CHECK_REPORT
else
        logToScreenAndFile "The updated check operation was not successifuly executed" $SCHEDULE_LOG
fi

if [ -f "$RUN_UPDATE_CRON" ]; then
	rm $RUN_UPDATE_CRON
fi

$SCRIPTS_DIR/install_crons.sh
