#!/bin/bash
##### THIS FILE MUST BE RUN AS ZIMBRA USER / ESTE ARCHIVO SOLO DEBE SER EJECUTADO COMO USUARIO ZIMBRA #########
LOGS="/var/log" #Put yout zimbra logs path here / Ponga su ruta de registros de zimbra aquí


Help() {
  # Display Help
  echo "Syntax: scriptTemplate [-g|h|v|V]"
  echo "options:"
  echo "u     User to eliminate."
  echo "l    Log Path."
  echo
}

function isUser() {

  #Verify if is a distribution list of is it and user or not exist
  if grep -q $1 /tmp/lista; then

    echo "Identified mailing list searching the members of $1"

    #Obtain the domain of the list
    DOMAIN=$(echo ${1##*@})

    #get all users of the distribution list
    users=$(zmprov gdl $1 \G | grep -ho "..*@$DOMAIN" | grep -v $1)

    for user in $users; do

      #For every member check if the process has been already done else execute recursively
      if grep -q $user "/tmp/$2"; then
        echo "The user/distribution list $user is not verified because it has already been done"
      else
        isUser $user $2

      fi
    done
    #Put user in temp and evit duplicated
    echo $1 >>"/tmp/$2"

  else
    if grep -q $1 /tmp/users; then
      #If exist scan account and delete
      echo "Scanning account $1 "
      eliminar $1 $2 $3
    else
      echo "$1 account does not exist "
    fi
  fi
}

function eliminar() {
  #Search sender in the input tray
  ZM="$(zmmailbox -z -m $1 search $2)"

  #Search sender in the junk
  JUNK=$(zmmailbox -z -m $1 search "in:Junk $2")

  #Search sender in the trash
  TRASH=$(zmmailbox -z -m $1 search "in:Trash $2")

  #For Special Attack
  RETURN=$(zmmailbox -z -m $1 search "#Return-Path: <$2>")

  #Concatena all
  ZM="$ZM $JUNK $TRASH $RETURN"

  #Separate the messages id
  message=$(echo "$ZM" | awk '$1 ~ /[0-9]/ { print $2 }' | grep - | sed 's/-//g' | xargs -n1 | sort -u | xargs)

  #Separate the conversations id
  conversations=$(echo "$ZM" | awk '$1 ~ /[0-9]/ { print $2 }' | grep -v - | xargs -n1 | sort -u | xargs)

  #Delete all message by id from mailbox
  for messageid in $message; do
    echo "Deleting message number $messageid from user $1 sent by $2 "
    zmmailbox -z -m "$1" dm "$messageid"

  done

  #Delete all conversation by id from mailbox
  for conversid in $conversations; do

    echo "Deleting conversation number $conversid of user $1 sent by $2"
    zmmailbox -z -m "$1" dc "$conversid"

  done

  #Put user in temp and evit duplicated
  echo $1 >>"/tmp/$2"

}

empty=true
while getopts ":hu:l:" option; do
  case $option in
  u)
    list=${OPTARG}
    empty=false
    ;;
  l)
    LOGS=${OPTARG}
    empty=false
    ;;
  h) Help ;;

  esac
done

# Check if is zimbra user
whoami=$(whoami)
if [[ $whoami != "zimbra" ]]; then
  echo "Must be run as zimbra user"
  exit 0
fi

# User(s) cant by null
if test -z "$list"; then
  echo "user cant be null"
  exit 0
fi

# Show Help for all not matching parameters
if $empty; then
  Help
fi

#If log path ends with / remove it
final="${LOGS: -1}"
if [ "$final" == "/" ]; then
  LOGS=$(echo "${LOGS::-1}")
fi

# Split user by ,
sep=$(echo "$list" | sed 's/,/\n/g')
for sender in $sep; do
  #Find all senders to whom $sender has sent mail
  OUT=$(zgrep -ho "<$sender> -> <..*>\|from=<$sender> to=<..*>" "$LOGS"/zimbra.log* | grep -ho " ..*<..*> " | grep -ho "<..*> ")

  # If is null not found and exit
  if [ -z "$OUT" ]; then
    echo "Not found in the most recent sender logs $sender"
    exit 0
  fi

  #Trim the strings
  sinespacios=$(echo "$OUT" | sed 's/,/\n/g' | sed 's/[[:space:]]*$//' | sed 's/^[[:space:]]*//' | sed 's/<//g' | sed 's/>//g' | tr ' ' '\n' | sort | uniq)

  #Message to usershowing all sendings user
  echo "It has been identified that the sender $sender has sent emails to these users/mailing lists"
  echo "$sinespacios"

  #Create temporary file to verify if the process has already been carried out on the senders
  touch "/tmp/$sender"

  #Fetching all mailing lists and users
  echo "Fetching all mailing lists and users, this may take a while"
  zmprov -l gaa >/tmp/users
  zmprov gadl >/tmp/lista

  #For every mailbox identified executed is User
  for mailbox in $sinespacios; do
    isUser "$mailbox" "$sender"
  done

  #Deleting temporary file for
  echo "Deleting temporary file for $sender"
  rm -rf "/tmp/${sender}"

done

#Deleting temporary files"
echo "Deleting temporary files"
rm -rf "/tmp/users"
rm -rf "/tmp/lista"

