#!/usr/bin/expect -f

set timeout -1

set HOST_DIR "/home/eip/prg/docker/eip-docker-testing"
set HOME_DIR "/home/eip"
set SHARED_DIR "$HOME_DIR/shared"
set LOG_DIR "$SHARED_DIR/logs"
set AFTER_UPGRADE_LOG_DIR "$LOG_DIR/upgrade"
set AFTER_UPGRADE_SCRIPTS_HOME "$HOME_DIR/scripts/after_upgrade"
set BEFORE_RESET_FILE "$AFTER_UPGRADE_SCRIPTS_HOME/before_reset_container.sh"
set RESET_DOCKER_CONTAINER_FILE "$AFTER_UPGRADE_SCRIPTS_HOME/reset_docker_container.sh"

spawn scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $SHARED_DIR eip@localhost:$HOST_DIR/
expect "eip@localhost's password:"
send -- "#eIP123#\n"

spawn ssh -o StrictHostKeyChecking=no eip@localhost "git -C $HOST_DIR reset --hard; git -C $HOST_DIR pull origin main; docker-compose -f $HOST_DIR/docker-compose.yml up --force-recreate -d"
#spawn ssh -o StrictHostKeyChecking=no eip@localhost "git -C /home/eip/prg/docker/eip-docker-testing reset --hard; git -C /home/eip/prg/docker/eip-docker-testing pull origin main; docker-compose -f /home/eip/prg/docker/eip-docker-testing/docker-compose.yml up --force-recreate -d"
expect "eip@localhost's password:"
send -- "#eIP123#\n"

expect eof
