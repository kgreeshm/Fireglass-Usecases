# Copyright (c) 2022 Cisco Systems, Inc. and its affiliates
# All rights reserved.

variable "ftd_version" {
  description = "specified FTD version."
  type        = string
  default     = "ftdv-7.4.2"
  validation {
    error_message = "Version name should include ftdv- followed by version. Example: ftdv-7.1.0."
    condition     = can(regex("^ftdv-.*", var.ftd_version))
  }
}
variable "prefix" {
  type        = string
}
variable "create_fmc" {
  description = "Boolean value to create FMC or not"
  type        = bool
  default     = true
}

variable "fmc_version" {
  description = "specified FMC version."
  type        = string
  default     = "fmcv-7.4.2"
  validation {
    error_message = "Version name should include fmcv- followed by version. Example: fmcv-7.1.0."
    condition     = can(regex("^fmcv-.*", var.fmc_version))
  }
}

variable "keyname" {
  description = "specified key pair name to connect firewall ."
  type        = string
}

variable "instances_per_az" {
  description = "Spacified no. of instance per az wants to be create . "
  type        = number
  default     = 1
}
variable "availability_zone_count" {
  description = "Spacified availablity zone count . "
  type        = number
  default     = 2
}
variable "ftd_size" {
  description = "specified server instance type ."
  type        = string
  default     = "c5a.2xlarge"
}
variable "fmc_mgmt_ip" {
  description = "specified fmc management IPs . "
  type        = string
  default     = ""
}
# variable "fmc_nat_id" {
#   description = "specified fmc nat id . "
#   type        = string
# }
variable "ftd_mgmt_interface" {
  description = "list out existing ENI IDs to be used for ftd management interface"
  type        = list(string)
  default     = ["172.16.1.10","172.16.11.10"]
}
variable "ftd_inside_interface" {
  description = "list out existing ENI IDs to be used forftd inside interface"
  type        = list(string)
  default     = ["172.16.3.10","172.16.13.10"]
}
variable "ftd_outside_interface" {
  description = "list out existing ENI IDs to be used for outside interface"
  type        = list(string)
  default     = ["172.16.2.10","172.16.12.10"]
}
variable "ftd_outside2_interface" {
  description = "list out existing ENI IDs to be used for outside interface"
  type        = list(string)
  default     = ["172.16.5.10","172.16.15.10"]
}
variable "ftd_diag_interface" {
  description = "list out existing ENI IDs to be used for digonstic interface"
  type        = list(string)
  default     = ["172.16.4.10","172.16.14.10"]
}
variable "fmcmgmt_interface" {
  description = "list out existing ENI IDs to be used for ftd management interface ."
  type        = string
  default     = "172.16.1.20"
}

variable "tags" {
  description = "map the required tags ."
  type        = map(any)
  default     = {}
}

variable "fmc_admin_password" {
  description = "specified fmc admin password ."
  type        = string
  sensitive   = true
  default     = "Cisco@123"
}

variable "ftd_admin_password" {
  description = "specified ftd admin password ."
  type        = string
  sensitive   = true
  default     = "Cisco@123"
}

variable "fmc_hostname" {
  description = "specified fmc hostname ."
  type        = string
  default     = "FMC-01"
}

variable "reg_key" {
  description = "specified reg key ."
  type        = string
}

variable "block_encrypt" {
  description = "boolean value to encrypt block or not"
  default = false
  type = bool
}

