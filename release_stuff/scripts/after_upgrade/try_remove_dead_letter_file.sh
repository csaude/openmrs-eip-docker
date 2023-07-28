#!/bin/sh
#ENV
HOME_DIR="/home/eip"
LOG_DIR="$SHARED_DIR/logs/upgrade"
DEAD_LETTER="/root/dead.letter"

if [ -f "$DEAD_LETTER" ]; then
        echo "THE DEAD LETTER FILE EXISTS... REMOVING IT..." | tee -a $LOG_DIR/upgrade.log
 	rm $DEAD_LETTER
        echo "DEAD LETTER FILE REMOD!" | tee -a $LOG_DIR/upgrade.log
else
       echo "THE DEAD LETTER FILER DOES NOT EXISTS" | tee -a $LOG_DIR/upgrade.log
fi
