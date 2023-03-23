#!/bin/sh
# description: This shell is intended to configure the smtp within the OS
#

# Set environment.
ORIGINAL_SSMTP_CONFIG_FILE=$1

. $EIP_SCRIPTS_DIR/commons.sh
. $EIP_SCRIPTS_DIR/try_to_load_environment.sh

echo "Configuring smtp..."

ORIGINAL_SSMTP_CONFIG_FILE=$EIP_HOME/ssmtp.conf
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
