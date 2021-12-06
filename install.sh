#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#
#ENV
HOME_DIR="/home/eip"
EIP_SETUP_BASE_DIR="/home/openmrs-eip-docker"
EIP_SETUP_STUFF_DIR="$EIP_SETUP_BASE_DIR/release_stuff"
SCRIPTS_DIR="$HOME_DIR/scripts"
SETUP_SCRIPTS_DIR="$EIP_SETUP_STUFF_DIR/scripts"
INSTALL_FINISHED_REPORT_FILE="$HOME_DIR/install_finished_report_file"

if [ -f "$INSTALL_FINISHED_REPORT_FILE" ]; then
	echo "INSTALLATION FINISHED"
else
	timestamp=`date +%Y-%m-%d_%H-%M-%S`

	echo "STARTING EIP INSTALLATION PROCESS AT $timespamp"

	cd $HOME_DIR

	source $SETUP_SCRIPTS_DIR/release_info.sh	

	REMOTE_RELEASE_NAME=$RELEASE_NAME
	REMOTE_RELEASE_DATE=$RELEASE_DATE

	echo "FOUND RELEASE {NAME: $REMOTE_RELEASE_NAME, DATE: $REMOTE_RELEASE_DATE} "

	echo "PERFORMING INSTALLATION STEPS..."

	echo "COPPING APP FILES"

	cp -R $EIP_SETUP_STUFF_DIR/* $HOME_DIR/
	cp -R $EIP_SETUP_BASE_DIR $HOME_DIR 

	echo "ALL FILES WERE COPIED"

        timestamp=`date +%Y-%m-%d_%H-%M-%S`
	echo "Installation finished at $timestamp" >> $INSTALL_FINISHED_REPORT_FILE
fi
echo "STARING EIP APPLICATION"

$SCRIPTS_DIR/eip_startup.sh

# Add update script to cron
echo "Adding updates.sh to crontab"
echo "*/2       *       *       *       *       /home/eip/scripts/updates.sh" >> /etc/crontabs/root
echo "Script added to crontab"
crond -f -l 8



