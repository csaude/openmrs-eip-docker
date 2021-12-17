#!/bin/sh
#This bash install all the necessary applications needed by the container

HOME_DIR=/home/eip

apk update

echo "TRYING TO INSTALL GIT" | tee -a $HOME_DIR/apk_install.log
apk add git
echo "GIT INSTALLED" | tee -a $HOME_DIR/apk_install.log

echo "INSTALLING SSMPT" | tee -a $HOME_DIR/apk_install.log
apk add ssmtp
echo "SSMPT INSTALLED" | tee -a $HOME_DIR/apk_install.log

echo "INSTALLING OPENSSH" | tee -a $HOME_DIR/apk_install.log
apk add openssh
echo "OPENSSH INSTALLED" | tee -a $HOME_DIR/apk_install.log

echo "INSTALLING EXPECT" | tee -a $HOME_DIR/apk_install.log
apk add expect
echo "EXPECT INSTALLED" | tee -a $HOME_DIR/apk_install.log
