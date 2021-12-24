# Set EIP environment.
HOME_DIR="/home/eip"
SCRIPTS_DIR="$HOME_DIR/scripts"

if [ -d "$LOG_DIR" ]; then
       echo "THE LOG DIR EXISTS" | tee -a $LOG_DIR/upgrade.log
else
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/upgrade.log
fi

cd $SCRIPTS_DIR

# Start application.
echo -n "INITIALIZING UPDATE CHECK"

./updates.sh >> $LOG_DIR/upgrade.log 2>&1 &
~
~
~
~
~
~

