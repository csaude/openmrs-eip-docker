#!/bin/sh
# Script to generate and install certificate
#
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
CRONS_DIR="$HOME_DIR/cron"
GENERATE_AND_INSTALL_CERTIFICATE_CRON="$CRONS_DIR/generate_and_install_certificate.sh"
GENERATE_AND_INSTALL_CERTIFICATE_LOG="$CRONS_DIR/generate_and_install_certificate.log"
PATH_TO_CERTIFICATE="$HOME_DIR/artemis.cert"

URL="$spring_artemis_host:$spring_artemis_port"
CERTIFICATE_ALIAS="artemis"

echo "Starting to generate and install Certificate"

if [ -z $JAVA_HOME ];then
    echo "JAVA_HOME is not defined! Configuring it"
    java_home=$(readlink -f $(which java))
    tmp="\/bin\/java"
    result=$(echo "$java_home" | sed "s/$tmp//g")
    export JAVA_HOME=$result
fi
echo "Using JAVA_HOME =$JAVA_HOME"

echo "Verifying if exists valid certificate with alias $CERTIFICATE_ALIAS"
ALIAS_EXISTS=$(keytool -list -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -alias "$CERTIFICATE_ALIAS" 2>/dev/null | grep -c "does not exist")

if [ ! "$ALIAS_EXISTS" -gt 0 ]; then
        echo "Certificate with alias $CERTIFICATE_ALIAS already exists in the keystore."

else
    
    echo "Certificate with alias $CERTIFICATE_ALIAS does not exist in the keystore. Generating new one."

    $SCRIPTS_DIR/generate_certificate.sh $URL $PATH_TO_CERTIFICATE

    if [ ! -s $PATH_TO_CERTIFICATE ]; then

        echo "The certificate cannot be generated now... scheduling..."
        echo "*/5       *       *       *       *       $SCRIPTS_DIR/generate_and_install_certificate.sh" > ${GENERATE_AND_INSTALL_CERTIFICATE_CRON}

        $SCRIPTS_DIR/install_crons.sh
        echo "Cron installed successfully" > ${GENERATE_AND_INSTALL_CERTIFICATE_LOG}

    else
    
        echo "Certificate generated successfully" > ${GENERATE_AND_INSTALL_CERTIFICATE_LOG}

        $SCRIPTS_DIR/install_certificate_to_jdk_carcets.sh $PATH_TO_CERTIFICATE "artemis"


        if [ -f "$GENERATE_AND_INSTALL_CERTIFICATE_CRON" ]; then

            echo "Removing old ceritificate installation cron" 
            rm $GENERATE_AND_INSTALL_CERTIFICATE_CRON
            $SCRIPTS_DIR/install_crons.sh
            echo "Cron Removed"

        fi
    fi

        
fi