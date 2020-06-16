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

kubectl -n cattle-system get pods -l app=support-agent -o wide --no-headers | awk '{print $1,$6,$7}' |\
while IF=',' read -r podname node ip
do
  Output=`timeout "$Timeout" ping -c 1 "$ip"`
  Result=$?
  if [ $Result -eq 0 ]
  then
    echo "Node $node is pingable using overlay"
  else
    echo "Node $node is not pingable using overlay"
  fi
done
