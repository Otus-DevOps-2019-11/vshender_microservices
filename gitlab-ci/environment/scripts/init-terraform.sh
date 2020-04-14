#!/bin/bash

# This script is run on a Gitlab runner.

# Install dependencies
apt update && apt install -y curl openssh-client unzip

# Generate a SSH key for the environment instance access
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -N "" -f /.id_rsa

# Install google-cloud-sdk
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
apt install -y apt-transport-https ca-certificates gnupg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt update && apt install -y google-cloud-sdk

# Get Google Cloud service account authorization key
echo $GCP_SERVICE_ACCOUNT_KEY | base64 -d > service-account.json

# Install terraform
curl https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip > /tmp/terraform.zip
unzip -o -d /usr/local/bin/ /tmp/terraform.zip

# Configure terraform
echo -e "project = \"$GCP_PROJECT_NAME\"\nenvironment = \"$CI_COMMIT_REF_NAME\"" > terraform.tfvars
sed -e "s/{{ var.project }}/$GCP_PROJECT_NAME/; s/{{ var.environment }}/$CI_COMMIT_REF_NAME/" templates/backend.tf.template > backend.tf

# Create docker-compose.yml
sed "s/{{ REDDIT_APP_IMAGE }}/${DOCKER_IMAGE_NAME//\//\\/}/" templates/docker-compose.yml.template > docker-compose.yml

echo "DOCKER_HUB_LOGIN: $DOCKER_HUB_LOGIN"
echo "DOCKER_HUB_PASSWD: $DOCKER_HUB_PASSED"
echo "GCP_PROJECT_NAME: $GCP_PROJECT_NAME"
echo "GCP_SERVICE_ACCOUNT_KEY: $GCP_SERVICE_ACCOUNT_KEY"
echo 'service-account.json:'
cat service-account.json
echo 'terraform.tfvars:'
cat terraform.tfvars
echo 'backend.tf:'
cat backend.tf
echo 'docker-compose.yml'
cat docker-compose.yml

terraform init
