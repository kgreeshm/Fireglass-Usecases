# variable "aws_access_key" {
#   type        = string
#   description = "AWS ACCESS KEY"
#   default = ""
# }

# variable "aws_secret_key" {
#   type        = string
#   description = "AWS SECRET KEY"
#   default = ""
# }
variable "prefix" {
  type    = string
  default = "Fireglass"
}
variable "region" {
  type        = string
  description = "AWS REGION"
  default     = "us-east-1"
}

variable "service_vpc_cidr" {
  type        = string
  description = "Service VPC CIDR"
  default     = "172.16.0.0/16"
}

variable "service_vpc_name" {
  type        = string
  description = "Service VPC Name"
  default     = "FireGlass-VPC"
}

variable "service_create_igw" {
  type        = bool
  description = "Boolean value to decide if to create IGW or not"
  default     = true
}

variable "mgmt_subnet_cidr" {
  description = "List out management Subnet CIDR . "
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.11.0/24"]
}

variable "ftd_mgmt_ip" {
  description = "List out management IPs . "
  type        = list(string)
  default     = ["172.16.1.10", "172.16.11.10"]
}

variable "outside_subnet_cidr" {
  description = "List out outside Subnet CIDR . "
  type        = list(string)
  default     = ["172.16.2.0/24", "172.16.12.0/24"]
}

variable "ftd_outside_ip" {
  type        = list(string)
  description = "List outside IPs . "
  default     = ["172.16.2.10", "172.16.12.10"]
}

variable "diag_subnet_cidr" {
  description = "List out diagonastic Subnet CIDR . "
  type        = list(string)
  default     = ["172.16.4.0/24", "172.16.14.0/24"]
}

variable "ftd_diag_ip" {
  type        = list(string)
  description = "List out FTD Diagonostic IPs . "
  default     = ["172.16.4.10", "172.16.14.10"]
}

variable "inside_subnet_cidr" {
  description = "List out inside Subnet CIDR . "
  type        = list(string)
  default     = ["172.16.3.0/24", "172.16.13.0/24"]
}

variable "ftd_inside_ip" {
  description = "List FTD inside IPs . "
  type        = list(string)
  default     = ["172.16.3.10", "172.16.13.10"]
}

variable "fmc_ip" {
  description = "List out FMCv IPs . "
  type        = string
  default     = "172.16.1.20"
}

variable "availability_zone_count" {
  type        = number
  description = "Specified availablity zone count . "
  default     = 2
}

variable "mgmt_subnet_name" {
  type        = list(string)
  description = "Specified management subnet names"
  default     = ["mgmt_subnet-1", "mgmt_subnet-2"]
}

variable "outside_subnet_name" {
  type        = list(string)
  description = "Specified outside subnet names"
  default     = ["outside_subnet-1", "outside_subnet-2"]
}

variable "diag_subnet_name" {
  description = "Specified diagonstic subnet names"
  type        = list(string)
  default     = ["diag_subnet-1", "diag_subnet-2"]
}

variable "inside_subnet_name" {
  type        = list(string)
  description = "Specified inside subnet names"
  default     = ["inside_subnet-1", "inside_subnet-2"]
}

variable "outside_interface_sg" {
  description = "Can be specified multiple times for each ingress rule. "
  type = list(object({
    from_port   = number
    protocol    = string
    to_port     = number
    cidr_blocks = list(string)
    description = string
  }))
  default = [{
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outside Interface SG"
  }]
}

variable "inside_interface_sg" {
  description = "Can be specified multiple times for each ingress rule. "
  type = list(object({
    from_port   = number
    protocol    = string
    to_port     = number
    cidr_blocks = list(string)
    description = string
  }))
  default = [{
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Inside Interface SG"
  }]
}

variable "mgmt_interface_sg" {
  description = "Can be specified multiple times for each ingress rule. "
  type = list(object({
    from_port   = number
    protocol    = string
    to_port     = number
    cidr_blocks = list(string)
    description = string
  }))
  default = [{
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Mgmt Interface SG"
  }]
}

variable "fmc_mgmt_interface_sg" {
  description = "Can be specified multiple times for each ingress rule. "
  type = list(object({
    from_port   = number
    protocol    = string
    to_port     = number
    cidr_blocks = list(string)
    description = string
  }))
  default = [{
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "FMC Mgmt Interface SG"
  }]
}

variable "instances_per_az" {
  type        = number
  description = "Specified no. of instance per az wants to be create . "
  default     = 1
}

########################################################################
## Instances
########################################################################

variable "ftd_size" {
  type        = string
  description = "FTD Instance Size"
  default     = "c5a.4xlarge"
}

variable "keyname" {
  type        = string
  description = "key to be used for the instances"
  default     = "fireglass-key"
}

variable "use_ftd_eip" {
  description = "boolean value to use EIP on FTD or not"
  type        = bool
  default     = false
}

variable "use_fmc_eip" {
  description = "boolean value to use EIP on FMC or not"
  type        = bool
  default     = true
}

variable "listener_ports" {
  description = "Load balancer will be listening on these ports."
  type = list(object({
    protocol = string
    port     = number
  }))
  default = [{
    protocol = "TCP"
    port     = 22
    },
    {
      protocol = "TCP"
      port     = 443
  }]
}

# variable "health_check" {
#   description = "port on target instance that will be used to check health status."
#   type = object({
#     protocol = string
#     port     = number
#   })
#   default = {
#     protocol = "TCP"
#     port     = 22
#   }
# }

variable "reg_key" {
  type        = string
  description = "FTD registration key"
  default     = "cisco"
}

# variable "fmc_nat_id" {
#   type        = string
#   description = "FMC Registration NAT ID"
# }

# variable "listener_ports" {
#   default = {
#     22  = "TCP"
#     443 = "TCP"
#   }
# }

# variable "health_check" {
#   default = {
#     protocol = "TCP"
#     port = 22
#   }
# }

variable "create_fmc" {
  default = true
}
