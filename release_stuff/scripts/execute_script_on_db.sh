#!/bin/sh
# This scripts execute a given script on a given db
#

DB_HOST=$1
DB_HOST_PORT=$2
DB_USER=$3
DB_PASSWD=$4
DB_NAME=$5
SCRIPT=$6

APK_CMD=$(which apk)


if [ ! -z $APK_CMD ];then
        echo "INSTALLING mysql-client"
	apt add mysql-client
else
	echo "PLEASE INSTALL mysql-client"	
	exit 0
fi

nohup mysql -u $DB_USER -p $DB_PASSWD -P $DB_HOST_PORT -h $DB_HOST $DB_NAME > $SCRIPT 2>&1 & 
