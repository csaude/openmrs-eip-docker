#!/bin/sh
# This scripts execute a given script on a given db
#

DB_HOST=$1
DB_HOST_PORT=$2
DB_USER=$3
DB_PASSWD=$4
DB_NAME=$5
SCRIPT=$6
RESULT_FILE=$7
MYSQL_CMD=$(which mysql)


if [ -z $MYSQL_CMD ]; then 
	echo "Tryning to install mysql-client"

	APK_CMD=$(which apk)

	if [ ! -z $APK_CMD ];then
       		echo "INSTALLING mysql-client"
		apk add mysql-client
	else
		echo "PLEASE INSTALL mysql-client"	
		exit 1 
	fi
fi

mysql -u $DB_USER --password=$DB_PASSWD -P $DB_HOST_PORT -h $DB_HOST $DB_NAME < $SCRIPT 2> /dev/null > $RESULT_FILE 
