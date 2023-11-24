# Introduction
This project hold the necessary stuffs for eip application installation using a docker container. The eip application run in a container called openmrs-eip-sender. The container has the ability to pickup updates for eip application. The new releases (routes, jar, scripts, etc) must be put in [release_stuff](./release_stuff) directory. The release update mechanism check the information in [release_info.sh](./release_stuff/scripts/release_info.sh) script. So, every time there is a new release the information in this script must be updated so that the remote computer can see the new releases. The eip container share the VOLUME with the host matchine in folder ./shared. This folder hold important things such as logs, debezium offset file, backups, etc. The container is shipped with backup mecanism which performe backups of eip mgt database and debezium offset files. The backup are persisted in shared folder under ./shared/bkps.

If you wish to send some maintenance commands to the remote sites, you can always ship the new releases with scripts included in [after_ugrade](release_stuff/scripts/after_upgrade/) folder. These scripts will be picked-up after the apgrade and run in the container. Scripts in this directory will be run once within the container.  

# Installation 
## Prerequisites
To have the eip application run, the mysql bin-logs must be active in the remote openmrs database.

If you are using openmrs instance based on [this docker project](https://github.com/FriendsInGlobalHealth/openmrs-docker-2x) follow the steps bellow:

Stop the openmrs instance containers using the command

```
docker-compose -f /opt/openmrs/appdata/openmrs-docker-2x/docker-compose.yml stop
```

Edit the file "/opt/openmrs/appdata/openmrs-docker-2x/mysql/mysql.cnf" adding 3 lines bellow under [mysqld] group: 

``` 
vi /opt/openmrs/appdata/openmrs-docker-2x/mysql/mysql.cnf
```

```
log-bin=mysql-bin.log
binlog_format=row
server-id=1000
```     

Rebuild the conteiners using the command
```
docker-compose -f /opt/openmrs/appdata/openmrs-docker-2x/docker-compose.yml up --build -d
```

After this, the 3 lines added  in step 3 must apear in “~/.my.cnf” file inside dabase container. Run the bellow command to check
``` 
docker exec -it refapp-db -c "cat ~/.my.cnf"
```
                
After rebuilding the containers you should check if the bin-logs is up running the instrunction bellow in mysql database
```
docker exec -i refapp-db mysql -u DB_USER_NAME -pDB_USER_PASSWORD -e "show variables like '%log_bin%'";
```

The result should be as shown in the image

![bin_log](etc/bin-logs.png)


## Setup
<a name="setup"></a>

Create a eip user

```
sudo useradd -m -d /home/eip -s /bin/bash -G sudo,docker eip
```

Define a password for eip user

```
sudo passwd eip
```

Now login as eip user

```
su - eip
```

<br/>

<i>(For offline installation, [see here](#offline-installation))</i>

<br/>

Init a git repository in /home/eip directory

```
git init && git checkout -b main
```

Associate the project to related docker project in github

```
git remote add origin https://github.com/csaude/openmrs-eip-docker.git
```


Pull the remote project into local directory

```
git pull --depth=1 origin main
```


#### Copy the [./eip.template.env](eip.template.env) file to ./eip.env using the command

```
cp eip.template.env eip.env
```

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
artemis_ssl_enabled=true
```

The SENDER_ID codes will be provided by the central team.
        
# Running the project
<a name="running"></a>

To run the project for the first time hit the bellow command inside of the eip user home directory (/home/eip)
        
```
docker-compose up -d
```

        
Follow the container logs using

```
docker logs --follow openmrs-eip-sender
```

And the eip logs using

```
docker exec -it openmrs-eip-sender tail -f /home/eip/shared/logs/eip/openmrs-eip.log
```
        
# Notes
If you notice some issue installing the application create a daemon.json file in location /var/lib/docker and put bellow code

```
{
  
        "dns": ["8.8.8.8"]
  
}
```

Depending on your docker environment this file could be in /etc/docker/daemon.json

# Offline installation
For this procedure you need to have the eip_home.tar.gz file, which can be found in the [releases page](https://github.com/csaude/openmrs-eip-docker/releases).

Copy the eip_home.tar.gz file to /home/eip
                
Change working directory to /home/eip
```
cd /home/eip
```
Extract

```
tar -xf eip_home.tar.gz
```
Import local images to docker
```
docker import docker_images/openmrs-eip-sender.tar openmrs-eip-sender:latest
```

Continue with the setup process [from here](#copy-the-eiptemplateenv-file-to-eipenv-using-the-command)

# Appendix A: Procedure for creating assets and publish a new release

## Prepare offline installation archive
First, proceed with a [fresh online installation](#installation) of the desired release, then create [EIP Sender](#running-the-project) container.

Change working directory to <b>/home/eip</b>

```
cd /home/eip
```

Create the EIP Sender container

```
docker-compose up -d
```

Stop the EIP Sender container

```
docker-compose stop
```

Clean local EIP Home

```
sudo rm -rf shared/.debezium
```

Create dir for docker images

```
mkdir docker_images
```

Export container

```
docker export $(docker ps -aqf "name=openmrs-eip-sender") > docker_images/openmrs-eip-sender.tar
```

Change base image from docker compose yml files

```
sed -i 's/openjdk:8-alpine/openmrs-eip-sender:latest/g' docker-compose.yml
```

Create archive with EIP Home content

```
tar -czf eip_home.tar.gz --exclude='eip.env' --exclude='snap' *
```

The file <b>eip_home.tar.gz</b> can now be uploaded as a release asset.

## Publish the release
#### First create releases for each of the <i>related repositories</i> (where applicable, or use existing ones), ie., [OpenMRS EIP](https://github.com/FriendsInGlobalHealth/openmrs-eip/) and [EPTS Sync](https://github.com/FriendsInGlobalHealth/openmrs-module-eptssync):

Build the appropriate <b>jar file</b>

Generate the hash file, replacing <code>[jar_file_name]</code> with the respective name:
                
```
sha256sum [jar_file_name] > [jar_file_name].SHA256
```

Create the release and attach the <b>jar</b> and <b>hash file</b> as Release Assets.

#### Then create a release <i>in this repository</i>:
1. Change the file [release_info.sh](release_stuff/scripts/release_info.sh), setting the <code>RELEASE_NAME</code>, <code>RELEASE_DATE</code> and <code>RELEASE_DESC</code> values.

2. If this release also ships a new release of the related repositories ([OpenMRS EIP](https://github.com/FriendsInGlobalHealth/openmrs-eip/) / [EPTS Sync](https://github.com/FriendsInGlobalHealth/openmrs-module-eptssync)), change the urls in <code>OPENMRS_EIP_APP_RELEASE_URL</code> and/or <code>EPTSSYNC_API_RELEASE_URL</code>.

3. Create the release and attach as Asset the offline installation archive created with [this procedure](#prepare-offline-installation-archive).

# Appendix B: Procedure for recovering Dbsync State After OpenMRS reinstallation

## Recovery with a backup of dbsync management database
If for any reason the OpenMRS server in a remote site need to be re-installed, a part from create a backup of OpenMRS database there is a need to backup the dbsync management database (mgt-db). The dbsync mgt-db resides in the same mysql server where the openmrs database is located. The name of mgt-db will be like *openmrs_eip_sender_mgt_SITE_ID*, where *SITE_ID* is the value of property *db_sync_senderId* in the configuration file. Before you re-install the dbsync you must restore the mgt-db and then proceed with a [fresh installation](#installation) of dbsync.

## Recovery without dbsync management database
If for some reason the dbsync management database (mgt-db) is lost. You will have to perform a [fresh installation](#installation) without a starting mgt-db. And after the installation you must run the re-sync process using the estimated last sync date; this date will be provided by the central team.
The re-sync processes will be run using the command bellow
```
docker exec -i openmrs-eip-sender /home/eip/etc/eptssync/scripts/eptssync_re_sync.sh 'LAST_KNOWN_SYNC_DATE'
```

Note that the date must be in format 'YYYY-MM-DD'.
