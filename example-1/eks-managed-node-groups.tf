locals {
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_443 = {
      description              = "Cluster API to node groups"
      protocol                 = "tcp"
      from_port                = 80#443
      to_port                  = 80#443
      type                     = "ingress"
      source_security_group_id = module.eks.cluster_security_group_id
    }
    ingress_cluster_kubelet = {
      description              = "Cluster API to node kubelets"
      protocol                 = "tcp"
      from_port                = 10250
      to_port                  = 10250
      type                     = "ingress"
      source_security_group_id = module.eks.cluster_security_group_id
    }
    ingress_cluster_ephemeral_ports_tcp = {
      description              = "Cluster API to node 1025-65535"
      protocol                 = "tcp"
      from_port                = 1025
      to_port                  = 65535
      type                     = "ingress"
      source_security_group_id = module.eks.cluster_security_group_id
    }
  }
}

resource "aws_security_group" "sg_nodes_general" {
  name_prefix = "my-great-nodes-group-general"
  description = "Security group attached to all worker nodes to allow cross-node communication and API access"
  vpc_id      = module.vpc.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sg_nodes_general" {
  for_each = local.node_security_group_additional_rules

  security_group_id = aws_security_group.sg_nodes_general.id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type

  description              = lookup(each.value, "description", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  self                     = lookup(each.value, "self", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
}


module "eks_managed_node" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "19.19.0"

  name            = "my-great-nodes"
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version
  platform        = "bottlerocket"
  ami_type        = "BOTTLEROCKET_ARM_64"

  subnet_ids                             = module.vpc.private_subnets
  cluster_primary_security_group_id      = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids                 = [aws_security_group.sg_nodes_general.id]
  update_launch_template_default_version = true

  min_size     = 1
  max_size     = 10
  desired_size = 2

  instance_types    = ["t4g.small"]
  capacity_type     = "ON_DEMAND"
  enable_monitoring = true

  labels = {
    platform = "arm"
  }

  tags = {
    Module = "eks_managed_node"
  }
}