terraform {
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
    cdo = {
      source = "CiscoDevnet/cdo"
    }
    fmc = {
      source = "CiscoDevNet/fmc"
    }
  }
}

provider "aws" {
  region = var.region
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}

provider "cdo" {
  api_token = var.cdo_token
  base_url  = local.https_cdo_host
}

provider "fmc" {
  fmc_host                 = var.cdfmc_host
  is_cdfmc                 = true
  cdo_token                = var.cdo_token
  cdfmc_domain_uuid        = "e276abec-e0f2-11e3-8169-6d9ed49b625f"
  fmc_insecure_skip_verify = true
}
