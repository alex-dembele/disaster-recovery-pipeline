# terraform/variables.tf

# Variables communes
variable "project_name" {
  description = "Nom du projet utilisé pour nommer les ressources."
  type        = string
  default     = "multi-cloud-dr"
}

variable "kubernetes_version" {
  description = "Version de Kubernetes à déployer."
  type        = string
  default     = "1.28"
}

# Variables AWS
variable "aws_region" {
  description = "Région AWS pour le déploiement EKS."
  type        = string
  default     = "us-east-1"
}

variable "eks_instance_type" {
  description = "Type d'instance pour les nœuds EKS."
  type        = string
  default     = "t3.medium"
}

# Variables Azure
variable "azure_region" {
  description = "Région Azure pour le déploiement AKS."
  type        = string
  default     = "East US"
}

variable "aks_node_vm_size" {
  description = "Taille de VM pour les nœuds AKS."
  type        = string
  default     = "Standard_DS2_v2"
}

# Variables GCP
variable "gcp_project_id" {
  description = "ID du projet GCP."
  type        = string
  # Remplacez par votre ID de projet GCP
  default     = "votre-gcp-project-id"
}

variable "gcp_region" {
  description = "Région GCP pour le déploiement GKE."
  type        = string
  default     = "us-central1"
}

variable "gke_machine_type" {
  description = "Type de machine pour les nœuds GKE."
  type        = string
  default     = "e2-medium"
}
