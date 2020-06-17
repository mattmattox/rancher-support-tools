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
  echo "Podname: $podname"
  echo "Node: $node"
  echo "IP: $ip"
  echo "Running check-dns..."
  if [[ ! $node == "<none>" ]]
  then
    kubectl -n cattle-system exec $podname -- /root/check-dns.sh | tee $TMPDIR/CoreDNS/check-dns/$node
  fi
done
echo "####################################################################################"

echo "####################################################################################"
echo "Collecting CNI info..."
if [[ ! `kubectl -n kube-system get pods -l k8s-app=flannel` == 'No resources found' ]]
then
  echo "##############################################"
  echo "Flannel found"
  echo "Collecting Pod info..."
  mkdir -p $TMPDIR/CNI/Flannel
  kubectl -n kube-system get pods -l k8s-app=flannel -o wide > $TMPDIR/CNI/Flannel/get-pods-wide
  kubectl -n kube-system get pods -l k8s-app=flannel -o yaml > $TMPDIR/CNI/Flannel/get-pods.yaml
  echo "Collecting ConfigMaps..."
  mkdir -p $TMPDIR/CNI/Flannel/configmap
  kubectl -n kube-system get configmaps kube-flannel-cfg -o yaml > $TMPDIR/CNI/Flannel/configmap/kube-flannel-cfg.yaml
  kubectl -n kube-system get configmaps rke-network-plugin -o yaml > $TMPDIR/CNI/Flannel/configmap/rke-network-plugin.yaml
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
    echo "########################"
    echo "Pod: $pod"
    mkdir -p $TMPDIR/CNI/Flannel/networkinfo/"$pod"
    echo "Running ifconfig -a"
    kubectl -n kube-system exec -it $pod -c kube-flannel -- ifconfig -a > $TMPDIR/CNI/Flannel/networkinfo/"$pod"-ifconfig
    echo "Running route -n"
    kubectl -n kube-system exec -it $pod -c kube-flannel -- route -n > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/route
    echo "Running iptables --list"
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables --list > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-list
    echo "Running iptables-save"
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables-save > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-save
    echo "Running iptables --numeric --verbose --list --table mangle"
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables --numeric --verbose --list --table mangle > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-mangle
    echo "Running iptables --numeric --verbose --list --table nat"
    kubectl -n kube-system exec -it $pod -c kube-flannel -- iptables --numeric --verbose --list --table nat > $TMPDIR/CNI/Flannel/networkinfo/"$pod"/iptables-nat
    echo "Grabbing /etc/cni/net.d"
    mkdir -p $TMPDIR/CNI/Flannel/networkinfo/"$pod"/net.d
    kubectl -n kube-system cp -c kube-flannel "$pod":/etc/cni/net.d $TMPDIR/CNI/Flannel/networkinfo/"$pod"/net.d
    echo "########################"
  done
  echo "##############################################"
elif ! kubectl -n kube-system get pods -l k8s-app=calico | grep 'No resources found'
then
  echo "##############################################"
  echo "Calico found"
  mkdir -p $TMPDIR/CNI/Calico
  kubectl -n kube-system get pods -l k8s-app=calico-node -o wide > $TMPDIR/CNI/Calico/calico-node-get-pods-wide
  kubectl -n kube-system get pods -l k8s-app=calico-node -o yaml > $TMPDIR/CNI/Calico/calico-node-get-pods.yaml
  kubectl -n kube-system get pods -l k8s-app=calico-kube-controllers -o wide > $TMPDIR/CNI/Calico/calico-kube-controllers-get-pods-wide
  kubectl -n kube-system get pods -l k8s-app=calico-kube-controllers -o yaml > $TMPDIR/CNI/Calico/calico-kube-controllers-get-pods.yaml
  echo "Collecting ConfigMaps..."
  mkdir -p $TMPDIR/CNI/Calico/configmap
  kubectl -n kube-system get configmaps calico-config -o yaml > $TMPDIR/CNI/Calico/configmap/kube-flannel-cfg.yaml
  kubectl -n kube-system get configmaps rke-network-plugin -o yaml > $TMPDIR/CNI/Calico/configmap/rke-network-plugin.yaml
  echo "Collecting Logs..."
  mkdir -p $TMPDIR/CNI/Calico/logs
  for pod in $(kubectl get pods -n kube-system -l k8s-app=calico-node -o name | awk -F '/' '{print $2}')
  do
    mkdir -p $TMPDIR/CNI/Calico/logs/"$pod"
    kubectl logs $pod -n kube-system calico-node > $TMPDIR/CNI/Calico/logs/"$pod"/calico-node
    kubectl logs $pod -n kube-system install-cni > $TMPDIR/CNI/Calico/logs/"$pod"/install-cni
    kubectl logs $pod -n kube-system flexvol-driver > $TMPDIR/CNI/Calico/logs/"$pod"/flexvol-driver
    kubectl logs $pod -n kube-system upgrade-ipam > $TMPDIR/CNI/Calico/logs/"$pod"/upgrade-ipam
  done
  echo "Collecting Network Info..."
  for pod in $(kubectl get pods -n kube-system -l k8s-app=calico-node -o name | awk -F '/' '{print $2}')
  do
    echo "########################"
    echo "Pod: $pod"
    mkdir -p $TMPDIR/CNI/Calico/networkinfo/"$pod"
    echo "Running ifconfig -a"
    kubectl -n kube-system exec -it $pod -c calico-node -- ifconfig -a > $TMPDIR/CNI/Calico/networkinfo/"$pod"-ifconfig
    echo "Running route -n"
    kubectl -n kube-system exec -it $pod -c calico-node -- route -n > $TMPDIR/CNI/Calico/networkinfo/"$pod"/route
    echo "Running iptables --list"
    kubectl -n kube-system exec -it $pod -c calico-node -- iptables --list > $TMPDIR/CNI/Calico/networkinfo/"$pod"/iptables-list
    echo "Running iptables-save"
    kubectl -n kube-system exec -it $pod -c calico-node -- iptables-save > $TMPDIR/CNI/Calico/networkinfo/"$pod"/iptables-save
    echo "Running iptables --numeric --verbose --list --table mangle"
    kubectl -n kube-system exec -it $pod -c calico-node -- iptables --numeric --verbose --list --table mangle > $TMPDIR/CNI/Calico/networkinfo/"$pod"/iptables-mangle
    echo "Running iptables --numeric --verbose --list --table nat"
    kubectl -n kube-system exec -it $pod -c calico-node -- iptables --numeric --verbose --list --table nat > $TMPDIR/CNI/Calico/networkinfo/"$pod"/iptables-nat
    echo "Grabbing /etc/cni/net.d"
    mkdir -p $TMPDIR/CNI/Calico/networkinfo/"$pod"/net.d
    kubectl -n kube-system cp -c calico-node "$pod":/etc/cni/net.d $TMPDIR/CNI/Calico/networkinfo/"$pod"/net.d
    echo "Grabbing /etc/calico"
    mkdir -p $TMPDIR/CNI/Calico/networkinfo/"$pod"/calico-etc-config
    kubectl -n kube-system cp -c calico-node "$pod":/etc/calico $TMPDIR/CNI/Calico/networkinfo/"$pod"/calico-etc-config
    echo "########################"
  done
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
