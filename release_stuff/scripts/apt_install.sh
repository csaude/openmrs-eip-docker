#!/bin/sh
#This bash install all the necessary applications needed by the container

export HOME_DIR="/home/eip"
export LOG_DIR="$HOME_DIR/logs/apt"
export SETUP_DIR="/home/openmrs-eip-docker"
export PACKAGE_INSTALLED="$LOG_DIR/finished"

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/apt_install.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/apt_install.log
fi


if [ ! -f "$PACKAGE_INSTALLED" ];then

	apt update

	JAVA=$(which java)

	echo "TRYING TO INSTALL JAVA" | tee -a $LOG_DIR/apt_install.log

	if [ -z $JAVA ];then
		apt install -y openjdk-17-jdk-headless
		echo "JAVA INSTALLED" | tee -a $LOG_DIR/apt_install.log
	else
		echo "JAVA WAS ALREADY INSTALLED" | tee -a $LOG_DIR/apt_install.log
	fi

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

	echo "INSTALLING OPENSSHPASS" | tee -a $LOG_DIR/apt_install.log
	apt install -y sshpass
	echo "OPENSSHPASS INSTALLED" | tee -a $LOG_DIR/apt_install.log

	echo "INSTALLING VIM" | tee -a $LOG_DIR/apt_install.log
	apt install -y vim
	echo "VIM INSTALLED" | tee -a $LOG_DIR/apt_install.log

	echo "INSTALLING CRON" | tee -a $LOG_DIR/apt_install.log
	apt install -y cron
	echo "CRON INSTALLED" | tee -a $LOG_DIR/apt_install.log

	MYSQL_CLIENT=$(which mysql)

	if [ -z $MYSQL_CLIENT ];then
		
		echo "Installing MySQL Community Client with official 2025 method..." | tee -a $LOG_DIR/apt_install.log

		# Step 1: Install prerequisites
		apt update
		apt install -y wget gnupg lsb-release ca-certificates

		# Step 2: Download OFFICIAL MySQL APT config package (includes new key)
		wget https://dev.mysql.com/get/mysql-apt-config_0.8.32-1_all.deb

		# Step 3: Install the config package (adds repo + new GPG key automatically)
		dpkg -i mysql-apt-config_0.8.32-1_all.deb

		# Step 4: Clean up
		rm mysql-apt-config_0.8.32-1_all.deb

		# Step 5: Update and install client
		apt update
		apt install -y mysql-community-client

		# Step 6: Verify
		if which mysql >/dev/null 2>&1; then
			echo "MySQL Client installed: $(mysql --version)" | tee -a $LOG_DIR/apt_install.log
		else
			echo "ERROR: MySQL installation failed" | tee -a $LOG_DIR/apt_install.log
			exit 1
		fi

		# Clean apt cache
		apt clean
	
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
else
	echo "PACKEGE ALREADY INSTALLED" | tee -a $LOG_DIR/apk_install.log
fi
