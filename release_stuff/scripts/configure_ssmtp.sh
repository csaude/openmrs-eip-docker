#!/bin/sh
# script for configure ssmtp
#

# Set environment.
HOME_DIR=/home/eip
SETUP_DIR=/home/openmrs-eip-docker
SSMTP_DEST_FILE=/etc/ssmtp/ssmtp.conf
timestamp=`date +%Y-%m-%d_%H-%M-%S`
LOG_DIR=$HOME_DIR/shared/logs/ssmtp

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/ssmtp_configure.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/ssmtp_configure.log
fi

if grep -q docker /proc/1/cgroup; then
   echo "ENV ALREADY SET"
else
   echo "SETTING ENV"
   export $(cat $HOME_DIR/eip.env | xargs)
fi

echo "CREATING SSMTP CONFIGURATION" | tee -a $LOG_DIR/ssmtp_configure.log

cp $SETUP_DIR/release_stuff/ssmtp.conf $SSMTP_DEST_FILE

sed -i "s/dbsync_notification_email_recipients/$dbsync_notification_email_recipients/g" $SSMTP_DEST_FILE
sed -i "s/dbsync_notification_email_smtp_auth_user/$dbsync_notification_email_smtp_auth_user/g" $SSMTP_DEST_FILE
sed -i "s/dbsync_notification_email_smtp_user_pass/$dbsync_notification_email_smtp_user_pass/g" $SSMTP_DEST_FILE
sed -i "s/dbsync_notification_email_smtp_host_name/$dbsync_notification_email_smtp_host_name/g" $SSMTP_DEST_FILE
sed -i "s/dbsync_notification_email_smtp_host_port/$dbsync_notification_email_smtp_host_port/g" $SSMTP_DEST_FILE
sed -i "s/db_sync_senderId/$db_sync_senderId/g" $SSMTP_DEST_FILE

echo "SMTP CONFIGURED" | tee -a $LOG_DIR/ssmtp_configure.log
