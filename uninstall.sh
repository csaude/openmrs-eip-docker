#!/bin/sh
#This bash install all the necessary applications needed by the container

export HOME_DIR="/home/eip"
export SETUP_DIR="/home/openmrs-eip-docker"

$SETUP_DIR/release_stuff/scripts/eip_stop.sh

echo "STARTING DBSYNC UNISTALLATION"

echo "REMOVING $HOME_DIR/application-sender.properties"

if [ -f $HOME_DIR/application-sender.properties ]; then 
	rm -fr $HOME_DIR/application-sender.properties

	echo "REMOVED $HOME_DIR/application-sender.properties"
else
	echo "$HOME_DIR/application-sender.properties DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/cron"

if [ -d $HOME_DIR/cron ]; then
	rm -fr $HOME_DIR/cron
	echo "REMOVED $HOME_DIR/cron"
else
	echo "$HOME_DIR/cron DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/dbsync-users.properties"
if [ -f $HOME_DIR/dbsync-users.properties ]; then 
	rm -fr $HOME_DIR/dbsync-users.properties
	echo "REMOVED $HOME_DIR/dbsync-users.properties"
else
	 echo "$HOME_DIR/dbsync-users.properties DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/etc"
if [ -d $HOME_DIR/etc ]; then 
	rm -fr $HOME_DIR/etc
	echo "REMOVED $HOME_DIR/etc"
else
	  echo "$HOME_DIR/etc DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/git"
if [ -d $HOME_DIR/git ]; then
	rm -fr $HOME_DIR/git
	echo "REMOVED $HOME_DIR/git"
else
	echo "$HOME_DIR/git DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/install_finished_report_file"
if [ -f $HOME_DIR/install_finished_report_file ]; then 
	rm -fr $HOME_DIR/install_finished_report_file
	echo "REMOVED $HOME_DIR/install_finished_report_file"
else
	echo "$HOME_DIR/install_finished_report_file DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/install_info"
if [ -f $HOME_DIR/install_info ]; then 
	rm -fr $HOME_DIR/install_info
	echo "REMOVED $HOME_DIR/install_info"
else
	echo "$HOME_DIR/install_info DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/logback-console.xml"
if [ -f $HOME_DIR/logback-console.xml ]; then
	rm -fr $HOME_DIR/logback-console.xml
	echo "REMOVED $HOME_DIR/logback-console.xml"
else
	echo "$HOME_DIR/logback-console.xml DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/logback-spring.xml"
if [ -f $HOME_DIR/logback-spring.xml ]; then 
	rm -fr $HOME_DIR/logback-spring.xml
	echo "REMOVED $HOME_DIR/logback-spring.xml"
else
	echo "$HOME_DIR/logback-spring.xml DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/openmrs-eip-app-sender.jar"
if [ -f $HOME_DIR/openmrs-eip-app-sender.jar ]; then 
	rm -fr $HOME_DIR/openmrs-eip-app-sender.jar
	echo "REMOVED $HOME_DIR/openmrs-eip-app-sender.jar"
else
	echo "$HOME_DIR/openmrs-eip-app-sender.jar DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/openmrs-eip-docker"
if [ -d $HOME_DIR/openmrs-eip-docker ]; then 
	rm -fr $HOME_DIR/openmrs-eip-docker
	echo "REMOVED $HOME_DIR/openmrs-eip-docker"
else
	echo "$HOME_DIR/openmrs-eip-docker DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/routes"
if [ -d $HOME_DIR/routes ]; then 
	rm -fr $HOME_DIR/routes
	echo "REMOVED $HOME_DIR/routes"
else
	echo "$HOME_DIR/routes DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/scripts"
if [ -d $HOME_DIR/scripts ]; then
	rm -fr $HOME_DIR/scripts
	echo "REMOVED $HOME_DIR/scripts"
else
	echo "$HOME_DIR/scripts DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/install_info"
if [ -d $HOME_DIR/install_info ]; then
        rm -fr $HOME_DIR/install_info
        echo "REMOVED $HOME_DIR/install_info"
else
        echo "$HOME_DIR/install_info DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/ssmtp.conf"
if [ -f $HOME_DIR/ssmtp.conf ]; then
	rm -fr $HOME_DIR/ssmtp.conf
	echo "REMOVED $HOME_DIR/ssmtp.conf"
else
	echo "$HOME_DIR/ssmtp.conf DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/update_email_content"
if [ -f $HOME_DIR/update_email_content ]; then
        rm -fr $HOME_DIR/update_email_content
        echo "REMOVED $HOME_DIR/update_email_content"
else
        echo "$HOME_DIR/update_email_content DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/tmp_update_done_01"
if [ -f $HOME_DIR/tmp_update_done_01 ]; then
        rm -fr $HOME_DIR/tmp_update_done_01
        echo "REMOVED $HOME_DIR/tmp_update_done_01"
else
        echo "$HOME_DIR/tmp_update_done_01 DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/apt_install.log"
if [ -f $HOME_DIR/apt_install.log ]; then
        rm -fr $HOME_DIR/apt_install.log
        echo "REMOVED $HOME_DIR/apt_install.log"
else
        echo "$HOME_DIR/apt_install.log DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/artemis.cert"
if [ -f $HOME_DIR/artemis.cert ]; then
        rm -fr $HOME_DIR/artemis.cert
        echo "REMOVED $HOME_DIR/artemis.cert"
else
        echo "$HOME_DIR/artemis.cert DOES NOT EXISTS"
fi

echo "REMOVING $HOME_DIR/liquibase_check_status.sql"
if [ -f $HOME_DIR/liquibase_check_status.sql ]; then
        rm -fr $HOME_DIR/liquibase_check_status.sql
        echo "REMOVED $HOME_DIR/liquibase_check_status.sql"
else
        echo "$HOME_DIR/liquibase_check_status.sql DOES NOT EXISTS"
fi


echo "DBSYNC SUCCESSIFULY UNISTALLED"


