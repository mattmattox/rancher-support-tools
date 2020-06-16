#!/bin/bash

usage()
{
cat << EOF
usage: $0 options
OPTIONS:
   -h      Show this message
   -T      DNS Timeout in seconds Default: 10s
EOF
}

VERBOSE=
while getopts .ht:T:v. OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         T)
             Timeout=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [[ -z $Timeout ]]
then
  Timeout=10s
fi

for ip in $(kubectl describe endpoints suport-agent --namespace=cattle-system | grep ' Addresses:' | awk '{print $2}' | sed 's/,/\n/g')
do
  Output=`timeout "$Timeout" ping -c 1 "$ip"`
  Result=$?
  if [ $Result -eq 0 ]
  then
    echo "$ip is pingable"
  else
    echo "$ip is not pingable"
  fi
done
