#!/bin/sh
# This scripts execute a given script on a given db
#
HOME_DIR="/home/eip"
GIT_BRANCHES_DIR="$HOME_DIR/git/branches"
UPDATE_NAME="update-host-name-on-setup"
SCRIPTS_DIR="$HOME_DIR/scripts"
UPDATES_DIR="$HOME_DIR/shared/updates"
LOG_DIR="$HOME_DIR/logs/updates"
LOG_FILE="$LOG_DIR/$UPDATE_NAME.log"
DB_HOST="172.17.0.1"
DB_HOST_PORT="$openmrs_db_port"
DB_USER="root"
DB_PASSWD="$spring_openmrs_datasource_password"
DB_NAME="$openmrs_db_name"
HOST_NAME_UPDATE_QUERY="$HOME_DIR/${UPDATE_NAME}.sql"
QUERT_SCRIPT_RESULT="$UPDATES_DIR/${UPDATE_NAME}.result"


# LOAD GLOBAL ENV
#====================================================================================================================================================================================
. $SCRIPTS_DIR/commons.sh
. $SCRIPTS_DIR/try_to_load_environment.sh
. $SCRIPTS_DIR/setenv.sh
#====================================================================================================================================================================================

if [ -d "$UPDATES_DIR" ];then
	echo "The updates dir exists"
else
	echo "The updates dir does not exist. Creating it..."
	
	mkdir -p $UPDATES_DIR
fi

#DEFINE NECESSARY VARIABLES
#====================================================================================================================================================================================
timestamp=$(getCurrDateTime)
branch_name=$(getGitBranch $GIT_BRANCHES_DIR)

#setenv file path
SETENV_FILE="$SCRIPTS_DIR/${branch_name}_setenv.sh"
. $SETENV_FILE
#====================================================================================================================================================================================


# DETERMINE SITE CODE
#====================================================================================================================================================================================
logToScreenAndFile "Determining SITE_CODE and Host Name FOR SITE $db_sync_senderId USING setenv file $SETENV_FILE and artemis port $spring_artemis_port" "$LOG_FILE"

SITE_CODE="undefined"

case "$spring_artemis_port" in
	"40401") 
		SITE_CODE="mc"
		;;
	"40402") 
		SITE_CODE="mp"
		;;
	"40403") 
		SITE_CODE="gz"
		;;
	"40404") 
		SITE_CODE="ib"
		;;
	"40405") 
		SITE_CODE="sf"
		;;
	"40406") 
		SITE_CODE="mn"
		;;
	"40407") 
		SITE_CODE="tt"
		;;
	"40408") 
		SITE_CODE="zb"
		;;
	"40409") 
		SITE_CODE="np"
		;;
	"40410") 
		SITE_CODE="ca"
		;;
	"40411") 
		SITE_CODE="ns"
		;;
esac


HOST_NAME="${SITE_CODE}.csaude.org.mz"
MPI_HOST_NAME="mpi-${HOST_NAME}"
SESP_HOST_NAME="sesp-${HOST_NAME}"

logToScreenAndFile "HOST NAMES DETERMINED: SESP: $SESP_HOST_NAME, MPI: $MPI_HOST_NAME" "$LOG_FILE"


# PERFORME GLOBAL_PROPERTIE TABLE UPDATE
#====================================================================================================================================================================================

logToScreenAndFile "STARTING GLOBAL_PROPERTIE TABLE UPDATE... USING DB_HOST $DB_HOST" "$LOG_FILE"
logToScreenAndFile "Trying to Update hostname at $timestamp" "$LOG_FILE"
logToScreenAndFile "Executing update script" "$QUERT_SCRIPT_RESULT"

# query for 'esaudefeatures.fhir.remote.server.url' update
echo "UPDATE global_property SET property_value='https://${MPI_HOST_NAME}' WHERE property='esaudefeatures.fhir.remote.server.url';" > "$HOST_NAME_UPDATE_QUERY"

# query for 'esaudefeatures.openmrs.remote.server.url' update
echo "UPDATE global_property SET property_value='https://${SESP_HOST_NAME}/openmrs' WHERE property='esaudefeatures.openmrs.remote.server.url';" >> "$HOST_NAME_UPDATE_QUERY"

$SCRIPTS_DIR/execute_script_on_db.sh $DB_HOST $DB_HOST_PORT $DB_USER $DB_PASSWD $DB_NAME $HOST_NAME_UPDATE_QUERY $QUERT_SCRIPT_RESULT

cat $HOST_NAME_UPDATE_QUERY

# SEND NOTIFICATION
#====================================================================================================================================================================================
MAIL_CONTENT_FILE="$UPDATES_DIR/${UPDATE_NAME}-mail-content.tmp"
MAIL_ATTACHMENT="$UPDATES_DIR/${UPDATE_NAME}-mail-attachment"
MAIL_RECIPIENTS="$administrators_emails"
MAIL_SUBJECT="EIP REMOTO - ESTADO DE ACTUALIZACAO [HOST-NAME-UPDATE-ON-SETUP]"

echo "Caros" >> $MAIL_CONTENT_FILE
echo "Servimo-nos deste para informar que a actualizacao ${UPDATE_NAME} no site $db_sync_senderId foi efetuado com sucess." >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "" >> $MAIL_CONTENT_FILE
echo "Enviado automaticamente a partir do servidor $db_sync_senderId." >> $MAIL_CONTENT_FILE

echo "No content" > $MAIL_ATTACHMENT

$SCRIPTS_DIR/generate_notification_content.sh "$MAIL_RECIPIENTS" "$MAIL_SUBJECT" "$MAIL_CONTENT_FILE" "$MAIL_ATTACHMENT"
