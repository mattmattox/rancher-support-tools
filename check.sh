#!/bin/bash

usage()
{
cat << EOF
usage: $0 options
OPTIONS:
   -h      Show this message
   -I      Infra Services only
   -N      Namespace
EOF
}

VERBOSE=
InfraOnly=
Namespace=
while getopts .ht:I.N:v. OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         I)
             InfraOnly=1
             ;;
         N)
             Namespace=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

echo "Checking connection to kubeapi..."
if ! kubectl version > /dev/null
then
	echo "Failed"
	exit 2
fi

if [[ "$InfraOnly" == '1' ]]
then
	echo "Infra services..."
	echo "Checking etcd..."
	NODES="$(kubectl get nodes -l node-role.kubernetes.io/etcd=true -o NAME | awk -F '/' '{print $2}')"
	for NODE in $NODES
	do
		echo "etcd node: $NODE"
	done
fi
