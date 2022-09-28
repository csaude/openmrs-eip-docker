#!/bin/sh
# description: This shell is intended to configure the smtp within the OS
#

# Set environment.
timestamp=`date +%Y-%m-%d_%H-%M-%S`

EIP_HOME="/home/eip"
EIP_SCRIPTS_DIR="$EIP_HOME/scripts"

ORIGINAL_SSMTP_CONFIG_FILE=$EIP_SCRIPTS_DIR/ssmtp.conf
TEMP_SSMTP_CONFIG_FILE=$EIP_SCRIPTS_DIR/ssmtp.conf.tmp

OS_SMTP_CONFIG_FILE=/etc/ssmtp/ssmtp.conf

cp $ORIGINAL_SSMTP_CONFIG_FILE $TEMP_SSMTP_CONFIG_FILE

sed -i "s/dbsync_notification_email_recipients/$dbsync_notification_email_recipients/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_auth_user/$dbsync_notification_email_smtp_auth_user/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_user_pass/$dbsync_notification_email_smtp_user_pass/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_host_name/$dbsync_notification_email_smtp_host_name/g" $TEMP_SSMTP_CONFIG_FILE
sed -i "s/dbsync_notification_email_smtp_host_port/$dbsync_notification_email_smtp_host_port/g" $TEMP_SSMTP_CONFIG_FILE

mv $TEMP_SSMTP_CONFIG_FILE $OS_SMTP_CONFIG_FILE
