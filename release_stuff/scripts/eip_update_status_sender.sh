#!/bin/bash


export UPDATE_INFO_FILE="/home/eip/updates.log"
export REPORT_DATE=`date +%Y-%m-%d_%H-%M-%S`
export REPORT_PRINTED_DATE=`date +%d-%m-%Y`
export REPORT_PRINTED_TIME=`date +%H-%M-%S`
echo "Sending update status to email..."
printf "Caros\n\nJunto enviamos o report da ultima tentativa de actualizacaoSegue o ponto de situação do estado de envio de dados da sincronização dos sites remotos no dia $REPORT_PRINTED_DATE as $REPORT_PRINTED_TIME.\n\nNOTA: O ficheiro é melhor visualizado no excell ou aplicativo similar.\n\n\n--------------------\nEnviado automaticamente a partir do servidor central." > sync_status_report_message_body.txt

mpack -s "Sincronizacao - Ponto de Situacao de Envio de Dados" -d sync_status_report_message_body.txt $REPORT_NAME jorge.boane@fgh.org.mz 
mpack -s "Sincronizacao - Ponto de Situacao de Envio de Dados" -d sync_status_report_message_body.txt $REPORT_NAME jose.chambule@fgh.org.mz
#mpack -s "Sincronizacao - Ponto de Situacao de Envio de Dados" -d sync_status_report_message_body.txt $REPORT_NAME eurico.jose@fgh.org.mz 


rm $REPORT_NAME
rm sync_status_report_message_body.txt 
echo "Done!"


