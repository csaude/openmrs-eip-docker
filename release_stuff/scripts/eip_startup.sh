#!/bin/sh
# Startup script for EIP Sender Application
#
# chkconfig: - 85 15
# description: EIP Sender Application
# processname: eip_sender
# pidfile:
# config:

# Set EIP environment.
export EIP_HOME=/home/eip
export EIP_MODE=sender
export HOME_DIR=/home/eip
export SCRIPTS_DIR=$HOME_DIR/scripts

cd $EIP_HOME

# Start application.
echo "Preparing to start Eip Application: [$EIP_MODE]"


if grep -q docker /proc/1/cgroup; then 
   echo "ENV ALREADY SET"
else
   echo "SETTING ENV"
   export $(cat $HOME_DIR/eip.env | xargs)
fi

echo "GENERATING ARTEMIS CERTIFICATE... URL: $spring_artemis_host:$spring_artemis_port"

echo "Q" | openssl s_client -connect $spring_artemis_host:$spring_artemis_port | openssl x509 > artemis.cert
echo "ARTEMIS CERTIFICATE GENERATED"

./scripts/setenv.sh
./scripts/install_certificate_to_jdk_carcets.exp "artemis.cert"

sleep 15 
echo "Starting Eip Application: [$EIP_MODE]"

if grep -q docker /proc/1/cgroup; then
        java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar
else
        nohup java -jar -Dspring.profiles.active=$EIP_MODE openmrs-eip-app-sender.jar 2>&1 &
	echo -n "APPLICATION STARTED IN BACKGROUND: [$EIP_MODE]"
fi
