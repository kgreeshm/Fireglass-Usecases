##################################################################################################################################
#Output
##################################################################################################################################

output "FTDv_Instance_Public_IPs" {
  value = azurerm_public_ip.ftdv-mgmt-interface[*].ip_address
}

output "FMC_Instance_Public_IPs" {
  value = azurerm_public_ip.fmc-mgmt-interface[*].ip_address
}
