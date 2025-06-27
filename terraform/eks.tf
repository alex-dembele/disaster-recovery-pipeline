# terraform/eks.tf

provider "aws" {
  region = var.aws_region
}

# Création du bucket S3 pour les sauvegardes Velero
resource "aws_s3_bucket" "velero_backups_s3" {
  bucket = "${var.project_name}-velero-backups-aws"
  
  tags = {
    Name        = "Velero Backups"
    Project     = var.project_name
  }
}

# NOTE: Ce qui suit est un exemple simplifié. 

# Création du rôle IAM pour le cluster EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "eks.amazonaws.com" },
        Action    = "sts:AssumeRole",
      },
    ],
  })
}

# Création du cluster EKS
resource "aws_eks_cluster" "eks" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    # REMPLACEZ PAR VOS IDs DE SUBNETS
    subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
  }

  depends_on = [aws_iam_role.eks_cluster_role]
}
