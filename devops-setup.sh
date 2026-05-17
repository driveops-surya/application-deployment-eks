#!/bin/bash
set -euo pipefail

# =========================================================
# DevOps Tools + Docker + SonarQube + EKS Setup Script
# Ubuntu 22.04 / 24.04
# =========================================================

echo "================================================="
echo "Updating system packages..."
echo "================================================="

sudo apt update -y
sudo apt upgrade -y

sudo apt install -y \
  unzip \
  curl \
  wget \
  git \
  gnupg \
  lsb-release \
  ca-certificates \
  apt-transport-https \
  software-properties-common \
  maven

# =========================================================
# Install AWS CLI v2
# =========================================================

echo "================================================="
echo "Installing AWS CLI v2..."
echo "================================================="

cd /tmp

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
-o "awscliv2.zip"

unzip -o awscliv2.zip

sudo ./aws/install --update

aws --version

# =========================================================
# Configure AWS CLI
# =========================================================

echo "================================================="
echo "Configure AWS CLI"
echo "================================================="

read -p "Enter AWS Access Key ID: " AWS_ACCESS_KEY_ID

read -p "Enter AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""

read -p "Enter AWS Region [ap-south-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-ap-south-1}

read -p "Enter AWS Output Format [json]: " AWS_OUTPUT
AWS_OUTPUT=${AWS_OUTPUT:-json}

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"
aws configure set output "$AWS_OUTPUT"

echo "AWS CLI configured successfully."

# =========================================================
# Install kubectl
# =========================================================

echo "================================================="
echo "Installing kubectl..."
echo "================================================="

KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

curl -LO \
"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

curl -LO \
"https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

echo "$(cat kubectl.sha256) kubectl" | sha256sum --check

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl version --client

# =========================================================
# Install eksctl
# =========================================================

echo "================================================="
echo "Installing eksctl..."
echo "================================================="

curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin

eksctl version

# =========================================================
# Install Helm
# =========================================================

echo "================================================="
echo "Installing Helm..."
echo "================================================="

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version

# =========================================================
# Install Trivy
# =========================================================

echo "================================================="
echo "Installing Trivy..."
echo "================================================="

sudo mkdir -p /etc/apt/keyrings

wget -qO - \
https://aquasecurity.github.io/trivy-repo/deb/public.key \
| gpg --dearmor \
| sudo tee /etc/apt/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb \
$(lsb_release -sc) main" \
| sudo tee /etc/apt/sources.list.d/trivy.list

sudo apt-get update -y

sudo apt-get install -y trivy

trivy --version

# =========================================================
# Install Docker
# =========================================================

echo "================================================="
echo "Installing Docker..."
echo "================================================="

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL \
https://download.docker.com/linux/ubuntu/gpg \
-o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y

sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER

sudo chmod 666 /var/run/docker.sock

docker --version

# =========================================================
# Install SonarQube
# =========================================================

echo "================================================="
echo "Installing SonarQube..."
echo "================================================="

docker pull sonarqube:lts-community

docker rm -f sonarqube >/dev/null 2>&1 || true

docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  --restart unless-stopped \
  sonarqube:lts-community

echo "Waiting for SonarQube to start..."
sleep 40

docker ps

PUBLIC_IP=$(curl -s ifconfig.me)

echo "================================================="
echo "SonarQube Started Successfully"
echo "================================================="
echo "Access URL: http://${PUBLIC_IP}:9000"
echo "Username: admin"
echo "Password: admin"

# =========================================================
# Create EKS Cluster
# =========================================================

echo "================================================="
echo "EKS Cluster Creation"
echo "================================================="

read -p "Do you want to create EKS cluster now? (yes/no): " CREATE_EKS

if [[ "$CREATE_EKS" == "yes" ]]; then

  read -p "Enter EKS Cluster Name [k8s-troubleshooting]: " CLUSTER_NAME
  CLUSTER_NAME=${CLUSTER_NAME:-k8s-troubleshooting}

  read -p "Enter AWS Region [ap-south-1]: " EKS_REGION
  EKS_REGION=${EKS_REGION:-ap-south-1}

  echo "Creating EKS cluster. This may take 15-25 minutes..."

  eksctl create cluster \
    --name "$CLUSTER_NAME" \
    --version 1.33 \
    --region "$EKS_REGION" \
    --nodegroup-name github-actions-cicd \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 3 \
    --managed

  aws eks update-kubeconfig \
    --region "$EKS_REGION" \
    --name "$CLUSTER_NAME"

  kubectl get nodes

  echo "EKS Cluster Created Successfully."

fi
echo "================================================="
echo "Setup Completed Successfully"
echo "================================================="
