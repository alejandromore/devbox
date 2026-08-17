terraform {
  backend "s3" {
    # Credenciales del backend (via environment variables)
    region = "us-east-1"

    bucket = "obs-terraform-tfstate"
    key    = "devbox.tfstate"

    endpoints = {
      s3 = "https://obs.la-south-2.myhuaweicloud.com"
    }

    # Virtual-hosted style (requerido por Huawei Cloud)
    use_path_style              = false
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
