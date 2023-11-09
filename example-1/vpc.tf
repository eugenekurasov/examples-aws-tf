locals {
  prefix_ip = "10.42"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-great-vpc"
  cidr = "${local.prefix_ip}.0.0/16"

  azs             = local.available_zones
  private_subnets = ["${local.prefix_ip}.1.0/24", "${local.prefix_ip}.2.0/24", "${local.prefix_ip}.3.0/24"]
  intra_subnets   = ["${local.prefix_ip}.50.0/24", "${local.prefix_ip}.51.0/24", "${local.prefix_ip}.52.0/24"]
  public_subnets  = ["${local.prefix_ip}.101.0/24", "${local.prefix_ip}.102.0/24", "${local.prefix_ip}.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Module = "vpc-module"
  }
}
