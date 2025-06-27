# terraform/network.tf

# Utilisation du module VPC officiel d'AWS pour créer un réseau robuste
# Il gère automatiquement les subnets publics/privés, les tables de routage, les gateways, etc.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2" # Utilisez une version stable

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  # Tags pour l'auto-découverte par le cluster EKS
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  tags = {
    Project = var.project_name
  }
}