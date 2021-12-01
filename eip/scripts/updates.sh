#!/bin/sh
# This scrip is intended to check for updates for eip application and apply them when avaliable
#
#INSTALL THE GIT
apk add git

export HOME_DIR="/home/eip/"
timestamp=`date +%Y-%m-%d_%H-%M-%S`
echo "CHECKING FOR UPDATES AT $timestamp" >> $HOME_DIR/updates.log
echo "-------------------------------------------------------------" >> $HOME_DIR/updates.log

cd $HOME_DIR

if not dir_exists then ...
   #log the cloning process
   git clone https://github.com/FriendsInGlobalHealth/openmrs-eip-releases.git
   #log the finishing clone process  
   #notify via email the remote administrator that the clonig was don
fi


git pull origin master

if there_is_changes then
	#execute the change script
fi


ls >> $HOME_DIR/updates.log

~
~
~

