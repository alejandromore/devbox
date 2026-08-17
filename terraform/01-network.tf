#######################################
# NETWORKING
#######################################

# VPC
resource "huaweicloud_vpc" "vpc" {
  name                  = local.vpc_name
  cidr                  = var.vpc_cidr
  region                = var.region
  enterprise_project_id = length(data.huaweicloud_enterprise_project.ep) > 0 ? data.huaweicloud_enterprise_project.ep[0].id : null

  tags = local.tags
}

# Subnet
resource "huaweicloud_vpc_subnet" "subnet" {
  name              = local.subnet_name
  vpc_id            = huaweicloud_vpc.vpc.id
  cidr              = var.subnet_cidr
  gateway_ip        = var.subnet_gateway
  description       = "Devbox subnet"
  dns_list          = var.dns_list
  dhcp_enable       = true
  availability_zone = data.huaweicloud_availability_zones.azs.names[0]
  tags              = local.tags
}
