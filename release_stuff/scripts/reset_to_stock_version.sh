#!/usr/bin/expect -f

set timeout -1
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
