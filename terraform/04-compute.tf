#######################################
# KEY PAIR + ECS
#######################################

# Generate private key with Terraform
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register key pair in Huawei Cloud
resource "huaweicloud_compute_keypair" "keypair" {
  name       = local.keypair_name
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Store private key in DEW (CSMS) for later retrieval
resource "huaweicloud_csms_secret" "private_key" {
  name        = local.csms_secret_name
  description = "Private SSH key for the devbox ECS ${local.prefix}"
  secret_text = tls_private_key.ssh_key.private_key_pem
}

# ECS Instance
resource "huaweicloud_compute_instance" "ecs" {
  name                  = local.ecs_name
  image_name            = var.ecs_image_name
  flavor_id             = data.huaweicloud_compute_flavors.ecs_flavors.ids[0]
  availability_zone     = data.huaweicloud_availability_zones.azs.names[0]
  key_pair              = huaweicloud_compute_keypair.keypair.name
  security_groups       = [huaweicloud_networking_secgroup.sg.name]
  enterprise_project_id = length(data.huaweicloud_enterprise_project.ep) > 0 ? data.huaweicloud_enterprise_project.ep[0].id : null

  network {
    uuid = huaweicloud_vpc_subnet.subnet.id
  }

  # Un solo disco de sistema: el devbox no necesita disco de datos aparte
  system_disk_type = "SSD"
  system_disk_size = var.ecs_sys_disk

  user_data = var.cloud_init_config

  tags = local.tags
}
