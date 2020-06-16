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
mkdir -p $TMPDIR/CoreDNS/check-dns
kubectl -n cattle-system get pods -l app=support-agent -o wide --no-headers | awk '{print $1,$6,$7}' |\
while IF=',' read -r podname node ip
do
  echo "Testing from $node"
  kubectl -n cattle-system exec -it $pod /root/check-dns.sh | tee $TMPDIR/CoreDNS/check-dns/$node
done

echo "Collecting CNI info..."
if ! kubectl -n kube-system get pods -l k8s-app=flannel | grep 'No resources found'
then
  echo "Flannel found"
  mkdir -p $TMPDIR/CNI/Flannel
  kubectl -n kube-system get pods -l k8s-app=flannel -o wide > $TMPDIR/CNI/Flannel/get-pods-wide
  kubectl -n kube-system get pods -l k8s-app=flannel -o yaml > $TMPDIR/CNI/Flannel/get-pods-yaml

elif ! kubectl -n kube-system get pods -l k8s-app=calico | grep 'No resources found'
then
  echo "Calico found"
  mkdir -p $TMPDIR/CNI/Calico
elif ! kubectl -n kube-system get pods -l k8s-app=canal | grep 'No resources found'
then
  echo "Canal found"
  mkdir -p $TMPDIR/CNI/Canal

elif ! kubectl -n kube-system get pods -l k8s-app=weave | grep 'No resources found'
then
  echo "Weave found"
  mkdir -p $TMPDIR/CNI/Weave
else
  echo "Could not CNI"
fi
