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

mysql -u $DB_USER --password=$DB_PASSWD -P $DB_HOST_PORT -h $DB_HOST $DB_NAME < $SCRIPT 2> /dev/null > $RESULT_FILE 
