FROM openjdk:8-alpine
#FROM ubuntu:latest
#FROM xqdocker/ubuntu-openjdk:8
#RUN apt-get update && apt-get -y install cron

ADD localtime /etc/localtime

WORKDIR /home/eip/

RUN echo '*/1 * * * * /home/eip/scripts/updates.sh >> /home/eip/updates.log 2>&1' >> /var/spool/cron/crontabs/root
#ADD scripts/updates.sh /etc/periodic/15min 

#RUN chmod 644 /etc/periodic/15min/updates.sh

EXPOSE $server_port

ENTRYPOINT ["sh","scripts/eip_tmp.sh"]
