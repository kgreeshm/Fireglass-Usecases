output "FMC_URL" {
  value = module.service_network.FMC_URL
}
# output "SSH_Command_FTD" {
#   value = "ssh -i ${var.prefix}-${var.keyname} admin@${module.service_network.aws_ftd_eip}"
# }

output "Bastion_URL" {
  value = "ssh ubuntu@${aws_instance.testLinux.public_ip}"
}
