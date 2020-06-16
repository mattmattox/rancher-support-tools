#!/bin/bash +x
echo "Starting deployment process..."

echo "Deploying agent...."
cd ./agent
cat ./deployment.yml | sed "s/BUILD_NUMBER/$BUILD_NUMBER/g" | kubectl apply -f -
cd ../

echo "Deploying manager...."
cd ./manager
cat ./deployment.yml | sed "s/BUILD_NUMBER/$BUILD_NUMBER/g" | kubectl apply -f -
cd ../

echo "Cleaning up workspace..."
git clean -f
