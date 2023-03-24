#!/bin/sh
# description: This shell is intended to configure the smtp within the OS
#

# Set environment.

EIP_HOME="/home/eip"

#Discovery where this script was called from which is the current script_dir
SCRIPTS_DIR=$(readlink -f "$0")
SCRIPTS_DIR=$(dirname $SCRIPTS_DIR)

echo "Configuring smtp..."

echo "EIP_SCRIPTS_DIR: $SCRIPTS_DIR"

CUR_DIR=$(pwd)

echo "CUR_DIR: $CUR_DIR"


#Enter to script dir and the go to the parent folder which is setup stuff dir of eip home dir
cd $SCRIPTS_DIR
cd ../


ORIGINAL_SSMTP_CONFIG_FILE=$(pwd)
ORIGINAL_SSMTP_CONFIG_FILE="$ORIGINAL_SSMTP_CONFIG_FILE/ssmtp.conf"


. $EIP_SCRIPTS_DIR/commons.sh
. $EIP_SCRIPTS_DIR/try_to_load_environment.sh


TEMP_SSMTP_CONFIG_FILE=$EIP_HOME/ssmtp.conf.tmp

OS_SMTP_CONFIG_FILE=/etc/ssmtp/ssmtp.conf

cp $ORIGINAL_SSMTP_CONFIG_FILE $TEMP_SSMTP_CONFIG_FILE

sed -i "s/dbsync_notification_email_recipients/$dbsync_notification_email_recipients/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_auth_user/$dbsync_notification_email_smtp_auth_user/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_user_pass/$dbsync_notification_email_smtp_user_pass/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_host_name/$dbsync_notification_email_smtp_host_name/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_host_port/$dbsync_notification_email_smtp_host_port/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/db_sync_senderId/$db_sync_senderId/g" $TEMP_SSMTP_CONFIG_FILE

mv $TEMP_SSMTP_CONFIG_FILE $OS_SMTP_CONFIG_FILE

cd $CUR_DIR
