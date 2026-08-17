locals {
  prefix = var.app_env

  # ============================
  # Naming estándar
  # ============================
  vpc_name         = "vpc-${local.prefix}"
  subnet_name      = "subnet-${local.prefix}"
  sg_name          = "sg-${local.prefix}"
  eip_name         = "eip-${local.prefix}"
  ecs_name         = "ecs-${local.prefix}"
  keypair_name     = "kp-${local.prefix}"
  csms_secret_name = "csms-${local.prefix}-private-key"

  # ============================
  # Tags enriquecidos
  # ============================
  tags = merge(var.tags, {
    app_env = var.app_env
  })
}
