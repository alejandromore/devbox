# Enterprise Project
data "huaweicloud_enterprise_project" "ep" {
  name = var.enterprise_project_name
}

data "huaweicloud_availability_zones" "myaz" {}

#######################################
# VPC Module
#######################################
module "vpc_service" {
  source = "github.com/terraform-huaweicloud-modules/terraform-huaweicloud-vpc"

  availability_zone                  = data.huaweicloud_availability_zones.myaz.names[0]
  enterprise_project_id              = data.huaweicloud_enterprise_project.ep.id

  vpc_name                           = var.vpc_name
  vpc_cidr                           = var.vpc_cidr
  subnets_configuration              = var.subnets_configuration
  security_group_name                = var.security_group_name
  security_group_description         = var.security_group_description
  security_group_rules_configuration = var.security_group_rules_configuration
}

resource "huaweicloud_networking_secgroup_rule" "ecs_egress_internet" {
  security_group_id = module.vpc_service.security_group_id
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "0"
  remote_ip_prefix  = "0.0.0.0/0"
  description       = "ECS -> Internet (All traffic)"
}

#######################################
# ECS Module
#######################################
data "huaweicloud_images_images" "ubuntu_latest" {
  name_regex  = "Ubuntu 24.04"
  visibility  = "public"
}

module "ecs_service" {
  source = "github.com/terraform-huaweicloud-modules/terraform-huaweicloud-ecs"

  availability_zone                   = data.huaweicloud_availability_zones.myaz.names[0]
  enterprise_project_id               = data.huaweicloud_enterprise_project.ep.id
  instance_name                       = var.instance_name
  instance_flavor_cpu_core_count      = var.instance_flavor_cpu_core_count
  instance_flavor_memory_size         = var.instance_flavor_memory_size
  instance_image_id                   = data.huaweicloud_images_images.ubuntu_latest.images[0].id
  instance_key_pair                   = var.keypair_name

  instance_security_group_ids         = [module.vpc_service.security_group_id]

  instance_networks_configuration     = [
    {
      uuid = try(module.vpc_service.subnet_ids[0], "")
    }
  ]

  instance_user_data                  = var.cloud_init_config
  use_inside_data_disks_configuration = true
  instance_disks_configuration        = var.instance_disks_configuration
  instance_tags                       = var.tags
}

#######################################
# EIP Module
#######################################
module "eip_publicip" {
  source = "github.com/terraform-huaweicloud-modules/terraform-huaweicloud-eip/modules/eip-publicip"

  enterprise_project_id = data.huaweicloud_enterprise_project.ep.id

  eip_publicip_configuration  = var.eip_publicip_configuration
  eip_bandwidth_configuration = var.eip_bandwidth_configuration
  eip_name                    = var.eip_name

  eip_associates_configuration = [
    {
      associate_instance_type = "PORT"
      associate_instance_id   = try(module.ecs_service.instance_networks[0].port, "")
    }
  ]
}
