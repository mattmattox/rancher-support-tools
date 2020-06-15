#!/bin/bash +x
GIT_BRANCH_SHORT="$(echo $GIT_BRANCH | awk -F '/' '{print $2}')"
echo "GIT_COMMIT: $GIT_COMMIT"
echo "GIT_BRANCH: $GIT_BRANCH_SHORT"
docker login -u "$DOCKER_REPO_USERNAME" -p "$DOCKER_REPO_PASSWORD"

REGISTRY='cube8021'

echo "Starting auto build process..."

echo "Docker build and deploy for agent...."
cd ./agent
docker build -t "$REGISTRY"/rancher-support-tools-agent:"$BUILD_NUMBER" .
docker push "$REGISTRY"/rancher-support-tools-agent:"$BUILD_NUMBER"
cat ./deployment.yml | sed "s/BUILD_NUMBER/$BUILD_NUMBER/g" | sed "s/GIT_BRANCH/$GIT_BRANCH_SHORT/g" | sed "s/REGISTRY/$REGISTRY/g" | kubectl apply -f -
cd ../

echo "Cleaning up workspace..."
git clean -f
