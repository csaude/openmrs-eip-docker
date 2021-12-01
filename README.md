# openmrs-eip-docker
This project hold the necessary stuffs for eip application

# notes
To avoid dsn issue running automated update process create a daemon.json file in location /var/lib/docker and put bellow code
{
    "dns": ["8.8.8.8"]
}

Depending on your docker environment this file could be in /etc/docker/daemon.json
