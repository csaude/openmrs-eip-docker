#!/bin/sh
#This bash install all the necessary applications needed by the container

export HOME_DIR="/home/eip"
export LOG_DIR="$HOME_DIR/logs/apt"
export SETUP_DIR="$HOME_DIR/openmrs-eip-docker"
export SETUP_SCRIPT_DIR="$SETUP_DIR/release_stuff/scripts"

. $SETUP_SCRIPT_DIR/commons.sh

apt update

logToScreenAndFile "INSTALLING OPENSSL" $LOG_DIR/apt_install.log
apt install -y openssl
logToScreenAndFile "OPENSSL INSTALLED" $LOG_DIR/apt_install.log

chown -R eip "$HOME_DIR/shared" && chgrp -R eip "$HOME_DIR/shared"

$SETUP_SCRIPT_DIR/configure_ssmtp.sh |  tee -a $LOG_DIR/apt_install.log

if [ -z $JAVA_HOME ]; then
        logToScreenAndFile "JAVA_HOME is not defined! Configuring it"
        java_home=$(readlink -f $(which java))
        tmp="\/jre\/bin\/java"

        result=$(echo "$java_home" | sed "s/$tmp//g")

        export JAVA_HOME=$result
fi

logToScreenAndFile "CHANGING MOD OF JAVA carcets FILE ($JAVA_HOME/jre/lib/security/cacerts) " $LOG_DIR/apt_install.log
sudo chmod 777 $JAVA_HOME/jre/lib/security/cacerts
