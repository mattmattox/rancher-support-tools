#!/bin/bash +x
echo "Starting auto build process..."

echo "Docker build and deploy for agent...."
cd ./agent
docker build -t cube8021/rancher-support-tools-agent:"$BUILD_NUMBER" .
docker push cube8021/rancher-support-tools-agent:"$BUILD_NUMBER"
cat ./deployment.yml | sed "s/BUILD_NUMBER/$BUILD_NUMBER/g" | kubectl apply -f -
cd ../

echo "Docker build and deploy for manager...."
cd ./agent
docker build -t cube8021/rancher-support-tools-manager:"$BUILD_NUMBER" .
docker push cube8021/rancher-support-tools-manager:"$BUILD_NUMBER"
cat ./deployment.yml | sed "s/BUILD_NUMBER/$BUILD_NUMBER/g" | kubectl apply -f -
cd ../

echo "Cleaning up workspace..."
git clean -f
