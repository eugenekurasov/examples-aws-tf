locals {
  available_zones = slice(data.aws_availability_zones.available.names, 0, 3)
}

data "aws_availability_zones" "available" {}