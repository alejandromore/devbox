region  = "la-south-2"
app_env = "devbox"

enterprise_project_name = "default"
devbox_domain           = "devbox.alejandromore.lat"

tags = {
  environment = "dev"
  project     = "devbox"
  owner       = "terraform"
}

# ============================================
# NETWORKING
# ============================================

vpc_cidr       = "10.4.0.0/16"
subnet_cidr    = "10.4.32.0/19"
subnet_gateway = "10.4.32.1"

dns_list = [
  "100.125.1.250",
  "100.125.21.250"
]

# ============================================
# BANDWIDTH / EIP
# ============================================

bandwidth_size = 5 # Mbps

# ============================================
# ECS
# ============================================

ecs_cpu        = 4
ecs_memory     = 8
ecs_image_name = "Ubuntu 24.04 server 64bit"
ecs_sys_disk   = 100

cloud_init_config = <<-EOF
  #cloud-config
  timezone: America/Lima
  runcmd:
    - [ timedatectl, set-timezone, America/Lima ]
EOF

# ============================================
# ACCESS / SECURITY
# ============================================

allowed_ssh_cidr = "0.0.0.0/0" # Restringir a tu IP: "X.X.X.X/32"

# 80 y 443 tienen que quedar abiertos a Internet: Let's Encrypt valida el
# dominio desde sus propios servidores.
allowed_https_cidr = "0.0.0.0/0"

# ============================================
# BACKEND (Terraform state)
# ============================================

tfstate_bucket = "obs-terraform-tfstate"
tfstate_key    = "devbox.tfstate"
