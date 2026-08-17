#######################################
# DATA SOURCES
#######################################

# Enterprise Project
data "huaweicloud_enterprise_project" "ep" {
  count = var.enterprise_project_name != null ? 1 : 0
  name  = var.enterprise_project_name
}

# Availability Zones
data "huaweicloud_availability_zones" "azs" {}

# Dynamic flavor lookup by CPU + RAM
data "huaweicloud_compute_flavors" "ecs_flavors" {
  availability_zone = data.huaweicloud_availability_zones.azs.names[0]
  cpu_core_count    = var.ecs_cpu
  memory_size       = var.ecs_memory
}
