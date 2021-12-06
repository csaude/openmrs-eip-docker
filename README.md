# openmrs-eip-docker
This project hold the necessary stuffs for eip application

# Setup
You need to setup the bellow env variables in [docker-compose file](docker-compose.yml):

        environment:
            - db_sync_senderId=SENDER_ID[Found the IDs here](https://docs.google.com/spreadsheets/d/1RjOwLWiE_0KGI34tZE-YmIHsf9lY_Lj9/edit?usp=sharing&ouid=117402189670664436672&rtpof=true&sd=true)
            - server_port=The port for EIP console(Use 8081 if avaliable)
            - openmrs_db_host=OPENMRS_DB_HOST
            - openmrs_db_port=OPENMRS_DB_PORT
            - openmrs_db_name=OPENMRS_DB_NAME
            - spring_openmrs_datasource_password=OPENMRS_DB_USER
            - spring_artemis_host=ACTIVE_MQ_ARTEMIS
            - spring_artemis_port=ACTIVE_MQ_PORT
            
# Notes
To avoid dsn issue running automated update process create a daemon.json file in location /var/lib/docker and put bellow code

{
  
        "dns": ["8.8.8.8"]
  
}

Depending on your docker environment this file could be in /etc/docker/daemon.json
