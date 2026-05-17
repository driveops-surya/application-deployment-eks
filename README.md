# DevOps Project Setup Guide

## Step 1: Create Ubuntu EC2 Instance

Launch an Ubuntu EC2 instance with the following configuration:

| Setting | Value |
|---|---|
| AMI | Ubuntu 22.04 |
| Instance Type | t3.large |
| Storage | 20 GB |
| Public IP | Enabled |

### Security Group

Allow all traffic.

---

## Step 2: Connect to EC2 Instance

```bash
ssh -i <your-key.pem> ubuntu@<EC2_PUBLIC_IP>
```

Example:

```bash
ssh -i devops.pem ubuntu@13.200.xxx.xxx
```

---

## Step 3: Clone Repository

```bash
git clone <YOUR_REPO_URL>
```

```bash
cd <REPO_NAME>
```

---

## Step 4: Execute Setup Script

Give execute permission:

```bash
chmod +x devops-setup.sh
```

Run the script:

```bash
./devops-setup.sh
```

The script installs:

- AWS CLI
- kubectl
- eksctl
- Helm
- Trivy
- Docker
- SonarQube
- EKS Cluster
- ECR Repository

---

## Step 5: Update AWS Account ID

Open `ds.yml`.

Replace AWS Account ID in line number `58` with your AWS Account ID.

Example:

```yaml
image: 123456789012.dkr.ecr.ap-south-1.amazonaws.com/bankapp:latest
```

---

## Step 6: Access SonarQube

Open browser:

```text
http://<EC2_PUBLIC_IP>:9000
```

Default credentials:

```text
Username: admin
Password: admin
```

---

## Step 7: Generate SonarQube Token

Go to:

```text
Profile -> My Account -> Security
```

Generate token with:

| Field | Value |
|---|---|
| Token Name | Any Name |
| Type | Global Analysis Token |

Copy the generated token.

---

## Step 8: Configure GitHub Secrets and Variables

Go to:

```text
GitHub Repo -> Settings -> Secrets and Variables -> Actions
```

### Add Secrets

| Secret Name |
|---|
| SONAR_TOKEN |
| AWS_ACCESS_KEY_ID |
| AWS_SECRET_ACCESS_KEY |
| EKS_KUBECONFIG |

---

## Step 9: Configure SONAR_HOST_URL Variable

Under Variables tab add:

| Variable | Example |
|---|---|
| SONAR_HOST_URL | http://13.200.xxx.xxx:9000 |

---

## Step 10: Add kubeconfig Secret

Run this command on EC2 instance:

```bash
cat ~/.kube/config
```

Copy the complete output.

Add it as GitHub secret:

```text
EKS_KUBECONFIG
```

---

## Step 11: Configure GitHub Self Hosted Runner

Go to:

```text
GitHub Repo -> Settings -> Actions -> Runners
```

Select:

```text
New self-hosted runner -> Linux
```

Run all commands shown except the last one.

Instead of:

```bash
./run.sh
```

Run:

```bash
nohup ./run.sh &> /dev/null &
```
---

# Setup Completed
