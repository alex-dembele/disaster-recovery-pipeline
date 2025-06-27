# terraform/eks.tf

# Rôle IAM pour le control plane EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole",
    }]
  })
}

# Attache les politiques managées par AWS nécessaires au cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Rôle IAM pour les Nœuds de Travail (Worker Nodes)
# Ce rôle sera assumé par les instances EC2 qui composent le cluster.
resource "aws_iam_role" "eks_node_role" {
  name = "${var.project_name}-eks-node-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole",
    }]
  })
}

# Politiques nécessaires pour que les nœuds fonctionnent correctement
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# Le cluster EKS lui-même
resource "aws_eks_cluster" "eks" {
  name     = "${var.project_name}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = module.vpc.private_subnets
    endpoint_private_access = true # Sécurité : le control plane n'est pas exposé sur internet
    endpoint_public_access  = true # Gardé à true pour pouvoir utiliser kubectl depuis l'extérieur
  }

  # Activation des logs du control plane pour l'audit et le débogage
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# Groupe de nœuds managé par AWS pour la simplicité et la robustesse
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = module.vpc.private_subnets

  instance_types = [var.eks_instance_type]
  
  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  update_config {
    max_unavailable_percentage = 33 # Permet des mises à jour progressives sans interruption
  }

  tags = {
    Project = var.project_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]
}

# N'oubliez pas le bucket S3 pour Velero
resource "aws_s3_bucket" "velero_backups_s3" {
  bucket = "${var.project_name}-velero-backups-${random_string.suffix.result}"

  tags = {
    Name    = "Velero Backups"
    Project = var.project_name
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}