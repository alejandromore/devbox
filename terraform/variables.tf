# ============================================================================
# VARIABLES BASICAS
# ============================================================================
variable "region" {
  description = "Nombre de la region"
  type        = string
  default = ""
}

variable "access_key" {
  description = "Access Key de Huawei Cloud"
  type        = string
  default = ""
}

variable "secret_key" {
  description = "Secret Key de Huawei Cloud"
  type        = string
  default = ""
}

# ============================================================================
# VARIABLES GENERALES
# ============================================================================
variable "environment" {
  description = "Environment name (dev, test, prod, local)"
  type        = string
}

variable "enterprise_project_name" {
  description = "Enterprise Project name"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}

variable "cloud_init_config" {
  description = "Cloud-init configuration for ECS instances"
  type        = string
}

variable "devbox_domain" {
  description = "Dominio publico del devbox, usado por Caddy para emitir el certificado TLS"
  type        = string
}

# ============================================================================
# VARIABLES PARA LA VPC
# ============================================================================

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets_configuration" {
  description = "List of subnet configurations"
  type = list(object({
    name     = string
    cidr     = string
    dns_list = list(string)
  }))
}

variable "security_group_name" {
  description = "Security group name"
  type        = string
}

variable "security_group_description" {
  description = "Security group description"
  type        = string
}

variable "security_group_rules_configuration" {
  description = "List of security group rules"
  type = list(object({
    description      = optional(string)
    direction        = optional(string)
    ethertype        = optional(string)
    protocol         = string
    ports            = optional(string)
    remote_ip_prefix = optional(string)
    action           = optional(string)
    priority         = optional(number)
  }))
}

# ============================================================================
# VARIABLES PARA EL ECS
# ============================================================================
variable "instance_name" {
  type = string
}

variable "instance_flavor_cpu_core_count" {
  type = number
}

variable "instance_flavor_memory_size" {
  type = number
}

variable "keypair_name" {
  type = string
}

variable "private_key_name" {
  description = "Nombre de la llave privada para el ECS"
  type        = string
}

variable "instance_disks_configuration" {
  type = list(object({
    is_system_disk = bool
    name           = optional(string)
    type           = string
    size           = number
  }))
}

# ============================================================================
# VARIABLES PARA EL ECS - EIP
# ============================================================================
variable "eip_name" {
  type = string
}

variable "eip_publicip_configuration" {
  type = list(object({
    type       = string
    ip_version = string
  }))
}

variable "eip_bandwidth_configuration" {
  type = list(object({
    share_type = string
    name       = string
    size       = number
  }))
}
