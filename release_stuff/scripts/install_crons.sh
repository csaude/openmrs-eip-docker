#!/bin/sh
# script for backup the debezium off-set file
#

# Set environment.
CRONS_HOME=/home/eip/cron
timestamp=`date +%Y-%m-%d_%H-%M-%S`

cd $CRONS_HOME

for FILE in *.sh; do 
	if [ -f "$FILE"_installed ]; then
   		echo "The $FILE is allredy installed" | tee $CRONS_HOME/install.log
	else
   		echo "INSTALLING CRON ON $FILE" | tee $CRONS_HOME/install.log
		./$FILE
   		echo "CRON ON $FILE INSTALLED" | tee $CRONS_HOME/install.log
		echo "Cron installed on $timestamp" > "$FILE"_installed
	fi

done

echo "AL CRONS WERE INSTALLED" | tee $CRONS_HOME/install.log

