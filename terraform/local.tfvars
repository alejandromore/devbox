# ============================================================================
# VARIABLES GENERALES
# ============================================================================
region                           = "la-south-2"
environment                      = "local"
enterprise_project_name          = "default"
devbox_domain                    = "devbox.alejandromore.lat"

tags                             = {
    environment = "local"
    project     = "devbox"
    owner       = "alejandro"
    costcenter  = "it-001"
}

cloud_init_config = <<-EOF
  #cloud-config
  timezone: America/Lima
  runcmd:
    - [ timedatectl, set-timezone, America/Lima ]
EOF

# ============================================================================
# VARIABLES PARA LA VPC
# ============================================================================
vpc_name = "vpc-devbox"
vpc_cidr = "10.4.0.0/16"

subnets_configuration = [
  {
    name = "subnet-devbox"
    cidr = "10.4.32.0/19"
    dns_list = ["100.125.1.250", "100.125.21.250"]
  }
]

security_group_name = "sg-devbox"
security_group_description = "Created by terraform module"

security_group_rules_configuration = [
  {
    description      = "Internet -> ECS (22 SSH)"
    direction        = "ingress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    ports            = "22"
    remote_ip_prefix = "0.0.0.0/0"
    action           = "allow"
    priority         = 1
  },
  {
    description      = "Internet -> ECS (80 HTTP, ACME challenge)"
    direction        = "ingress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    ports            = "80"
    remote_ip_prefix = "0.0.0.0/0"
    action           = "allow"
    priority         = 1
  },
  {
    description      = "Internet -> ECS (443 HTTPS, escritorio web)"
    direction        = "ingress"
    ethertype        = "IPv4"
    protocol         = "tcp"
    ports            = "443"
    remote_ip_prefix = "0.0.0.0/0"
    action           = "allow"
    priority         = 1
  }
]

# ============================================================================
# VARIABLES PARA EL ECS
# ============================================================================
instance_name = "ecs-devbox"

instance_flavor_cpu_core_count = 4
instance_flavor_memory_size    = 8

keypair_name = "basic-project-key"
private_key_name = "basic-project-private-key"

instance_disks_configuration = [
  {
    is_system_disk = true
    type           = "SSD"
    size           = 100
  }
]

# ============================================================================
# VARIABLES PARA EL ECS - EIP
# ============================================================================
eip_name = "eip-ecs-devbox"

eip_publicip_configuration = [
  {
    type       = "5_bgp"
    ip_version = "4"
  }
]

eip_bandwidth_configuration = [
  {
    share_type = "PER"
    name       = "eip-bw-ecs-devbox"
    size       = 5
  }
]
