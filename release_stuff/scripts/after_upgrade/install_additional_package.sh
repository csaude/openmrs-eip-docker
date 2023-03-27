#!/bin/sh
#This bash install all the necessary applications needed by the container

export HOME_DIR="/home/eip"
export LOG_DIR="$HOME_DIR/shared/logs/apk"
export SCRIPTS_DIR="$HOME_DIR/scripts"
export LOG_FILE="$LOG_DIR/apk_install.log"

. $SCRIPTS_DIR/commons.sh

isDockerInstallation
isDockerContainer=$?

if [ $isDockerContainer = 1 ]; then 
	apk update

	logToScreenAndFile "TRYING TO INSTALL OPENSSL" $LOG_FILE

	apk add openssl 

	logToScreenAndFile "OPENSSL INSTALLED" $LOG_FILE
else
 	SSL_LOCATION=$(which openssl)

        if [ -z $SSL_LOCATION ]; then
	   logToScreenAndFile "OPENSSL IS NOT PRESENT. PLEASE RE-RUN THE INSTALL IT USING THE COMMAND BELLOW. " $LOG_FILE
	   logToScreenAndFile "-----------------------------------------------------------------------------" $LOG_FILE
	   logToScreenAndFile "sudo /home/eip/scripts/apt_install.sh" $LOG_FILE
	   logToScreenAndFile "-----------------------------------------------------------------------------" $LOG_FILE
	   logToScreenAndFile "THE APPLICATION MAY NOT RUN CORRECTILY WITHOUT MISSING PACKAGES" $LOG_FILE
	fi
fi
