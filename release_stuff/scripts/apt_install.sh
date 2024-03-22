#!/bin/sh
#This bash install all the necessary applications needed by the container

export HOME_DIR="/home/eip"
export LOG_DIR="$HOME_DIR/logs/apt"
export SETUP_DIR="/home/openmrs-eip-docker"

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/apt_install.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/apt_install.log
fi

apt update

echo "TRYING TO INSTALL JAVA" | tee -a $LOG_DIR/apt_install.log
apt install -y openjdk-8-jdk-headless
echo "JAVA INSTALLED" | tee -a $LOG_DIR/apt_install.log

echo "TRYING TO INSTALL CURL" | tee -a $LOG_DIR/apt_install.log
apt install -y curl
echo "CURL INSTALLED" | tee -a $LOG_DIR/apt_install.log

echo "TRYING TO INSTALL GIT" | tee -a $LOG_DIR/apt_install.log
apt install -y git
echo "GIT INSTALLED" | tee -a $LOG_DIR/apt_install.log

echo "INSTALLING EXPECT" | tee -a $LOG_DIR/apt_install.log
apt install -y expect
echo "EXPECT INSTALLED" | tee -a $LOG_DIR/apt_install.log

echo "INSTALLING OPENSSL" | tee -a $LOG_DIR/apt_install.log
apt install -y openssl
echo "OPENSSL INSTALLED" | tee -a $LOG_DIR/apt_install.log

echo "INSTALLING OPENSSH" | tee -a $LOG_DIR/apt_install.log
apt install -y openssh
echo "OPENSSH INSTALLED" | tee -a $LOG_DIR/apt_install.log

echo "INSTALLING OPENSSHPASS" | tee -a $LOG_DIR/apt_install.log
apt install -y sshpass
echo "OPENSSHPASS INSTALLED" | tee -a $LOG_DIR/apt_install.log

MYSQL_CLIENT=$(which mysql)

if [ -z $MYSQL_CLIENT ];then

	echo "INSTALLING MYSQL CLIENT" | tee -a $LOG_DIR/apt_install.log
	apt install -y mysql-client
	echo "MYSQL CLIENT INSTALLED" | tee -a $LOG_DIR/apt_install.log
	
	else
		echo "MYSQL CLIENT ALREADY INSTALLED" | tee -a $LOG_DIR/apt_install.log
fi

chown -R eip "$HOME_DIR/shared" && chgrp -R eip "$HOME_DIR/shared"
chown -R eip "$HOME_DIR/logs" && chgrp -R eip "$HOME_DIR/logs"

if [ -z $JAVA_HOME ];then
	echo "JAVA_HOME is not defined! Configuring it"
	java_home=$(readlink -f $(which java))
	tmp="\/bin\/java"

	result=$(echo "$java_home" | sed "s/$tmp//g")

	export JAVA_HOME=$result
fi

echo "CHANGING MOD OF JAVA carcets FILE ($JAVA_HOME/lib/security/cacerts) " | tee -a $LOG_DIR/apt_install.log
chmod 777 $JAVA_HOME/lib/security/cacerts
