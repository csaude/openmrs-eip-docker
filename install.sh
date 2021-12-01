#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#

#ENV
HOME_DIR="/home/eip"
INSTALL_FINISHED_REPORT_FILE="/home/install_finished_report_file"

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
	echo "INSTALLATION FINISHED"
else
	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo "STARTING EIP INSTALLATION PROCESS AT $timespamp"

	cd $HOME_DIR

	source ../eip_setup/scripts/realease_info.sh	

	REMOTE_RELEASE_NAME=$RELEASE_NAME
	REMOTE_RELEASE_DATE=$RELEASE_DATE

	echo "FOUND RELEASE {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE} "

	echo "PERFORMING INSTALLATION STEPS..."

	echo "COPPING APP FILES"

	cp -R ../eip_setup/* .
	echo "ALL FILES WERE COPIED"
        echo "STARING EIP APPLICATION"
	scripts/eip.sh

        timestamp=`date +%Y-%m-%d_%H-%M-%S`
	echo "Installation finished at " >> /home/install_finished_report_file
fi

# Add update script to cron
echo "Adding updates.sh to crontab"
echo "*/2       *       *       *       *       /home/eip/scripts/updates.sh" >> /etc/crontabs/root
echo "Script added to crontab"
crond -f -l 8



