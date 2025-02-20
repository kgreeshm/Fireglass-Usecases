terraform {
  required_providers {
    fmc = {
      source = "CiscoDevNet/fmc"
    }
  }
}
provider "fmc" {
  fmc_host                 = var.cdfmc_host
  is_cdfmc                 = true
  cdo_token                = var.scc_token
  cdfmc_domain_uuid        = "e276abec-e0f2-11e3-8169-6d9ed49b625f"
  fmc_insecure_skip_verify = true
}
