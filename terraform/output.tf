output "ecs_public_ip" {
  value = module.eip_publicip.eip_ipv4_address
}

data "huaweicloud_csms_secret_version" "key_data" {
  secret_name = var.private_key_name
}

output "ecs_private_key" {
  value     = data.huaweicloud_csms_secret_version.key_data.secret_text
  sensitive = true
}
