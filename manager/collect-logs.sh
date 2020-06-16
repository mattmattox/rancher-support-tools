#!/bin/bash

# Create temp directory
TMPDIR=$(mktemp -d $MKTEMP_BASEDIR)

echo "####################################################################################"
echo "Collecting Cluster info..."
mkdir -p $TMPDIR/clusterinfo
kubectl cluster-info > $TMPDIR/clusterinfo/summary 2>&1
kubectl cluster-info dump > $TMPDIR/clusterinfo/dump 2>&1
kubectl get nodes -o wide > $TMPDIR/clusterinfo/nodes 2>&1

echo "Collecting Kube-System info..."
mkdir -p $TMPDIR/kube-system
kubectl get pods -n kube-system -o wide > $TMPDIR/kube-system/pods 2>&1
echo "####################################################################################"

echo "####################################################################################"
echo "Collecting CoreDNS info..."
mkdir -p $TMPDIR/CoreDNS
echo "Getting pods..."
kubectl get pods -n kube-system -l k8s-app=kube-dns -o yaml > $TMPDIR/CoreDNS/coredns-pods 2>&1
kubectl get pods -n kube-system -l k8s-app=coredns-autoscaler -o yaml > $TMPDIR/CoreDNS/autoscaler-pods 2>&1
echo "Getting coredns logs..."
mkdir -p $TMPDIR/CoreDNS/coredns-logs
for pod in $(kubectl get pods -n kube-system -l k8s-app=kube-dns -o name | awk -F '/' '{print $2}')
do
  kubectl logs $pod -n kube-system > $TMPDIR/CoreDNS/coredns-logs/$pod
done
echo "Getting autoscaler logs..."
mkdir -p $TMPDIR/CoreDNS/autoscaler-logs
for pod in $(kubectl get pods -n kube-system -l k8s-app=coredns-autoscaler -o name | awk -F '/' '{print $2}')
do
  kubectl logs $pod -n kube-system > $TMPDIR/CoreDNS/autoscaler-logs/$pod
done
echo "####################################################################################"

echo "####################################################################################"
echo "Testing DNS..."
mkdir -p $TMPDIR/CoreDNS/check-dns
kubectl -n cattle-system get pods -l app=support-agent -o wide --no-headers | awk '{print $1,$6,$7}' |\
while IF=',' read -r podname node ip
do
  echo "Testing from node $node"
  kubectl -n cattle-system exec -it $pod -- /root/check-dns.sh | tee $TMPDIR/CoreDNS/check-dns/$node
done
echo "####################################################################################"

echo "####################################################################################"
echo "Collecting CNI info..."
if ! kubectl -n kube-system get pods -l k8s-app=flannel | grep 'No resources found'
then
  echo "##############################################"
  echo "Flannel found"
  echo "Collecting Pod info..."
  mkdir -p $TMPDIR/CNI/Flannel
  kubectl -n kube-system get pods -l k8s-app=flannel -o wide > $TMPDIR/CNI/Flannel/get-pods-wide
  kubectl -n kube-system get pods -l k8s-app=flannel -o yaml > $TMPDIR/CNI/Flannel/get-pods.yaml
  echo "Collecting ConfigMaps..."
  mkdir -p $TMPDIR/CNI/Flannel/configmap
  kubectl -n kube-system get configmaps kube-flannel-cfg -o yaml $TMPDIR/CNI/Flannel/configmap/kube-flannel-cfg.yaml
  kubectl -n kube-system get configmaps rke-network-plugin -o yaml $TMPDIR/CNI/Flannel/configmap/rke-network-plugin.yaml
  echo "Collecting Logs..."
  mkdir -p $TMPDIR/CNI/Flannel/logs
  for pod in $(kubectl get pods -n kube-system -l k8s-app=flannel -o name | awk -F '/' '{print $2}')
  do
    mkdir -p $TMPDIR/CNI/Flannel/logs/"$pod"
    kubectl logs $pod -n kube-system kube-flannel > $TMPDIR/CNI/Flannel/logs/"$pod"/kube-flannel
    kubectl logs $pod -n kube-system install-cni > $TMPDIR/CNI/Flannel/logs/"$pod"/install-cni
  done
  echo "Collecting Network Info..."
  for pod in $(kubectl get pods -n kube-system -l k8s-app=flannel -o name | awk -F '/' '{print $2}')
  do
    mkdir -p $TMPDIR/CNI/Flannel/networkinfo/"$pod"
    kubectl -n kube-system exec -it $pod -c kube-flannel -- ifconfig -a > $TMPDIR/CNI/Flannel/networkinfo/"$pod"-ifconfig
    kubectl -n kube-system exec -it $pod -c kube-flannel -- route -n > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/route
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables --list > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-list
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables-save > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-save
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables --numeric --verbose --list --table mangle > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-mangle
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables --numeric --verbose --list --table nat > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-nat
    kubectl -n kube-system exec -it $pod -c kube-flannel -- netstat -antu > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/netstat
    mkdir -p $TMPDIR/CNI/Flannel/networkinfo/"$pod"/net.d
    kubectl -n kube-system cp "$pod": -c kube-flannel /etc/cni/net.d $TMPDIR/CNI/Flannel/networkinfo/"$pod"/net.d
  done
  echo "##############################################"
elif ! kubectl -n kube-system get pods -l k8s-app=calico | grep 'No resources found'
then
  echo "##############################################"
  echo "Calico found"
  mkdir -p $TMPDIR/CNI/Calico
  echo "##############################################"
elif ! kubectl -n kube-system get pods -l k8s-app=canal | grep 'No resources found'
then
  echo "##############################################"
  echo "Canal found"
  mkdir -p $TMPDIR/CNI/Canal
  echo "##############################################"
elif ! kubectl -n kube-system get pods -l k8s-app=weave | grep 'No resources found'
then
  echo "##############################################"
  echo "Weave found"
  mkdir -p $TMPDIR/CNI/Weave
  echo "##############################################"
else
  echo "##############################################"
  echo "Could not CNI"
  echo "##############################################"
fi
echo "####################################################################################"
