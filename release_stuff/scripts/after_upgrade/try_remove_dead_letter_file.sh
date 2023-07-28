#!/bin/sh
#ENV
HOME_DIR="/home/eip"
LOG_DIR="$SHARED_DIR/logs/upgrade"
DEAD_LETTER="/root/dead.letter"
RESCHEDULE_FOLDER="/home/eip/shared/mail/reschedule"

echo "TRY TO REMOVE dead.letter FILE..." | tee -a $LOG_DIR/upgrade.log

if [ -f "$DEAD_LETTER" ]; then
        echo "THE DEAD LETTER FILE EXISTS... REMOVING IT..." | tee -a $LOG_DIR/upgrade.log
 	rm $DEAD_LETTER
        echo "DEAD LETTER FILE REMOVED!" | tee -a $LOG_DIR/upgrade.log
else
       echo "THE DEAD LETTER FILER DOES NOT EXISTS" | tee -a $LOG_DIR/upgrade.log
fi

echo "TRY TO REMOVE RESCHEDULE FOLDER..." | tee -a $LOG_DIR/upgrade.log

if [ -d "$RESCHEDULE_FOLDER" ]; then
        echo "THE RESCHEDULE FOLDER EXISTS... REMOVING IT..." | tee -a $LOG_DIR/upgrade.log
	rm -fr /home/eip/shared/mail/reschedule
        echo "RESCHEDULE FOLDER REMOVED!" | tee -a $LOG_DIR/upgrade.log
else
       echo "THE RESCHEDULE FOLDER DOES NOT EXISTS" | tee -a $LOG_DIR/upgrade.log
fi

