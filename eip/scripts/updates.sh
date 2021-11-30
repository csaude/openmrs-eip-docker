#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#
#INSTALL THE GIT
apk add git

export HOME_DIR="/home/eip/"
timestamp=`date +%Y-%m-%d_%H-%M-%S`
echo "LISTING $HOME_DIR CONTENT AT $timestamp" >> $HOME_DIR/updates.log
echo "-------------------------------------------------------------" >> $HOME_DIR/updates.log

cd $HOME_DIR
ls >> $HOME_DIR/updates.log

~
~
~

