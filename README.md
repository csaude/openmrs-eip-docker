# Introduction
This project hold the necessary stuffs for eip application installation using a docker container. The eip application run in a container called openmrs-eip-sender. The container has the ability to pickup updates for eip application. The new releases (routes, jar, scripts, etc) must be put in [release_stuff](./release_stuff) directory. The release update mechanism check the information in [release_info.sh](./release_stuff/scripts/release_info.sh) script. So, every time there is a new release the information in this script must be updated so that the remote computer can see the new releases. The eip container share the VOLUME with the host matchine in folder ./shared. This folder hold important things such as logs, debezium offset file, backups, etc. The container is shipped with backup mecanism which performe backups of eip mgt database and debezium offset files. The backup are persisted in shared folder under ./shared/bkps.

If you wish to send some maintenance commands to the remote sites, you can always ship the new releases with scripts included in [after_ugrade](release_stuff/scripts/after_upgrade/) folder. These scripts will be picked-up after the apgrade and run in the container. Scripts in this directory will be run once within the container.  

# Installation 
## Prerequisites
Note: before you go for upgrade and eip installation you may want to run the inconsistences check agaist the openmrs db. Please refere to [Running inconsistence check session](#inconsistence_check). 


To have the eip application run, the mysql bin-logs must be active in the remote openmrs database.

If you are using openmrs instance based on [this docker project](https://github.com/FriendsInGlobalHealth/openmrs-docker-2x) follow the steps bellow:
<ol>
        <li>
                Stop the openmrs instance containers using the command
                <ul>
                        <code>docker-compose -f /opt/openmrs/appdata/openmrs-docker-2x/docker-compose.yml stop</code>
                </ul>
        </li>
        <li>
                Edit the file "/opt/openmrs/appdata/openmrs-docker-2x/mysql/mysql.cnf" adding 3 lines bellow under [mysqld] group: 
<pre>vi /opt/openmrs/appdata/openmrs-docker-2x/mysql/mysql.cnf</pre>
<pre>
log-bin=mysql-bin.log
binlog_format=row
server-id=1000
</pre>
        </li>
        <li>
                Rebuild the conteiners using the command
                <ul>
                <code>docker-compose -f /opt/openmrs/appdata/openmrs-docker-2x/docker-compose.yml up --build -d</code>
                </ul>
        </li>
        <li>
                After this, the 3 lines added  in step 3 must apear in “~/.my.cnf” file inside dabase container. Run the bellow command to check
                <ul>
                        <code>docker exec -it refapp-db -c "cat ~/.my.cnf"</code>        
                </ul>
        </li>
        <li>
                After rebuilding the containers you should check if the bin-logs is up running the instrunction bellow in mysql database
                <ul>
                        <code>show variables like '%log_bin%';</code>
                </ul>
        </li>
</ol> 
 The result should be as shown in the image
        
 ![bin_log](etc/bin-logs.png)


## Setup
<a name="setup"></a>

Create a eip user

<code>sudo useradd -m -d /home/eip -s /bin/bash -G sudo,docker eip</code>

Define a password for eip user

<code>sudo passwd eip</code>

Now login as eip user

<code>su - eip</code>

<br/>

<i>(For offline installation, [see here](#offline-installation))</i>

<br/>

Init a git repository in /home/eip directory

<code>git init && git checkout -b main</code>

Associate the project to related docker project in github

<code>git remote add origin https://github.com/FriendsInGlobalHealth/openmrs-eip-docker.git</code>

Pull the remote project into local directory

<code>git pull --depth=1 origin main</code>

#### Copy the [./eip.template.env](eip.template.env) file to ./eip.env using the command

<code>cp eip.template.env eip.env</code>

Edit the env in the file copied above putting the correct values for the env variables 

```
db_sync_senderId=SENDER_ID
server_port=SERVER_PORT
openmrs_db_host=OPENMRS_DB_HOST
openmrs_db_port=OPENMRS_DB_PORT
openmrs_db_name=OPENMRS_DB_NAME
spring_openmrs_datasource_password=OPENMRS_DB_USER
spring_artemis_user=ACTIVE_MQ_USER
spring_artemis_password=ACTIVE_MQ_PASSWORD
origin_app_location_code=ORIGIN_APP_LOCATION_CODE
spring_artemis_host=ACTIVE_MQ_HOST
spring_artemis_port=ACTIVE_MQ_PORT
```

The SENDER_ID codes can be found [here](https://docs.google.com/spreadsheets/d/1RjOwLWiE_0KGI34tZE-YmIHsf9lY_Lj9/edit?usp=sharing&ouid=117402189670664436672&rtpof=true&sd=true). Use <code>Server_Code</code> column.
        
# Running the project
<a name="running"></a>

To run the project for the first time hit the bellow command inside of the eip user home directory (/home/eip)
        
<code>docker-compose up -d</code>
        
Follow the container logs using

<code>docker logs --follow openmrs-eip-sender</code>

And the eip logs using

<code>docker exec -it openmrs-eip-sender tail -f /home/eip/shared/logs/eip/openmrs-eip.log</code>
        
# Notes
If you notice some issue installing the application create a daemon.json file in location /var/lib/docker and put bellow code

{
  
        "dns": ["8.8.8.8"]
  
}

Depending on your docker environment this file could be in /etc/docker/daemon.json

# Running inconsistence check

This docker project is packed with the inconsistency check module (epts-sync). The rountine to check the inconsistences run in separeted docker service which is defined in [docker-compose-inconsistence-check.yml](docker-compose-inconsistence-check.yml) file.

To run the inconsistence check, first follow the [setup](#setup) process.

Then hit the command:

<code>docker-compose -f docker-compose-inconsistence-check.yml up -d</code>

Follow the logs using the command bellow

<code>docker exec -it epts-inconsistence-check tail -f /home/eptssync/logs/log.txt</code>

# Offline installation
For this procedure you need to have the eip_home.tar.gz file, which can be found in the [releases page](https://github.com/FriendsInGlobalHealth/openmrs-eip-docker/releases).

<ol>
        <li>
                Copy the eip_home.tar.gz file to /home/eip
        </li>
        <li>
                Change working directory to /home/eip
                <ul>
                        <code>cd /home/eip</code>
                </ul>
        </li>
        <li>
                Extract
                <ul>
                        <code>tar -xf eip_home.tar.gz</code>
                </ul>
        </li>
        <li>
                Import local images to docker
                <ul>
                        <code>docker import docker_images/openmrs-eip-sender.tar openmrs-eip-sender:latest</code>
                </ul>
                <ul>
                        <code>docker import docker_images/epts-inconsistence-check.tar epts-inconsistence-check:latest</code>
                </ul>
        </li>
</ol>

Continue with the setup process [from here](#copy-the-eiptemplateenv-file-to-eipenv-using-the-command)

# Steps to prepare offline installation archive
First, proceed with a [fresh online installation](#installation) of the desired release, then create [EIP Sender](#running-the-project) and [Inconsistence check](#running-inconsistence-check) containers.

<ol>
        <li>
                Change working directory to <b>/home/eip</b>
                <ul>
                        <code>cd /home/eip</code>
                </ul>
        </li>
        <br/>
        <li>
                Start the EIP Sender container
                <ul>
                        <code>docker-compose up -d</code>
                </ul>
        </li>
        <br/>
        <li>
                Enter the EIP Sender container SH console
                <ul>
                        <code>docker exec -it openmrs-eip-sender sh</code>
                </ul>
                <br/>
                <ol>
                        <li>
                                Clean the project update temporary directory
                                <ul>
                                        <code>cd openmrs-eip-docker</code>
                                </ul>
                                <ul>
                                        <code>git clean -df</code>
                                </ul>
                                <ul>
                                        <code>rm -rf .bash_history .bash_logout .bashrc .cache .profile .sudo_as_admin_successful eip.env shared</code>
                                </ul>
                        </li>
                        <br/>
                        <li>
                                Exit the container
                                <ul>
                                        <code>exit</code>
                                </ul>
                        </li>
                </ol>
        </li>
        <br/>
        <li>
                Stop the EIP Sender container
                <ul>
                        <code>docker-compose stop</code>
                </ul>
        </li>
        <br/>
        <li>
                Clean local EIP Home
                <ul>
<pre>
sudo rm -rf logs release_stuff/etc/eptssync/conf/source_sync_config.tmp.json \
release_stuff/etc/eptssync/logs release_stuff/etc/eptssync/process_status \
release_stuff/etc/eptssync/*.jar shared/logs/eip/* shared/.debezium
</pre>
                </ul>
        </li>
        <li>
                Create dir for docker images
                <ul>
                        <code>mkdir docker_images</code>
                </ul>
        </li>
        <br/>
        <li>
                Export containers
                <ul>
                        <code>docker export $(docker ps -aqf "name=openmrs-eip-sender") > docker_images/openmrs-eip-sender.tar</code>
                </ul>
                <ul>
                        <code>docker export $(docker ps -aqf "name=epts-inconsistence-check") > docker_images/epts-inconsistence-check.tar</code>
                </ul>
        </li>
        <br/>
        <li>
                Change base image from docker compose yml files
                <ul>
                        <code>sed -i 's/openjdk:8-alpine/openmrs-eip-sender:latest/g' docker-compose.yml</code>
                </ul>
                <ul>
                        <code>sed -i 's/openjdk:8-alpine/epts-inconsistence-check:latest/g' docker-compose-inconsistence-check.yml</code>
                </ul>
        </li>
        <br/>
        <li>
                Create archive with EIP Home content
                <ul>
                        <code>tar -czf eip_home.tar.gz --exclude='eip.env' --exclude='snap' *</code>
                </ul>
        </li>
        <br/>
        <li>
                Upload <b>eip_home.tar.gz</b> to the proper release as Asset
        </li>
</ol>
