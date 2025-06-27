# Automated Multi-Cloud Disaster Recovery Pipeline

A production-ready solution for orchestrating a robust, automated disaster recovery (DR) strategy across AWS, Azure, and GCP using Terraform, Kubernetes, Velero, and GitOps with ArgoCD.
Table of Contents

**Overview**

In today's cloud-native landscape, relying on a single cloud provider introduces significant business risk. A regional outage or service failure can lead to catastrophic downtime and data loss. This project solves that problem by implementing a fully automated, multi-cloud disaster recovery pipeline.

It provisions identical Kubernetes clusters on AWS (EKS), Azure (AKS), and GCP (GKE). State and applications are continuously backed up and synchronized, allowing for rapid, automated failover to a healthy cloud provider in the event of a disaster, thereby ensuring business continuity.
Architecture

The architecture is designed for high availability and resilience.
* **Infrastructure as Code (IaC)**: Terraform is used to define and provision all cloud resources, including VPCs, Kubernetes clusters (EKS, AKS, GKE), and storage buckets, ensuring consistent infrastructure across all three clouds.
* **Application Delivery (GitOps)**: ArgoCD implements the GitOps methodology. It continuously monitors a dedicated Git repository and ensures that the state of deployed applications on all clusters matches the configuration defined in Git.
* **ackup & Restore**: Velero is deployed on each cluster. It performs scheduled backups of Kubernetes persistent volumes and object configurations to the native object storage of each cloud (AWS S3, Azure Blob Storage, Google Cloud Storage).
* **Monitoring**: Prometheus and Grafana (deployment manifests included as placeholders) are used for monitoring cluster health, backup success rates, and tracking key recovery metrics like RTO and RPO.



# Tech Stack

* **Cloud Providers** : AWS, Azure, GCP
* **Infrastructure as Code**: Terraform
* **Orchestration** : Kubernetes (AWS EKS, Azure AKS, GCP GKE)
* **Backup & Restore** : Velero
* **Application Delivery** : ArgoCD (GitOps)
* **CI/CD** : GitHub Actions
* **Monitoring**: Prometheus, Grafana
* **Chaos Engineering** : Chaos Monkey (via script)
  

# Key Features

* **Automated Multi-Cloud Provisioning**: Single Terraform configuration to stand up entire Kubernetes environments on AWS, Azure, and GCP.
* **Cross-Cloud Backup & Restore**: Automated and scheduled backups of Kubernetes volumes and resources to native object storage in each cloud.
* **GitOps-Driven Synchronization**: Applications are kept in sync across all clusters from a single source of truth in Git.
* **Rapid Failover Capability**: Clear, documented procedures to restore service on a secondary cloud provider in minutes.
* **Resilience Testing**: Integrated scripts for chaos engineering to proactively test the system's resilience.
* **Secure by Design**: Utilizes modern, secretless authentication methods for Velero (IAM Roles for Service Accounts on AWS, Workload Identity on Azure/GCP).


# Prerequisites

Before you begin, ensure you have the following:
1. Cloud Accounts: Active accounts and subscriptions for:
    * Amazon Web Services (AWS)
    * Microsoft Azure
    * Google Cloud Platform (GCP)

2. CLI Tools: The latest versions of the following CLI tools installed and configured:
    * terraform (v1.5+)
    * kubectl
    * helm (v3+)
    * aws CLI
    * az CLI
    * gcloud CLI

Permissions: Your user/principal must have sufficient permissions to create all the resources defined in the Terraform scripts (VPCs, Kubernetes Clusters, IAM Roles, Storage Accounts, etc.). Typically, AdministratorAccess, Owner, or similar high-level roles are required for the initial setup.


# Project Deployment Guide

Follow these phases sequentially to deploy the entire solution.

**Phase 1: Environment Configuration**

Clone the Repository:
```
    git clone <YOUR_REPO_URL>
    cd disaster-recovery-pipeline
```

Configure Cloud Credentials:
Ensure your CLI is authenticated with all three cloud providers.
```
    aws configure
    az login
    gcloud auth application-default login
```
Update Terraform Variables:
Edit the file **terraform/variables.tf** and replace placeholder values with your own, especially gcp_project_id.


**Phase 2: Provision Infrastructure with Terraform**

This will create the VPCs, Kubernetes clusters, and storage buckets.
Navigate to the Terraform directory:
```
    cd terraform
```
Initialize Terraform:
```
    terraform init
```
Plan and Apply:
```
    terraform plan
    terraform apply --auto-approve
```
This process can take 20-30 minutes. Upon completion, Terraform will output the commands needed to configure kubectl for each new cluster.

Configure kubectl:
Run the output commands from Terraform to add the EKS, AKS, and GKE clusters to your kubeconfig file. Verify with:
```
    kubectl config get-contexts
```

**Phase 3: Set Up Application GitOps Repositor**

ArgoCD requires a separate Git repository containing your application's Kubernetes manifests. This project uses a Kustomize structure.
Create a new Git repository (e.g., my-sample-app).
Structure the repository as follows:

    my-sample-app/
    ├── base/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── overlays/
        └── production/
            ├── deployment-patch.yaml
            └── kustomization.yaml

Use the file contents provided in the previous detailed responses to populate these files.

**Update the ArgoCD Application Manifest:**

In this project's repository, edit **kubernetes/argocd-configs/sample-app.yaml** and update the repoURL to point to your new application repository.

    # kubernetes/argocd-configs/sample-app.yaml
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: my-sample-app
      namespace: argocd
    spec:
      source:
        # CHANGE THIS LINE
        repoURL: 'https://github.com/your-username/my-sample-app.git'
        path: overlays/production
        targetRevision: HEAD
      # ... rest of the file

**Phase 4: Deploy Core Kubernetes Tooling**

Deploy ArgoCD and the monitoring stack to each of your three clusters.
For each cluster (EKS, AKS, GKE), run the following:

1. Set kubectl context:
```
    # Example for EKS
    kubectl config use-context <your-eks-cluster-context>
```

2. Install ArgoCD:
```
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
3. Deploy Your Application via ArgoCD:
```
    # This points ArgoCD to your application repository
    kubectl apply -f kubernetes/argocd-configs/sample-app.yaml
```

4. Deploy Monitoring Placeholders (Optional):
```
    kubectl apply -f kubernetes/monitoring/
```

**Phase 5: Deploy Velero for Backups (Multi-Cloud)**
This is the most critical step. Run the appropriate setup for each cloud provider on its respective cluster.

**A. Velero on AWS (EKS)**
    
1. Set kubectl context to your EKS cluster.

2. **Run Prerequisite Script**: The commands from the previous detailed responses to create the IAM Role for Service Accounts (IRSA) are required. This ensures Velero authenticates securely without static keys.
3. **Update values-aws.yaml:**    
Edit **kubernetes/velero/values-aws.yaml** and replace placeholders:
* **serviceAccount.server.annotations.eks.amazonaws.com/role-arn**: Your newly created IAM role ARN
* **configuration.backupStorageLocation.bucket**: Your S3 bucket name created by Terraform.  
* **configuration.backupStorageLocation.config.region**: Your AWS region.
4. Install Velero using Helm:
```
    helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
    helm install velero vmware-tanzu/velero \
      --namespace velero --create-namespace \
      -f kubernetes/velero/values-aws.yaml
```

**B. Velero on Azure (AKS)**
1. Set kubectl context to your AKS cluster.
2. Run Prerequisite Commands: Follow the az CLI steps from the previous detailed responses to enable Workload Identity on AKS, create a managed identity, and assign it the required permissions.
3. Update values-azure.yaml:
    Edit kubernetes/velero/values-azure.yaml and replace placeholders:

        azure.clientID: The Client ID of the managed identity you created.

        azure.subscriptionID: Your Azure Subscription ID.

        azure.tenantID: Your Azure Tenant ID.

        configuration.backupStorageLocation.config.storageAccount: Your Azure Storage Account name.

    Install Velero using Helm:

    helm install velero vmware-tanzu/velero \
      --namespace velero --create-namespace \
      -f kubernetes/velero/values-azure.yaml

C. Velero on GCP (GKE)

    Set kubectl context to your GKE cluster.

    Run Prerequisite Commands: Follow the gcloud CLI steps from the previous detailed responses to enable Workload Identity on GKE, create a Google Service Account (GSA), and bind it to the Velero Kubernetes Service Account (KSA).

    Update values-gcp.yaml:
    Edit kubernetes/velero/values-gcp.yaml and replace placeholders:

        serviceAccount.server.annotations.iam.gke.io/gcp-service-account: The email of the GSA you created.

        configuration.backupStorageLocation.bucket: Your GCS bucket name.

    Install Velero using Helm:

    helm install velero vmware-tanzu/velero \
      --namespace velero --create-namespace \
      -f kubernetes/velero/values-gcp.yaml

Usage and Operations
Verifying the Setup

    Check ArgoCD:

    # Get the initial admin password
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    # Access the UI
    kubectl port-forward svc/argocd-server -n argocd 8080:443

    Navigate to https://localhost:8080. Your application should appear and be synced.

    Check Velero: (On any cluster)

    # Create a test backup
    velero backup create manual-test-backup --include-namespaces default --wait
    # Check status
    velero backup get

Disaster Recovery (Failover) Procedure

Assume your primary cluster on AWS EKS has failed. You want to failover to GCP GKE.

    Confirm Failure: Your monitoring tools (Prometheus/Grafana) should alert you that the EKS cluster is down.

    Update DNS: Change your application's DNS records (e.g., in Route 53, Cloudflare) to point from the AWS load balancer to the GCP load balancer's IP address.

    Identify Latest Backup: On the GCP GKE cluster, list the available backups. Velero automatically syncs backup metadata from the object storage location.

    # Set context to the GKE cluster
    kubectl config use-context <your-gke-cluster-context>

    # Find the most recent successful backup from AWS
    velero backup get

    Initiate Restore:

    # Restore everything from the chosen backup
    velero restore create --from-backup <name-of-latest-aws-backup>

    Verify Restoration:

        Check the restore status: velero restore get

        Check that pods and services are running: kubectl get all -n production

        ArgoCD on the GKE cluster will ensure the application logic is perfectly in sync with your Git repository.

Your application is now live on GCP.
Testing Resilience

Use the provided scripts to validate the system.

    Run the Backup/Restore Test: This script performs a full backup and restore cycle within a single cluster.

    # Set context to any cluster
    ./scripts/backup-test.sh

    Run the Chaos Monkey Test: This script randomly deletes an application pod, testing Kubernetes' self-healing capabilities.

    # Set context to any cluster
    ./scripts/chaos-monkey.sh

CI/CD Pipeline

This repository includes a GitHub Actions workflow in .github/workflows/ci-cd.yml. This pipeline:

    Triggers on push or pull request to the main branch.

    Validates the Terraform configuration (terraform validate).

    Plans the infrastructure changes (terraform plan).

    Applies the changes (terraform apply) automatically on a push to main. Note: In a real-world scenario, this step should be protected by a manual approval gate.

Contributing

Contributions are welcome! Please fork the repository, create a new branch for your feature or fix, and submit a pull request.
License

This project is licensed under the MIT License. See the LICENSE file for details.