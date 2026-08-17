#######################################
# CORE
#######################################
variable "region" {
  description = "Huawei Cloud region"
  type        = string
}

variable "app_env" {
  description = "Application + environment (ej: devbox)"
  type        = string
}

variable "enterprise_project_name" {
  description = "Enterprise project name (optional override)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "devbox_domain" {
  description = "Dominio publico del devbox, usado por Caddy para emitir el certificado TLS"
  type        = string
}

#######################################
# AUTH
#######################################
variable "access_key" {
  description = "Access Key (optional, prefer environment variables)"
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_key" {
  description = "Secret Key (optional, prefer environment variables)"
  type        = string
  default     = null
  sensitive   = true
}

#######################################
# NETWORKING
#######################################
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR for subnet"
  type        = string
}

variable "subnet_gateway" {
  description = "Gateway IP for subnet"
  type        = string
}

variable "dns_list" {
  description = "DNS servers"
  type        = list(string)
}

#######################################
# BANDWIDTH / EIP
#######################################
variable "bandwidth_size" {
  description = "Bandwidth size (Mbps)"
  type        = number
}

#######################################
# ECS
#######################################
variable "ecs_cpu" {
  description = "ECS CPU cores"
  type        = number
}

variable "ecs_memory" {
  description = "ECS RAM (GB)"
  type        = number
}

variable "ecs_image_name" {
  description = "ECS OS image name"
  type        = string
}

variable "ecs_sys_disk" {
  description = "ECS system disk size (GB)"
  type        = number
}

variable "cloud_init_config" {
  description = "Cloud-init configuration for ECS instance"
  type        = string
}

#######################################
# ACCESS / SECURITY
#######################################
variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH access (restrict to your IP)"
  type        = string
}

variable "allowed_https_cidr" {
  description = "CIDR allowed for HTTP/HTTPS access. Let's Encrypt valida desde Internet, asi que en la practica va 0.0.0.0/0"
  type        = string
}

#######################################
# BACKEND
#######################################
variable "tfstate_bucket" {
  description = "OBS bucket for Terraform state"
  type        = string
}

variable "tfstate_key" {
  description = "State file key in OBS bucket"
  type        = string
}
