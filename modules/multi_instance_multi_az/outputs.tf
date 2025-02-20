output "FMC_URL" {
  value = module.service_network.FMC_URL
}
# output "SSH_Command_FTD" {
#   value = "ssh -i ${var.prefix}-${var.keyname} admin@${module.service_network.aws_ftd_eip}"
# }

output "Bastion_SSH_Command" {
  value = "ssh -i key ubuntu@${aws_instance.testLinux.public_ip}"
}

output "Inside_SSH_Command" {
  value = "ssh -i key ubuntu@172.16.3.30"
}
