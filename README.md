# utc-aws-infracture
# 3-Tier AWS Terraform Infrastructure

A modular, production-grade AWS infrastructure managed via Terraform. This repository provisions a highly available, secure, and environment-aware 3-tier architecture (`dev` and `prod`) following security best practices.

---

## 🏗️ Architecture Overview

The architecture is split into three distinct subnet tiers deployed across multiple Availability Zones (AZs):

* **Public Tier:** Application Load Balancer (ALB) and Single NAT Gateway for outbound internet access.
* **Private App Tier:** EC2 Auto Scaling Group (ASG) running Ubuntu 22.04 LTS, mounted to Amazon EFS.
* **Private Database Tier:** Isolated Multi-AZ RDS MySQL database with no direct internet ingress or egress.
* **Secure Access:** Zero-bastion architecture. Remote management and database access are secured exclusively via **AWS Systems Manager (SSM) Session Manager** and SSM Port Forwarding.

```text
                  +----------------------------------------------+
                  |                 Internet                     |
                  +-----------------------+----------------------+
                                          |
                                          v
                  +-----------------------+----------------------+
                  |      Application Load Balancer (ALB)         |
                  +-----------------------+----------------------+
                                          |
                                          v
+-----------------------------------------+-----------------------------------------+
| VPC                                                                               |
|                                                                                   |
|  +-----------------------------------+   +-------------------------------------+  |
|  | Private App Subnets (ASG / EC2)   |   | Storage Tier                        |  |
|  | - Security Group Chaining from ALB|--->| - Amazon EFS Shared Mounts          |  |
|  | - Outbound via NAT Gateway        |   | - S3 Backup & Log Buckets           |  |
|  +-----------------+-----------------+   +-------------------------------------+  |
|                    |                                                              |
|                    v                                                              |
|  +-----------------+-----------------+                                            |
|  | Private Database Subnets          |                                            |
|  | - RDS MySQL Instance              |                                            |
|  | - Ingress strictly from App SG    |                                            |
|  | - Isolated Route Table (No IGW/NAT) |                                            |
|  +-----------------------------------+                                            |
+-----------------------------------------------------------------------------------+

Deployment
cd environments/dev
terraform init
terraform plan
terraform apply

AWS SSM Shell Access
aws ssm start-session --target <INSTANCE_ID>

Private Database SSM Tunnel
aws ssm start-session \
  --target <APP_INSTANCE_ID> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<RDS_ENDPOINT>"],"portNumber":["3306"],"localPortNumber":["3306"]}'