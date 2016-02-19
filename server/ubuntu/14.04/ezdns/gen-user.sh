#!/bin/bash

db=$1
user=$2
if [ "$db" == "" ]; then
  echo "Usage: $0 [DB path] [user name]"
  exit 1
fi

passwd=`openssl rand -base64 8`

echo "password is $passwd"

htdbm -b $db $user $passwd
