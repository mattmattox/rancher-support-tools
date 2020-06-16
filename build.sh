#!/bin/bash +x
echo "Starting build process..."

echo "Building agent...."
cd ./agent
docker build -t cube8021/rancher-support-tools-agent:"$BUILD_NUMBER" .
docker push cube8021/rancher-support-tools-agent:"$BUILD_NUMBER"
cd ../

echo "Building manager...."
cd ./manager
docker build -t cube8021/rancher-support-tools-manager:"$BUILD_NUMBER" .
docker push cube8021/rancher-support-tools-manager:"$BUILD_NUMBER"
cd ../
