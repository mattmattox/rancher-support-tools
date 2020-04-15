#!/bin/bash

# Create temp directory
TMPDIR=$(mktemp -d $MKTEMP_BASEDIR)

echo "Collecting Cluster info..."
mkdir -p $TMPDIR/clusterinfo
kubectl cluster-info > $TMPDIR/clusterinfo/summary 2>&1
kubectl cluster-info dump > $TMPDIR/clusterinfo/dump 2>&1
kubectl get nodes -o wide > $TMPDIR/clusterinfo/nodes 2>&1

echo "Collecting Kube-System info..."
mkdir -p $TMPDIR/kube-system
kubectl get pods -n kube-system -o wide > $TMPDIR/kube-system/pods 2>&1

echo "Collecting CNI/overlay info..."
#Canal
#Flannel
#Calico
#Weave

echo "Collecting CoreDNS info..."
mkdir -p $TMPDIR/CoreDNS
echo "Getting pods..."
kubectl get pods -n kube-system -l k8s-app=kube-dns -o yaml > $TMPDIR/CoreDNS/coredns-pods 2>&1
kubectl get pods -n kube-system -l k8s-app=coredns-autoscaler -o yaml > $TMPDIR/CoreDNS/autoscaler-pods 2>&1
echo "Getting coredns logs..."
mkdir -p $TMPDIR/CoreDNS/coredns-logs
for pod in $(kubectl get pods -n kube-system -l k8s-app=kube-dns -o name)
do
  kubectl logs $pod -n kube-system > $TMPDIR/CoreDNS/coredns-logs/$pod
done
echo "Getting autoscaler logs..."
mkdir -p $TMPDIR/CoreDNS/autoscaler-logs
for pod in $(kubectl get pods -n kube-system -l k8s-app=coredns-autoscaler -o name)
do
  kubectl logs $pod -n kube-system > $TMPDIR/CoreDNS/autoscaler-logs/$pod
done
echo "Testing DNS..."
InternalHost="kube-dns.kube-system"
InternalIP="$(kubectl get services -n kube-system kube-dns -o yaml | grep 'clusterIP:' | awk '{print $2}')"
ExternalHost="a.root-servers.net"
ExternalIP="198.41.0.4"
Timeout="10s"
kubectl exec -it

echo "Collecting CNI info..."
#Flannel

#Calico

#Canal

#Weave
