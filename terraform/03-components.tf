#######################################
# EIP + ASSOCIATION
#######################################

# Elastic IP con ancho de banda dedicado (PER), no compartido
resource "huaweicloud_vpc_eip" "eip" {
  name = local.eip_name

  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "bw-${local.prefix}"
    share_type  = "PER"
    size        = var.bandwidth_size
    charge_mode = "traffic"
  }

  charging_mode         = "postPaid"
  enterprise_project_id = length(data.huaweicloud_enterprise_project.ep) > 0 ? data.huaweicloud_enterprise_project.ep[0].id : null
  tags                  = local.tags
}

# Associate EIP to ECS
resource "huaweicloud_compute_eip_associate" "eip_assoc" {
  public_ip   = huaweicloud_vpc_eip.eip.address
  instance_id = huaweicloud_compute_instance.ecs.id
}
