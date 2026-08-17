#######################################
# SECURITY GROUPS
#######################################
# Ojo con las descripciones: la API de VPC rechaza la regla si el texto trae
# caracteres como ">" (devuelve "is invalid rule!"). Solo texto plano.

resource "huaweicloud_networking_secgroup" "sg" {
  name                  = local.sg_name
  description           = "Security group for the devbox ECS - SSH, HTTP and HTTPS"
  enterprise_project_id = length(data.huaweicloud_enterprise_project.ep) > 0 ? data.huaweicloud_enterprise_project.ep[0].id : null
}

# SSH
resource "huaweicloud_networking_secgroup_rule" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.allowed_ssh_cidr
  security_group_id = huaweicloud_networking_secgroup.sg.id
  description       = "SSH access"
}

# HTTP: lo necesita el desafio ACME de Let's Encrypt
resource "huaweicloud_networking_secgroup_rule" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = var.allowed_https_cidr
  security_group_id = huaweicloud_networking_secgroup.sg.id
  description       = "HTTP access for the ACME challenge"
}

# HTTPS: el escritorio web
resource "huaweicloud_networking_secgroup_rule" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = var.allowed_https_cidr
  security_group_id = huaweicloud_networking_secgroup.sg.id
  description       = "HTTPS access to the web desktop"
}

# Egress - all traffic
resource "huaweicloud_networking_secgroup_rule" "egress" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = null
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.sg.id
  description       = "Allow all egress traffic"
}
