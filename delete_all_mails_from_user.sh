#!/bin/bash
##### THIS FILE MUST BE RUN AS ZIMBRA USER / ESTE ARCHIVO SOLO DEBE SER EJECUTADO COMO USUARIO ZIMBRA #########
DOMAIN="@instec.cu" #Put your domain here / Ponga su dominio aquí
LOGS="/var/log" #Put yout zimbra logs path here / Ponga su ruta de registros de zimbra aquí


function isUser(){

if zmprov ga $1 > /dev/null 2>&1; then
eliminar $1 $2
else
if zmprov gdl $1 \G | grep -ho "..*$DOMAIN" | grep -v $1 > /dev/null 2>&1; then

echo "Identified mailing list looking at $1 members / Identificada lista de correo buscando en los integrantes de $1"
users=$(zmprov gdl $1 \G | grep -ho "..*$DOMAIN" | grep -v $1)

for user in $users; do
isUser $user $2

done
else
echo "User $1 not found it is likely that the sender has sent an email to an account that does not exist / Usuario $1 no encontrado es probable que el remitente haya enviado un correo a una cuenta que no existe"

fi
fi
}


function eliminar () {
ZM="$(zmmailbox -z -m $1 search $2)"
JUNK=`zmmailbox -z -m $1 search "in:Junk $2"`
TRASH=`zmmailbox -z -m $1 search "in:Trash $2"`
RETURN=`zmmailbox -z -m $1 search "#Return-Path: <$2>"`
ZM="$ZM $JUNK $TRASH $RETURN"


message=`echo "$ZM" | awk '$1 ~ /[0-9]/ { print $2 }' | grep - | sed 's/-//g' `
conversations=`echo "$ZM" | awk '$1 ~ /[0-9]/ { print $2 }' | grep -v -`

 for messageid in $message; do
   echo "Deleting the message number $messageid of user $1 sent by $2 / Borrando el mensaje numero $messageid del usuario $1 enviado por $2"
   zmmailbox -z -m $1 dm $messageid

  done

 for conversid in $conversations; do

    echo "Deleting conversation number $conversid of user $1 sent for $2 / Borrando la conversación número $conversid del usuario $1 enviado por $2"
    zmmailbox -z -m $1 dc $conversid

  done


}





echo -e  "Please enter the sender of the emails to be blocked separated with commas without spaces / Por favor introduzca el remitente de los correos a bloquear separado con comas sin espacios "
read list
sep=$(echo "$list" | sed 's/,/\n/g')
for sender in $sep; do
OUT=`zgrep -ho "<$sender> -> <..*>\|from=<$sender> to=<..*>"  $LOGS/zimbra* | grep -ho " ..*<..*> " | grep -ho "<..*> "`
if [ -z "$OUT" ]; then
echo "Sender $sender not found in $LOGS / No encontrado en los logs ubicados en $LOGS el remitente $sender"
else
sinespacios=$(echo "$OUT" | sed 's/,/\n/g' | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | sed 's/<//g' | sed 's/>//g'  | tr ' ' '\n' | sort | uniq)
echo "The sender $sender has been identified as having sent emails to these users or mailing lists / Se han identificado que el remitente $sender le ha enviado correos a estos usuarios/listas de correos "
echo "$sinespacios"
for mailbox in $sinespacios; do
isUser $mailbox $sender
done

fi

done