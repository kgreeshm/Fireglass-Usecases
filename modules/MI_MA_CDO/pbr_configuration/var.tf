variable "fmc_host" {
    type = string
    default = ""
}

variable "fmc_username" {
  default = "admin"
}
variable "cdo_host" {
}
variable "fmc_password" {
  default = "Cisco@123"
}
variable "cdo_token" {
  type        = string
  description = "CDO Token"
}