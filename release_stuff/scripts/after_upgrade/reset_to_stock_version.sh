#!/usr/bin/expect -f

set timeout -1

HOME_DIR=/home/eip
LOG_DIR=$HOME_DIR/shared/logs
OLD_EIP_LOG_DIR=$HOME_DIR/logs


if [ ! -d "$LOG_DIR" ]; then
       mkdir -p $LOG_DIR
       echo "THE LOG DIR WAS CREATED" | tee -a $LOG_DIR/reset_to_stock.log
fi


mv $OLD_EIP_LOG_DIR/* $LOG_DIR/eip/ 


spawn scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r /home/eip/tmp_scripts eip@localhost:/home/eip/prg/docker/openmrs-eip-docker/
expect "eip@localhost's password:"
send -- "#eIP123#\n"

spawn scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r /home/eip/.debezium_ eip@localhost:/home/eip/prg/docker/openmrs-eip-docker/bkps
expect "eip@localhost's password:"
send -- "#eIP123#\n"

spawn scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r /home/eip/shared eip@localhost:/home/eip/prg/docker/openmrs-eip-docker/bkps
expect "eip@localhost's password:"
send -- "#eIP123#\n"

spawn ssh -o StrictHostKeyChecking=no eip@localhost "git -C /home/eip/prg/docker/openmrs-eip-docker/bkps reset --hard; git -C /home/eip/prg/docker/openmrs-eip-docker/bkps pull origin main; docker-compose -f /home/eip/prg/docker/openmrs-eip-docker/docker-compose.yml up --force-recreate -d"
expect "eip@localhost's password:"
send -- "#eIP123#\n"
expect eof
