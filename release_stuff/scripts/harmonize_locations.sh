#!/bin/sh
# This scripts execute a given script on a given db
#
HOST_DIR=/home/eip
DB_HOST=172.17.0.1
DB_HOST_PORT=$openmrs_db_port
DB_USER=root
DB_PASSWD=$spring_openmrs_datasource_password
DB_NAME=$openmrs_db_name
SCRIPT=$HOME_DIR/etc/sql/harmonize_location_zambezia.sql

./execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $SCRIPT
