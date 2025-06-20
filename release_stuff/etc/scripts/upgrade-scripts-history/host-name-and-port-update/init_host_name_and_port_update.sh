#!/bin/sh
# This scripts execute a given script on a given db
#

HOME_DIR="/home/eip/shared/dbsync"
UPDATES_DIR="$HOME_DIR/updates"
SITE_CODE_INPUT=$1
ARTEMIS_PORT_INPUT=$2
UPDATE_SCRIPT="update_client_hostname_and_notify.sh"
UPDATE_SCRIPT_TMP="update_client_hostname_and_notify_01.sh"
SITE_ID="${SITE_CODE_INPUT}:${ARTEMIS_PORT_INPUT}"
SITES_CODE_FILE="./sites_codes"


if [ -f "$SITES_CODE_FILE" ]; then
       rm $SITES_CODE_FILE
fi

echo "mc:40401" >  $SITES_CODE_FILE
echo "mp:40402" >> $SITES_CODE_FILE
echo "gz:40403" >> $SITES_CODE_FILE
echo "ib:40404" >> $SITES_CODE_FILE
echo "sf:40405" >> $SITES_CODE_FILE
echo "mn:40406" >> $SITES_CODE_FILE
echo "tt:40407" >> $SITES_CODE_FILE
echo "zb:40408" >> $SITES_CODE_FILE
echo "np:40409" >> $SITES_CODE_FILE
echo "ca:40410" >> $SITES_CODE_FILE
echo "ns:40411" >> $SITES_CODE_FILE


# VALIDATE SITE
#====================================================================================================================================================================================
. $HOME_DIR/commons.sh

checkIfTokenExistsInFile $SITES_CODE_FILE $SITE_ID
exists=$?

if [ "$exists" = 1 ]; then
	cp $UPDATE_SCRIPT $UPDATE_SCRIPT_TMP

	sed -i "s/SITE_CODE_INPUT/$SITE_CODE_INPUT/g" "$UPDATE_SCRIPT_TMP"
	sed -i "s/ARTEMIS_PORT_INPUT/$ARTEMIS_PORT_INPUT/g" "$UPDATE_SCRIPT_TMP"
	
	mv $UPDATE_SCRIPT_TMP $UPDATES_DIR
	
	echo "Update file $UPDATE_SCRIPT copied to update dir $UPDATES_DIR"
else
	echo "Invalid SITE_CODE_INPUT or ARTEMIS_PORT_INPUT"	
fi

rm $SITES_CODE_FILE
#====================================================================================================================================================================================

