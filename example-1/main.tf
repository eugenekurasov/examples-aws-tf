locals {
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  cluster_version = "1.28"
}

data aws_caller_identity "caller" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "my-great-cluster"
  cluster_version = local.cluster_version

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  cluster_addons                        = local.cluster_addons
  vpc_id                                = module.vpc.vpc_id
  subnet_ids                            = module.vpc.private_subnets
  control_plane_subnet_ids              = module.vpc.intra_subnets

  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_node_iam_role_arns_non_windows = [
    module.eks_managed_node.iam_role_arn
  ]

  # Not best practice for available AWS UI
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.caller.account_id}:root"
      username = "root"
      groups   = [
        "system:masters"
      ]
    }
  ]

  tags = {
    Module = "EKS"
  }
}

