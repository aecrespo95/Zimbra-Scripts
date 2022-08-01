#!/bin/bash
###########################################################
#Help                                                     #
###########################################################
Help() {
  # Display Help
  echo "Add description of the script functions here."
  echo
  echo "Syntax: scriptTemplate [-g|h|v|V]"
  echo "options:"
  echo "u     Set the mailbox"
  echo "h     Print this Help."
  echo "s     Set the store path."
  echo "d     Not eliminat duplicates."
  echo
  exit 0
}

remove_dupl() {
  #Obtain the message id from the entry
  message_id=$(grep "Message-ID:" "$1" | grep -Po '(?<=(<)).*(?=>)')

  echo "Checking if there is a duplicate of the message with id $message_id"

  #Create command for too much ""
  camd="zmmailbox -z -m $id search \"#Message-ID: <$message_id>\""

  #Run the command
  ZM=$(eval $camd)

  #Separate the messages id
  message=$(echo "$ZM" | awk '$1 ~ /[0-9]/ { print $2 }' | grep - | sed 's/-//g' | uniq)

  #Separate the conversations id
  conversations=$(echo "$ZM" | awk '$1 ~ /[0-9]/ { print $2 }' | grep -v - | uniq)

  #Delete all message by id from mailbox
  for messageid in $message; do
    echo "Deleting duplicate message with id $message_id from user $id"
    zmmailbox -z -m "$id" dm "$messageid"

  done

  #Delete all conversation by id from mailbox
  for conversid in $conversations; do

    echo "Borrando la conversación número $conversid del usuario $id"
    zmmailbox -z -m "$id" dc "$conversid"

  done

}

# Set variables
empty=true
id=""
store=""
remove_duplicate=true
while getopts ":hu:ds:" option; do
  case $option in
  h) Help ;;
  u) # Enter a id
    id=$OPTARG
    empty=false
    ;;
  s) # Enter a store
    store=$OPTARG
    empty=false
    ;;
  d)
    remove_duplicate=false
    ;;
  esac
done
if $empty; then
  Help
fi

# Check if is zimbra user
whoami=$(whoami)
if [[ $whoami != "zimbra" ]]; then
  echo "Must be run as zimbra user"
  exit 0
fi

#Mailbox cant be null
if test -z "$id"; then
  echo "user cant be null"
  exit 0
fi

#store cant be null
if test -z "$store"; then
  echo "store cant be null"
  exit 0
fi

#If log path not ends with / add it
final="${store: -1}"
if [ "$final" != "/" ]; then
  store="$store/"
fi

#for every mail in the path
for entry in "$store"*; do

  #If remove duplicate is true then remove if already exist
  if $remove_duplicate; then
    remove_dupl "$entry"

  fi

  #Add Mail in Inbox
  zmmailbox -z -m "$id" addMessage /Inbox "$entry"

done
