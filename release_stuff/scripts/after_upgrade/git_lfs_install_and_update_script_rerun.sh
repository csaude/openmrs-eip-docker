#!/bin/sh
# Installing git-lfs and pulling for the first time
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"
RELEASE_BASE_DIR="$HOME_DIR/openmrs-eip-docker"
LOG_DIR="$HOME_DIR/shared/logs/upgrade"

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/upgrade.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/upgrade.log
fi

APK_CMD=$(which apk)

if [ ! -z $APK_CMD ] then
    echo "TRYING TO INSTALL GIT LFS USING APK" | tee -a $LOG_DIR/upgrade.log
    apk add git-lfs
else
    echo "TRYING TO INSTALL GIT LFS USING APT" | tee -a $LOG_DIR/upgrade.log
    apt install -y git-lfs
fi
echo "GIT LFS INSTALLED" | tee -a $LOG_DIR/upgrade.log

echo "CHANGING RELEASE INFO TO FORCE UPDATE" | tee -a $LOG_DIR/upgrade.log

cat > $SCRIPTS_DIR/release_info.sh << EOF
#!/bin/sh
# EIP RELEASES INFO
#
export RELEASE_NAME="EIP release GIT LFS"
export RELEASE_DATE="1900-01-01 00:00:00"
export RELEASE_DESC="Dummy version to force update after GIT LFS installation"
EOF

echo "INVOKING UPDATE SCRIPT IN BACKGROUND" | tee -a $LOG_DIR/upgrade.log
$SCRIPTS_DIR/updates.sh &
