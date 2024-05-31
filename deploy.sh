#!/bin/bash

# Variables
EC2_USER="ubuntu"
EC2_HOST="ip"
SSH_KEY="/var/lib/jenkins/.ssh/id_rsa"
REMOTE_WORKING_DIR="/home/ubunt/workdir"
SLACK_WEBHOOK_URL=""
BACKEND_ENDPOINT="test endpoint"

# Commands to execute on the EC2 instance
REMOTE_COMMANDS="
cd $REMOTE_WORKING_DIR && \
git pull origin develop && \
docker-compose build && \
docker-compose down --remove-orphans && \
docker-compose up -d && \
uptime
"

# Execute the commands on the EC2 instance via SSH
ssh -i $SSH_KEY -o StrictHostKeyChecking=no $EC2_USER@$EC2_HOST "$REMOTE_COMMANDS"
COMMAND_STATUS=$?

# Function to check the backend service
check_backend() {
    local url=$1
    http_status=$(curl -o /dev/null -s -w "%{http_code}\n" $url)
    if [ "$http_status" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Wait for the service to start
sleep 30

# Retry logic for the health check
RETRY_COUNT=5
RETRY_DELAY=10
for i in $(seq 1 $RETRY_COUNT); do
    check_backend $BACKEND_ENDPOINT
    HEALTH_STATUS=$?
    if [ $HEALTH_STATUS -eq 0 ]; then
        break
    fi
    echo "Health check failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
done

# Send notification to Slack
if [ $COMMAND_STATUS -eq 0 ]; then
    if [ $HEALTH_STATUS -eq 0 ]; then
        curl -X POST --data-urlencode "payload={\"text\": \"Jenkins job successfully deployed the latest commit to the Develop Backend Server. The backend service is running and healthy at $BACKEND_ENDPOINT.\"}" $SLACK_WEBHOOK_URL
    else
        curl -X POST --data-urlencode "payload={\"text\": \"Jenkins job deployed the latest commit to the Develop Backend Server, but the backend service health check failed at $BACKEND_ENDPOINT.\"}" $SLACK_WEBHOOK_URL
    fi
else
    curl -X POST --data-urlencode "payload={\"text\": \"Jenkins job failed during deployment on the Develop Backend Server. Check the Jenkins logs for more details.\"}" $SLACK_WEBHOOK_URL
fi
