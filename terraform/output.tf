output "ecs_public_ip" {
  value = module.eip_publicip.eip_ipv4_address
}

output "keypair_name" {
  value       = huaweicloud_kps_keypair.devbox_key.name
  description = "Key Pair registrado en KPS"
}

output "private_key_secret_name" {
  value       = huaweicloud_csms_secret.devbox_key.name
  description = "Nombre del secreto en CSMS que guarda la llave privada"
}

# Se lee desde CSMS y no desde tls_private_key para que la fuente de verdad sea
# siempre el secreto, tal como lo consume cualquier otro pipeline.
data "huaweicloud_csms_secret_version" "key_data" {
  secret_name = huaweicloud_csms_secret.devbox_key.name

  depends_on = [huaweicloud_csms_secret.devbox_key]
}

output "ecs_private_key" {
  value     = data.huaweicloud_csms_secret_version.key_data.secret_text
  sensitive = true
}
