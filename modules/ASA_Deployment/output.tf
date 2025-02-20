output "SSH_Private_Key" {
  value = module.network.private_key
  sensitive =true
}

output "ASA_Public_IP" {
  value = module.instance.ASA-Public-IP
}