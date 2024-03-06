#!/bin/sh
#This bash install all the necessary applications needed by the container

export HOME_DIR=/home/eip
export LOG_DIR=$HOME_DIR/logs/apk

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/apk_install.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/apk_install.log
fi

apk update

echo "TRYING TO INSTALL CURL" | tee -a $LOG_DIR/apk_install.log
apk add curl

echo "TRYING TO INSTALL GIT" | tee -a $LOG_DIR/apk_install.log
apk add git
echo "GIT INSTALLED" | tee -a $LOG_DIR/apk_install.log

echo "INSTALLING EXPECT" | tee -a $LOG_DIR/apk_install.log
apk add expect
echo "EXPECT INSTALLED" | tee -a $LOG_DIR/apk_install.log

echo "TRYING TO INSTALL WGET" | tee -a $LOG_DIR/apk_install.log
apk add wget
echo "WGET INSTALLED" | tee -a $LOG_DIR/apk_install.log

echo "TRYING TO INSTALL OPENSSL" | tee -a $LOG_DIR/apk_install.log
apk add openssl
echo "OPENSSL INSTALLED" | tee -a $LOG_DIR/apk_install.log

echo "INSTALLING OPENSSH" | tee -a $LOG_DIR/apk_install.log
apk add openssh
echo "OPENSSH INSTALLED" | tee -a $LOG_DIR/apk_install.log

echo "INSTALLING SSHPASS" | tee -a $LOG_DIR/apk_install.log
apk add sshpass
echo "SSHPASS INSTALLED" | tee -a $LOG_DIR/apk_install.log
