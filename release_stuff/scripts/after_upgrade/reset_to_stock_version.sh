#!/usr/bin/expect -f

set timeout -1

export HOST_DIR=/home/eip/prg/docker/eip-docker-testing
export HOME_DIR=/home/eip
export SHARED_DIR=$HOME_DIR/shared
export LOG_DIR=$SHARED_DIR/logs

if [ ! -d "$LOG_DIR/eip" ]; then
       mkdir -p $EIP_LOG_DIR
       echo "THE EIP LOG DIR WAS CREATED" | tee -a $LOG_DIR/reset_to_stock.log

fi

mv $HOME_DIR/logs* $LOG_DIR/eip/ 
mv $HOME_DIR/.debezium $SHARED_DIR/

spawn scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $SHARED_DIR eip@localhost:$HOST_DIR/
expect "eip@localhost's password:"
send -- "#eIP123#\n"


spawn ssh -o StrictHostKeyChecking=no eip@localhost "git -C /home/eip/prg/docker/eip-docker-testing reset --hard; git -C /home/eip/prg/docker/eip-docker-testing pull origin main; docker-compose -f /home/eip/prg/docker/eip-docker-testing/docker-compose.yml up --force-recreate -d"
#spawn ssh -o StrictHostKeyChecking=no eip@localhost "git -C /home/eip/prg/docker/openmrs-eip-docker/bkps reset --hard; git -C /home/eip/prg/docker/openmrs-eip-docker/bkps pull origin main; docker-compose -f /home/eip/prg/docker/openmrs-eip-docker/docker-compose.yml up --force-recreate -d"
expect "eip@localhost's password:"
send -- "#eIP123#\n"

expect eof
